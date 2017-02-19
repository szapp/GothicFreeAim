/*
 * Initialization
 *
 * G2 Free Aim v0.1.2 - Free aiming for the video game Gothic 2 by Piranha Bytes
 * Copyright (C) 2016  mud-freak (@szapp)
 *
 * This file is part of G2 Free Aim.
 * <http://github.com/szapp/g2freeAim>
 *
 * G2 Free Aim is free software: you can redistribute it and/or modify
 * it under the terms of the MIT License.
 * On redistribution this notice must remain intact and all copies must
 * identify the original author.
 *
 * G2 Free Aim is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * MIT License for more details.
 *
 * You should have received a copy of the MIT License
 * along with G2 Free Aim.  If not, see <http://opensource.org/licenses/MIT>.
 */

/* Initialize free aim framework */
func void freeAim_Init() {
    const int hookFreeAim = 0;
    if (!hookFreeAim) {
        MEM_Info(""); // Copyright notice in zSpy
        var int s; s = SB_New();
        SB("     "); SB(FREEAIM_VERSION); SB(", Copyright "); SBc(169 /* (C) */); SB(" 2016  mud-freak (@szapp)");
        MEM_Info(SB_ToString()); SB_Destroy();
        MEM_Info("     <http://github.com/szapp/g2freeAim>");
        MEM_Info("     Released under the MIT License.");
        MEM_Info("     For more details see <http://opensource.org/licenses/MIT>.");
        MEM_Info("");
        CC_Register(freeAimVersion, "freeaim version", "print freeaim version info");
        CC_Register(freeAimLicense, "freeaim license", "print freeaim license info");
        CC_Register(freeAimInfo, "freeaim info", "print freeaim info");
        HookEngineF(oCAniCtrl_Human__InterpolateCombineAni, 5, freeAimAnimation); // Update aiming animation
        HookEngineF(oCAIArrow__SetupAIVob, 6, freeAimSetupProjectile); // Set projectile direction and trajectory
        HookEngineF(oCAIHuman__BowMode, 6, freeAimManageReticle); // Manage the reticle (on/off)
        HookEngineF(oCNpcFocus__SetFocusMode, 7, freeAimSwitchMode); // Manage the reticle (on/off) and draw force
        HookEngineF(mouseUpdate, 5, freeAimManualRotation); // Update the player model rotation by mouse input
        HookEngineF(oCAIArrowBase__DoAI, 7, freeAimWatchProjectile); // AI loop for each projectile
        HookEngineF(onArrowDamageAddr, 7, freeAimDetectCriticalHit); // Critical hit detection
        HookEngineF(onArrowHitChanceAddr, 5, freeAimDoNpcHit); // Decide whether a projectile hits or not
        MemoryProtectionOverride(projectileDeflectOffNpcAddr, 2); // Collision behavior on npcs
        HookEngineF(onArrowCollVobAddr, 5, freeAimOnArrowCollide); // Collision behavior on non-npc vob material
        HookEngineF(onArrowCollStatAddr, 5, freeAimOnArrowCollide); // Collision behavior on static world material
        HookEngineF(onDmgAnimationAddr , 9, freeAimDmgAnimation); // Disable damage animation while aiming
        if (!FREEAIM_DISABLE_SPELLS) {
            HookEngineF(oCAIHuman__MagicMode, 7, freeAimSpellReticle); // Manage focus collection and reticle
            HookEngineF(oCSpell__Setup_484BA9, 6, freeAimSetupSpell); // Set spell fx direction and trajectory
            HookEngineF(spellAutoTurnAddr, 6, freeAimDisableSpellAutoTurn); // Prevent auto turning towards target
        };
        if (FREEAIM_DEBUG_CONSOLE) || (FREEAIM_DEBUG_WEAKSPOT) || (FREEAIM_DEBUG_TRACERAY) { // Debug visualization
            HookEngineF(zCWorld__AdvanceClock, 10, freeAimVisualizeWeakspot); // FrameFunctions hook too early
            HookEngineF(zCWorld__AdvanceClock, 10, freeAimVisualizeTraceRay);
            if (FREEAIM_DEBUG_CONSOLE) { // Enable console command for debugging
                CC_Register(freeAimDebugWeakspot, "debug freeaim weakspot", "turn debug visualization on/off");
                CC_Register(freeAimDebugTraceRay, "debug freeaim traceray", "turn debug visualization on/off");
            };
        };
        if (FREEAIM_REUSE_PROJECTILES) { // Because of balancing issues, this is a constant and not a variable
            HookEngineF(onArrowHitNpcAddr, 5, freeAimOnArrowHitNpc); // Put projectile into inventory
            HookEngineF(onArrowHitVobAddr, 5, freeAimOnArrowGetStuck); // Keep projectile alive when stuck in vob
            HookEngineF(onArrowHitStatAddr, 5, freeAimOnArrowGetStuck); // Keep projectile alive when stuck in world
        };
        if (FREEAIM_TRIGGER_COLL_FIX) { // Because by default all triggers react to objects, this is a setting
            HookEngineF(oCAIArrow__CanThisCollideWith, 7, freeAimTriggerCollisionCheck); // Fix trigger collision bug
        };
        if (!MEM_GothOptExists("FREEAIM", "enabled")) { MEM_SetGothOpt("FREEAIM", "enabled", "1"); }; // If not set
        if (!MEM_GothOptExists("FREEAIM", "focusEnabled")) { MEM_SetGothOpt("FREEAIM", "focusEnabled", "1"); }
        else if (!STR_ToInt(MEM_GetGothOpt("FREEAIM", "focusEnabled"))) {
            FREEAIM_FOCUS_COLLECTION = 0; }; // No focuscollection (performance) not recommended
        r_DefaultInit(); // Start rng for aiming accuracy
        hookFreeAim = 1;
    };
    MEM_Info(ConcatStrings(FREEAIM_VERSION, " initialized successfully."));
};

