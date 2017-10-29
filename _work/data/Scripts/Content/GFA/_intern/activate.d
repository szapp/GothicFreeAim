/*
 * Activate free aiming and set internal settings
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
 * Update internal settings when turning free aim on/off in the options menu. Settings include focus ranges/angles and
 * camera angles. The constant GFA_ACTIVE will be updated accordingly. This function is called from GFA_UpdateStatus()
 * if the menu is closed.
 */
func void GFA_UpdateSettings(var int on) {
    if ((GFA_ACTIVE > 0) == on) {
        return; // No change necessary
    };

    MEM_Info(ConcatStrings("  OPT: GFA: freeAimingEnabled=", IntToString(on))); // Print to zSpy, same style as options

    if (on) {
        // Turn free aiming on
        if (GFA_Flags & GFA_RANGED) {
            // Set stricter focus collection
            Focus_Ranged.npc_azi = castFromIntf(castToIntf(GFA_FOCUS_FAR_NPC)); // Cast twice, Deadalus floats are dumb

            // New camera mode (does not affect Gothic 1)
            MEM_WriteString(zString_CamModRanged, STR_Upper(GFA_CAMERA));
        };

        if (GFA_Flags & GFA_SPELLS) {
            // New camera mode (does not affect Gothic 1)
            MEM_WriteString(zString_CamModMagic, STR_Upper(GFA_CAMERA));
        };

    } else {
        // Reset focus collection to default
        Focus_Ranged.npc_azi = castFromIntf(GFA_FOCUS_FAR_NPC_DFT);
        Focus_Magic.npc_azi = castFromIntf(GFA_FOCUS_SPL_NPC_DFT);
        Focus_Magic.item_prio = GFA_FOCUS_SPL_ITM_DFT;

        // Restore camera modes (does not affect Gothic 1)
        MEM_WriteString(zString_CamModRanged, "CAMMODRANGED");
        MEM_WriteString(zString_CamModMagic, "CAMMODMAGIC");
    };
    GFA_ACTIVE = !GFA_ACTIVE;
};


/*
 * The contents of this function used to be in GFA_InitFeatureFreeAiming() and initialized on startup. Now the hooks of
 * the free aiming feature (other features of GFA excluded!) are only initialized when free aiming is active in the game
 * menu.
 */
