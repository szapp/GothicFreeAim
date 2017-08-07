/*
 * Initialization
 *
 * G2 Free Aim v1.0.0-alpha - Free aiming for the video games Gothic 1 and Gothic 2 by Piranha Bytes
 * Copyright (C) 2016-2017  mud-freak (@szapp)
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
 * Initialize all hooks for the free aiming feature. This function is called from freeAimInitOnce().
 */
func void freeAimInitFeatureFreeAiming() {
    // Menu update
    HookEngineF(cGameManager__ApplySomeSettings_rtn, 6, freeAimUpdateStatus); // Update settings when leaving menu

    // Controls
    MEM_Info("Initializing free aiming mouse controls.");
    HookEngineF(mouseUpdate, 5, freeAimManualRotation); // Rotate the player model by mouse input
    if (GOTHIC_BASE_VERSION == 2) {
        MemoryProtectionOverride(oCNpc__TurnToEnemy_camCheck, 6); // G2: Prevent auto turning (target lock)
    } else {
        MemoryProtectionOverride(oCAIHuman__MagicMode_turnToTarget, 5); // G1: Prevent auto turning in magic combat
    };
    HookEngineF(oCNpc__OnDamage_Anim_getModel, 9, freeAimDmgAnimation); // Disable damage animation while aiming

    // Free aiming for ranged combat aiming and shooting
    if (GFA_RANGED) {
        MEM_Info("Initializing free aiming for ranged combat.");
        HookEngineF(oCAIHuman__BowMode_shoot, 6, freeAimRangedShooting); // Fix focus collection while shooting
        HookEngineF(oCAIHuman__BowMode_interpolateAim, 5, freeAimAnimation); // Interpolate aiming animation
        HookEngineF(oCAIArrow__SetupAIVob, 6, freeAimSetupProjectile); // Setup projectile trajectory (shooting)
        HookEngineF(oCAIArrow__ReportCollisionToAI_collAll, 8, freeAimResetGravity); // Reset gravity on collision
        // HookEngineF(oCAIHuman__BowMode_postInterpolate, 6, freeAimRangedStrafing); // Strafe when aiming. NOT WORKING

        // Gothic 2 controls
        if (GOTHIC_BASE_VERSION == 2) {
            MEM_Info("Initializing free aiming Gothic 2 controls.");
            MemoryProtectionOverride(oCAIHuman__BowMode_g2ctrlCheck, 6); // Skip jump to G2 controls: jz to 0x696391
            MemoryProtectionOverride(oCAIHuman__BowMode_shootingKey, 2); // Shooting key: push 3
            MemoryProtectionOverride(oCAIHuman__PC_ActionMove_aimingKey, 5); // Aim key: mov eax [esp+8+4], push eax
        };
    };

    // Free aiming for spells
    if (GFA_SPELLS) {
        MEM_Info("Initializing free aiming for spell combat.");
        HookEngineF(oCAIHuman__MagicMode, 7, freeAimSpellReticle); // Manage focus collection and reticle
        HookEngineF(oCSpell__Setup_oCVisFXinit, 6, freeAimSetupSpell); // Set spell FX trajectory (shooting)
    };

    // Reticle
    MEM_Info("Initializing reticle.");
    if (GFA_RANGED) {
        HookEngineF(oCAIHuman__BowMode, 6, freeAimManageReticle); // Hide reticle when not pressing aiming key
    };
    HookEngineF(oCNpcFocus__SetFocusMode, 7, freeAimSwitchMode); // Hide reticle when changing weapons, reset draw force

    // Debugging
    if (GFA_DEBUG_CONSOLE) || (GFA_DEBUG_WEAKSPOT) || (GFA_DEBUG_TRACERAY) {
        MEM_Info("Initializing debug visualizations.");
        HookEngineF(zCWorld__AdvanceClock, 10, freeAimVisualizeWeakspot); // FrameFunctions hook too late for rendering
        HookEngineF(zCWorld__AdvanceClock, 10, freeAimVisualizeTraceRay);
        if (GFA_DEBUG_CONSOLE) {
            // Enable console commands for debugging
            CC_Register(freeAimDebugWeakspot, "debug freeaim weakspot", "turn debug visualization on/off");
            CC_Register(freeAimDebugTraceRay, "debug freeaim traceray", "turn debug visualization on/off");
        };
    };

    // Read INI Settings
    MEM_Info("Initializing entries in Gothic.ini.");

    if (!MEM_GothOptExists("FREEAIM", "enabled")) {
        // Add INI-entry, if not set
        MEM_SetGothOpt("FREEAIM", "enabled", "1");
    };

    if (!MEM_GothOptExists("FREEAIM", "focusUpdateIntervalMS")) {
        // Add INI-entry, if not set (set to 10ms by default)
        MEM_SetGothOpt("FREEAIM", "focusUpdateIntervalMS", "10");
    };
};


