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
        // Copyright notice in zSpy
        var int s; s = SB_New();
        SB("     "); SB(FREEAIM_VERSION); SB(", Copyright "); SBc(169 /* (C) */); SB(" 2016  mud-freak (@szapp)");
        MEM_Info("");
        MEM_Info(SB_ToString()); SB_Destroy();
        MEM_Info("     <http://github.com/szapp/g2freeAim>");
        MEM_Info("     Released under the MIT License.");
        MEM_Info("     For more details see <http://opensource.org/licenses/MIT>.");
        MEM_Info("");
        // Controls
        MEM_Info("Initializing controls.");
        HookEngineF(mouseUpdate, 5, freeAimManualRotation); // Update the player model rotation by mouse input
        HookEngineF(onDmgAnimationAddr , 9, freeAimDmgAnimation); // Disable damage animation while aiming
        // Ranged combat aiming and shooting
        MEM_Info("Initializing ranged combat aiming and shooting.");
        HookEngineF(oCAIHuman__BowMode_696296, 5, freeAimAnimation); // Update aiming animation
        HookEngineF(oCAIArrow__SetupAIVob, 6, freeAimSetupProjectile); // Set projectile direction and trajectory
        // Gothic 2 controls
        MEM_Info("Initializing Gothic 2 controls.");
        MemoryProtectionOverride(oCAIHuman__BowMode_695F2B, 6); // Skip jump to Gothic 2 controls: jz to 0x696391
        MemoryProtectionOverride(oCAIHuman__BowMode_6962F2, 2); // Shooting key: push 3
        MemoryProtectionOverride(oCAIHuman__PC_ActionMove_69A0BB, 5); // Aiming key: mov eax, [esp+8h+4h] // push eax
        // Reticle
        MEM_Info("Initializing reticle.");
        HookEngineF(oCAIHuman__BowMode, 6, freeAimManageReticle); // Manage the reticle (on/off)
        HookEngineF(oCNpcFocus__SetFocusMode, 7, freeAimSwitchMode); // Manage the reticle (on/off) and draw force
        HookEngineF(oCAIArrowBase__DoAI, 7, freeAimWatchProjectile); // AI loop for each projectile
        // Collision detection
        MEM_Info("Initializing collision detection.");
        HookEngineF(onArrowDamageAddr, 7, freeAimDetectCriticalHit); // Critical hit detection
        HookEngineF(onArrowHitChanceAddr, 5, freeAimDoNpcHit); // Decide whether a projectile hits or not
        HookEngineF(onArrowCollVobAddr, 5, freeAimOnArrowCollide); // Collision behavior on non-npc vob material
        HookEngineF(onArrowCollStatAddr, 5, freeAimOnArrowCollide); // Collision behavior on static world material
        MemoryProtectionOverride(projectileDeflectOffNpcAddr, 2); // Collision behavior on npcs: jz to 0x6A0BA3
        // Spells
        if (!FREEAIM_DISABLE_SPELLS) {
            MEM_Info("Initializing spell combat.");
            HookEngineF(oCAIHuman__MagicMode, 7, freeAimSpellReticle); // Manage focus collection and reticle
            HookEngineF(oCSpell__Setup_484BA9, 6, freeAimSetupSpell); // Set spell fx direction and trajectory
            HookEngineF(spellAutoTurnAddr, 6, freeAimDisableSpellAutoTurn); // Prevent auto turning towards target
        };
        // Console commands
        MEM_Info("Initializing console commands.");
        CC_Register(freeAimVersion, "freeaim version", "print freeaim version info");
        CC_Register(freeAimLicense, "freeaim license", "print freeaim license info");
        CC_Register(freeAimInfo, "freeaim info", "print freeaim info");
        if (FREEAIM_DEBUG_CONSOLE) || (FREEAIM_DEBUG_WEAKSPOT) || (FREEAIM_DEBUG_TRACERAY) { // Debug visualization
            MEM_Info("Initializing debug visualizations.");
            HookEngineF(zCWorld__AdvanceClock, 10, freeAimVisualizeWeakspot); // FrameFunctions hook too early
            HookEngineF(zCWorld__AdvanceClock, 10, freeAimVisualizeTraceRay);
            if (FREEAIM_DEBUG_CONSOLE) { // Enable console command for debugging
                CC_Register(freeAimDebugWeakspot, "debug freeaim weakspot", "turn debug visualization on/off");
                CC_Register(freeAimDebugTraceRay, "debug freeaim traceray", "turn debug visualization on/off");
            };
        };
        // Collectable projectiles
        if (FREEAIM_REUSE_PROJECTILES) { // Because of balancing issues, this is a constant and not a variable
            MEM_Info("Initializing collectable projectiles.");
            HookEngineF(onArrowHitNpcAddr, 5, freeAimOnArrowHitNpc); // Put projectile into inventory
            HookEngineF(onArrowHitVobAddr, 5, freeAimOnArrowGetStuck); // Keep projectile alive when stuck in vob
            HookEngineF(onArrowHitStatAddr, 5, freeAimOnArrowGetStuck); // Keep projectile alive when stuck in world
        };
        // Trigger collision fix
        if (FREEAIM_TRIGGER_COLL_FIX) { // Because by default all triggers react to objects, this is a setting
            MEM_Info("Initializing trigger collision fix.");
            HookEngineF(oCAIArrow__CanThisCollideWith, 7, freeAimTriggerCollisionCheck); // Fix trigger collision bug
        };
        // INI Settings
        MEM_Info("Initializing settings from Gothic.ini.");
        if (!MEM_GothOptExists("FREEAIM", "enabled")) { MEM_SetGothOpt("FREEAIM", "enabled", "1"); }; // If not set
        if (!MEM_GothOptExists("FREEAIM", "focusEnabled")) { MEM_SetGothOpt("FREEAIM", "focusEnabled", "1"); }
        else if (!STR_ToInt(MEM_GetGothOpt("FREEAIM", "focusEnabled"))) {
            FREEAIM_FOCUS_COLLECTION = 0; }; // No focus collection (performance) not recommended
        if (!MEM_GothOptExists("FREEAIM", "focusCollFreqMS")) { MEM_SetGothOpt("FREEAIM", "focusCollFreqMS", "10"); };
        freeAimTraceRayFreq = STR_ToInt(MEM_GetGothOpt("FREEAIM", "focusCollFreqMS"));
        if (freeAimTraceRayFreq > 500) { freeAimTraceRayFreq = 500; }; // Recalculate trace ray intersection every x ms
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