func void GFA_AddFreeAimingHooks() {
    var int i;

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
        HookEngineF(oCAIArrow__ReportCollisionToAI_collAll, 8, GFA_ResetProjectileGravity); // Reset gravity on impact
        HookEngineF(oCAIArrow__ReportCollisionToAI_hitChc, 6, GFA_OverwriteHitChance); // Manipulate hit chance
        MemoryProtectionOverride(oCAIHuman__CheckFocusVob_ranged, 1); // Prevent toggling focus in ranged combat
        HookEngineF(zCModel__CalcModelBBox3DWorld, 6, GFA_EnlargeHumanModelBBox); // Include head in model bounding box
        HookEngineF(oCAIArrow__CanThisCollideWith_positive, MEMINT_SwitchG1G2(6, 7), GFA_ExtendCollisionCheck);
        if (GFA_STRAFING) {
            HookEngineF(oCAIHuman__BowMode_rtn, 7, GFA_RangedLockMovement); // Allow strafing or not when falling
        };

        // Aiming condition (detect aiming onset and overwrite aiming condition if GFA_STRAFING)
        MemoryProtectionOverride(oCAIHuman__BowMode_aimCondition, 5);
        repeat(i, 5);
            MEM_WriteByte(oCAIHuman__BowMode_aimCondition+i, ASMINT_OP_nop); // Erase condition to make room for hook
        end;
        HookEngineF(oCAIHuman__BowMode_aimCondition, 5, GFA_RangedAimingCondition); // Replace condition with own

        // Gothic 2 controls
        if (GOTHIC_BASE_VERSION == 2) {
            MEM_Info("Initializing free aiming Gothic 2 controls.");
            MemoryProtectionOverride(oCAIHuman__BowMode_g2ctrlCheck, 6); // Skip jump to G2 controls: jz to 0x696391
            MemoryProtectionOverride(oCAIHuman__BowMode_shootingKey, 2); // Shooting key: push 3
            MemoryProtectionOverride(oCAIHuman__PC_ActionMove_aimingKey, 5); // Aim key: mov eax [esp+8+4], push eax
            HookEngineF(cGameManager__HandleEvent_clearKeyBuffer, 6, GFA_CancelOUsDontClearKeyBuffer); // Fix key buffer
        };

        // Fix knockout by ranged weapon bug (also allow customization with GFA_CUSTOM_COLLISIONS)
        MEM_Info("Initializing fixed damage behavior for ranged weapons.");
        HookEngineF(oCAIArrow__ReportCollisionToAI_damage, 5, GFA_CC_SetDamageBehavior);

        // Fix dropped projectile AI bug
        MEM_Info("Initializing dropped projectiles AI bug fix.");
        MemoryProtectionOverride(oCAIVobMove__DoAI_stopMovement, 7); // First erase a call, to make room for hook
        repeat(i, 7);
            MEM_WriteByte(oCAIVobMove__DoAI_stopMovement+i, ASMINT_OP_nop);
        end;
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
        };

        // Fix open inventory bug
        MEM_Info("Initializing open inventory bug fix.");
        MemoryProtectionOverride(oCGame__HandleEvent_openInvCheck, 5); // First erase a call, to make room for hook
        repeat(i, 5);
            MEM_WriteByte(oCGame__HandleEvent_openInvCheck+i, ASMINT_OP_nop);
        end;
        HookEngineF(oCGame__HandleEvent_openInvCheck, 5, GFA_FixOpenInventory); // Rewrite what has been overwritten
    };

    // Treat special body states (lying or sliding)
    HookEngineF(zCAIPlayer__IsSliding_true, 5, GFA_TreatBodyStates); // Called during sliding
    HookEngineF(oCAIHuman__PC_CheckSpecialStates_lie, 5, GFA_TreatBodyStates); // Called when lying after a fall
    HookEngineF(oCAniCtrl_Human__SearchStandAni_walkmode, 6, GFA_FixStandingBodyState); // Fix bug with wrong body state
    HookEngineF(oCNpc__SetWeaponMode2_walkmode, 6, GFA_FixStandingBodyState); // Fix bug with wrong body state
    // Prevent focus collection during jumping and falling (necessary for Gothic 2 only)
    if (GOTHIC_BASE_VERSION == 2) && (GFA_NO_AIM_NO_FOCUS) {
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
        MemoryProtectionOverride(oCNpc__EV_AttackRun_playerTurn, 7); // Erase call to oCAIHuman::PC_Turnings()
        repeat(i, 7);
            MEM_WriteByte(oCNpc__EV_AttackRun_playerTurn+i, ASMINT_OP_nop);
        end;
        HookEngineF(oCNpc__EV_AttackRun_playerTurn, 7, GFA_FixNpcAttackRun); // Re-write what has been overwritten
    };
};


/*
 * This function removes all hooks initialized with GFA_AddFreeAimingHooks() to revert the game back to its default
 * state 100%. This functionality was added to have solid fallback should there be any compatibility issues or bugs
 * found in free aiming (other features of GFA excluded!). This would allow turning off free aiming in the game menu
 * until a patch of a given mod is released.
 */
