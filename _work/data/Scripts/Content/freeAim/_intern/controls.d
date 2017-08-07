/*
 * Input and controls manipulation
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
 * Mouse handling for manually turning the player model by mouse input. This function hooks an engine function that
 * records physical(!) mouse movement and is called every frame.
 *
 * Usually when holding the action button down, rotating the player model is prevented. To allow free aiming the has to
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
func void freeAimManualRotation() {
    // Retrieve free aim state and exit if player is not currently aiming
    MEM_Call(freeAimIsActive);
    if (GFA_ACTIVE < FMODE_FAR) {
        return;
    };

    // The _Cursor class from LeGo is used here. It is not necessarily a cursor: it holds mouse movement
    var _Cursor mouse; mouse = _^(Cursor_Ptr);

    // Add recoil to mouse movement
    if (GFA_Recoil) {
        // These mouse manipulations work great and are consistent in Gothic 2. Not so much in Gothic 1. This is NOT due
        // to differences in mouse handling (it is pretty much exactly the same, except for some additional mouse
        // smoothing in Gothic 2, which is ignored for free aiming), but because of the camera easing: Once the camera
        // is moving in Gothic 1, a single mouse input has much more impact than when the camera is still.
        // This easing cannot be controlled with the CCamSys_Def instance and it is not clear where this easing is done
        // internally. Thus, recoil just works a bit different in Gothic 1. (Varying with mouse/camera movement.)

        // Manipulate vertical mouse movement: Add negative (upwards) movement (multiplied by sensitivity)
        mouse.relY = -roundf(divf(mkf(GFA_Recoil), MEM_ReadInt(Cursor_sY)));

        // Reset recoil ASAP, since this function is called in fast succession
        GFA_Recoil = 0;

        // Manipulate horziontal mouse movement slightly: Add random positive or negative (sideways) movement
        var int manipulateX; manipulateX = fracf(r_MinMax(-GFA_HORZ_RECOIL*10, GFA_HORZ_RECOIL*10), 10);
        mouse.relX = roundf(divf(manipulateX, MEM_ReadInt(Cursor_sX)));
    };

    // Gothic 2 controls only need the rotation if currently shooting
    if (GOTHIC_BASE_VERSION == 2) {
        // Separate if-conditions to increase performance (Gothic checks ALL chained if-conditions)
        if (!MEM_ReadInt(oCGame__s_bUseOldControls)) {
            if (!MEM_KeyPressed(MEM_GetKey("keyAction"))) && (!MEM_KeyPressed(MEM_GetSecondaryKey("keyAction"))) {
                return;
            };
        };
    };

    // Retrieve vertical mouse movement (along x-axis) and apply mouse sensitivity
    var int deltaX; deltaX = mulf(mkf(mouse.relX), MEM_ReadInt(Cursor_sX));
    if (deltaX == FLOATNULL) || (Cursor_NoEngine) {
        // Only rotate if there was movement along x position and if mouse movement is not disabled
        return;
    };

    // Apply turn rate
    deltaX = mulf(deltaX, castToIntf(GFA_ROTATION_SCALE));

    // Gothic 1 has a maximum turn rate
    if (GOTHIC_BASE_VERSION == 1) {
        // Also add another mulitplier for Gothic 1
        deltaX = mulf(deltaX, castToIntf(0.5));

        if (gf(deltaX, castToIntf(GFA_MAX_TURN_RATE_G1))) {
            deltaX = castToIntf(GFA_MAX_TURN_RATE_G1);
        } else if (lf(deltaX, negf(castToIntf(GFA_MAX_TURN_RATE_G1)))) {
            deltaX = negf(castToIntf(GFA_MAX_TURN_RATE_G1));
        };
    };

    // Turn player model
    var oCNpc her; her = Hlp_GetNpc(hero);
    var int hAniCtrl; hAniCtrl = her.anictrl;
    const int call = 0; var int zero; var int ret;
    if (CALL_Begin(call)) {
        CALL_IntParam(_@(zero)); // 0 = disable turn animation (there is none while aiming anyways)
        CALL_FloatParam(_@(deltaX));
        CALL_PutRetValTo(_@(ret)); // Get return value from stack
        CALL__thiscall(_@(hAniCtrl), oCAniCtrl_Human__Turn);
        call = CALL_End();
    };
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
        // In Gothic 1 there is only auto turning during magic combat. But it is not done by oCNpc::TurnToEnemy
        if (on) {
            // Skip focus vob check to always jump beyond auto turning
            MEM_WriteByte(oCAIHuman__MagicMode_turnToTarget, /*33*/ 51); // Clear register: xor eax, eax
            MEM_WriteByte(oCAIHuman__MagicMode_turnToTarget+1, /*C0*/ 192);
            MEM_WriteByte(oCAIHuman__MagicMode_turnToTarget+2, ASMINT_OP_nop);
            MEM_WriteByte(oCAIHuman__MagicMode_turnToTarget+3, ASMINT_OP_nop);
            MEM_WriteByte(oCAIHuman__MagicMode_turnToTarget+4, ASMINT_OP_nop);
        } else {
            MEM_WriteByte(oCAIHuman__MagicMode_turnToTarget, /*E8*/ 232); // Revert to default: call oCNpc::GetFocusVob
            MEM_WriteByte(oCAIHuman__MagicMode_turnToTarget+1, /*8B*/ 139);
            MEM_WriteByte(oCAIHuman__MagicMode_turnToTarget+2, /*2C*/ 44);
            MEM_WriteByte(oCAIHuman__MagicMode_turnToTarget+3, /*22*/ 34);
            MEM_WriteByte(oCAIHuman__MagicMode_turnToTarget+4, /*00*/ 0);
        };
    };
    SET = !SET;
};