/* Update internal settings for Gothic 2 controls */
func void freeAimUpdateSettingsG2Ctrl(var int on) {
    MEM_Info("Updating internal free aim settings for Gothic 2 controls");
    if (on) { // Gothic 2 controls and free aiming enabled: Mimic the Gothic 1 controls but change the keys
        MEM_WriteByte(oCAIHuman__BowMode_695F2B, ASMINT_OP_nop); // Skip jump to Gothic 2 controls
        MEM_WriteByte(oCAIHuman__BowMode_695F2B+1, ASMINT_OP_nop);
        MEM_WriteByte(oCAIHuman__BowMode_695F2B+2, ASMINT_OP_nop);
        MEM_WriteByte(oCAIHuman__BowMode_695F2B+3, ASMINT_OP_nop);
        MEM_WriteByte(oCAIHuman__BowMode_695F2B+4, ASMINT_OP_nop);
        MEM_WriteByte(oCAIHuman__BowMode_695F2B+5, ASMINT_OP_nop);
        MEM_WriteByte(oCAIHuman__BowMode_6962F2+1, 5); // Overwrite shooting key to action button
        MEM_WriteByte(oCAIHuman__PC_ActionMove_69A0BB, ASMINT_OP_nop);
        MEM_WriteByte(oCAIHuman__PC_ActionMove_69A0BB+1, ASMINT_OP_nop);
        MEM_WriteByte(oCAIHuman__PC_ActionMove_69A0BB+2, ASMINT_OP_nop);
        MEM_WriteByte(oCAIHuman__PC_ActionMove_69A0BB+3, /*6A*/ 106); // push 0
        MEM_WriteByte(oCAIHuman__PC_ActionMove_69A0BB+4, 0); // Will be set to 0 or 1 depending on key press
        FREEAIM_G2CTRL_PREVFRAME = 1;
    } else { // Gothic 2 controls or free aiming disabled: Revert to original Gothic 2 controls
        MEM_WriteByte(oCAIHuman__BowMode_695F2B, /*0F*/ 15); // Revert G2 controls to default: jz to 0x696391
        MEM_WriteByte(oCAIHuman__BowMode_695F2B+1, /*84*/ 132);
        MEM_WriteByte(oCAIHuman__BowMode_695F2B+2, /*60*/ 96);
        MEM_WriteByte(oCAIHuman__BowMode_695F2B+3, /*04*/ 4);
        MEM_WriteByte(oCAIHuman__BowMode_695F2B+4, /*00*/ 0);
        MEM_WriteByte(oCAIHuman__BowMode_695F2B+5, /*00*/ 0);
        MEM_WriteByte(oCAIHuman__BowMode_6962F2+1, 3); // Revert to default: push 3
        MEM_WriteByte(oCAIHuman__PC_ActionMove_69A0BB, /*8B*/ 139); // Revert action key to default: mov eax, [esp+8+a3]
        MEM_WriteByte(oCAIHuman__PC_ActionMove_69A0BB+1, /*44*/ 68);
        MEM_WriteByte(oCAIHuman__PC_ActionMove_69A0BB+2, /*24*/ 36);
        MEM_WriteByte(oCAIHuman__PC_ActionMove_69A0BB+3, /*0C*/ 12); // Revert action key to default: push eax
        MEM_WriteByte(oCAIHuman__PC_ActionMove_69A0BB+4, /*50*/ 80);
        FREEAIM_G2CTRL_PREVFRAME = -1;
    };
};

