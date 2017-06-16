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


/*
 * Initialize free aim framework. This function is called in Init_Global(). It includes registering hooks, console
 * commands and the retrieval of settings from the INI-file and other initializations.
 */
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
        MemoryProtectionOverride(oCNpc__TurnToEnemy_737D75, 6); // Prevent auto turning towards target
        HookEngineF(onDmgAnimationAddr , 9, freeAimDmgAnimation); // Disable damage animation while aiming
        // Ranged combat aiming and shooting
        MEM_Info("Initializing ranged combat aiming and shooting.");
        HookEngineF(oCAIHuman__BowMode_69633B, 6, freeAimRangedShooting); // Focus collection during shooting
        HookEngineF(oCAIHuman__BowMode_696296, 5, freeAimAnimation); // Update aiming animation
        HookEngineF(oCAIArrow__SetupAIVob, 6, freeAimSetupProjectile); // Set projectile direction and trajectory
        HookEngineF(oCAIArrow__DoAI_6A1489, 6, freeAimKeepProjectileInWorld); // End of DoAI loop for each projectile
        // Gothic 2 controls
        MEM_Info("Initializing Gothic 2 controls.");
        MemoryProtectionOverride(oCAIHuman__BowMode_695F2B, 6); // Skip jump to Gothic 2 controls: jz to 0x696391
        MemoryProtectionOverride(oCAIHuman__BowMode_6962F2, 2); // Shooting key: push 3
        MemoryProtectionOverride(oCAIHuman__PC_ActionMove_69A0BB, 5); // Aiming key: mov eax, [esp+8h+4h] // push eax
        // Reticle
        MEM_Info("Initializing reticle.");
        HookEngineF(oCAIHuman__BowMode, 6, freeAimManageReticle); // Manage the reticle (on/off)
        HookEngineF(oCNpcFocus__SetFocusMode, 7, freeAimSwitchMode); // Manage the reticle (on/off) and draw force
        // Collision detection
        MEM_Info("Initializing collision detection.");
        HookEngineF(onArrowDamageAddr, 7, freeAimDetectCriticalHit); // Critical hit detection
        HookEngineF(onArrowHitChanceAddr, 5, freeAimDoNpcHit); // Decide whether a projectile hits or not
        HookEngineF(onArrowCollVobAddr, 5, freeAimOnArrowCollide); // Collision behavior on non-NPC vob material
        HookEngineF(onArrowCollStatAddr, 5, freeAimOnArrowCollide); // Collision behavior on static world material
        MemoryProtectionOverride(projectileDeflectOffNpcAddr, 2); // Collision behavior on NPCs: jz to 0x6A0BA3
        // Spells
        if (!FREEAIM_DISABLE_SPELLS) {
            MEM_Info("Initializing spell combat.");
            HookEngineF(oCAIHuman__MagicMode, 7, freeAimSpellReticle); // Manage focus collection and reticle
            HookEngineF(oCSpell__Setup_484BA9, 6, freeAimSetupSpell); // Set spell fx direction and trajectory
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
        if (!MEM_GothOptExists("FREEAIM", "focusCollIntvMS")) { MEM_SetGothOpt("FREEAIM", "focusCollIntvMS", "10"); };
        freeAimRayInterval = STR_ToInt(MEM_GetGothOpt("FREEAIM", "focusCollIntvMS"));
        if (freeAimRayInterval > 500) { freeAimRayInterval = 500; }; // Recalculate trace ray intersection every x ms
        r_DefaultInit(); // Start rng for aiming accuracy
        hookFreeAim = 1;
    };
    // Reset setting constant. In case of loading a game the focus instances would not be updated
    FREEAIM_ACTIVE = 0;
    MEM_Call(freeAimManageReticle); // Remove reticle on level change

    MEM_Info(ConcatStrings(FREEAIM_VERSION, " initialized successfully."));
};


/*
 * This function assigns the focus instances (see Focus.d). This is necessary after a level change, because Gothic does
 * not do it. The focus instances are, however, critical for enabling/disabling free aiming.
 * The function is called when setting the focus instances, in case of changing the free aiming settings or drawing a
 * spell that supports free aiming after a spell that does not.
 */
func void freeAimReinitFocus() {
    if (!_@(Focus_Ranged)) {
        MEM_Info("Reinitializing focus modes");
        const int call = 0;
        if (CALL_Begin(call)) {
            CALL__cdecl(oCNpcFocus__InitFocusModes);
            call = CALL_End();
        };
    };
};


