/*
 * Initialization of GFA
 *
 * Gothic Free Aim (GFA) v1.1.0 - Free aiming for the video games Gothic 1 and Gothic 2 by Piranha Bytes
 * Copyright (C) 2016-2018  mud-freak (@szapp)
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

    // Controls
    MEM_Info("Initializing free aiming mouse controls.");
    HookEngineF(mouseUpdate, 5, GFA_TurnPlayerModel); // Rotate the player model by mouse input
    if (GOTHIC_BASE_VERSION == 1) {
        MemoryProtectionOverride(oCAIHuman__MagicMode_turnToTarget, 5); // G1: Prevent auto turning in spell combat
        HookEngineF(oCNpc__OnDamage_Anim_stumbleAniName, 5, GFA_AdjustDamageAnimation); // Additional hurt animation
    } else {
        MemoryProtectionOverride(oCNpc__TurnToEnemy_camCheck, 6); // G2: Prevent auto turning (target lock)
    };
    HookEngineF(oCNpc__OnDamage_Anim_gotHitAniName, 5, GFA_AdjustDamageAnimation); // Adjust hurt animation while aiming
    MemoryProtectionOverride(zCModel__TraceRay_softSkinCheck, 3); // Prepare allowing soft skin model trace ray

    // Free aiming for ranged combat (aiming and shooting)
    if (GFA_Flags & GFA_RANGED) {
        MEM_Info("Initializing free aiming for ranged combat.");
        HookEngineF(oCAIHuman__BowMode_notAiming, 6, GFA_RangedIdle); // Fix focus collection while not aiming
        HookEngineF(oCAIHuman__BowMode_interpolateAim, 5, GFA_RangedAiming); // Interpolate aiming animation
        HookEngineF(oCAIArrow__SetupAIVob, 6, GFA_SetupProjectile); // Setup projectile trajectory (shooting)
        writeNOP(oCAIArrowBase__DoAI_setLifeTime, 7);
        MEM_WriteByte(oCAIArrowBase__DoAI_setLifeTime, /*85*/ 133); // test eax, eax
        MEM_WriteByte(oCAIArrowBase__DoAI_setLifeTime+1, /*C0*/ 192);
        HookEngineF(oCAIArrowBase__DoAI_setLifeTime, 7, GFA_EnableProjectileGravity); // Enable gravity after some time
        HookEngineF(oCAIArrow__ReportCollisionToAI_collAll, 8, GFA_ResetProjectileGravity); // Reset gravity on impact
        HookEngineF(oCAIArrow__ReportCollisionToAI_hitChc, 6, GFA_OverwriteHitChance); // Manipulate hit chance
        MemoryProtectionOverride(oCAIHuman__CheckFocusVob_ranged, 1); // Prevent toggling focus in ranged combat
        HookEngineF(zCModel__CalcModelBBox3DWorld_rtn, 6, GFA_EnlargeHumanModelBBox); // Include head in model bbox
        HookEngineF(oCAIArrow__CanThisCollideWith_positive, MEMINT_SwitchG1G2(6, 7), GFA_ExtendCollisionCheck);
        if (GFA_STRAFING) {
            HookEngineF(oCAIHuman__BowMode_rtn, 7, GFA_RangedLockMovement); // Allow strafing or not when falling
        };

        // Aiming condition (detect aiming onset and overwrite aiming condition if GFA_STRAFING)
        writeNOP(oCAIHuman__BowMode_aimCondition, 5);
        HookEngineF(oCAIHuman__BowMode_aimCondition, 5, GFA_RangedAimingCondition); // Replace condition with own

        // Gothic 2 controls
        if (GOTHIC_BASE_VERSION == 2) {
            MEM_Info("Initializing free aiming Gothic 2 controls.");
            MemoryProtectionOverride(oCAIHuman__BowMode_g2ctrlCheck, 6); // Skip jump to G2 controls: jz to 0x696391
            MemoryProtectionOverride(oCAIHuman__BowMode_shootingKey, 2); // Shooting key: push 3
            MemoryProtectionOverride(oCAIHuman__PC_ActionMove_aimingKey, 5); // Aim key: mov eax [esp+8+4], push eax
            HookEngineF(cGameManager__HandleEvent_clearKeyBuffer, 6, GFA_CancelOUsDontClearKeyBuffer); // Fix key buffer
        };

        // Fix dropped projectile AI bug
        MEM_Info("Initializing dropped projectiles AI bug fix.");
        writeNOP(oCAIVobMove__DoAI_stopMovement, 7); // First erase a call, to make room for hook
        HookEngineF(oCAIVobMove__DoAI_stopMovement, 7, GFA_FixDroppedProjectileAI); // Rewrite what has been overwritten
    };

    // Free aiming for spells
    if (GFA_Flags & GFA_SPELLS) {
        MEM_Info("Initializing free aiming for spell combat.");
        HookEngineF(oCAIHuman__MagicMode, 7, GFA_SpellAiming); // Manage focus collection and reticle
        HookEngineF(oCSpell__Setup_initFallbackNone, 6, GFA_SetupSpell); // Set spell FX trajectory (shooting)
        HookEngineF(oCNpc__EV_Strafe_commonOffset, 5, GFA_FixSpellOnStrafe); // Fix spell FX after interrupted casting
        MemoryProtectionOverride(oCAIHuman__CheckFocusVob_spells, 1); // Prevent toggling focus in spell combat
        if (GFA_STRAFING) {
            HookEngineF(oCAIHuman__MagicMode_rtn, 7, GFA_SpellLockMovement); // Lock movement while aiming
        };

        // Fixes for Gothic 2
        if (GOTHIC_BASE_VERSION == 2) {
            HookEngineF(oCVisualFX__ProcessCollision_checkTarget, 6, GFA_SpellFixTarget); // Match target with collision
            MemoryProtectionOverride(oCNpc__EV_Strafe_magicCombat, 5); // Disable magic during default strafing
            HookEngineF(oCNpc__EV_Strafe_g2ctrl, 6, GFA_SpellStrafeReticle); // Update reticle while default strafing
            MemoryProtectionOverride(oCAIHuman__MagicMode_g2ctrlCheck, 4); // Change Gothic 2 controls
        };
    };

    // Fix open inventory bug
    if (GFA_Flags & GFA_SPELLS) || (GFA_STRAFING) {
        MEM_Info("Initializing open inventory bug fix.");
        writeNOP(oCGame__HandleEvent_openInvCheck, 5); // First erase a call, to make room for hook
        HookEngineF(oCGame__HandleEvent_openInvCheck, 5, GFA_FixOpenInventory); // Rewrite what has been overwritten
    };

    // Treat special body states (lying or sliding)
    HookEngineF(zCAIPlayer__IsSliding_true, 5, GFA_TreatBodyStates); // Called during sliding
    HookEngineF(oCAIHuman__PC_CheckSpecialStates_lie, 5, GFA_TreatBodyStates); // Called when lying after a fall
    HookEngineF(oCAniCtrl_Human__SearchStandAni_walkmode, 6, GFA_FixStandingBodyState); // Fix bug with wrong body state
    HookEngineF(oCNpc__SetWeaponMode2_walkmode, 6, GFA_FixStandingBodyState); // Fix bug with wrong body state
    // Prevent focus collection during jumping and falling (necessary for Gothic 2 only)
    if (GOTHIC_BASE_VERSION == 2) {
        HookEngineF(oCAIHuman__PC_ActionMove_bodyState, 6, GFA_PreventFocusCollectionBodyStates);
    };

    // Do not interrupt strafing by oCNpc::Interrupt()
    if (GFA_STRAFING) {
        HookEngineF(oCNpc__Interrupt_stopAnis, 5, GFA_DontInterruptStrafing);
        MemoryProtectionOverride(oCNpc__Interrupt_stopAnisLayerA, 1);
    };

    // Reticle
    MEM_Info("Initializing reticle.");
    HookEngineF(oCNpc__SetWeaponMode_player, 6, GFA_ResetOnWeaponSwitch); // Hide reticle, hide aim FX, reset draw force

    // Fix player turning NPCs on attack run
    // Prevent the player from controlling the turning of NPCs that are performing an attack run. This inherent Gothic 2
    // bug becomes very obvious with free aiming and thus needs to be fixed.
    // To still allow the player to turn while performing an attack run, the solution from the link below is extended,
    // to squeeze in a check whether the character in question is the player.
    //
    // Inspired by: http://forum.worldofplayers.de/forum/threads/879891?p=14886885
    if (GOTHIC_BASE_VERSION == 2) {
        MEM_Info("Initializing NPC attack-run turning bug fix.");
        writeNOP(oCNpc__EV_AttackRun_playerTurn, 7); // Erase call to oCAIHuman::PC_Turnings()
        HookEngineF(oCNpc__EV_AttackRun_playerTurn, 7, GFA_FixNpcAttackRun); // Re-write what has been overwritten
    };

    // Read INI Settings
    MEM_Info("Initializing entries in Gothic.ini.");

    if (!MEM_GothOptExists("GFA", "freeAimingEnabled")) {
        // Add INI-entry, if not set
        MEM_SetGothOpt("GFA", "freeAimingEnabled", "1");
    };

    // Retrieve trace ray interval: Recalculate trace ray intersection every x ms
    if (!MEM_GothOptExists("GFA", "focusUpdateIntervalMS")) {
        // Add INI-entry, if not set (set to instantaneous=0ms by default)
        MEM_SetGothOpt("GFA", "focusUpdateIntervalMS", "0");
    };
    GFA_RAY_INTERVAL = STR_ToInt(MEM_GetGothOpt("GFA", "focusUpdateIntervalMS"));
    if (GFA_RAY_INTERVAL > 500) {
        GFA_RAY_INTERVAL = 500;
        MEM_SetGothOpt("GFA", "focusUpdateIntervalMS", IntToString(GFA_RAY_INTERVAL));
    };

    // Remove focus when not aiming: Prevent using bow/spell as enemy detector
    if (!MEM_GothOptExists("GFA", "showFocusWhenNotAiming")) {
        // Add INI-entry, if not set (disable by default)
        MEM_SetGothOpt("GFA", "showFocusWhenNotAiming", "0");
    };
    GFA_NO_AIM_NO_FOCUS = !STR_ToInt(MEM_GetGothOpt("GFA", "showFocusWhenNotAiming"));

    // Set the reticle size in pixels
    if (!MEM_GothOptExists("GFA", "reticleSizePx")) {
        // Add INI-entry, if not set
        MEM_SetGothOpt("GFA", "reticleSizePx", IntToString(GFA_RETICLE_MAX_SIZE));
    };
    GFA_RETICLE_MAX_SIZE = STR_ToInt(MEM_GetGothOpt("GFA", "reticleSizePx"));
    if (GFA_RETICLE_MAX_SIZE < GFA_RETICLE_MIN_SIZE) {
        GFA_RETICLE_MAX_SIZE = GFA_RETICLE_MIN_SIZE;
        MEM_SetGothOpt("GFA", "reticleSizePx", IntToString(GFA_RETICLE_MAX_SIZE));
    };
    GFA_RETICLE_MIN_SIZE = GFA_RETICLE_MAX_SIZE/2;

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
    if (GOTHIC_BASE_VERSION == 1) {
        writeNOP(oCAIArrow__ReportCollisionToAI_destroyPrj, 7); // Disable destroying of projectiles
        if (!(GFA_Flags & GFA_REUSE_PROJECTILES)) {
            HookEngineF(oCAIArrow__DoAI_rtn, 6, GFA_CC_FadeProjectileVisibility); // Implement fading like in Gothic 2
        };
        HookEngineF(oCAIArrow__ReportCollisionToAI_collAll, 8, GFA_CC_ProjectileCollisionWithWorld); // Collision world
        MemoryProtectionOverride(oCAIArrow__ReportCollisionToAI_keepPlyStrp, 2); // Keep poly strip after coll
        MEM_WriteByte(oCAIArrow__ReportCollisionToAI_keepPlyStrp, /*EB*/ 235); // jmp
        MEM_WriteByte(oCAIArrow__ReportCollisionToAI_keepPlyStrp+1, /*3D*/ 61); // to 0x619648
    } else {
        // Gothic 2
        writeNOP(oCAIArrowBase__ReportCollisionToAI_PFXon1, 7); // Prevent too early setting of dust PFX
        writeNOP(oCAIArrowBase__ReportCollisionToAI_PFXon2, 7);
        HookEngineF(oCAIArrowBase__ReportCollisionToAI_collVob, 5, GFA_CC_ProjectileCollisionWithWorld); // Vobs
        HookEngineF(oCAIArrowBase__ReportCollisionToAI_collWld, 5, GFA_CC_ProjectileCollisionWithWorld); // Static world
        MemoryProtectionOverride(oCAIArrowBase__ReportCollisionToAI_collNpc, 2); // Set collision behavior on NPCs
    };

    // Extend and refine collision detection on vobs
    if ((GFA_COLL_PRIOR_NPC == -1) || ((GFA_TRIGGER_COLL_FIX) && (GOTHIC_BASE_VERSION == 2))) {
        HookEngineF(oCAIArrow__CanThisCollideWith_positive, MEMINT_SwitchG1G2(6, 7), GFA_ExtendCollisionCheck);
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

    // Fix dropped projectile AI bug
    if (!IsHookF(oCAIVobMove__DoAI_stopMovement, GFA_FixDroppedProjectileAI)) {
        MEM_Info("Initializing dropped projectiles AI bug fix.");
        writeNOP(oCAIVobMove__DoAI_stopMovement, 7); // First erase a call, to make room for hook
        HookEngineF(oCAIVobMove__DoAI_stopMovement, 7, GFA_FixDroppedProjectileAI); // Rewrite what has been overwritten
    };
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
    SB("     "); SB(GFA_VERSION); SB(", Copyright "); SBc(169 /* (C) */); SB(" 2016-2018  mud-freak (@szapp)");
    MEM_Info("");
    MEM_Info(SB_ToString()); SB_Destroy();
    MEM_Info("     <http://github.com/szapp/GothicFreeAim>");
    MEM_Info("     Released under the MIT License.");
    MEM_Info("     For more details see <http://opensource.org/licenses/MIT>.");
    MEM_Info("");

    // Add emergency-lock, in case a mod-project is released with a critical bug related to GFA
    if (MEM_ModOptExists("OVERRIDES", "GFA.emergencyLock")) {
        MEM_SendToSpy(zERR_TYPE_WARN, "GFA emergency lock active");
        MEM_Info("Remove GFA.emergencyLock override in Mod-INI to enable GFA.");
        return FALSE;
    };

    // FEATURE: Free aiming
    if (GFA_Flags & GFA_RANGED) || (GFA_Flags & GFA_SPELLS) {
        GFA_InitFeatureFreeAiming();
    };

    // FEATURE: Critical hits
    if (GFA_Flags & GFA_CRITICALHITS) {
        GFA_InitFeatureCriticalHits();
    };

    // FEATURE: Custom collision behaviors
    if (GFA_Flags & GFA_CUSTOM_COLLISIONS) {
        GFA_InitFeatureCustomCollisions();
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
        CC_Register(GFA_DebugBone, "debug GFA bone", "turn debug visualization on/off");
    };

    // Successfully initialized
    return TRUE;
};