func void GFA_RemoveFreeAimingHooks() {
    // Controls
    MEM_Info("Un-initializing free aiming mouse controls.");
    RemoveHookF(mouseUpdate, 5, GFA_TurnPlayerModel);
    if (GOTHIC_BASE_VERSION == 1) {
        RemoveHookF(oCNpc__OnDamage_Anim_stumbleAniName, 5, GFA_AdjustDamageAnimation);
    };
    RemoveHookF(oCNpc__OnDamage_Anim_gotHitAniName, 5, GFA_AdjustDamageAnimation);
    MemoryProtectionOverride(zCModel__TraceRay_softSkinCheck, 3);

    // Ranged combat
    if (GFA_Flags & GFA_RANGED) {
        MEM_Info("Un-initializing free aiming for ranged combat.");
        RemoveHookF(oCAIHuman__BowMode_notAiming, 6, GFA_RangedIdle);
        RemoveHookF(oCAIHuman__BowMode_interpolateAim, 5, GFA_RangedAiming);
        RemoveHookF(oCAIArrow__SetupAIVob, 6, GFA_SetupProjectile);
        RemoveHookF(oCAIArrow__ReportCollisionToAI_collAll, 8, GFA_ResetProjectileGravity);
        RemoveHookF(oCAIArrow__ReportCollisionToAI_hitChc, 6, GFA_OverwriteHitChance);
        RemoveHookF(zCModel__CalcModelBBox3DWorld, 6, GFA_EnlargeHumanModelBBox);
        RemoveHookF(oCAIHuman__BowMode_rtn, 7, GFA_RangedLockMovement);

        if (!GFA_INIT_COLL_CHECK) {
            RemoveHookF(oCAIArrow__CanThisCollideWith_positive, MEMINT_SwitchG1G2(6, 7), GFA_ExtendCollisionCheck);
        };

        RemoveHookF(oCAIHuman__BowMode_aimCondition, 5, GFA_RangedAimingCondition);
        // Rewrite the original code: call oCAniCtrl_Human::IsStanding(void)
        MEM_WriteByte(oCAIHuman__BowMode_aimCondition, ASMINT_OP_call);
        if (GOTHIC_BASE_VERSION == 1) {
            MEM_WriteByte(oCAIHuman__BowMode_aimCondition+1, /*82*/ 130);
            MEM_WriteByte(oCAIHuman__BowMode_aimCondition+2, /*4B*/ 75);
        } else {
            MEM_WriteByte(oCAIHuman__BowMode_aimCondition+1, /*71*/ 113);
            MEM_WriteByte(oCAIHuman__BowMode_aimCondition+2, /*7B*/ 123);
        };
        MEM_WriteByte(oCAIHuman__BowMode_aimCondition+3, 1);
        MEM_WriteByte(oCAIHuman__BowMode_aimCondition+4, 0);

        if (GOTHIC_BASE_VERSION == 2) {
            MEM_Info("Un-initializing free aiming Gothic 2 controls.");
            RemoveHookF(cGameManager__HandleEvent_clearKeyBuffer, 6, GFA_CancelOUsDontClearKeyBuffer);
        };

        // Revert miscellaneous Gothic fixes

        // Revert knockout by ranged weapon bug fix (keep hook for GFA_CUSTOM_COLLISIONS)
        if (!(GFA_Flags & GFA_CUSTOM_COLLISIONS)) {
            MEM_Info("Un-initializing fixed damage behavior for ranged weapons.");
            HookEngineF(oCAIArrow__ReportCollisionToAI_damage, 5, GFA_CC_SetDamageBehavior);
        };

        // Revert dropped projectile AI bug fix
        MEM_Info("Un-initializing dropped projectiles AI bug fix.");
        HookEngineF(oCAIVobMove__DoAI_stopMovement, 7, GFA_FixDroppedProjectileAI);
        // Rewrite the original code: push 1; call zCVob::SetSleeping(void)
        MEM_WriteByte(oCAIVobMove__DoAI_stopMovement, /*6A*/ 106);
        MEM_WriteByte(oCAIVobMove__DoAI_stopMovement+1, 1);
        MEM_WriteByte(oCAIVobMove__DoAI_stopMovement+2, /*E8*/ 232);
        if (GOTHIC_BASE_VERSION == 1) {
            MEM_WriteByte(oCAIVobMove__DoAI_stopMovement+3, /*E5*/ 229);
            MEM_WriteByte(oCAIVobMove__DoAI_stopMovement+4, /*F3*/ 243);
            MEM_WriteByte(oCAIVobMove__DoAI_stopMovement+5, /*FB*/ 251);
        } else {
            MEM_WriteByte(oCAIVobMove__DoAI_stopMovement+3, /*15*/ 21);
            MEM_WriteByte(oCAIVobMove__DoAI_stopMovement+4, /*2F*/ 47);
            MEM_WriteByte(oCAIVobMove__DoAI_stopMovement+5, /*F6*/ 246);
        };
        MEM_WriteByte(oCAIVobMove__DoAI_stopMovement+6, /*FF*/ 255);
    };

    // Spell combat
    if (GFA_Flags & GFA_SPELLS) {
        MEM_Info("Un-initializing free aiming for spell combat.");
        RemoveHookF(oCAIHuman__MagicMode, 7, GFA_SpellAiming);
        RemoveHookF(oCSpell__Setup_initFallbackNone, 6, GFA_SetupSpell);
        RemoveHookF(oCNpc__EV_Strafe_commonOffset, 5, GFA_FixSpellOnStrafe);
        RemoveHookF(oCAIHuman__MagicMode_rtn, 7, GFA_SpellLockMovement);

        if (GOTHIC_BASE_VERSION == 2) {
            RemoveHookF(oCVisualFX__ProcessCollision_checkTarget, 6, GFA_SpellFixTarget);
            RemoveHookF(oCNpc__EV_Strafe_g2ctrl, 6, GFA_SpellStrafeReticle);
        };

        // Revert open inventory bug fix
        MEM_Info("Un-initializing open inventory bug fix.");
        HookEngineF(oCGame__HandleEvent_openInvCheck, 5, GFA_FixOpenInventory);
        // Rewrite the original code: call oCNpc::GetInteractMob(void)
        MEM_WriteByte(oCGame__HandleEvent_openInvCheck, /*E8*/ 232);
        if (GOTHIC_BASE_VERSION == 1) {
            MEM_WriteByte(oCGame__HandleEvent_openInvCheck+1, /*8E*/ 142);
            MEM_WriteByte(oCGame__HandleEvent_openInvCheck+2, /*75*/ 117);
        } else {
            MEM_WriteByte(oCGame__HandleEvent_openInvCheck+1, /*D8*/ 216);
            MEM_WriteByte(oCGame__HandleEvent_openInvCheck+2, /*E6*/ 230);
        };
        MEM_WriteByte(oCGame__HandleEvent_openInvCheck+3, 4);
        MEM_WriteByte(oCGame__HandleEvent_openInvCheck+4, 0);
    };

    // General hooks
    RemoveHookF(zCAIPlayer__IsSliding_true, 5, GFA_TreatBodyStates);
    RemoveHookF(oCAIHuman__PC_CheckSpecialStates_lie, 5, GFA_TreatBodyStates);
    RemoveHookF(oCAniCtrl_Human__SearchStandAni_walkmode, 6, GFA_FixStandingBodyState);
    RemoveHookF(oCNpc__SetWeaponMode2_walkmode, 6, GFA_FixStandingBodyState);
    RemoveHookF(oCNpc__Interrupt_stopAnis, 5, GFA_DontInterruptStrafing);

    if (GOTHIC_BASE_VERSION == 2) {
        RemoveHookF(oCAIHuman__PC_ActionMove_bodyState, 6, GFA_PreventFocusCollectionBodyStates);
    };

    // Reticle
    MEM_Info("Un-initializing reticle.");
    RemoveHookF(oCNpc__SetWeaponMode_player, 6, GFA_ResetOnWeaponSwitch);

    // Revert player turning NPCs on attack run fix
    if (GOTHIC_BASE_VERSION == 2) {
        MEM_Info("Un-initializing NPC attack-run turning bug fix.");
        HookEngineF(oCNpc__EV_AttackRun_playerTurn, 7, GFA_FixNpcAttackRun);
        // Rewrite original code: push 0; call oCAIHuman::PC_Turnings()
        MEM_WriteByte(oCNpc__EV_AttackRun_playerTurn, /*6A*/ 106);
        MEM_WriteByte(oCNpc__EV_AttackRun_playerTurn+1, 0);
        MEM_WriteByte(oCNpc__EV_AttackRun_playerTurn+2, /*E8*/ 232);
        MEM_WriteByte(oCNpc__EV_AttackRun_playerTurn+3, /*E4*/ 228);
        MEM_WriteByte(oCNpc__EV_AttackRun_playerTurn+4, /*8F*/ 143);
        MEM_WriteByte(oCNpc__EV_AttackRun_playerTurn+5, /*F4*/ 244);
        MEM_WriteByte(oCNpc__EV_AttackRun_playerTurn+6, /*FF*/ 255);
    };
};