/*
 * Update internal settings when turning free aim on/off in the options menu. Settings include focus ranges/angles,
 * camera angles along with resetting some other settings. The constant FREEAIM_ACTIVE will be updated accordingly.
 * This function is called from freeAimIsActive() nearly every frame.
 */
func void freeAimUpdateSettings(var int on) {
    if ((FREEAIM_ACTIVE > 0) == on) {
        return; // No change necessary
    };

    MEM_Info("Updating internal free aim settings");
    freeAimReinitFocus();

    if (on) {
        // Set stricter focus collection
        Focus_Ranged.npc_azi = 15.0;

        // New camera modes, upper case is important
        MEM_WriteString(zString_CamModRanged, STR_Upper(FREEAIM_CAMERA));
        if (!FREEAIM_DISABLE_SPELLS) {
            MEM_WriteString(zString_CamModMagic, STR_Upper(FREEAIM_CAMERA));
        };
    } else {
        // Reset ranged focus collection to standard
        Focus_Ranged.npc_azi = 45.0;
        Focus_Magic.npc_azi = 45.0;
        Focus_Magic.item_prio = -1;

        // Restore camera modes, upper case is important
        MEM_WriteString(zString_CamModRanged, "CAMMODRANGED");
        MEM_WriteString(zString_CamModMagic, "CAMMODMAGIC");

        // Reset to default collision behavior on NPCs
        MEM_WriteByte(projectileDeflectOffNpcAddr, /*74*/ 116); // jz to 0x6A0BA3
        MEM_WriteByte(projectileDeflectOffNpcAddr+1, /*3B*/ 59);
    };
    FREEAIM_ACTIVE = !FREEAIM_ACTIVE;
};


/*
 * Update internal settings for Gothic 2 controls.
 * The support for the Gothic 2 controls is accomplished by emulating the Gothic 1 controls with different sets of
 * aiming and shooting keys. To do this, the condition to differentiate between the control schemes is skipped and the
 * keys are overwritten (all on the level of opcode).
 * This function is called from freeAimIsActive() nearly every frame.
 */
func void freeAimUpdateSettingsG2Ctrl(var int on) {
    const int SET = 0; // Gothic 1 controls are considered default here
    if (SET == on) {
        return; // No change necessary
    };

    MEM_Info("Updating internal free aim settings for Gothic 2 controls");
    if (on) {
        // Gothic 2 controls enabled: Mimic the Gothic 1 controls but change the keys
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
    } else {
        // Gothic 2 controls disabled: Revert to original Gothic 2 controls
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
    };
    SET = !SET;
};


/*
 * Disable/re-enable auto turning of player model towards enemy while aiming. The auto turning prevents free aiming, as
 * it moves the player model to always face the focus. Of course, this should only by prevented during aiming such that
 * the melee combat is not affected. Consequently, it needs to be disabled and enabled continuously.
 * This function is called from freeAimIsActive() nearly every frame.
 */
func void freeAimDisableAutoTurn(var int on) {
    const int SET = 0;
    if (on == SET) {
        return; // No change necessary
    };

    // MEM_Info("Updating internal free aim settings for auto turning"); // Happens too often
    if (on) {
        // Jump from 0x737D75 to 0x737E32: 7568946-7568757 = 189-5 = 184 // Length of instruction: 5
        MEM_WriteByte(oCNpc__TurnToEnemy_737D75, /*E9*/ 233); // jmp
        MEM_WriteByte(oCNpc__TurnToEnemy_737D75+1, /*B8*/ 184); // B8 instead of B7 because jmp is of length 5 not 6
        MEM_WriteByte(oCNpc__TurnToEnemy_737D75+2, /*00*/ 0);
        MEM_WriteByte(oCNpc__TurnToEnemy_737D75+5, ASMINT_OP_nop);
    } else {
        MEM_WriteByte(oCNpc__TurnToEnemy_737D75, /*0F*/ 15); // Revert to default: jnz loc_00737E32
        MEM_WriteByte(oCNpc__TurnToEnemy_737D75+1, /*85*/ 133);
        MEM_WriteByte(oCNpc__TurnToEnemy_737D75+2, /*B7*/ 183);
        MEM_WriteByte(oCNpc__TurnToEnemy_737D75+5, /*00*/ 0);
    };
    SET = !SET;
};


/*
 * This function is called nearly every frame by freeAimManualRotation() to check whether free aiming is enabled and
 * active (player in either magic or ranged combat). It sets the constant FREEAIM_ACTIVE accordingly:
 *  0 if disabled in menu or mouse disabled
 *  1 if enabled but not active (not currently aiming)
 *  5 if enabled and currently aiming in ranged fight mode (FMODE_FAR)
 *  7 if enabled and currently aiming in magic fight mode with FA-eligible spell (FMODE_MAGIC)
 * Different checks are performed in performance-favoring order (exiting the function as early as possible) to set the
 * constant, which is subsequently used in a lot of functions to determine the state of free aiming.
 */
