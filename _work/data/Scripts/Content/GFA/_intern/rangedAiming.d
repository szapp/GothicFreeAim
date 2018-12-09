/*
 * Free aiming mechanics for ranged combat aiming
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
 * Correct focus when not aiming. This includes preventing changes in focus collection during the shooting animation,
 * removing the reticle when not aiming and disabling focus collection all together when not aiming. This function
 * hooks oCAIHuman::BowMode() at an offset where the player model is explicitly not in the aiming animation.
 */
func void GFA_RangedIdle() {
    if (GFA_ACTIVE > 1) {
        // In bow mode during transition between shooting and reloading

        // Shoot trace ray to update focus
        var int distance; var int target;
        GFA_AimRay(GFA_MAX_DIST, TARGET_TYPE_NPCS, _@(target), 0, _@(distance), 0);

        // Additionally, update reticle
        if (GFA_UPDATE_RET_SHOOT) {
            distance = roundf(divf(mulf(distance, FLOAT1C), mkf(GFA_MAX_DIST))); // Distance scaled between [0, 100]

            // Create reticle
            var int reticlePtr; reticlePtr = MEM_Alloc(sizeof_Reticle);
            var Reticle reticle; reticle = _^(reticlePtr);
            reticle.texture = ""; // Do not show reticle by default
            reticle.color = -1; // Do not set color by default
            reticle.size = 75; // Medium size by default

            // Retrieve reticle specs and draw/update it on screen
            GFA_GetRangedReticle_(target, distance, reticlePtr); // Retrieve reticle specs
            GFA_InsertReticle(reticlePtr);
            MEM_Free(reticlePtr);
        };

        // Allow to stop strafing (not to start strafing, that causes weird behavior)
        if (GFA_IsStrafing) {
            GFA_Strafe();
        };

    } else if (GFA_ACTIVE) {
        // In bow mode but not pressing down the aiming key
        GFA_RemoveReticle();

        if (GFA_NO_AIM_NO_FOCUS) {
            GFA_SetFocusAndTarget(0);
        };

        // Remove movement animations when not aiming
        GFA_AimMovement(0, "");
    };
};


/*
 * Interpolate the ranged aiming animation. This function hooks oCAIHuman::BowMode() just before
 * oCAniCtrl_Human::InterpolateCombineAni() to adjust the direction the ranged weapon is pointed in. Also the focus
 * collection is overwritten and the reticle is displayed.
 */
func void GFA_RangedAiming() {
    if (!GFA_ACTIVE) {
        return;
    } else if (GFA_ACTIVE < FMODE_FAR) {
        GFA_RemoveReticle();
        if (GFA_NO_AIM_NO_FOCUS) {
            GFA_SetFocusAndTarget(0);
        };
        return;
    };

    // Shoot aim ray to retrieve the focus NPC and distance to it from the camera(!)
    var int distance; var int target;
    GFA_AimRay(GFA_MAX_DIST, TARGET_TYPE_NPCS, _@(target), 0, _@(distance), 0);
    distance = roundf(divf(mulf(distance, FLOAT1C), mkf(GFA_MAX_DIST))); // Distance scaled between [0, 100]

    // Create reticle
    var int reticlePtr; reticlePtr = MEM_Alloc(sizeof_Reticle);
    var Reticle reticle; reticle = _^(reticlePtr);
    reticle.texture = ""; // Do not show reticle by default
    reticle.color = -1; // Do not set color by default
    reticle.size = 75; // Medium size by default

    // Retrieve reticle specs and draw/update it on screen
    GFA_GetRangedReticle_(target, distance, reticlePtr); // Retrieve reticle specs
    GFA_InsertReticle(reticlePtr);
    MEM_Free(reticlePtr);

    // Pointing distance: Take the max distance, otherwise it looks strange on close range targets
    distance = mkf(GFA_MAX_DIST);

    // Get camera vob
    var zCVob camVob; camVob = _^(MEM_Game._zCSession_camVob);
    var zMAT4 camPos; camPos = _^(_@(camVob.trafoObjToWorld[0]));

    // Calculate position form distance and camera position (not from the player model!)
    var int pos[3];
    // Distance along out vector (facing direction) from camera position
    pos[0] = addf(camPos.v0[zMAT4_position], mulf(camPos.v0[zMAT4_outVec], distance));
    pos[1] = addf(camPos.v1[zMAT4_position], mulf(camPos.v1[zMAT4_outVec], distance));
    pos[2] = addf(camPos.v2[zMAT4_position], mulf(camPos.v2[zMAT4_outVec], distance));

    // Get aiming angles
    var oCNpc her; her = getPlayerInst();
    var int herPtr; herPtr = _@(her);
    var int angleX; var int angXptr; angXptr = _@(angleX);
    var int angleY; var int angYptr; angYptr = _@(angleY);
    var int posPtr; posPtr = _@(pos);
    const int call = 0;
    if (CALL_Begin(call)) {
        CALL_PtrParam(_@(angYptr));
        CALL_PtrParam(_@(angXptr)); // X angle not needed
        CALL_PtrParam(_@(posPtr));
        CALL__thiscall(_@(herPtr), oCNpc__GetAngles);
        call = CALL_End();
    };

    // Prevent multiplication with too small numbers. Would result in twitching while aiming
    if (lf(absf(angleY), 1048576000)) { // 0.25
        if (lf(angleY, FLOATNULL)) {
            angleY =  -1098907648; // -0.25
        } else {
            angleY = 1048576000; // 0.25
        };
    };

    // This following paragraph is inspired by oCAIHuman::BowMode() (0x6961FA in Gothic 2)
    angleY = negf(subf(mulf(angleY, /* 0.0055 */ 1001786197), FLOATHALF)); // Scale and flip Y [-90° +90°] to [+1 0]
    if (lf(angleY, FLOATNULL)) {
        // Maximum aim height (straight up)
        angleY = FLOATNULL;
    } else if (gf(angleY, FLOATONE)) {
        // Minimum aim height (down)
        angleY = FLOATONE;
    };

    // New aiming coordinates. Overwrite the arguments one and two passed to oCAniCtrl_Human::InterpolateCombineAni()
    MEM_WriteInt(ESP+20, FLOATHALF); // First argument: Always aim at center (azimuth). G2: esp+44h-30h, G1: esp+2Ch-18h
    ECX = angleY; // Second argument: New elevation
};


