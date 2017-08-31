/*
 * Movement during free aiming
 *
 * Gothic Free Aim (GFA) v1.0.0-alpha - Free aiming for the video games Gothic 1 and Gothic 2 by Piranha Bytes
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
 * Update movement animations during aiming (i.e. strafing in eight directions). The parameter 'movement' is the index
 * of animation to be played, see GFA_AIM_ANIS.
 */
func void GFA_AimMovement(var int movement) {
    // Send perception before anything else (every 1500 ms)
    if (movement) {
        var int percTimer; percTimer += MEM_Timer.frameTime;
        if (percTimer >= 1500) {
            percTimer -= 1500;
            // Ignore sneaking, because PERC_OBSERVESUSPECT is disabled
            Npc_SendPassivePerc(hero, PERC_ASSESSQUIETSOUND, NULL, hero);
        };
    };

    // Increase performance: Exit if movement did not change
    if (GFA_IsStrafing == movement) {
        return;
    };
    GFA_IsStrafing = movement;

    // Get player model
    var oCNpc her; her = Hlp_GetNpc(hero);
    var int herPtr; herPtr = _@(her);
    var int model;
    const int call = 0;
    if (CALL_Begin(call)) {
        CALL_PutRetValTo(_@(model));
        CALL__thiscall(_@(herPtr), oCNpc__GetModel);
        call = CALL_End();
    };

    // Stopping all movements is faster this way
    if (!movement) {
        const int call2 = 0;
        if (CALL_Begin(call2)) {
            CALL_IntParam(_@(GFA_MOVE_ANI_LAYER));
            CALL_IntParam(_@(GFA_MOVE_ANI_LAYER));
            CALL__thiscall(_@(model), zCModel__StopAnisLayerRange);
            call2 = CALL_End();
        };
        return;
    };

    // Find animation name prefix by fight mode
    var string prefix;
    if (her.fmode == FMODE_MAGIC) {
        prefix = "S_MAG";
    } else if (her.fmode == FMODE_FAR) {
        prefix = "S_BOW";
    } else if (her.fmode == FMODE_FAR+1) {
        prefix = "S_CBOW";
    } else {
        MEM_Warn("GFA_AimMovement: Player not in valid aiming fight mode.");
        return;
    };

    var int zero;

    // Ensure that there is enough space to move (WIP: NOT WORKING YET)
    if (movement & GFA_MOVE_FORWARD) || (movement & GFA_MOVE_BACKWARD) {
        var int aniCtrlPtr; aniCtrlPtr = her.anictrl;
        var int enoughSpace;

        const int zCAIPlayer__CheckEnoughSpaceMoveForward = 5314304; //0x511700
        const int zCAIPlayer__CheckEnoughSpaceMoveBackward = 5314368; //0x511740

        if (movement & GFA_MOVE_FORWARD) {
            const int call3 = 0;
            if (CALL_Begin(call3)) {
                CALL_IntParam(_@(zero));
                CALL_PutRetValTo(_@(enoughSpace));
                CALL__thiscall(_@(aniCtrlPtr), zCAIPlayer__CheckEnoughSpaceMoveForward);
                call3 = CALL_End();
            };
        } else {
            const int call4 = 0;
            if (CALL_Begin(call4)) {
                CALL_IntParam(_@(zero));
                CALL_PutRetValTo(_@(enoughSpace));
                CALL__thiscall(_@(aniCtrlPtr), zCAIPlayer__CheckEnoughSpaceMoveBackward);
                call4 = CALL_End();
            };
        };

        if (!enoughSpace) {
            MEM_Info("### STOP MOVEMENT ###");
            movement = movement & ~GFA_MOVE_FORWARD & ~GFA_MOVE_BACKWARD;
        };
    };

    // Get full name of animation
    var string aniName; aniName = ConcatStrings(prefix, MEM_ReadStatStringArr(GFA_AIM_ANIS, movement));
    var int aniNamePtr; aniNamePtr = _@s(aniName);

    // Check whether animation is active
    const int call5 = 0;
    if (CALL_Begin(call5)) {
        CALL_PtrParam(_@(aniNamePtr));
        CALL__thiscall(_@(model), zCModel__IsAnimationActive);
        call5 = CALL_End();
    };

    // Start animation if not active
    if (!CALL_RetValAsInt()) {
        const int call6 = 0;
        if (CALL_Begin(call6)) {
            CALL_IntParam(_@(zero));
            CALL_PtrParam(_@(aniNamePtr));
            CALL__thiscall(_@(model), zCModel__StartAni);
            call6 = CALL_End();
        };
    };
};