/*
 * Initializations to perform on every game start, level change and loading of saved games. This function is called from
 * GFA_Init().
 */
func void GFA_InitAlways() {
    // Reset/reinitialize free aiming settings every time to prevent crashes
    if (GFA_Flags & GFA_RANGED) || (GFA_Flags & GFA_SPELLS) {
        // On level change, Gothic does not maintain the focus instances (see Focus.d), nor does it reinitialize them.
        // The focus instances are, however, critical for enabling/disabling free aiming: Reinitialize them by hand.
        // Additionally, they need to be reset on loading. Otherwise the default values are lost
        MEM_Info("Initializing focus modes.");

        if (!MEM_ReadInt(oCNpcFocus__focus)) {
            // Create and initialize focus modes
            const int call = 0;
            if (CALL_Begin(call)) {
                CALL__cdecl(oCNpcFocus__InitFocusModes);
                call = CALL_End();
            };
        } else {
            // Reinitialize already created focus modes
            repeat(i, oCNpcFocus__num); var int i;
                var int focusModePtr; focusModePtr = MEM_ReadIntArray(oCNpcFocus__focuslist, i);
                var int focusModeNamePtr; focusModeNamePtr = oCNpcFocus__focusnames + i * sizeof_zString;

                const int call2 = 0;
                if (CALL_Begin(call2)) {
                    CALL_PtrParam(_@(focusModeNamePtr));
                    CALL__thiscall(_@(focusModePtr), oCNpcFocus__Init);
                    call2 = CALL_End();
                };
            end;
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
    if (!GFA_INITIALIZED) {
        if (!GFA_InitOnce()) {
            MEM_Info(ConcatStrings(GFA_VERSION, " failed to initialize."));
            return;
        };
        GFA_INITIALIZED = 1;
    };

    // Perform for every new session and on every load and level change
    GFA_InitAlways();

    MEM_Info(ConcatStrings(GFA_VERSION, " was initialized successfully."));
};
