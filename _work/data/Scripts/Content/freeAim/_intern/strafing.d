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
            CALL__thiscall(_@(model), zCModel__FadeOutAnisLayerRange);
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

    // Iterate over all aim movement animations and stop or play them
    repeat(aniIdx, GFA_MAX_AIM_ANIS); var int aniIdx;
        // Skip empty indices
        if (aniIdx == 0) || (aniIdx == 3) || (aniIdx == 7) {
            continue;
        };

        // Get full name of animation
        var string aniName; aniName = ConcatStrings(prefix, MEM_ReadStatStringArr(GFA_AIM_ANIS, aniIdx));
        var int aniNamePtr; aniNamePtr = _@s(aniName);

        // Increase performance: work with zCModelAni instead of string (every following function would do this over)
        var int aniID;
        const int call3 = 0;
        if (CALL_Begin(call3)) {
            CALL_PtrParam(_@(aniNamePtr));
            CALL_PutRetValTo(_@(aniID));
            CALL__thiscall(_@(model), zCModel__GetAniIDFromAniName);
            call3 = CALL_End();
        };
        var int modelAni;
        const int call4 = 0;
        if (CALL_Begin(call4)) {
            CALL_IntParam(_@(aniID));
            CALL_PutRetValTo(_@(modelAni));
            CALL__thiscall(_@(model), zCModel__GetAniFromAniID);
            call4 = CALL_End();
        };
        if (!modelAni) {
            MEM_SendToSpy(zERR_TYPE_WARN, // Same as MEM_Warn(), but avoid Ikarus stack trace
                ConcatStrings(ConcatStrings("GFA_AimMovement: Animation not found: ", aniName), "."));
            continue;
        };

        // Check whether animation is active
        var int aniActive;
        const int call5 = 0;
        if (CALL_Begin(call5)) {
            CALL_PtrParam(_@(modelAni));
            CALL_PutRetValTo(_@(aniActive));
            CALL__thiscall(_@(model), zCModel__IsAniActive);
            call5 = CALL_End();
        };

        // Update animations
        if (movement == aniIdx) && (!aniActive) {
            // Start requested animation
            var int zero;
            const int call6 = 0;
            if (CALL_Begin(call6)) {
                CALL_IntParam(_@(zero));
                CALL_PtrParam(_@(modelAni));
                CALL__thiscall(_@(model), zCModel__StartAni);
                call6 = CALL_End();
            };
        } else if (aniActive) {
            // Stop any other animation
            const int call7 = 0;
            if (CALL_Begin(call7)) {
                CALL_PtrParam(_@(modelAni));
                CALL__thiscall(_@(model), zCModel__FadeOutAni);
                call7 = CALL_End();
            };
        };
    end;
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
    MEM_PushInstParam(hero);
    MEM_PushIntParam(BS_STAND);
    MEM_Call(C_BodyStateContains);
    if (!MEM_PopIntResult()) {
        GFA_AimMovement(0);
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