/*
 * Enable movement while aiming. This function checks key presses and passes on a movement ID to GFA_AimMovement(). The
 * function hooks oCAIHuman::BowMode() at an offset, where the player is aiming. Additionally, the function is called
 * from GFA_RangedIdle() to allow movement during shooting and to reset movement when letting go of the aiming key.
 * The function is also called from GFA_SpellAiming() for strafing during spell combat.
 */
func void GFA_Strafe() {
    if (!GFA_ACTIVE) {
        GFA_AimMovement(0);
        return;
    };

    // Safety check that player is not running/falling/jumping
    if (GOTHIC_CONTROL_SCHEME == 1) {
        // Does not work for Gothic 2 controls (but movement locked anyways, check not necessary)
        MEM_PushInstParam(hero);
        MEM_PushIntParam(BS_STAND);
        MEM_Call(C_BodyStateContains);
        if (!MEM_PopIntResult()) {
            GFA_AimMovement(0);
            return;
        };
    };

    // Magic mode does not allow sneaking (messes up the perception and would require more animations)
    if (Npc_IsInFightMode(hero, FMODE_MAGIC)) {
        var oCNpc her; her = Hlp_GetNpc(hero);
        var int aniCtrlPtr; aniCtrlPtr = her.anictrl;

        // Check if sneaking
        if (MEM_ReadInt(aniCtrlPtr+oCAIHuman_walkmode_offset) & NPC_SNEAK) {
            // Set up and check new walk mode as NPC_RUN (see Constants.d)
            const int call = 0;
            if (CALL_Begin(call)) {
                CALL_IntParam(_@(NPC_RUN));
                CALL__thiscall(_@(aniCtrlPtr), oCAniCtrl_Human__CanToggleWalkModeTo);
                call = CALL_End();
            };

            // Toggle walk mode
            if (CALL_RetValAsInt()) {
                const int negOne = -1;
                const int call2 = 0;
                if (CALL_Begin(call2)) {
                    CALL_IntParam(_@(negOne));
                    CALL__thiscall(_@(aniCtrlPtr), oCAniCtrl_Human__ToggleWalkMode);
                    call2 = CALL_End();
                };
            };
        };

        // For Gothic 2 control remove running animation if it was started during weapon change
        if (GOTHIC_CONTROL_SCHEME == 2) {
            var int herPtr; herPtr = _@(her);
            var int model;
            const int call3 = 0;
            if (CALL_Begin(call3)) {
                CALL_PutRetValTo(_@(model));
                CALL__thiscall(_@(herPtr), oCNpc__GetModel);
                call3 = CALL_End();
            };
            const string anis[3] = {
                "S_MAGRUNL",
                "S_MAGWALKL",
                "S_MAGSNEAKL"
            };
            repeat(i, 3); var int i;
                var int aniNamePtr; aniNamePtr = _@s(MEM_ReadStatStringArr(anis, i));
                const int call4 = 0;
                if (CALL_Begin(call4)) {
                    CALL_PtrParam(_@(aniNamePtr));
                    CALL__thiscall(_@(model), zCModel__StopAnimation);
                    call4 = CALL_End();
                };
            end;
        };
    };

    // Check whether keys are pressed down (held)
    var int mFront;
    var int mBack;
    var int mLeft;
    var int mRight;

    mBack  = (MEM_KeyPressed(MEM_GetKey("keyDown")))        || (MEM_KeyPressed(MEM_GetSecondaryKey("keyDown")));
    mLeft  = (MEM_KeyPressed(MEM_GetKey("keyStrafeLeft")))  || (MEM_KeyPressed(MEM_GetSecondaryKey("keyStrafeLeft")));
    mRight = (MEM_KeyPressed(MEM_GetKey("keyStrafeRight"))) || (MEM_KeyPressed(MEM_GetSecondaryKey("keyStrafeRight")));

    // Allow forward movement for Gothic 2 controls only
    if (GOTHIC_CONTROL_SCHEME == 2) {
        mFront = (MEM_KeyPressed(MEM_GetKey("keyUp"))) || (MEM_KeyPressed(MEM_GetSecondaryKey("keyUp")));
    } else {
        mFront = FALSE;
    };

    // Evaluate movement from key presses (because there are also diagonal movements)
    var int movement; movement = (GFA_MOVE_FORWARD  * mFront)
                               | (GFA_MOVE_BACKWARD * mBack)
                               | (GFA_MOVE_LEFT     * mLeft)
                               | (GFA_MOVE_RIGHT    * mRight);
    GFA_AimMovement(movement);
};