/*
 * Initialize all hooks for the custom collision behaviors feature. This function is called form freeAimInitOnce().
 */
func void freeAimInitFeatureCustomCollisions() {
    MEM_Info("Initializing custom collision behaviors.");
    if (GOTHIC_BASE_VERSION == 1) {
        MemoryProtectionOverride(oCAIArrow__ReportCollisionToAI_destroyPrj, 7); // Disable destroying of projectiles
        MEM_WriteByte(oCAIArrow__ReportCollisionToAI_destroyPrj, ASMINT_OP_nop); // Remove fixed destruction
        MEM_WriteByte(oCAIArrow__ReportCollisionToAI_destroyPrj+1, ASMINT_OP_nop);
        MEM_WriteByte(oCAIArrow__ReportCollisionToAI_destroyPrj+2, ASMINT_OP_nop);
        MEM_WriteByte(oCAIArrow__ReportCollisionToAI_destroyPrj+3, ASMINT_OP_nop);
        MEM_WriteByte(oCAIArrow__ReportCollisionToAI_destroyPrj+4, ASMINT_OP_nop);
        MEM_WriteByte(oCAIArrow__ReportCollisionToAI_destroyPrj+5, ASMINT_OP_nop);
        MEM_WriteByte(oCAIArrow__ReportCollisionToAI_destroyPrj+6, ASMINT_OP_nop);
        HookEngineF(oCAIArrow__ReportCollisionToAI_collAll, 8, freeAimOnArrowCollide); // Collision behavior of world
        MemoryProtectionOverride(oCAIArrow__ReportCollisionToAI_keepPlyStrp, 2); // Keep projectile strip after coll
        MEM_WriteByte(oCAIArrow__ReportCollisionToAI_keepPlyStrp, /*EB*/ 235); // jmp
        MEM_WriteByte(oCAIArrow__ReportCollisionToAI_keepPlyStrp+1, /*3D*/ 61); // to 0x619648
    } else {
        // Gothic 2
        MemoryProtectionOverride(oCAIArrowBase__ReportCollisionToAI_PFXon1, 7); // Prevent too early setting of dust PFX
        MemoryProtectionOverride(oCAIArrowBase__ReportCollisionToAI_PFXon2, 7);
        MEM_WriteByte(oCAIArrowBase__ReportCollisionToAI_PFXon1, ASMINT_OP_nop); // First occurrence
        MEM_WriteByte(oCAIArrowBase__ReportCollisionToAI_PFXon1+1, ASMINT_OP_nop);
        MEM_WriteByte(oCAIArrowBase__ReportCollisionToAI_PFXon1+2, ASMINT_OP_nop);
        MEM_WriteByte(oCAIArrowBase__ReportCollisionToAI_PFXon1+3, ASMINT_OP_nop);
        MEM_WriteByte(oCAIArrowBase__ReportCollisionToAI_PFXon1+4, ASMINT_OP_nop);
        MEM_WriteByte(oCAIArrowBase__ReportCollisionToAI_PFXon1+5, ASMINT_OP_nop);
        MEM_WriteByte(oCAIArrowBase__ReportCollisionToAI_PFXon1+6, ASMINT_OP_nop);
        MEM_WriteByte(oCAIArrowBase__ReportCollisionToAI_PFXon2, ASMINT_OP_nop); // Second occurrence
        MEM_WriteByte(oCAIArrowBase__ReportCollisionToAI_PFXon2+1, ASMINT_OP_nop);
        MEM_WriteByte(oCAIArrowBase__ReportCollisionToAI_PFXon2+2, ASMINT_OP_nop);
        MEM_WriteByte(oCAIArrowBase__ReportCollisionToAI_PFXon2+3, ASMINT_OP_nop);
        MEM_WriteByte(oCAIArrowBase__ReportCollisionToAI_PFXon2+4, ASMINT_OP_nop);
        MEM_WriteByte(oCAIArrowBase__ReportCollisionToAI_PFXon2+5, ASMINT_OP_nop);
        MEM_WriteByte(oCAIArrowBase__ReportCollisionToAI_PFXon2+6, ASMINT_OP_nop);
        HookEngineF(oCAIArrowBase__ReportCollisionToAI_collVob, 5, freeAimOnArrowCollide); // Coll non-NPC vob material
        HookEngineF(oCAIArrowBase__ReportCollisionToAI_collWld, 5, freeAimOnArrowCollide); // Coll stat world material
        MemoryProtectionOverride(oCAIArrowBase__ReportCollisionToAI_collNpc, 2); // Collision behavior on NPCs
    };

    if (GFA_COLL_PRIOR_NPC == -1) {
        // Ignore NPCs after a projectile has bounced off of a surface
        HookEngineF(oCAIArrow__CanThisCollideWith, 6, freeAimDisableNpcCollisionOnRebound);
    };

    // Trigger collision fix (only necessary for Gothic 2)
    if (GFA_TRIGGER_COLL_FIX) && (GOTHIC_BASE_VERSION == 2) {
        MEM_Info("Initializing trigger collision fix.");
        HookEngineF(oCAIArrow__CanThisCollideWith, 6, freeAimTriggerCollisionCheck); // Trigger collision bug
    };
};


