/*
 * Initialization of GFA
 *
 * Gothic Free Aim (GFA) v1.0.0-beta.21 - Free aiming for the video games Gothic 1 and Gothic 2 by Piranha Bytes
 * Copyright (C) 2016-2017  mud-freak (@szapp)
 *
 * This file is part of Gothic Free Aim.
 * <http://github.com/szapp/GothicFreeAim>
 *
 * Gothic Free Aim is free software: you can redistribute it and/or
 * modify it under the terms of the MIT License.
 * On redistribution this notice must remain intact and all copies must
 * identify the original author.
 *
 * Gothic Free Aim is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * MIT License for more details.
 *
 * You should have received a copy of the MIT License along with
 * Gothic Free Aim.  If not, see <http://opensource.org/licenses/MIT>.
 */


/*
 * Initialize all hooks for the free aiming feature. This function is called from GFA_InitOnce().
 */
func void GFA_InitFeatureFreeAiming() {
    // Menu update
    HookEngineF(cGameManager__ApplySomeSettings_rtn, 6, GFA_UpdateStatus); // Update settings when leaving menu

    // The hook initializations for free aiming have been moved into a dedicated function GFA_AddFreeAimingHooks(). This
    // was done to allow removing the hooks dynamically by changing the game menu setting of free aiming, with the
    // complementary funciton GFA_RemoveFreeAimingHooks().

    // Read INI Settings
    MEM_Info("Initializing entries in Gothic.ini.");

    if (!MEM_GothOptExists("GFA", "freeAimingEnabled")) {
        // Add INI-entry, if not set
        MEM_SetGothOpt("GFA", "freeAimingEnabled", "1");
    };

    if (!MEM_GothOptExists("GFA", "focusUpdateIntervalMS")) {
        // Add INI-entry, if not set (set to instantaneous=0ms by default)
        MEM_SetGothOpt("GFA", "focusUpdateIntervalMS", "0");
    };

    if (GOTHIC_BASE_VERSION == 2) {
        if (GFA_Flags & GFA_RANGED) {
            if (!MEM_GothOptExists("GFA", "overwriteControlSchemeRanged")) {
                // Add INI-entry, if not set (disable override by default)
                MEM_SetGothOpt("GFA", "overwriteControlSchemeRanged", "0");
            };
        };

        if (GFA_Flags & GFA_SPELLS) {
            if (!MEM_GothOptExists("GFA", "overwriteControlSchemeSpells")) {
                // Add INI-entry, if not set (disable override by default)
                MEM_SetGothOpt("GFA", "overwriteControlSchemeSpells", "0");
            };
        };
    };
};


/*
 * Initialize all hooks for the custom collision behaviors feature. This function is called form GFA_InitOnce().
 */
func void GFA_InitFeatureCustomCollisions() {
    MEM_Info("Initializing custom collision behaviors.");
    HookEngineF(oCAIArrow__ReportCollisionToAI_hitChc, 6, GFA_CC_ProjectileCollisionWithNpc); // Hit reg/coll on NPCs
    HookEngineF(oCAIArrow__ReportCollisionToAI_damage, 5, GFA_CC_SetDamageBehavior); // Change knockout behavior
    if (GOTHIC_BASE_VERSION == 1) {
        MemoryProtectionOverride(oCAIArrow__ReportCollisionToAI_destroyPrj, 7); // Disable destroying of projectiles
        repeat(i, 7); var int i;
            MEM_WriteByte(oCAIArrow__ReportCollisionToAI_destroyPrj+i, ASMINT_OP_nop); // Disable fixed destruction
        end;
        HookEngineF(oCAIArrow__ReportCollisionToAI_collAll, 8, GFA_CC_ProjectileCollisionWithWorld); // Collision world
        MemoryProtectionOverride(oCAIArrow__ReportCollisionToAI_keepPlyStrp, 2); // Keep poly strip after coll
        MEM_WriteByte(oCAIArrow__ReportCollisionToAI_keepPlyStrp, /*EB*/ 235); // jmp
        MEM_WriteByte(oCAIArrow__ReportCollisionToAI_keepPlyStrp+1, /*3D*/ 61); // to 0x619648
    } else {
        // Gothic 2
        MemoryProtectionOverride(oCAIArrowBase__ReportCollisionToAI_PFXon1, 7); // Prevent too early setting of dust PFX
        MemoryProtectionOverride(oCAIArrowBase__ReportCollisionToAI_PFXon2, 7);
        repeat(i, 7);
            MEM_WriteByte(oCAIArrowBase__ReportCollisionToAI_PFXon1+i, ASMINT_OP_nop); // First occurrence
        end;
        repeat(i, 7);
            MEM_WriteByte(oCAIArrowBase__ReportCollisionToAI_PFXon2+i, ASMINT_OP_nop); // Second occurrence
        end;
        HookEngineF(oCAIArrowBase__ReportCollisionToAI_collVob, 5, GFA_CC_ProjectileCollisionWithWorld); // Vobs
        HookEngineF(oCAIArrowBase__ReportCollisionToAI_collWld, 5, GFA_CC_ProjectileCollisionWithWorld); // Static world
        MemoryProtectionOverride(oCAIArrowBase__ReportCollisionToAI_collNpc, 2); // Set collision behavior on NPCs
    };

    // Extend and refine collision detection on vobs
    if ((GFA_COLL_PRIOR_NPC == -1) || ((GFA_TRIGGER_COLL_FIX) && (GOTHIC_BASE_VERSION == 2))) {
        HookEngineF(oCAIArrow__CanThisCollideWith_positive, MEMINT_SwitchG1G2(6, 7), GFA_ExtendCollisionCheck);
        GFA_INIT_COLL_CHECK = TRUE;
    };
};


