/*
 * Ranged combat aiming mechanics
 *
 * G2 Free Aim v0.1.2 - Free aiming for the video game Gothic 2 by Piranha Bytes
 * Copyright (C) 2016  mud-freak (@szapp)
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
 * Collect focus during shooting. Otherwise the focus collection changes during the shooting animation. This function
 * hooks oCAIHuman::BowMode at a position where the player model is carrying out the animation of shooting.
 */
func void freeAimRangedShooting() {
    if (FREEAIM_ACTIVE) {
        // Shoot aim trace ray to update focus
        freeAimRay(FREEAIM_MAX_DIST, TARGET_TYPE_NPCS, 0, 0, 0, 0);
    };
};


/*
 * Interpolate the ranged aiming animation. This function hooks oCAIHuman::BowMode just before
 * oCAniCtrl_Human::InterpolateCombineAni to adjust the direction the ranged weapon is pointed in. Also the focus
 * collection is overwritten.
 */
func void freeAimAnimation() {
    if (!FREEAIM_ACTIVE) {
        return;
    };

    // Shoot aim trace ray to retrieve the focus NPC and distance to it from the camera(!)
    var int distance; var int target;
    freeAimRay(FREEAIM_MAX_DIST, TARGET_TYPE_NPCS, _@(target), 0, _@(distance), 0);
    distance = roundf(divf(mulf(distance, FLOAT1C), mkf(FREEAIM_MAX_DIST))); // Distance scaled between [0, 100]

    // Create reticle
    var int reticlePtr; reticlePtr = MEM_Alloc(sizeof_Reticle);
    var Reticle reticle; reticle = _^(reticlePtr);
    reticle.texture = ""; // Do not show reticle by default
    reticle.color = -1; // Do not set color by default
    reticle.size = 75; // Medium size by default

    // Retrieve reticle specs and draw/update it on screen
    freeAimGetReticleRanged_(target, distance, reticlePtr); // Retrieve reticle specs
    freeAimInsertReticle(reticlePtr);
    MEM_Free(reticlePtr);

    // Pointing distance: Take the max distance, otherwise it looks strange on close range targets
    distance = mkf(FREEAIM_MAX_DIST);

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
    var int herPtr; herPtr = _@(hero);
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

    // This following paragraph is inspired by oCAIHuman::BowMode (0x695F00 in g2)
    angleY = negf(subf(mulf(angleY, /* 0.0055 */ 1001786197), FLOATHALF)); // Scale and flip Y [-90° +90°] to [+1 0]
    if (lef(angleY, FLOATNULL)) {
        // Maximum aim height (straight up)
        angleY = FLOATNULL;
    } else if (gef(angleY, FLOATONE)) {
        // Minimum aim height (down)
        angleY = FLOATONE;
    };

    // New aiming coordinates. Overwrite the arguments one and two passed to oCAniCtrl_Human::InterpolateCombineAni
    MEM_WriteInt(ESP+20, FLOATHALF); // First argument: Always aim at center (azimuth) (esp+44h-30h)
    ECX = angleY; // Second argument: New elevation
};
