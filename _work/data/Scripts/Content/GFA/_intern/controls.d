/*
 * Input and controls manipulation
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
 * Mouse handling for manually turning the player model by mouse input. This function hooks an engine function that
 * records physical(!) mouse movement and is called every frame.
 *
 * Usually when holding the action button down, rotating the player model is prevented. To allow free aiming that has to
 * be disabled. This can be (and was at some point) done by just skipping the condition by which turning is prevented.
 * However, it turned out to be very inaccurate and the movement was too jaggy for aiming. Instead, this function here
 * reads the (unaltered) change in mouse movement along the x-axis and performs the rotation manually the same way the
 * engine does it.
 *
 * To adjust the turn rate (translation between mouse movement and model rotation), modify GFA_ROTATION_SCALE.
 * By this implementation of free aiming, the manual turning of the player model is only necessary when using Gothic 1
 * controls.
 *
 * Since this function is called so frequently and regularly, it also serves to call the function to update the free aim
 * active/enabled state to set the constant GFA_ACTIVE.
 */
func void GFA_TurnPlayerModel() {
    // Retrieve free aim state and exit if player is not currently aiming
    MEM_Call(GFA_IsActive);
    if (!(GFA_ACTIVE & GFA_ACT_MOVEMENT)) {
        return;
    };

    // The _Cursor class from LeGo is used here. It is not necessarily a cursor: it holds mouse properties
    var _Cursor mouse; mouse = _^(Cursor_Ptr);

    // Update time of last mouse movement
    if (mouse.relX) || (mouse.relY) {
        GFA_MouseMovedLast = MEM_Timer.totalTime+100; // Keep from jittering
    };

    // Gothic 2 controls only need the rotation if currently shooting
    var oCNpc her; her = getPlayerInst();
    if (GFA_ACTIVE_CTRL_SCHEME == 2) {
        // Enabled turning when action key is down
        if (!MEM_KeyPressed(MEM_GetKey("keyAction"))) && (!MEM_KeyPressed(MEM_GetSecondaryKey("keyAction"))) {
            // Additional special case for spell combat: if action button already up, but spell is still being cast
            if (her.fmode == FMODE_MAGIC) {
                if (!GFA_InvestingOrCasting(hero)) && (GFA_SpellPostCastDelay <= MEM_Timer.totalTime) {
                    return;
                };
            } else {
                return;
            };
        };
    };

    // Retrieve horizontal mouse movement (along x-axis) and apply mouse sensitivity
    var int deltaX; deltaX = mulf(mkf(mouse.relX), MEM_ReadInt(Cursor_sX));
    if (deltaX == FLOATNULL) || (Cursor_NoEngine) {
        // Only rotate if there was movement along x position and if mouse movement is not disabled
        return;
    };

    // Apply turn rate
    deltaX = mulf(deltaX, castToIntf(GFA_ROTATION_SCALE));

    // Gothic 1 has a maximum turn rate
    if (GOTHIC_BASE_VERSION == 1) {
        // Also add another multiplier for Gothic 1 (mouse is faster)
        deltaX = mulf(deltaX, castToIntf(0.5));

        if (gf(deltaX, castToIntf(GFA_MAX_TURN_RATE_G1))) {
            deltaX = castToIntf(GFA_MAX_TURN_RATE_G1);
        } else if (lf(deltaX, negf(castToIntf(GFA_MAX_TURN_RATE_G1)))) {
            deltaX = negf(castToIntf(GFA_MAX_TURN_RATE_G1));
        };
    };

    // Turn player model
    var int hAniCtrl; hAniCtrl = her.anictrl;
    const int call = 0; var int zero;
    if (CALL_Begin(call)) {
        CALL_IntParam(_@(zero)); // 0 = disable turn animation (there is none while aiming anyways)
        CALL_FloatParam(_@(deltaX));
        CALL_PutRetValTo(0);
        CALL__thiscall(_@(hAniCtrl), oCAniCtrl_Human__Turn);
        call = CALL_End();
    };
};