/* Update internal settings when turning free aim on/off in the options */
func void freeAimUpdateSettings(var int on) {
    MEM_Info("Updating internal free aim settings");
    MEM_InitGlobalInst(); // Important as this function will be called during level change, otherwise the game crashes
    if (on) {
        Focus_Ranged.npc_azi = 15.0; // Set stricter focus collection
        MEM_WriteString(zString_CamModRanged, STR_Upper(FREEAIM_CAMERA)); // New camera mode, upper case is important
        if (!FREEAIM_DISABLE_SPELLS) { MEM_WriteString(zString_CamModMagic, STR_Upper(FREEAIM_CAMERA)); };
        FREEAIM_ACTIVE_PREVFRAME = 1;
    } else {
        Focus_Ranged.npc_azi = 45.0; // Reset ranged focus collection to standard
        Focus_Magic.npc_azi = 45.0;
        Focus_Magic.item_prio = -1;
        FREEAIM_FOCUS_SPELL_FREE = -1;
        MEM_WriteString(zString_CamModRanged, "CAMMODRANGED"); // Restore camera mode, upper case is important
        MEM_WriteString(zString_CamModMagic, "CAMMODMAGIC"); // Also for spells
        MEM_WriteByte(projectileDeflectOffNpcAddr, /*74*/ 116); // Reset to default collision behavior on npcs
        MEM_WriteByte(projectileDeflectOffNpcAddr+1, /*3B*/ 59); // jz to 0x6A0BA3
        FREEAIM_ACTIVE_PREVFRAME = -1;
    };
};

/* Check whether free aiming should be activated */
func int freeAimIsActive() {
    if (!STR_ToInt(MEM_GetGothOpt("FREEAIM", "enabled"))) // Free aiming is disabled in the menu
    || (!MEM_ReadInt(mouseEnabled)) // Mouse controls are disabled
    || (!MEM_ReadInt(oCGame__s_bUseOldControls)) { // Classic gothic 1 controls are disabled
        if (FREEAIM_ACTIVE_PREVFRAME != -1) { freeAimUpdateSettings(0); }; // Update internal settings (turn off)
        return 0;
    };
    if (FREEAIM_ACTIVE_PREVFRAME != 1) { freeAimUpdateSettings(1); }; // Update internal settings (turn on)
    // Everything below is only reached if free aiming is enabled (but not necessarily active)
    if (MEM_Game.pause_screen) { return 0; }; // Only when playing
    if (!InfoManager_HasFinished()) { return 0; }; // Not in dialogs
    if (!Npc_IsInFightMode(hero, FMODE_FAR)) && (!Npc_IsInFightMode(hero, FMODE_MAGIC)) { return 0; };
    // Everything below is only reached if free aiming is enabled and active (player is in respective fight mode)
    var int keyStateAction1; keyStateAction1 = MEM_KeyState(MEM_GetKey("keyAction")); // A bit much, but needed below
    var int keyStateAction2; keyStateAction2 = MEM_KeyState(MEM_GetSecondaryKey("keyAction"));
    if (keyStateAction1 != KEY_PRESSED) && (keyStateAction1 != KEY_HOLD) // Only while pressing the action button
    && (keyStateAction2 != KEY_PRESSED) && (keyStateAction2 != KEY_HOLD) { return 0; };
    if (Npc_IsInFightMode(hero, FMODE_MAGIC)) {
        if (FREEAIM_DISABLE_SPELLS) { return 0; }; // If free aiming for spells is disabled
        var C_Spell spell; spell = freeAimGetActiveSpellInst(hero);
        if (!freeAimSpellEligible(spell)) { // Check if the active spell supports free aiming
            if (FREEAIM_FOCUS_SPELL_FREE != -1) {
                Focus_Magic.npc_azi = 45.0; // Reset ranged focus collection
                Focus_Magic.item_prio = -1;
                FREEAIM_FOCUS_SPELL_FREE = -1;
            };
            return 0;
        };
        if (FREEAIM_FOCUS_SPELL_FREE != 1) {
            Focus_Magic.npc_azi = 15.0; // Set stricter focus collection
            Focus_Magic.item_prio = 0;
            FREEAIM_FOCUS_SPELL_FREE = 1;
        };
        return FMODE_MAGIC;
    };
    // Get onset for drawing the bow - right when pressing down the action key
    if (keyStateAction1 == KEY_PRESSED) || (keyStateAction2 == KEY_PRESSED) {
        freeAimBowDrawOnset = MEM_Timer.totalTime + FREEAIM_DRAWTIME_READY; };
    return FMODE_FAR;
};