/*
 * Initialize all hooks for the critical hits feature. This function is called from GFA_InitOnce().
 */
func void GFA_InitFeatureCriticalHits() {
    MEM_Info("Initializing critical hit detection.");
    HookEngineF(oCAIArrow__ReportCollisionToAI_damage, 5, GFA_CH_DetectCriticalHit); // Perform critical hit detection
    if (GOTHIC_BASE_VERSION == 1) {
        HookEngineF(oCNpc__OnDamage_Hit_criticalHit, 5, GFA_CH_DisableDefaultCriticalHits); // Disable G1 critical hits
    };
};


/*
 * Initialize all hooks for the reusable projectiles feature. This function is called from GFA_InitOnce().
 */
func void GFA_InitFeatureReuseProjectiles() {
    MEM_Info("Initializing collectable projectiles.");
    HookEngineF(oCAIArrow__DoAI_rtn, 6, GFA_RP_KeepProjectileInWorld); // Keep projectiles when stop moving
    HookEngineF(oCAIArrowBase__ReportCollisionToAI_hitNpc, 5, GFA_RP_PutProjectileIntoInventory); // Projectile hits NPC
    if (GOTHIC_BASE_VERSION == 2) {
        // Reposition projectiles when they are stuck in the surface, only necessary for Gothic 2
        HookEngineF(oCAIArrowBase__ReportCollisionToAI_hitVob, 5, GFA_RP_RepositionProjectileInSurface);
        HookEngineF(oCAIArrowBase__ReportCollisionToAI_hitWld, 5, GFA_RP_RepositionProjectileInSurface);
    };

    // Reduce number of auto created munition items for NPCs (exploit on ransacking downed/killed NPCs)
    MemoryProtectionOverride(oCNpc__RefreshNpc_createAmmoIfNone, 1);
    MEM_WriteByte(oCNpc__RefreshNpc_createAmmoIfNone, 5); // Reduce to five projectiles (default 50)
};


/*
 * Initializations to perform only once every session. This function overwrites memory protection at certain addresses,
 * and registers hooks and console commands, all depending on the selected features (see config\settings.d). The
 * function is called from GFA_Init().
 */