/*
 * Disable/re-enable auto turning of player model towards enemy while aiming. The auto turning prevents free aiming, as
 * it moves the player model to always face the focus. Of course, this should only by prevented during aiming such that
 * the melee combat is not affected. Consequently, it needs to be disabled and enabled continuously.
 * This function is called from GFA_IsActive() and GFA_UpdateStatus().
 */
func void GFA_DisableAutoTurning(var int on) {
    const int SET = 0;
    if (on == SET) {
        return; // No change necessary
    };

    if (GOTHIC_BASE_VERSION == 2) {
        if (on) {
            // Jump from 0x737D75 to 0x737E32: 7568946-7568757 = 189-5 = 184 // Length of instruction: 5
            MEM_WriteByte(oCNpc__TurnToEnemy_camCheck, /*E9*/ 233); // jmp
            MEM_WriteByte(oCNpc__TurnToEnemy_camCheck+1, /*B8*/ 184); // B8 instead of B7, because jmp is 5 not 6 long
            MEM_WriteByte(oCNpc__TurnToEnemy_camCheck+2, /*00*/ 0);
            MEM_WriteByte(oCNpc__TurnToEnemy_camCheck+5, ASMINT_OP_nop);
        } else {
            MEM_WriteByte(oCNpc__TurnToEnemy_camCheck, /*0F*/ 15); // Revert to default: jnz loc_00737E32
            MEM_WriteByte(oCNpc__TurnToEnemy_camCheck+1, /*85*/ 133);
            MEM_WriteByte(oCNpc__TurnToEnemy_camCheck+2, /*B7*/ 183);
            MEM_WriteByte(oCNpc__TurnToEnemy_camCheck+5, /*00*/ 0);
        };
    } else {
        // In Gothic 1 there is only auto turning during spell combat. But it is not done by oCNpc::TurnToEnemy()
        if (on) {
            // Skip focus vob check to always jump beyond auto turning
            MEM_WriteByte(oCAIHuman__MagicMode_turnToTarget, /*33*/ 51); // Clear register: xor eax, eax
            MEM_WriteByte(oCAIHuman__MagicMode_turnToTarget+1, /*C0*/ 192);
            MEM_WriteByte(oCAIHuman__MagicMode_turnToTarget+2, ASMINT_OP_nop);
            MEM_WriteByte(oCAIHuman__MagicMode_turnToTarget+3, ASMINT_OP_nop);
            MEM_WriteByte(oCAIHuman__MagicMode_turnToTarget+4, ASMINT_OP_nop);
        } else {
            MEM_WriteByte(oCAIHuman__MagicMode_turnToTarget, /*E8*/ 232); // Reset to default: call oCNpc::GetFocusVob()
            MEM_WriteByte(oCAIHuman__MagicMode_turnToTarget+1, /*8B*/ 139);
            MEM_WriteByte(oCAIHuman__MagicMode_turnToTarget+2, /*2C*/ 44);
            MEM_WriteByte(oCAIHuman__MagicMode_turnToTarget+3, /*22*/ 34);
            MEM_WriteByte(oCAIHuman__MagicMode_turnToTarget+4, /*00*/ 0);
        };
    };
    SET = !SET;
};


/*
 * Set internal changes for Gothic controls for ranged combat. Gothic 2 relevant only.
 * The support for the Gothic 2 controls is accomplished by emulating the Gothic 1 controls with different sets of
 * aiming and shooting keys. To do this, the condition to differentiate between the control schemes is skipped and the
 * keys are overwritten (all on the level of opcode and only affecting ranged combat).
 *  scheme == 0: Revert to default (control scheme check by options)
 *  scheme == 1: Override with Gothic 1 controls
 *  scheme == 2: Override with Gothic 2 controls
 * This function is called from GFA_UpdateStatus() if the menu settings change.
 */