/*
 * Wrapper function for free aiming hook (un-)initialization (see functions above).
 */
func void GFA_SetFreeAimingHooks(var int on) {
    const int SET = 0;
    if (on == SET) {
        return; // No change necessary
    };

    if (on) {
        GFA_AddFreeAimingHooks();
    } else {
        GFA_RemoveFreeAimingHooks();
    };
    SET = on;
};


/*
 * This function updates the settings when free aiming or the Gothic 2 controls are enabled or disabled. It is called
 * every time when the Gothic settings are updated (after leaving the game menu), as well as during loading and level
 * changes. The function hooks cGameManager::ApplySomeSettings() at the very end (after all other menu settings!).
 * The constant GFA_ACTIVE is modified in the subsequent function GFA_UpdateSettings().
 */
func void GFA_UpdateStatus() {
    // Check if free aiming and mouse controls are enabled
    if (!STR_ToInt(MEM_GetGothOpt("GFA", "freeAimingEnabled"))) || (!MEM_ReadInt(zCInput_Win32__s_mouseEnabled)) {
        // Disable if previously enabled
        GFA_UpdateSettings(0);
        GFA_DisableAutoTurning(0);
        GFA_SetCameraModes(0);
        GFA_DisableToggleFocusRanged(0);
        GFA_DisableToggleFocusSpells(0);
        GFA_DisableMagicDuringStrafing(0);
        GFA_SetControlSchemeRanged(0);
        GFA_SetControlSchemeSpells(0);

        // Clean up
        GFA_RemoveReticle();
        GFA_AimVobDetachFX();

        // Remove all hooks
        GFA_SetFreeAimingHooks(0);
    } else {
        // Add all hooks
        GFA_SetFreeAimingHooks(1);

        // Enable if previously disabled
        GFA_UpdateSettings(1);
        GFA_DisableToggleFocusRanged(GFA_Flags & GFA_RANGED);
        GFA_DisableMagicDuringStrafing(GFA_Flags & GFA_SPELLS);

        // Apply control schemes for ranged and spell combat free aiming
        if (GOTHIC_BASE_VERSION == 2) {
            // Get control scheme and overrides
            var int schemeAcross; schemeAcross = -(MEM_ReadInt(oCGame__s_bUseOldControls))+2; // G1 == 1, G2 == 2
            var int schemeRanged; schemeRanged = STR_ToInt(MEM_GetGothOpt("GFA", "overwriteControlSchemeRanged"));
            var int schemeSpells; schemeSpells = STR_ToInt(MEM_GetGothOpt("GFA", "overwriteControlSchemeSpells"));

            // If override is disabled, use general (across) control scheme (as from the game menu settings)
            if (schemeRanged < 1) || (schemeRanged > 2) {
                schemeRanged = schemeAcross;
            };
            if (schemeSpells < 1) || (schemeSpells > 2) {
                schemeSpells = schemeAcross;
            };

            GFA_SetControlSchemeRanged(schemeRanged);
            GFA_SetControlSchemeSpells(schemeSpells);
        } else {
            // Gothic 1 has always G1 controls
            GFA_CTRL_SCHEME_RANGED = 1;
            GFA_CTRL_SCHEME_SPELLS = 1;
        };
    };
};


