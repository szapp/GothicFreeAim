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
func void GFA_AimMovement(var int movement, var string modifier) {
    if (!GFA_STRAFING) {
        return;
    };

    // Send perception before anything else (every 1500 ms)
    if (movement) {
        var int percTimer; percTimer += MEM_Timer.frameTime;
        if (percTimer >= 1500) {
            percTimer -= 1500;
            Npc_SendPassivePerc(hero, PERC_ASSESSQUIETSOUND, NULL, hero);
        };
    };

    // Increase performance: Exit if movement did not change
    if (GFA_IsStrafing == movement) && (Hlp_StrCmp(modifier, lastMod)) {
        return;
    };

    // Remember last movement for animation transitions
    var int lastMove; lastMove = GFA_IsStrafing;
    var string lastMod; lastMod = modifier;
    GFA_IsStrafing = movement;

    // Get player model
    var oCNpc her; her = Hlp_GetNpc(hero);
    var zCAIPlayer playerAI; playerAI = _^(her.anictrl);
    var int model; model = playerAI.model;
    var int bitfield; bitfield = MEM_ReadInt(her.anictrl+oCAIHuman_bitfield_offset);

    // Stopping all movements is faster this way
    if (!movement) {
        const int call2 = 0;
        if (CALL_Begin(call2)) {
            CALL_IntParam(_@(GFA_MOVE_ANI_LAYER));
            CALL_IntParam(_@(GFA_MOVE_ANI_LAYER));
            CALL__thiscall(_@(model), zCModel__FadeOutAnisLayerRange);
            call2 = CALL_End();
        };

        // Send observe intruder perception (relevant for Gothic 1 only)
        if (bitfield & oCAIHuman_bitfield_startObserveIntruder) {
            MEM_WriteInt(aniCtrlPtr+oCAIHuman_bitfield_offset, bitfield & ~oCAIHuman_bitfield_startObserveIntruder);
            Npc_SendPassivePerc(hero, PERC_OBSERVEINTRUDER, NULL, hero);
        };
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
        GFA_AimMovement(0, "");
        return;
    };

    // Check force movement halt
    if (playerAI.bitfield[1] & zCAIPlayer_bitfield1_forceModelHalt) {
        playerAI.bitfield[1] = playerAI.bitfield[1] & ~zCAIPlayer_bitfield1_forceModelHalt;
        GFA_AimMovement(0, "");
        return;
    };


    // Add animation transition prefix (transition or state animation)
    var string prefix;
    var string postfix;
    if (lastMove & movement) {
        prefix = "T_";
        postfix = MEM_ReadStatStringArr(GFA_AIM_ANIS, GFA_MOVE_TRANS);
    } else {
        prefix = "S_";
        postfix = "";
    };
    // New animation
    postfix = ConcatStrings(postfix, MEM_ReadStatStringArr(GFA_AIM_ANIS, movement));

    // Get full name of complete animation
    var string aniName; aniName = ConcatStrings(ConcatStrings(prefix, modifier), postfix);
    var int aniNamePtr; aniNamePtr = _@s(aniName);

    // Check if spell animation with casting modifier exists (otherwise assume default)
    if (STR_Len(lastMod) > 3) {
        var int modelPrototype; modelPrototype = MEM_ReadInt(MEM_ReadInt(model+zCModel__modelPrototype_offset));
        const int call5 = 0;
        if (CALL_Begin(call5)) {
            CALL__fastcall(_@(modelPrototype), _@(aniNamePtr), zCModelPrototype__SearchAniIndex);
            call5 = CALL_End();
        };

        // If animation with modifier does not exist, take base animation
        if (CALL_RetValAsInt() < 0) {
            // Remove spell casting modifier, 'MAG' should remain
            modifier = STR_Prefix(modifier, 3);
            lastMod = modifier;
            aniName = ConcatStrings(ConcatStrings(prefix, modifier), postfix);
        };
    };

    // Start animation
    const int call6 = 0;
    if (CALL_Begin(call6)) {
        CALL_IntParam(_@(zero));
        CALL_PtrParam(_@(aniNamePtr));
        CALL__thiscall(_@(model), zCModel__StartAni);
        call6 = CALL_End();
    };

    // Set observe intruder flag (relevant for Gothic 1 only)
    MEM_WriteInt(aniCtrlPtr+oCAIHuman_bitfield_offset, bitfield | oCAIHuman_bitfield_startObserveIntruder);
};


/*
 * Enable movement while aiming. This function checks key presses and passes on a movement ID to GFA_AimMovement(). The
 * function hooks oCAIHuman::BowMode() at an offset, where the player is aiming. Additionally, the function is called
 * from GFA_RangedIdle() to allow movement during shooting and to reset movement when letting go of the aiming key.
 * The function is also called from GFA_SpellAiming() for strafing during spell combat.
 */
func void GFA_Strafe() {
    if (GFA_ACTIVE < FMODE_FAR) || (!GFA_STRAFING) {
        GFA_AimMovement(0, "");
        return;
    };

    var oCNpc her; her = Hlp_GetNpc(hero);

    // Magic mode does not allow sneaking (messes up the perception and would require more animations)
    if (GOTHIC_CONTROL_SCHEME == 1)
    && (her.fmode == FMODE_MAGIC) {
        var int aniCtrlPtr; aniCtrlPtr = her.anictrl;

        // Sneaking not allowed
        if (MEM_ReadInt(aniCtrlPtr+oCAniCtrl_Human_walkmode_offset) & NPC_SNEAK) {
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

    // Allow forward movement only when using Gothic 2 controls while investing or casting a spell (or ranged combat)
    if (GOTHIC_CONTROL_SCHEME == 2) && ((GFA_InvestingOrCasting(hero)) || (her.fmode != FMODE_MAGIC)) {
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

    // Add animation modifier based on fight mode
    var string modifier;
    if (movement) {
        if (her.fmode == FMODE_MAGIC) {
            modifier = "MAG";
            // Also treat variations of casting animations
            if (GFA_InvestingOrCasting(hero)) {
                modifier = ConcatStrings(modifier, MEM_ReadStatStringArr(spellFxAniLetters, Npc_GetActiveSpell(hero)));
            };
        } else if (her.fmode == FMODE_FAR) {
            modifier = "BOW";
        } else if (her.fmode == FMODE_FAR+1) {
            modifier = "CBOW";
        } else {
            MEM_Warn("GFA_AimMovement: Player not in valid aiming fight mode.");
            movement = 0;
            modifier = "";
        };
    } else {
        modifier = "";
    };

    GFA_AimMovement(movement, modifier);
};