func void GFA_SetControlSchemeRanged(var int scheme) {
    if (GOTHIC_BASE_VERSION != 2) || (!(GFA_Flags & GFA_RANGED)) {
        return;
    };

    if (GFA_CTRL_SCHEME_RANGED == scheme) {
        return; // No change necessary
    };

    MEM_Info(ConcatStrings("  OPT: GFA: Ranged-ctrl-scheme=", IntToString(scheme))); // To zSpy in style as options
    if (scheme > 0) {
        // Control scheme override: Skip jump to Gothic 2 controls
        repeat(i, 6); var int i;
            MEM_WriteByte(oCAIHuman__BowMode_g2ctrlCheck+i, ASMINT_OP_nop);
        end;

        if (scheme == 2) {
            // Gothic 2 controls enabled: Mimic the Gothic 1 controls but change the keys
            MEM_WriteByte(oCAIHuman__BowMode_shootingKey+1, 5); // Overwrite shooting key to action button
            MEM_WriteByte(oCAIHuman__PC_ActionMove_aimingKey, ASMINT_OP_nop);
            MEM_WriteByte(oCAIHuman__PC_ActionMove_aimingKey+1, ASMINT_OP_nop);
            MEM_WriteByte(oCAIHuman__PC_ActionMove_aimingKey+2, ASMINT_OP_nop);
            MEM_WriteByte(oCAIHuman__PC_ActionMove_aimingKey+3, /*6A*/ 106); // push 0
            MEM_WriteByte(oCAIHuman__PC_ActionMove_aimingKey+4, 0); // Will be set to 0 or 1 depending on key press
        } else {
            // Revert keys to Gothic 1 controls
            MEM_WriteByte(oCAIHuman__BowMode_shootingKey+1, 3); // Revert to default: push 3
            MEM_WriteByte(oCAIHuman__PC_ActionMove_aimingKey, /*8B*/ 139); // Revert to default: mov eax, [esp+8h+a3h]
            MEM_WriteByte(oCAIHuman__PC_ActionMove_aimingKey+1, /*44*/ 68);
            MEM_WriteByte(oCAIHuman__PC_ActionMove_aimingKey+2, /*24*/ 36);
            MEM_WriteByte(oCAIHuman__PC_ActionMove_aimingKey+3, /*0C*/ 12);
            MEM_WriteByte(oCAIHuman__PC_ActionMove_aimingKey+4, /*50*/ 80); // Revert action key to default: push eax
        };
    } else {
        // Revert to original Gothic controls
        MEM_WriteByte(oCAIHuman__BowMode_g2ctrlCheck, /*0F*/ 15); // Revert G2 controls to default: jz to 0x696391
        MEM_WriteByte(oCAIHuman__BowMode_g2ctrlCheck+1, /*84*/ 132);
        MEM_WriteByte(oCAIHuman__BowMode_g2ctrlCheck+2, /*60*/ 96);
        MEM_WriteByte(oCAIHuman__BowMode_g2ctrlCheck+3, /*04*/ 4);
        MEM_WriteByte(oCAIHuman__BowMode_g2ctrlCheck+4, /*00*/ 0);
        MEM_WriteByte(oCAIHuman__BowMode_g2ctrlCheck+5, /*00*/ 0);

        // Revert key changes
        MEM_WriteByte(oCAIHuman__BowMode_shootingKey+1, 3); // Revert to default: push 3
        MEM_WriteByte(oCAIHuman__PC_ActionMove_aimingKey, /*8B*/ 139); // Revert to default: mov eax, [esp+8h+a3h]
        MEM_WriteByte(oCAIHuman__PC_ActionMove_aimingKey+1, /*44*/ 68);
        MEM_WriteByte(oCAIHuman__PC_ActionMove_aimingKey+2, /*24*/ 36);
        MEM_WriteByte(oCAIHuman__PC_ActionMove_aimingKey+3, /*0C*/ 12);
        MEM_WriteByte(oCAIHuman__PC_ActionMove_aimingKey+4, /*50*/ 80); // Revert action key to default: push eax
    };
    GFA_CTRL_SCHEME_RANGED = scheme;
};


/*
 * Set internal changes for Gothic controls for spell combat. Gothic 2 relevant only.
 * Gothic 1 and Gothic 2 control schemes are left untouched in this function. What is changed is the dependency on the
 * general (across) control scheme set in the game menu.
 *  scheme == 0: Revert to default (control scheme check by options)
 *  scheme == 1: Override with Gothic 1 controls
 *  scheme == 2: Override with Gothic 2 controls
 * This function is called from GFA_UpdateStatus() if the menu settings change.
 */
