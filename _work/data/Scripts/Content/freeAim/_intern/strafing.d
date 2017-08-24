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
    // Increase performance: Only update if movement changed
    if (GFA_IsStrafing == movement) {
        return;
    };
    GFA_IsStrafing = movement;

    // Find animation name prefix by fight mode
    var oCNpc her; her = Hlp_GetNpc(hero);
    var string prefix;
    if (her.fmode == FMODE_MAGIC) {
        prefix = "S_MAG";
        // MEM_Warn("GFA_AimMovement: Spell combat movement not supported yet.");
    } else if (her.fmode == FMODE_FAR) {
        prefix = "S_BOW";
    } else if (her.fmode == FMODE_FAR+1) {
        prefix = "S_CBOW";
        MEM_Warn("GFA_AimMovement: Crossbow movement not supported yet.");
        return;
    } else {
        MEM_Warn("GFA_AimMovement: Player not in valid aiming fight mode.");
        return;
    };

    // Get player model
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

    // Iterate over all aim movement animations and stop or play them
    repeat(aniID, GFA_MAX_AIM_ANIS); var int aniID;
        // Skip empty IDs
        if (aniID == 0) || (aniID == 3) || (aniID == 7) {
            continue;
        };

        // Get full name of animation
        var string aniName; aniName = ConcatStrings(prefix, MEM_ReadStatStringArr(GFA_AIM_ANIS, aniID));
        var int aniNamePtr; aniNamePtr = _@s(aniName);

        // Check whether animation is active
        var int aniActive;
        const int call3 = 0;
        if (CALL_Begin(call3)) {
            CALL_PtrParam(_@(aniNamePtr));
            CALL_PutRetValTo(_@(aniActive));
            CALL__thiscall(_@(model), zCModel__IsAnimationActive);
            call3 = CALL_End();
        };

        // Update animations
        if (movement == aniID) && (!aniActive) {
            // Start animation
            var int zero;
            const int call4 = 0;
            if (CALL_Begin(call4)) {
                CALL_IntParam(_@(zero));
                CALL_PtrParam(_@(aniNamePtr));
                CALL__thiscall(_@(model), zCModel__StartAni);
                call4 = CALL_End();
            };
        } else if (aniActive) {
            // Stop all other animations
            const int call5 = 0;
            if (CALL_Begin(call5)) {
                CALL_PtrParam(_@(aniNamePtr));
                CALL__thiscall(_@(model), zCModel__StopAnimation);
                call5 = CALL_End();
            };
        };
    end;
};


/*
 * Enable movement while aiming. This function checks key presses and passes on a movement ID to GFA_AimMovement(). The
 * function hooks oCAIHuman::BowMode() at an offset, where the player is aiming. Additionally, the function is called
 * from GFA_RangedIdle() to allow movement during shooting and to reset movement when letting go of the aiming key.
 */
func void GFA_Strafe() {
    if (!GFA_ACTIVE) {
        return;
    };

    // Check whether keys are pressed down (held)
    var int mFront;
    var int mBack;
    var int mLeft;
    var int mRight;

    mFront = FALSE; // False by default, for Gothic 1 controls
    mBack  = (MEM_KeyPressed(MEM_GetKey("keyDown")))        || (MEM_KeyPressed(MEM_GetSecondaryKey("keyDown")));
    mLeft  = (MEM_KeyPressed(MEM_GetKey("keyStrafeLeft")))  || (MEM_KeyPressed(MEM_GetSecondaryKey("keyStrafeLeft")));
    mRight = (MEM_KeyPressed(MEM_GetKey("keyStrafeRight"))) || (MEM_KeyPressed(MEM_GetSecondaryKey("keyStrafeRight")));

    // Allow forward movement for Gothic 2 controls only
    if (GOTHIC_BASE_VERSION == 2) {
        if (!MEM_ReadInt(oCGame__s_bUseOldControls)) {
            mFront = (MEM_KeyPressed(MEM_GetKey("keyUp")))  || (MEM_KeyPressed(MEM_GetSecondaryKey("keyUp")));
        };
    };

    // Evaluate movement from key presses (because there are also diagonal movements)
    var int movement; movement = (GFA_MOVE_FORWARD  * mFront)
                               | (GFA_MOVE_BACKWARD * mBack)
                               | (GFA_MOVE_LEFT     * mLeft)
                               | (GFA_MOVE_RIGHT    * mRight);
    GFA_AimMovement(movement);
};