/*
 * Initialize all hooks for the critical hits feature. This function is called from freeAimInitOnce().
 */
func void freeAimInitFeatureCriticalHits() {
    MEM_Info("Initializing critical hit detection.");
    HookEngineF(oCAIArrow__ReportCollisionToAI_damage, 5, freeAimDetectCriticalHit); // Perform critical hit detection
    if (GOTHIC_BASE_VERSION == 1) {
        HookEngineF(oCNpc__OnDamage_Hit_criticalHit, 5, freeAimDisableDefaultCriticalHits); // Disable G1 critical hits
    };
};


/*
 * Initialize all hooks for the reusable projectiles feature. This function is called from freeAimInitOnce().
 */
func void freeAimInitFeatureReuseProjectiles() {
    MEM_Info("Initializing collectable projectiles.");
    HookEngineF(oCAIArrow__DoAI_rtn, 6, freeAimKeepProjectileInWorld); // Keep projectiles when stop moving
    HookEngineF(oCAIArrowBase__ReportCollisionToAI_hitNpc, 5, freeAimOnArrowHitNpc); // Put projectile into inventory
    if (GOTHIC_BASE_VERSION == 2) {
        // Reposition projectiles when they are stuck in the surface, only necessary for Gothic 2
        HookEngineF(oCAIArrowBase__ReportCollisionToAI_hitVob, 5, freeAimOnArrowGetStuck);
        HookEngineF(oCAIArrowBase__ReportCollisionToAI_hitWld, 5, freeAimOnArrowGetStuck);
    };
};


/*
 * Initializations to perform only once every session. This function overwrites memory protection at certain addresses,
 * and registers hooks and console commands, all depending on the selected features (see config\settings.d). The
 * function is call from freeAim_Init().
 */
func int freeAimInitOnce() {
    // Make sure LeGo is initialized with the required flags
    if ((_LeGo_Flags & GFA_LEGO_FLAGS) != GFA_LEGO_FLAGS) {
        MEM_Error("Insufficient LeGo flags for G2 Free Aim.");
        return FALSE;
    };

    // Copyright notice in zSpy
    var int s; s = SB_New();
    SB("     "); SB(GFA_VERSION); SB(", Copyright "); SBc(169 /* (C) */); SB(" 2016-2017  mud-freak (@szapp)");
    MEM_Info("");
    MEM_Info(SB_ToString()); SB_Destroy();
    MEM_Info("     <http://github.com/szapp/g2freeAim>");
    MEM_Info("     Released under the MIT License.");
    MEM_Info("     For more details see <http://opensource.org/licenses/MIT>.");
    MEM_Info("");

    // FEATURE: Free aiming
    if ((GFA_RANGED) || (GFA_SPELLS)) {
        freeAimInitFeatureFreeAiming();
    };

    // FEATURE: Custom collision behaviors
    if (GFA_CUSTOM_COLLISIONS) || ((GFA_RANGED) && (GFA_TRUE_HITCHANCE)) {
        HookEngineF(oCAIArrow__ReportCollisionToAI_hitChc, 5, freeAimDoNpcHit); // Hit registration, change hit chance
    };
    if (GFA_CUSTOM_COLLISIONS) {
        freeAimInitFeatureCustomCollisions();
    };

    // FEATURE: Critical hits
    if (GFA_CRITICALHITS) {
        freeAimInitFeatureCriticalHits();
    };

    // FEATURE: Reusable projectiles
    if (GFA_REUSE_PROJECTILES) {
        // Because of balancing issues, this is feature is stored as a constant and not a variable. It should not be
        // enabled/disabled during the game. That would cause too many/too few projectiles
        freeAimInitFeatureReuseProjectiles();
    };

    // Register console commands
    MEM_Info("Initializing console commands.");
    CC_Register(freeAimVersion, "freeaim version", "print freeaim version info");
    CC_Register(freeAimLicense, "freeaim license", "print freeaim license info");
    CC_Register(freeAimInfo, "freeaim info", "print freeaim info");

    // Successfully initialized
    return TRUE;
};