func void GFA_SetControlSchemeSpells(var int scheme) {
    if (GOTHIC_BASE_VERSION != 2) || (!(GFA_Flags & GFA_SPELLS)) {
        return;
    };

    if (GFA_CTRL_SCHEME_SPELLS == scheme) {
        return; // No change necessary
    };

    MEM_Info(ConcatStrings("  OPT: GFA: Spell-ctrl-scheme=", IntToString(scheme))); // To zSpy in style as options
    if (scheme > 0) {
        // Control scheme override: Replace general (across) control scheme with local setting
        GFA_SPELLS_G1_CTRL = (scheme == 1);
        MEM_WriteInt(oCAIHuman__MagicMode_g2ctrlCheck, _@(GFA_SPELLS_G1_CTRL));
    } else {
        // Revert to original Gothic controls
        MEM_WriteInt(oCAIHuman__MagicMode_g2ctrlCheck, oCGame__s_bUseOldControls);
    };
    GFA_CTRL_SCHEME_SPELLS = scheme;
};


/*
 * Overwrite/reset camera modes for Gothic 1. Gothic 1 does not use the different camera modes (CCamSys_Def) defined.
 * Instead of CamModRanged and CamModMagic, mostly CamModNormal and CamModMelee are used. A free aiming specific camera
 * is thus not possible. To solve this issue, the camera modes are overwritten and reset whenever needed.
 * This function is called from GFA_IsActive() and GFA_UpdateStatus().
 */
func void GFA_SetCameraModes(var int on) {
    if (GOTHIC_BASE_VERSION != 1) {
        return;
    };

    const int SET = 0;
    if (on == SET) {
        return; // No change necessary
    };

    if (on) {
        // Overwrite all camera modes, Gothic 1 just throws them around. ALL of them need to be replaced
        var string mode; mode = STR_Upper(GFA_CAMERA);
        MEM_WriteString(zString_CamModNormal, mode);
        MEM_WriteString(zString_CamModMelee, mode);
        MEM_WriteString(zString_CamModRun, mode);
        MEM_WriteString(oCAIHuman__Cam_Normal, mode);
        MEM_WriteString(oCAIHuman__Cam_Fight, mode);
    } else {
        // Reset all camera modes
        MEM_WriteString(zString_CamModNormal, "CAMMODNORMAL");
        MEM_WriteString(zString_CamModMelee, "CAMMODMELEE");
        MEM_WriteString(zString_CamModRun, "CAMMODRUN");
        MEM_WriteString(oCAIHuman__Cam_Normal, "CAMMODNORMAL");
        MEM_WriteString(oCAIHuman__Cam_Fight, "CAMMODNORMAL"); // Note: This is not CAMMODFIGHT!
    };
    SET = !SET;
};


/*
 * Enable/disable the switching between targets in focus for ranged combat. This is necessary to stay on the target
 * below the reticle and to prevent the focus from flickering. This function is called from GFA_UpdateStatus().
 */
func void GFA_DisableToggleFocusRanged(var int on) {
    if (!(GFA_Flags & GFA_RANGED)) {
        return;
    };

    const int SET = 0;
    if (on == SET) {
        return; // No change necessary
    };

    if (on) {
        // Disable toggling focus with left and right keys
        MEM_WriteByte(oCAIHuman__CheckFocusVob_ranged, FMODE_FAR+1); // No focus toggle if her.fmode <= FMODE_FAR+1
    } else {
        MEM_WriteByte(oCAIHuman__CheckFocusVob_ranged, 4); // Revert to default: 83 F8 04  mov eax, 4
    };
    SET = !SET;
};


/*
 * Enable/disable the switching between targets in focus for spell combat. This is necessary to stay on the target
 * below the reticle and to prevent the focus from flickering. This function is called from GFA_UpdateStatus() and also
 * from GFA_IsActive() to enable switching the focus for free aiming non-eligible spells.
 */