/*
 * Prevent locking the player in place when aiming in ranged combat while falling. This function hooks the end of
 * oCAIHuman::BowMode() to overwrite, whether aiming is active or not, to force reaction to falling in
 * oCAIHuman::_WalkCycle().
 */
func void GFA_RangedLockMovement() {
    if (!GFA_ACTIVE) {
        return;
    };

    if (GFA_ACTIVE < FMODE_FAR) {
        // Overwrite: Not aiming. Necessary for falling while strafing
        GFA_AimMovement(0, "");
        EAX = 0;
    } else {
        // Otherwise allow strafing and lock movement
        GFA_Strafe();
        EAX = 1; // Should not be necessary, just for safety
    };
};


/*
 * This function hooks the condition whether to start aiming or not. Setting EAX to one starts aiming, setting it to
 * zero prevents the initiation of aiming. This function hooks oCAIHuman::BowMode() at the aiming condition and
 * overwrites the outcome of the if-condition. Essentially, this function allows to start aiming while running.
 * Additionally, this function is used to detect the onset of aiming (so it is also used if GFA_STRAFING is disabled).
 */
func void GFA_RangedAimingCondition() {
    var oCNpc her; her = getPlayerInst();
    var int herPtr; herPtr = _@(her);
    var int aniCtrlPtr; aniCtrlPtr = her.anictrl;

    // Set onset for draw force and steady aim
    GFA_BowDrawOnset = MEM_Timer.totalTime;
    GFA_MouseMovedLast = MEM_Timer.totalTime;

    // If free aiming or aim movement are not enabled, revert to default condition (aiming only if standing)
    if (!GFA_ACTIVE) || (!GFA_STRAFING) {
        const int call = 0;
        if (CALL_Begin(call)) {
            CALL_PutRetValTo(_@(EAX));
            CALL__thiscall(_@(aniCtrlPtr), oCAniCtrl_Human__IsStanding);
            call = CALL_End();
        };
        return;
    } else if (GFA_ACTIVE < FMODE_FAR) {
        EAX = 0;
        return;
    };

    // There is no forward aim movement with Gothic 1 controls (do not allow aiming while moving forwards)
    if (GFA_ACTIVE_CTRL_SCHEME == 1) {
        if (MEM_KeyPressed(MEM_GetKey("keyUp"))) || (MEM_KeyPressed(MEM_GetSecondaryKey("keyUp"))) {
            EAX = 0;
            return;
        };
    };

    // Set body state to standing
    var int standing; standing = BS_STAND & ~BS_FLAG_INTERRUPTABLE & ~BS_FLAG_FREEHANDS;
    const int call2 = 0;
    if (CALL_Begin(call2)) {
        CALL_IntParam(_@(standing));
        CALL__thiscall(_@(herPtr), oCNpc__SetBodyState);
        call2 = CALL_End();
    };

    // Remove turning animations (player model sometimes gets stuck in turning animation)
    var int model; model = her._zCVob_visual;
    if (objCheckInheritance(model, zCModel__classDef)) {
        const int twenty = 20;
        const int call3 = 0;
        if (CALL_Begin(call3)) {
            CALL_IntParam(_@(twenty));
            CALL_IntParam(_@(twenty));
            CALL__thiscall(_@(model), zCModel__FadeOutAnisLayerRange);
            call3 = CALL_End();
        };
    };

    // Start aiming animation
    EAX = 1;
};