/*
 * Initializations to perfrom on every game start, level change and loading of saved games. This function is called from
 * freeAim_Init().
 */
func void freeAimInitAlways() {
    // Pause frame functions when in menu
    Timer_SetPauseInMenu(1);

    // Retrieve trace ray interval: Recalculate trace ray intersection every x ms
    GFA_AimRayInterval = STR_ToInt(MEM_GetGothOpt("FREEAIM", "focusUpdateIntervalMS"));
    if (GFA_AimRayInterval > 500) {
        GFA_AimRayInterval = 500;
    };

    // Reset/reinitialize free aiming settings every time to prevent crashes
    if ((GFA_RANGED) || (GFA_SPELLS)) {
        // On level change, Gothic does not maintain the focus instances (see Focus.d), nor does it reinitialize them.
        // The focus instances are, however, critical for enabling/disabling free aiming: Reinitialize them by hand.
        if (!_@(Focus_Ranged)) {
            MEM_Info("Initializing focus modes.");
            const int call = 0;
            if (CALL_Begin(call)) {
                CALL__cdecl(oCNpcFocus__InitFocusModes);
                call = CALL_End();
            };
        };

        // Reset internal settings. Focus instances would otherwise not be updated on level change
        GFA_ACTIVE = 0;
        freeAimUpdateStatus();

        // Remove reticle. Would otherwise be stuck on screen on level change
        freeAimManageReticle();

        // Reset aim ray calculation time. Would otherwise result in an invalid vob pointer on loading a game (crash)
        GFA_AimRayPrevCalcTime = 0;

        // Reset debug vob pointer. Would otherwise result in an invalid vob pointer on loading a game (crash)
        GFA_DebugTRPrevVob = 0;
    };
};


/*
 * Initialize free aim framework. This function is called in Init_Global(). It includes registering hooks, console
 * commands and the retrieval of settings from the INI-file and other initializations.
 */
func void freeAim_Init() {
    // Ikarus and LeGo need to be initialized first
    const int INIT_LEGO_NEEDED = 0; // Set to 1, if LeGo is not initialized by user (in INIT_Global())
    if (!_LeGo_Init) {
        LeGo_Init(_LeGo_Flags | GFA_LEGO_FLAGS);
        INIT_LEGO_NEEDED = 1;
    } else if (INIT_LEGO_NEEDED) {
        // If user does not initialize LeGo in INIT_Global(), as determined by INIT_LEGO_NEEDED, reinitialize Ikarus and
        // LeGo on every level change and loading here
        LeGo_Init(_LeGo_Flags);
    };

    // Fix zTimer for Gothic 1 (the address in Ikarus is wrong)
    if (GOTHIC_BASE_VERSION == 1) {
        MEMINT_zTimer_Address = ztimer;
        MEM_Timer = _^(MEMINT_zTimer_Address);
    };

    MEM_Info(ConcatStrings(ConcatStrings("Initialize ", GFA_VERSION), "."));

    // Perform only once per session
    const int INITIALIZED = 0;
    if (!INITIALIZED) {
        if (!freeAimInitOnce()) {
            MEM_Info(ConcatStrings(GFA_VERSION, " failed to initialize."));
            return;
        };
    };
    INITIALIZED = 1;

    // Perform for every new session and on every load and level change
    freeAimInitAlways();

    MEM_Info(ConcatStrings(GFA_VERSION, " was initialized successfully."));
};