func void GFA_DisableToggleFocusSpells(var int on) {
    if (!(GFA_Flags & GFA_SPELLS)) {
        return;
    };

    const int SET = 0;
    if (on == SET) {
        return; // No change necessary
    };

    if (on) {
        // Disable toggling focus with left and right keys
        MEM_WriteByte(oCAIHuman__CheckFocusVob_spells, /*7D*/ 125); // jge: No focus toggle if her.fmode >= FMODE_MAGIC
    } else {
        MEM_WriteByte(oCAIHuman__CheckFocusVob_spells, /*7F*/ 127);  // Revert to default: 7F 54  jg 0x61589B
    };
    SET = !SET;
};


/*
 * Disable magic combat during default strafing. This allows quick-casting spells while strafing, which is not desired
 * with free aiming, because it does not use the normal spell casting functions, does not allow displaying a reticle and
 * does not allow investing spells. This questionable design choice was fortunately only made for Gothic 2, hence this
 * function exits immediately when called with Gothic 1.
 */
func void GFA_DisableMagicDuringStrafing(var int on) {
    if (GOTHIC_BASE_VERSION != 2) || (!(GFA_Flags & GFA_SPELLS)) {
        return;
    };

    const int SET = 0;
    if (on == SET) {
        return; // No change necessary
    };

    if (on) {
        // Disable magic combat during default strafing
        repeat(i, 5); var int i;
            MEM_WriteByte(oCNpc__EV_Strafe_magicCombat+i, ASMINT_OP_nop); // Remove call to oCNpc::FightAttackMagic()
        end;
    } else {
        MEM_WriteByte(oCNpc__EV_Strafe_magicCombat, /*E8*/ 232); // Revert to default call
        MEM_WriteByte(oCNpc__EV_Strafe_magicCombat+1, /*A0*/ 160);
        MEM_WriteByte(oCNpc__EV_Strafe_magicCombat+2, /*B4*/ 180);
        MEM_WriteByte(oCNpc__EV_Strafe_magicCombat+3, /*FF*/ 255);
        MEM_WriteByte(oCNpc__EV_Strafe_magicCombat+4, /*FF*/ 255);
    };
    SET = !SET;
};


/*
 * Remove reticle, prevent strafing and detach FX from aim vob during special body states. This function hooks at two
 * different addresses: During sliding (offset where sliding is positively determined in zCAIPlayer::IsSliding()) and
 * when lying on the ground after a deep fall (offset where lying is positively determined in
 * oCAIHuman::PC_CheckSpecialStates()).
 * Caution: This function is always called, even if free aiming is not currently active.
 */
func void GFA_TreatBodyStates() {
    if (!GFA_ACTIVE) {
        return;
    };

    GFA_ResetSpell();
    GFA_AimMovement(0, "");
    GFA_RemoveReticle();
    GFA_AimVobDetachFX();

    // Reset draw force
    GFA_BowDrawOnset = MEM_Timer.totalTime + GFA_DRAWTIME_READY;
};


/*
 * Prevent focus collection while jumping and falling during free aiming fight modes. This function hooks
 * oCAIHuman::PC_ActionMove() at an offset at which the fight modes are not reached. This happens during certain body
 * states. At that offset, the focus collection remains normal, which will counteract the idea of GFA_NO_AIM_NO_FOCUS.
 * This only happens for Gothic 2.
 */
func void GFA_PreventFocusCollectionBodyStates() {
    if (!GFA_ACTIVE) {
        return;
    };

    var oCNpc her; her = getPlayerInst();
    if ((her.fmode == FMODE_FAR) || (her.fmode == FMODE_FAR+1)) && (GFA_Flags & GFA_RANGED) // Bow or crossbow
    || ((her.fmode == FMODE_MAGIC) && (GFA_Flags & GFA_SPELLS)) { // Spell
        if (GFA_NO_AIM_NO_FOCUS) || ((GFA_ACTIVE_CTRL_SCHEME == 2) && (her.fmode == FMODE_MAGIC)) {
            GFA_SetFocusAndTarget(0);
        };

        // With Gothic 2 controls, the reticle is still visible
        if (GFA_ACTIVE_CTRL_SCHEME == 2) {
            GFA_RemoveReticle();
            GFA_AimVobDetachFX();
        };
    };
};


/*
 * This function fixes a bug where Gothics sets the body state to running, walking or sneaking when the NPC is acutally
 * standing. This function hooks oCAniCtrl_Human::SearchStandAni() at an offset after the walk mode is set to reset the
 * body state to standing and oCNpc::SetWeaponMode2() with the same bug.
 */