func int GFA_InitOnce() {
    // Make sure LeGo is initialized with the required flags
    if ((_LeGo_Flags & GFA_LEGO_FLAGS) != GFA_LEGO_FLAGS) {
        MEM_Error("Insufficient LeGo flags for Gothic Free Aim.");
        return FALSE;
    };

    // Copyright notice in zSpy
    var int s; s = SB_New();
    SB("     "); SB(GFA_VERSION); SB(", Copyright "); SBc(169 /* (C) */); SB(" 2016-2017  mud-freak (@szapp)");
    MEM_Info("");
    MEM_Info(SB_ToString()); SB_Destroy();
    MEM_Info("     <http://github.com/szapp/GothicFreeAim>");
    MEM_Info("     Released under the MIT License.");
    MEM_Info("     For more details see <http://opensource.org/licenses/MIT>.");
    MEM_Info("");

    // Add emergency-lock, in case a mod-project is released with a critical bug related to GFA
    if (MEM_GothOptExists("GFA", "emergencyLock"))
    || (MEM_ModOptExists("OVERRIDES", "GFA.emergencyLock")) {
        MEM_SendToSpy(zERR_TYPE_WARN, "GFA emergency lock active");
        MEM_Info("Remove GFA.emergencyLock from Gothic.INI or override in Mod-INI to enable GFA.");
        return FALSE;
    };

    // FEATURE: Free aiming
    if (GFA_Flags & GFA_RANGED) || (GFA_Flags & GFA_SPELLS) {
        GFA_InitFeatureFreeAiming();
    };

    // FEATURE: Custom collision behaviors
    if (GFA_Flags & GFA_CUSTOM_COLLISIONS) {
        GFA_InitFeatureCustomCollisions();
    };

    // FEATURE: Critical hits
    if (GFA_Flags & GFA_CRITICALHITS) {
        GFA_InitFeatureCriticalHits();
    };

    // FEATURE: Reusable projectiles
    if (GFA_Flags & GFA_REUSE_PROJECTILES) {
        GFA_InitFeatureReuseProjectiles();
    };

    // Register console commands
    MEM_Info("Initializing console commands.");
    CC_Register(GFA_GetVersion, "GFA version", "print GFA version info");
    CC_Register(GFA_GetLicense, "GFA license", "print GFA license info");
    CC_Register(GFA_GetInfo, "GFA info", "print GFA config info");
    CC_Register(GFA_GetShootingStats, "GFA stats", "print shooting statistics");
    CC_Register(GFA_ResetShootingStats, "GFA stats reset", "reset shooting statistics");
    if (GFA_DEBUG_CONSOLE) {
        // Enable console commands for debugging
        CC_Register(GFA_DebugPrint, "debug GFA zSpy", "turn on GFA debug information in zSpy");
        CC_Register(GFA_DebugTraceRay, "debug GFA traceray", "turn debug visualization on/off");
        CC_Register(GFA_DebugTrajectory, "debug GFA trajectory", "turn debug visualization on/off");
        CC_Register(GFA_DebugWeakspot, "debug GFA weakspot", "turn debug visualization on/off");
    };

    // Successfully initialized
    return TRUE;
};


/*
 * Initializations to perfrom on every game start, level change and loading of saved games. This function is called from
 * GFA_Init().
 */
func void GFA_InitAlways() {
    // Pause frame functions when in menu
    Timer_SetPauseInMenu(1);

    // Retrieve trace ray interval: Recalculate trace ray intersection every x ms
    GFA_AimRayInterval = STR_ToInt(MEM_GetGothOpt("GFA", "focusUpdateIntervalMS"));
    if (GFA_AimRayInterval > 500) {
        GFA_AimRayInterval = 500;
        MEM_SetGothOpt("GFA", "focusUpdateIntervalMS", IntToString(GFA_AimRayInterval));
    };

    // Reset/reinitialize free aiming settings every time to prevent crashes
    if (GFA_Flags & GFA_RANGED) || (GFA_Flags & GFA_SPELLS) {
        // On level change, Gothic does not maintain the focus instances (see Focus.d), nor does it reinitialize them.
        // The focus instances are, however, critical for enabling/disabling free aiming: Reinitialize them by hand.
        // Additionally, they need to be reset on loading. Otherwise the default values are lost
        MEM_Info("Initializing focus modes.");
        const int call = 0;
        if (CALL_Begin(call)) {
            CALL__cdecl(oCNpcFocus__InitFocusModes);
            call = CALL_End();
        };

        // Backup focus instance values
        GFA_FOCUS_FAR_NPC_DFT = castToIntf(Focus_Ranged.npc_azi);
        GFA_FOCUS_SPL_NPC_DFT = castToIntf(Focus_Magic.npc_azi);
        GFA_FOCUS_SPL_ITM_DFT = Focus_Magic.item_prio;

        // Reset internal settings. Focus instances would otherwise not be updated on level change
        GFA_ACTIVE = 0;
        GFA_UpdateStatus();

        // Remove reticle. Would otherwise be stuck on screen on level change
        GFA_RemoveReticle();

        // Reset aim ray calculation time. Would otherwise result in an invalid vob pointer on loading a game (crash)
        GFA_AimRayPrevCalcTime = 0;

        // For safety (player might strafe into level change trigger)
        GFA_IsStrafing = 0;

        // Reset post casting delay (total time was most likely higher previously)
        GFA_SpellPostCastDelay = 0;
    };
};


/*
 * Initialize GFA framework. This function is called in Init_Global(). It includes registering hooks, console commands
 * and the retrieval of settings from the INI-file and other initializations.
 */
func void GFA_Init(var int flags) {
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
    GFA_Flags = flags;

    // Perform only once per session
    const int INITIALIZED = 0;
    if (!INITIALIZED) {
        if (!GFA_InitOnce()) {
            MEM_Info(ConcatStrings(GFA_VERSION, " failed to initialize."));
            return;
        };
        INITIALIZED = 1;
    };

    // Perform for every new session and on every load and level change
    GFA_InitAlways();

    MEM_Info(ConcatStrings(GFA_VERSION, " was initialized successfully."));
};
