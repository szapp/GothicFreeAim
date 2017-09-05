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
    var zCAIPlayer playerAI; playerAI = _^(her.anictrl);
    var int model; model = playerAI.model;

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

    // Compute movement direction
    var zMAT4 herTrf; herTrf = _^(_@(her._zCVob_trafoObjToWorld));
    var int dir[3];
    var int dirPtr; dirPtr = _@(dir);

    // Front/back axis
    if (movement & GFA_MOVE_FORWARD) {
        dir[0] = herTrf.v0[zMAT4_outVec];
        dir[1] = herTrf.v1[zMAT4_outVec];
        dir[2] = herTrf.v2[zMAT4_outVec];
    } else if (movement & GFA_MOVE_BACKWARD) {
        dir[0] = negf(herTrf.v0[zMAT4_outVec]);
        dir[1] = negf(herTrf.v1[zMAT4_outVec]);
        dir[2] = negf(herTrf.v2[zMAT4_outVec]);
    } else {
        dir[0] = FLOATNULL;
        dir[1] = FLOATNULL;
        dir[2] = FLOATNULL;
    };

    // Left right axis (combine vector for diagonal movement directions)
    if (movement & GFA_MOVE_LEFT) || (movement & GFA_MOVE_RIGHT) {
        if (movement & GFA_MOVE_LEFT) {
            dir[0] = subf(dir[0], herTrf.v0[zMAT4_rightVec]);
            dir[1] = subf(dir[1], herTrf.v1[zMAT4_rightVec]);
            dir[2] = subf(dir[2], herTrf.v2[zMAT4_rightVec]);
        } else {
            dir[0] = addf(dir[0], herTrf.v0[zMAT4_rightVec]);
            dir[1] = addf(dir[1], herTrf.v1[zMAT4_rightVec]);
            dir[2] = addf(dir[2], herTrf.v2[zMAT4_rightVec]);
        };
        // Direction vector needs to be normalized
        const int call3 = 0;
        if (CALL_Begin(call3)) {
            CALL__thiscall(_@(dirPtr), zVEC3__NormalizeSafe);
            call3 = CALL_End();
        };
        MEM_CopyBytes(CALL_RetValAsPtr(), dirPtr, sizeof_zVEC3);
    };

    // Check if there is enough space in the computed movement direction
    var int aniCtrlPtr; aniCtrlPtr = her.anictrl;
    var int zero;
    const int call4 = 0;
    if (CALL_Begin(call4)) {
        CALL_IntParam(_@(zero));
        CALL_PtrParam(_@(dirPtr));
        CALL__thiscall(_@(aniCtrlPtr), zCAIPlayer__CheckEnoughSpaceMoveDir);
        call4 = CALL_End();
    };
    if (!CALL_RetValAsInt()) {
        GFA_AimMovement(0);
        return;
    };

    // Check force movement halt
    if (playerAI.bitfield[1] & zCAIPlayer_bitfield1_forceModelHalt) {
        playerAI.bitfield[1] = playerAI.bitfield[1] & ~zCAIPlayer_bitfield1_forceModelHalt;
        GFA_AimMovement(0);
        return;
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
    if (GFA_ACTIVE < FMODE_FAR) {
        GFA_AimMovement(0);
        return;
    };

    // Magic mode does not allow sneaking (messes up the perception and would require more animations)
    if (Npc_IsInFightMode(hero, FMODE_MAGIC)) {
        var oCNpc her; her = Hlp_GetNpc(hero);
        var int aniCtrlPtr; aniCtrlPtr = her.anictrl;

        // Sneaking not allowed
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

    // Allow forward movement only when using Gothic 2 controls while investing or casting a spell
    if (GOTHIC_CONTROL_SCHEME == 2) && (GFA_InvestingOrCasting(hero)) {
        mFront = (MEM_KeyPressed(MEM_GetKey("keyUp"))) || (MEM_KeyPressed(MEM_GetSecondaryKey("keyUp")));
    } else {
        mFront = FALSE;
    };

    // Evaluate movement from key presses (because there are also diagonal movements)
    var int movement; movement = (GFA_MOVE_FORWARD  * mFront)
                               | (GFA_MOVE_BACKWARD * mBack)
                               | (GFA_MOVE_LEFT     * mLeft)
                               | (GFA_MOVE_RIGHT    * mRight);

    // Prevent opposing directions
    if (mFront) && (mBack) {
        movement = movement & ~GFA_MOVE_FORWARD & ~GFA_MOVE_BACKWARD;
    };
    if (mLeft) && (mRight) {
        movement = movement & ~GFA_MOVE_LEFT & ~GFA_MOVE_RIGHT;
    };

    GFA_AimMovement(movement);
};