func void GFA_FixStandingBodyState() {
    var int npcPtr;

    // This function hooks two different engine functions (differentiate here)
    if (Hlp_Is_oCNpc(ESI)) {
        // oCNpc::SetWeaponMode2()
        npcPtr = ESI;

        // Exit if NPC is walking/running during weapon switch
        var int moving; moving = MEM_ReadInt(ESP+MEMINT_SwitchG1G2(/*esp+0A0h-08Ch*/ 20, /*esp+0A0h-088h*/ 24));
        if (moving) {
            return;
        };
    } else {
        // oCAniCtrl_Human::SearchStandAni()
        npcPtr = MEM_ReadInt(ESI+oCAniCtrl_Human_npc_offset);

        if (!Hlp_Is_oCNpc(npcPtr)) {
            return;
        };
    };

    // Reset body state back to standing (instead of running/walking/sneaking)
    var int standing; standing = BS_STAND & ~BS_FLAG_INTERRUPTABLE & ~BS_FLAG_FREEHANDS;
    const int call = 0;
    if (CALL_Begin(call)) {
        CALL_IntParam(_@(standing));
        CALL__thiscall(_@(npcPtr), oCNpc__SetBodyState);
        call = CALL_End();
    };
};


/*
 * Perform a stricter check whether to allow opening the inventory. This fixes the bug, where the player freezes when
 * opening the inventory while casting a spell. This function hooks oCGame::HandleEvent() at an offset where or the
 * inventory key was pressed and it is check whether to open the inventory.
 * Because of restricted address space, a function call was overwritten with this hook and is re-written at the start of
 * this function.
 */
func void GFA_FixOpenInventory() {
    // Re-write what has been overwritten with nop
    const int call = 0;
    if (CALL_Begin(call)) {
        CALL_PutRetValTo(_@(EAX));
        CALL__thiscall(_@(ECX), oCNpc__GetInteractMob);
        call = CALL_End();
    };

    // New: Additionally check if player is performing aim movement or not standing during spell combat
    if (!EAX) {
        EAX = GFA_IsStrafing;

        if (!EAX) {
            var oCNpc her; her = _^(ECX);
            if (her.fmode == FMODE_MAGIC) {
                var int aniCtrlPtr; aniCtrlPtr = her.anictrl;
                const int call2 = 0;
                if (CALL_Begin(call2)) {
                    CALL_PutRetValTo(_@(EAX));
                    CALL__thiscall(_@(aniCtrlPtr), oCAniCtrl_Human__IsStanding);
                    call2 = CALL_End();
                };
                EAX = !EAX;
            };
        };
    };
};


/*
 * Modify the attack run turning to only allow it for the player. This function hooks oCNpc::EV_AttackRun() at an offset
 * where the player can turn while performing an attack run. This function is only called for Gothic 2.
 */
func void GFA_FixNpcAttackRun() {
    var C_Npc slf; slf = _^(ESI);
    if (Npc_IsPlayer(slf)) {
        const int call = 0; var int zero;
        if (CALL_Begin(call)) {
            CALL_IntParam(_@(zero));
            CALL__thiscall(_@(ECX), oCAIHuman__PC_Turnings);
            call = CALL_End();
        };
    };
};


/*
 * Reset spell FX when interrupting investing/casting by the default strafing. This function hooks oCNpc::EV_Strafe() at
 * an offset where the fight mode is checked. oCNpc::EV_Strafe() is only called for the player.
 */
func void GFA_FixSpellOnStrafe() {
    if (!GFA_ACTIVE) {
        return;
    };

    var oCNpc her; her = _^(ECX);
    if (her.fmode == FMODE_MAGIC) {
        GFA_ResetSpell();
        GFA_AimVobDetachFX();
    };
};


/*
 * Prevent canceling the aim movement animations in oCNpc::Interrupt(). Naturally, this function hooks
 * oCNpc::Interrupt() at an offset before all animations are stopped to manipulate the ranges of layers to be stopped.
 * The first argument passed to the function zCModel::StopAnisLayerRange(), is increased or reset to two depending on
 * whether aim movement is active.
 */