/*
 * Update internal settings for Gothic 2 controls.
 * The support for the Gothic 2 controls is accomplished by emulating the Gothic 1 controls with different sets of
 * aiming and shooting keys. To do this, the condition to differentiate between the control schemes is skipped and the
 * keys are overwritten (all on the level of opcode).
 * This function is called from freeAimIsActive() nearly every frame.
 */
func void freeAimUpdateSettingsG2Ctrl(var int on) {
    if (GOTHIC_BASE_VERSION != 2) || (!GFA_RANGED) {
        return;
    };

    const int SET = 0; // Gothic 1 controls are considered default here
    if (SET == on) {
        return; // No change necessary
    };

    MEM_Info(ConcatStrings("  OPT: Free-Aim: G2-controls=", IntToString(on))); // Print to zSpy in same style as options
    if (on) {
        // Gothic 2 controls enabled: Mimic the Gothic 1 controls but change the keys
        MEM_WriteByte(oCAIHuman__BowMode_g2ctrlCheck, ASMINT_OP_nop); // Skip jump to Gothic 2 controls
        MEM_WriteByte(oCAIHuman__BowMode_g2ctrlCheck+1, ASMINT_OP_nop);
        MEM_WriteByte(oCAIHuman__BowMode_g2ctrlCheck+2, ASMINT_OP_nop);
        MEM_WriteByte(oCAIHuman__BowMode_g2ctrlCheck+3, ASMINT_OP_nop);
        MEM_WriteByte(oCAIHuman__BowMode_g2ctrlCheck+4, ASMINT_OP_nop);
        MEM_WriteByte(oCAIHuman__BowMode_g2ctrlCheck+5, ASMINT_OP_nop);
        MEM_WriteByte(oCAIHuman__BowMode_shootingKey+1, 5); // Overwrite shooting key to action button
        MEM_WriteByte(oCAIHuman__PC_ActionMove_aimingKey, ASMINT_OP_nop);
        MEM_WriteByte(oCAIHuman__PC_ActionMove_aimingKey+1, ASMINT_OP_nop);
        MEM_WriteByte(oCAIHuman__PC_ActionMove_aimingKey+2, ASMINT_OP_nop);
        MEM_WriteByte(oCAIHuman__PC_ActionMove_aimingKey+3, /*6A*/ 106); // push 0
        MEM_WriteByte(oCAIHuman__PC_ActionMove_aimingKey+4, 0); // Will be set to 0 or 1 depending on key press
    } else {
        // Gothic 2 controls disabled: Revert to original Gothic 2 controls
        MEM_WriteByte(oCAIHuman__BowMode_g2ctrlCheck, /*0F*/ 15); // Revert G2 controls to default: jz to 0x696391
        MEM_WriteByte(oCAIHuman__BowMode_g2ctrlCheck+1, /*84*/ 132);
        MEM_WriteByte(oCAIHuman__BowMode_g2ctrlCheck+2, /*60*/ 96);
        MEM_WriteByte(oCAIHuman__BowMode_g2ctrlCheck+3, /*04*/ 4);
        MEM_WriteByte(oCAIHuman__BowMode_g2ctrlCheck+4, /*00*/ 0);
        MEM_WriteByte(oCAIHuman__BowMode_g2ctrlCheck+5, /*00*/ 0);
        MEM_WriteByte(oCAIHuman__BowMode_shootingKey+1, 3); // Revert to default: push 3
        MEM_WriteByte(oCAIHuman__PC_ActionMove_aimingKey, /*8B*/ 139); // Revert to default: mov eax, [esp+8h+a3h]
        MEM_WriteByte(oCAIHuman__PC_ActionMove_aimingKey+1, /*44*/ 68);
        MEM_WriteByte(oCAIHuman__PC_ActionMove_aimingKey+2, /*24*/ 36);
        MEM_WriteByte(oCAIHuman__PC_ActionMove_aimingKey+3, /*0C*/ 12); // Revert action key to default: push eax
        MEM_WriteByte(oCAIHuman__PC_ActionMove_aimingKey+4, /*50*/ 80);
    };
    SET = !SET;
};


/*
 * Overwrite/reset camera modes for Gothic 1. Gothic 1 does not use the different camera modes (CCamSys_Def) defined.
 * Instead of CamModRanged and CamModMagic, mostly CamModNormal and CamModMelee are used. A free aiming specific camera
 * is thus not possible. To solve this issue, the camera modes are overwritten and reset whenever needed.
 * This function is called from freeAimIsActive() nearly every frame.
 */
func void freeAimSetCameraMode_G1(var int on) {
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
 * Disable damage animation while aiming. This function hooks the function that deals damage to NPCs and prevents the
 * damage animation for the player while aiming, as it looks questionable if the reticle stays centered but the player
 * model is crooked.
 * Taken from http://forum.worldofplayers.de/forum/threads/1474431?p=25057480#post25057480
 */
func void freeAimDmgAnimation() {
    var C_Npc victim; victim = _^(ECX);
    if (Npc_IsPlayer(victim)) && (GFA_ACTIVE > 1) {
        EAX = 0; // Disable animation by removing 'this'
    };
};