/* Check whether free aiming should be activated */
func int freeAimIsActive() {
    if (!STR_ToInt(MEM_GetGothOpt("FREEAIM", "enabled"))) // Free aiming is disabled in the menu
    || (!MEM_ReadInt(mouseEnabled)) { // Mouse controls are disabled
        if (FREEAIM_ACTIVE_PREVFRAME != -1) { freeAimUpdateSettings(0); }; // Update internal settings (turn off)
        if (FREEAIM_G2CTRL_PREVFRAME != -1) { freeAimUpdateSettingsG2Ctrl(0); }; // Disable extended Gothic 2 Controls
        return 0;
    };
    if (FREEAIM_ACTIVE_PREVFRAME != 1) { freeAimUpdateSettings(1); }; // Update internal settings (turn on)
    // Everything below is only reached if free aiming is enabled (but not necessarily active)
    if (MEM_Game.pause_screen) { return 0; }; // Only when playing
    if (!InfoManager_HasFinished()) { return 0; }; // Not in dialogs
    if (!Npc_IsInFightMode(hero, FMODE_FAR)) && (!Npc_IsInFightMode(hero, FMODE_MAGIC)) { return 0; };
    // Everything below is only reached if free aiming is enabled and active (player is in respective fight mode)
    var int keyStateAiming1; var int keyStateAiming2; // Depending on control scheme either action or blocking key
    if (MEM_ReadInt(oCGame__s_bUseOldControls)) {
        keyStateAiming1 = MEM_KeyState(MEM_GetKey("keyAction")); // A bit much, but the keys are also needed below
        keyStateAiming2 = MEM_KeyState(MEM_GetSecondaryKey("keyAction"));
        if (FREEAIM_G2CTRL_PREVFRAME != -1) { freeAimUpdateSettingsG2Ctrl(0); }; // Disable extended Gothic 2 controls
    } else {
        keyStateAiming1 = MEM_KeyState(MEM_GetKey("keyParade"));
        keyStateAiming2 = MEM_KeyState(MEM_GetSecondaryKey("keyParade"));
        if (FREEAIM_G2CTRL_PREVFRAME != 1) { freeAimUpdateSettingsG2Ctrl(1); }; // Enable extended Gothic 2 controls
    };
    var int keyPressed; keyPressed = (keyStateAiming1 == KEY_PRESSED) || (keyStateAiming1 == KEY_HOLD)
        || (keyStateAiming2 == KEY_PRESSED) || (keyStateAiming2 == KEY_HOLD);  // Pressing or holding the aiming key
    if (Npc_IsInFightMode(hero, FMODE_MAGIC)) {
        if (FREEAIM_DISABLE_SPELLS) { return 0; }; // If free aiming for spells is disabled
        if (FREEAIM_G2CTRL_PREVFRAME == -1) && (!keyPressed) { return 0; }; // G1 controls require action key
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
    if (FREEAIM_G2CTRL_PREVFRAME == 1) { MEM_WriteByte(oCAIHuman__PC_ActionMove_69A0BB+4, keyPressed); }; // Aiming
    if (!keyPressed) { return 0; }; // If aiming key is not pressed or held
    // Get onset for drawing the bow - right when pressing down the aiming key
    if (keyStateAiming1 == KEY_PRESSED) || (keyStateAiming2 == KEY_PRESSED) {
        freeAimBowDrawOnset = MEM_Timer.totalTime + FREEAIM_DRAWTIME_READY; };
    return FMODE_FAR;
};