func void GFA_DontInterruptStrafing() {
    var C_NPC slf; slf = _^(ESI);
    if (Npc_IsPlayer(slf)) && (GFA_IsStrafing) {
        // Stop only all animations in layers higher than the aim movements
        MEM_WriteByte(oCNpc__Interrupt_stopAnisLayerA, GFA_MOVE_ANI_LAYER+1); // zCModel::StopAnisLayerRange(X+1, 1000)
    } else {
        // Revert to default
        MEM_WriteByte(oCNpc__Interrupt_stopAnisLayerA, 2); // zCModel::StopAnisLayerRange(2, 1000)
    };
};


/*
 * Ambient OUs can be canceled with right mouse button, which will reset the aiming animation when using Gothic 2
 * controls, because it clears the key buffer. This is prevented with this function. It hooks
 * CGameManager::HandleEvent() at an offset where the key buffer is cleared after canceling OUs.
 */
func void GFA_CancelOUsDontClearKeyBuffer() {
    if (GFA_ACTIVE_CTRL_SCHEME == 2) && (GFA_ACTIVE == FMODE_FAR) {
        EAX = 0;
    };
};


/*
 * Adjust damage animation while aiming. This function hooks oCNpc::OnDamage_Anim() and replaces the hurting animation
 * if the player is aiming. Also the draw force and steady aim are reset.
 */
func void GFA_AdjustDamageAnimation() {
    var int victimPtr; victimPtr = MEM_ReadInt(ESP+204); // G1: esp+200h-134h, G2: esp+1FCh-130h
    var C_Npc victim; victim = _^(victimPtr);
    if (!Npc_IsPlayer(victim)) || (GFA_ACTIVE < FMODE_FAR) {
        return;
    };

    // Reset draw time and steady aim
    GFA_BowDrawOnset = MEM_Timer.totalTime + GFA_DRAWTIME_READY;
    GFA_MouseMovedLast = MEM_Timer.totalTime + GFA_DRAWTIME_READY;

    // Retrieve hurting animation name
    var string aniName; aniName = MEM_ReadStatStringArr(GFA_AIM_ANIS, GFA_HURT_ANI);
    var string prefix; prefix = "T_";
    var string modifier;

    // Retrieve animation name modifier by fight mode
    var oCNpc npc; npc = _^(victimPtr);
    if (npc.fmode == FMODE_MAGIC) {
        modifier = "MAG";

        // Also treat variations of casting animations
        var int spellID; spellID = Npc_GetActiveSpell(victim); // Scrolls are removed: sometimes not found
        if (GFA_InvestingOrCasting(victim) > 0) && (spellID != -1) {
            var string castMod; castMod = ConcatStrings(modifier, MEM_ReadStatStringArr(spellFxAniLetters, spellID));

            // Check if animation with casting modifier exists
            var int aniNamePtr; aniNamePtr = _@s(ConcatStrings(ConcatStrings(prefix, castMod), aniName));
            var int model; model = MEM_ReadInt(MEMINT_SwitchG1G2(/*esp+200h-ECh*/ ESP+276, /*esp+1FCh-DCh*/ ESP+288));
            var zCArray protoTypes; protoTypes = _^(model+zCModel_prototypes_offset);
            var int modelPrototype; modelPrototype = MEM_ReadInt(protoTypes.array);
            const int call = 0;
            if (CALL_Begin(call)) {
                CALL__fastcall(_@(modelPrototype), _@(aniNamePtr), zCModelPrototype__SearchAniIndex);
                call = CALL_End();
            };
            if (CALL_RetValAsInt() >= 0) {
                modifier = castMod;
            };
        };
    } else if (npc.fmode == FMODE_FAR) {
        modifier = "BOW";
    } else {
        modifier = "CBOW";
    };

    // Build complete animation name
    aniName = ConcatStrings(ConcatStrings(prefix, modifier), aniName);

    // Overwrite damage animation
    var int aniNameAddr; aniNameAddr = ESP+24; // G1: esp+200h-1E8h, G2: esp+1FCh-1E4h
    MEM_WriteString(aniNameAddr, aniName);
};