func void freeAimIsActive() {

    // Check if g2freeAim is enabled and mouse controls are enabled
    if (!STR_ToInt(MEM_GetGothOpt("FREEAIM", "enabled"))) || (!MEM_ReadInt(mouseEnabled)) {
        // Disable if previously enabled
        freeAimUpdateSettings(0);
        freeAimUpdateSettingsG2Ctrl(0);
        freeAimDisableAutoTurn(0);
        return;
    } else {
        // Enable if previously disabled
        freeAimUpdateSettings(1);
    };

    // Check if currently in a menu or in a dialog
    if (MEM_Game.pause_screen) || (!InfoManager_HasFinished()) {
        freeAimDisableAutoTurn(0);
        FREEAIM_ACTIVE = 1;
        return;
    };

    // Before anything else, check if player is in magic or ranged fight mode
    var oCNpc her; her = Hlp_GetNpc(hero);
    if (her.fmode < FMODE_FAR) {
        freeAimDisableAutoTurn(0);
        FREEAIM_ACTIVE = 1;
        return;
    };

    // Set aiming key depending on control scheme to either action or blocking key
    var String keyAiming;
    if (MEM_ReadInt(oCGame__s_bUseOldControls)) { // Gothic 1 controls
        keyAiming = "keyAction";
        freeAimUpdateSettingsG2Ctrl(0);
    } else { // Gothic 2 controls
        keyAiming = "keyParade";
        freeAimUpdateSettingsG2Ctrl(1);
    };
    var int keyStateAiming1; keyStateAiming1 = MEM_KeyState(MEM_GetKey(keyAiming));
    var int keyStateAiming2; keyStateAiming2 = MEM_KeyState(MEM_GetSecondaryKey(keyAiming));

    // Check if aiming button is pressed/held
    var int keyPressed; keyPressed = (keyStateAiming1 == KEY_PRESSED) || (keyStateAiming1 == KEY_HOLD)
                                  || (keyStateAiming2 == KEY_PRESSED) || (keyStateAiming2 == KEY_HOLD);

    // Check fight mode
    if (her.fmode == FMODE_MAGIC) {
        // Check if free aiming for spells is disabled
        if (FREEAIM_DISABLE_SPELLS) {
            freeAimDisableAutoTurn(0);
            FREEAIM_ACTIVE = 1;
            return;
        };

        // Gothic 1 controls require action key to be pressed/held
        if (MEM_ReadInt(oCGame__s_bUseOldControls)) && (!keyPressed) {
            freeAimDisableAutoTurn(0);
            FREEAIM_ACTIVE = 1;
            return;
        };

        // Check if active spell supports free aiming
        freeAimReinitFocus();
        var C_Spell spell; spell = freeAimGetActiveSpellInst(hero);
        if (!freeAimSpellEligible(spell)) {
            // Reset ranged focus collection
            Focus_Magic.npc_azi = 45.0;
            Focus_Magic.item_prio = -1;
            freeAimDisableAutoTurn(0);
            FREEAIM_ACTIVE = 1;
            return;
        } else {
            // Spell uses free aiming: Set stricter focus collection
            Focus_Magic.npc_azi = 15.0;
            Focus_Magic.item_prio = 0;
            freeAimDisableAutoTurn(1);
            FREEAIM_ACTIVE = her.fmode;
        };

    } else if (her.fmode == FMODE_FAR) {
        // Set internally whether the aiming key is held or not (only if using Gothic 2 controls)
        if (!MEM_ReadInt(oCGame__s_bUseOldControls)) {
            MEM_WriteByte(oCAIHuman__PC_ActionMove_69A0BB+4, keyPressed);
        };

        // Check if aiming key is not pressed/held
        if (!keyPressed) {
            freeAimDisableAutoTurn(0);
            FREEAIM_ACTIVE = 1;
            return;
        } else {
            freeAimDisableAutoTurn(1);
            FREEAIM_ACTIVE = her.fmode;
        };

        // Get onset for drawing the bow - right when pressing down the aiming key
        if (keyStateAiming1 == KEY_PRESSED) || (keyStateAiming2 == KEY_PRESSED) {
            freeAimBowDrawOnset = MEM_Timer.totalTime + FREEAIM_DRAWTIME_READY;
        };
    };
};