/*
 * This function is called nearly every frame by GFA_TurnPlayerModel(), providing the mouse is enabled, to check
 * whether free aiming is active (player in either magic or ranged combat). It sets the constant GFA_ACTIVE
 * accordingly:
 *  1 if not active (not currently aiming)
 *  4 if currently using a spell that supports aim movement (GFA_ACT_MOVEMENT)
 *  5 if currently aiming in ranged fight mode (FMODE_FAR)
 *  7 if currently aiming in magic fight mode with free aiming supported spell (FMODE_MAGIC)
 *
 * GFA_ACTIVE is prior set to 0 in GFA_UpdateStatus() if free aiming is disabled in the menu.
 *
 * Different checks are performed in performance-favoring order (exiting the function as early as possible) to set the
 * constant, which is subsequently used in a lot of functions to determine the state of free aiming.
 */
func void GFA_IsActive() {
    if (!GFA_ACTIVE) {
        return;
    };

    // Check if currently in a menu or in a dialog
    if (MEM_Game.pause_screen) || (!InfoManager_HasFinished()) {
        if (MEM_Timer.totalTime) && (Hlp_IsValidNpc(hero)) {
            GFA_SetCameraModes(0);
            GFA_AimMovement(0, "");
            GFA_DisableAutoTurning(0);
        };
        GFA_ACTIVE = 1;
        return;
    };

    // Before anything else, check if player is in magic or ranged fight mode
    var oCNpc her; her = getPlayerInst();
    if (her.fmode < FMODE_FAR) {
        GFA_SetCameraModes(0);
        GFA_AimMovement(0, "");
        GFA_DisableAutoTurning(0);
        GFA_RemoveReticle(); // Necessary for SPL_Control
        GFA_ACTIVE = 1;
        return;
    };

    // Check if falling (body state BS_FALL is unreliable, because it is set after the falling animation has started)
    var zCAIPlayer playerAI; playerAI = _^(her.anictrl);
    if (gef(playerAI.aboveFloor, mkf(12))) {
        GFA_ResetSpell();
        GFA_AimMovement(0, "");
        GFA_RemoveReticle();
        GFA_AimVobDetachFX();
        GFA_ACTIVE = 1;
        return;
    };

    // Set active control scheme for current fight mode
    if (her.fmode == FMODE_MAGIC) {
        GFA_ACTIVE_CTRL_SCHEME = GFA_CTRL_SCHEME_SPELLS;
    } else {
        GFA_ACTIVE_CTRL_SCHEME = GFA_CTRL_SCHEME_RANGED;
    };

    // Set aiming key depending on control scheme to either action or blocking key
    var String keyAiming;
    if (GFA_ACTIVE_CTRL_SCHEME == 1) {
        keyAiming = "keyAction";
    } else {
        keyAiming = "keyParade";
    };

    // Check if aiming buttons are held
    var _Cursor mouse; mouse = _^(Cursor_Ptr); // The _Cursor class from LeGo holds mouse properties
    var int keyPressed; keyPressed = (MEM_KeyPressed(MEM_GetKey(keyAiming)))
                                  || (MEM_KeyPressed(MEM_GetSecondaryKey(keyAiming)))
                                  || (MEMINT_SwitchG1G2(mouse.keyLeft, FALSE)); // Additional key binding for Gothic 1

    // Body state checks
    var int standing;
    var int stumbling;

    // Check fight mode
    if (her.fmode == FMODE_MAGIC) {
        // Check if free aiming for spells is disabled
        if (!(GFA_Flags & GFA_SPELLS)) {
            GFA_SetCameraModes(0);
            GFA_DisableAutoTurning(0);
            GFA_ACTIVE = 1;
            return;
        };

        // Gothic 1 does not differentiate between camera modes. Force/overwrite all to free aiming mode
        GFA_SetCameraModes(1);

        // Check if active spell supports free aiming
        var C_Spell spell; spell = GFA_GetActiveSpellInst(hero);
        var int eligible; eligible = GFA_IsSpellEligible(spell);
        if (!(eligible & GFA_ACT_FREEAIM)) {
            // Reset spell focus collection
            Focus_Magic.npc_azi = castFromIntf(GFA_FOCUS_SPL_NPC_DFT);
            Focus_Magic.item_prio = GFA_FOCUS_SPL_ITM_DFT;

            // Basic spells, that use neither free aiming nor movement
            if (!(eligible & GFA_ACT_MOVEMENT)) {
                GFA_DisableAutoTurning(0);
                GFA_DisableToggleFocusSpells(0);
                GFA_AimMovement(0, ""); // Might have switched directly from other spell while still in movement
                GFA_ACTIVE = 1;
                return;
            };
        } else {
            // Spell uses free aiming: Set stricter focus collection
            Focus_Magic.npc_azi = castFromIntf(castToIntf(GFA_FOCUS_SPL_NPC)); // Cast twice, Deadalus floats are dumb
            Focus_Magic.item_prio = GFA_FOCUS_SPL_ITM;
        };

        // Movement spells disable auto turning
        if (eligible & GFA_ACT_MOVEMENT) {
            GFA_DisableToggleFocusSpells(1);
            GFA_DisableAutoTurning(1);
        };

        // Disable reticle when holding the action key while running (will also disable turning!)
        if (GFA_ACTIVE_CTRL_SCHEME == 1) {
            if (!keyPressed) {
                GFA_ACTIVE = 1;
                return;
            };

            // Check if standing
            MEM_PushInstParam(hero);
            MEM_PushIntParam(BS_STAND);
            MEM_Call(C_BodyStateContains);
            standing = MEM_PopIntResult();

            // Exception: receiving damage removes standing body state
            MEM_PushInstParam(hero);
            MEM_PushIntParam(BS_STUMBLE);
            MEM_Call(C_BodyStateContains);
            stumbling = MEM_PopIntResult();

            if (!standing) && (!stumbling) && (!GFA_InvestingOrCasting(hero)) {
                GFA_ACTIVE = 1;
                return;
            };
        };

        // If this is reached, free aiming or at least free movement for the spell is active
        GFA_ACTIVE = eligible;

    } else if (her.fmode >= FMODE_FAR) { // Greater or equal: Crossbow has different fight mode!
        // Check if free aiming for ranged combat is disabled
        if (!(GFA_Flags & GFA_RANGED)) {
            GFA_DisableAutoTurning(0);
            GFA_SetCameraModes(0);
            GFA_ACTIVE = 1;
            return;
        };

        // Gothic 1 does not differentiate between camera modes. Force/overwrite all to free aiming mode
        GFA_SetCameraModes(1);
        GFA_DisableAutoTurning(1);

        // Set internally whether the aiming key is held or not (only if using Gothic 2 controls)
        if (GFA_ACTIVE_CTRL_SCHEME == 2) {
            MEM_WriteByte(oCAIHuman__PC_ActionMove_aimingKey+4, keyPressed);
        };

        // Aiming key is required to be held
        if (!keyPressed) {
            GFA_ACTIVE = 1;
            return;
        };

        // Disable focus collection while running
        if (GFA_ACTIVE_CTRL_SCHEME == 1) || (!GFA_STRAFING) {
            // Check if standing
            MEM_PushInstParam(hero);
            MEM_PushIntParam(BS_STAND);
            MEM_Call(C_BodyStateContains);
            standing = MEM_PopIntResult();

            // Exception: receiving damage removes standing body state
            MEM_PushInstParam(hero);
            MEM_PushIntParam(BS_STUMBLE);
            MEM_Call(C_BodyStateContains);
            stumbling = MEM_PopIntResult();

            if (!standing) && (!stumbling) {
                GFA_ACTIVE = 1;
                return;
            };
        };

        // If this is reached, free aiming for ranged weapons is currently active
        GFA_ACTIVE = FMODE_FAR; // Do not differentiate between bow and crossbow
    };
};
