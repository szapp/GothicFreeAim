/*
 * Ranged combat mechanics
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
 * Collect focus for aiming in ranged mode. This function is called from two different functions: While aiming, and
 * while shooting, to prevent the focus from changing while shooting. Additionally, this function checks the distance
 * to the nearest intersection (or to the focus) from the camera (not the player model!).
 */
func void freeAimRangedFocus(var int targetPtr, var int distancePtr) {
    if (!FREEAIM_ACTIVE) {
        return;
    };

    // Retrieve target NPC and the distance to it from the camera(!)
    var int distance; var int target;

    if (FREEAIM_FOCUS_COLLECTION) {
        // Shoot aim trace ray, to retrieve the distance to an intersection and a possible target
        freeAimRay(FREEAIM_MAX_DIST, TARGET_TYPE_NPCS, _@(target), 0, _@(distance), 0);
        distance = roundf(divf(mulf(distance, FLOAT1C), mkf(FREEAIM_MAX_DIST))); // Distance scaled between [0, 100]

    } else {
        // FREEAIM_FOCUS_COLLECTION can be set to false (see INI-file) for weaker computers. However, it is not
        // recommended, as there will be NO focus at all (otherwise it would get stuck on NPCs)

        var oCNpc her; her = Hlp_GetNpc(hero);
        var int herPtr; herPtr = _@(her);

        // Remove focus completely
        const int call = 0; var int zero; // Set the focus vob properly: reference counter
        if (CALL_Begin(call)) {
            CALL_PtrParam(_@(zero)); // This will remove the focus
            CALL__thiscall(_@(herPtr), oCNpc__SetFocusVob);
            call = CALL_End();
        };

        // Always remove oCNpc.enemy. With no focus, there is also no target NPC. Caution: This invalidates the use of
        // Npc_GetTarget()
        if (her.enemy) {
            const int call2 = 0; // Remove the enemy properly: reference counter
            if (CALL_Begin(call2)) {
                CALL_PtrParam(_@(zero));
                CALL__thiscall(_@(herPtr), oCNpc__SetEnemy);
                call2 = CALL_End();
            };
        };
        distance = 25; // No distance check ever. Set it to medium distance
        target = 0; // No focus target ever
    };

    if (distancePtr) {
        MEM_WriteInt(distancePtr, distance);
    };
    if (targetPtr) {
        MEM_WriteInt(targetPtr, target);
    };
};


/*
 * Collect focus during shooting. Otherwise the focus collection changes during the shooting animation. This function
 * hooks oCAIHuman::BowMode at a position where the player model is carrying out the animation of shooting.
 */
func void freeAimRangedShooting() {
    if (FREEAIM_ACTIVE) {
        freeAimRangedFocus(0, 0);
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

    // Retrieve target NPC and the distance to it from the camera(!)
    var int distance; var int target;
    freeAimRangedFocus(_@(target), _@(distance));

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

    // Get camera vob (not camera itself, because it does not offer a reliable position)
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


/*
 * Internal helper function to retrieve the readied weapon and the respective talent value. This function is called by
 * several wrapper/helper functions.
 * Returns 1 on success, 0 otherwise.
 */
func int freeAimGetWeaponTalent(var int weaponPtr, var int talentPtr) {
    var C_Npc slf; slf = Hlp_GetNpc(hero);
    var int error; error = 0;

    // Get readied/equipped ranged weapon
    var C_Item weapon;
    if (Npc_IsInFightMode(slf, FMODE_FAR)) {
        weapon = Npc_GetReadiedWeapon(slf);
    } else if (Npc_HasEquippedRangedWeapon(slf)) {
        weapon = Npc_GetEquippedRangedWeapon(slf);
    } else {
        MEM_Warn("freeAimGetWeaponTalent: No valid weapon equipped/readied!");
        weapon = MEM_NullToInst();
        error = 1;
    };
    if (weaponPtr) {
        MEM_WriteInt(weaponPtr, _@(weapon));
    };

    // Distinguish between (cross-)bow talent
    if (talentPtr) {
        var int talent; talent = 0;
        if (!error) {
            if (weapon.flags & ITEM_BOW) {
                talent = slf.HitChance[NPC_TALENT_BOW];
            } else if (weapon.flags & ITEM_CROSSBOW) {
                talent = slf.HitChance[NPC_TALENT_CROSSBOW];
            } else {
                MEM_Warn("freeAimGetWeaponTalent: No valid weapon equipped/readied!");
                error = 1;
            };
        };
        MEM_WriteInt(talentPtr, talent);
    };

    return !error;
};


/*
 * Internal helper function for freeAimGetDrawForce(). It is called from freeAimSetupProjectile().
 * This function is necessary for error handling and to supply the readied weapon and respective talent value.
 */
func int freeAimGetDrawForce_() {
    // Get readied/equipped ranged weapon
    var int talent; var int weaponPtr;
    if (!freeAimGetWeaponTalent(_@(weaponPtr), _@(talent))) {
        // On error return 50% draw force
        return 50;
    };
    var C_Item weapon; weapon = _^(weaponPtr);

    // Call customized function to retrieve draw force value
    MEM_PushInstParam(weapon);
    MEM_PushIntParam(talent);
    MEM_Call(freeAimGetDrawForce); // freeAimGetDrawForce(weapon, talent);
    var int drawForce; drawForce = MEM_PopIntResult();

    // Must be a percentage in range of [0, 100]
    if (drawForce > 100) {
        drawForce = 100;
    } else if (drawForce < 0) {
        drawForce = 0;
    };
    return drawForce;
};


/*
 * Internal helper function for freeAimGetAccuracy(). It is called from freeAimSetupProjectile().
 * This function is necessary for error handling and to supply the readied weapon and respective talent value.
 */
func int freeAimGetAccuracy_() {
    // Get readied/equipped ranged weapon
    var int talent; var int weaponPtr;
    if (!freeAimGetWeaponTalent(_@(weaponPtr), _@(talent))) {
        // On error return 50% accuracy
        return 50;
    };
    var C_Item weapon; weapon = _^(weaponPtr);

    // Call customized function to retrieve accuracy value
    MEM_PushInstParam(weapon);
    MEM_PushIntParam(talent);
    MEM_Call(freeAimGetAccuracy); // freeAimGetAccuracy(weapon, talent);
    var int accuracy; accuracy = MEM_PopIntResult();

    // Must be a percentage in range of [1, 100], division by 0!
    if (accuracy > 100) {
        accuracy = 100;
    } else if (accuracy < 1) {
        // Prevent devision by zero later
        accuracy = 1;
    };
    return accuracy;
};


/*
 * Internal helper function for freeAimScaleInitialDamage(). It is called from freeAimSetupProjectile().
 * This function is necessary for error handling and to supply the readied weapon and respective talent value.
 */
func int freeAimScaleInitialDamage_(var int basePointDamage) {
    // Get readied/equipped ranged weapon
    var int talent; var int weaponPtr;
    if (!freeAimGetWeaponTalent(_@(weaponPtr), _@(talent))) {
        // On error return the base damage unaltered
        return basePointDamage;
    };
    var C_Item weapon; weapon = _^(weaponPtr);

    // Call customized function to retrieve adjusted damage value
    MEM_PushIntParam(basePointDamage);
    MEM_PushInstParam(weapon);
    MEM_PushIntParam(talent);
    MEM_Call(freeAimScaleInitialDamage); // freeAimScaleInitialDamage(basePointDamage, weapon, talent);
    basePointDamage = MEM_PopIntResult();

    // No negative damage
    if (basePointDamage < 0) {
        basePointDamage = 0;
    };
    return basePointDamage;
};


/*
 * Set the projectile direction. This function hooks oCAIArrow::SetupAIVob to overwrite the target vob with the aim vob
 * that is placed in front of the camera at the nearest intersection with the world or an object.
 * Setting up the projectile involves five parts:
 *  1st: Set base damage of projectile:            freeAimScaleInitialDamage()
 *  2nd: Manipulate aiming accuracy (scatter):     freeAimGetAccuracy()
 *  3rd: Set projectile drop-off (by draw force):  freeAimGetDrawForce()
 *  4th: Add trial strip FX for better visibility
 *  5th: Setup the aim vob and overwrite the target
 */
func void freeAimSetupProjectile() {
    // Only if shooter is the player and if FA is enabled
    var C_Npc shooter; shooter = _^(MEM_ReadInt(ESP+8)); // Second function argument is the shooter
    if (!FREEAIM_ACTIVE) || (!Npc_IsPlayer(shooter)) {
        return;
    };

    var int projectilePtr; projectilePtr = MEM_ReadInt(ESP+4); // First function argument is the projectile
    if (!Hlp_Is_oCItem(projectilePtr)) {
        return;
    };
    var oCItem projectile; projectile = _^(projectilePtr);


    // 1st: Modify the base damage of the projectile
    // This allows for dynamical adjustment of damage (e.g. based on draw force).
    var int baseDamage; baseDamage = projectile.damage[DAM_INDEX_POINT]; // Only point damage is considered
    var int newBaseDamage; newBaseDamage = freeAimScaleInitialDamage_(baseDamage);
    projectile.damage[DAM_INDEX_POINT] = newBaseDamage;


    // 2nd: Manipulate aiming accuracy (scatter)
    // The scattering is optional: If disabled, the default hit chance from Gothic is used, where shots are always
    // accurate, but only register damage in a fraction of shots depending on the skill

    // Retrieve accuracy percentage
    var int accuracy; accuracy = freeAimGetAccuracy_(); // Change the accuracy in that function, not here!
    var int pos[3]; // Position of the target shot
    var int angleX; var int angleY; // Scattering angles

    if (FREEAIM_TRUE_HITCHANCE) {
        // The accuracy is first used as a probability to decide whether a projectile should hit or not. Depending on
        // this, the minimum (rmin) and maximum (rmax) scattering angles are designed by which the shot is deviated.
        // Not-a-hit results in rmin=FREEAIM_SCATTER_HIT and rmax=FREEAIM_SCATTER_MAX.
        // A positive hit results in rmin=0 and rmax=FREEAIM_SCATTER_HIT*(-accuracy+100).
        var int rmin;
        var int rmax;

        // Determine whether it is considered accurate enough for a positive hit
        if (r_MinMax(0, 99) < accuracy) {

            // The projectile will land inside the hit radius scaled by the accuracy
            rmin = FLOATNULL;

            // The circle area from the radius scales better with accuracy
            var int hitRadius; hitRadius = castToIntf(FREEAIM_SCATTER_HIT);
            var int hitArea; hitArea = mulf(PI, sqrf(hitRadius)); // Area of circle from radius

            // Scale the maximum area with minimum acurracy
            // (hitArea - 1) * (accuracy - 100)
            // --------------------------------  + 1
            //               -100
            var int maxArea;
            areaMax = addf(divf(mulf(subf(hitArea, FLOATONE), mkf(accuracy-100)), negf(FLAOT1C)), FLOATONE);

            // Convert back to a radius
            rmax = sqrtf(divf(maxArea, PI));

            if (rmax > hitRadius) {
                rmax = hitRadius;
            };

        } else {
            // The projectile will land outside of the hit radius
            rmin = castToIntf(FREEAIM_SCATTER_HIT);
            rmax = castToIntf(FREEAIM_SCATTER_MAX);
        };

        // r_MinMax works with integers: scale up
        var int rmaxI; rmaxI = roundf(mulf(rmax, FLOAT1K));

        // Azimiuth scatter (horizontal deviation from a perfect shot in degrees)
        angleX = fracf(r_MinMax(FLOATNULL, rmaxI), 1000); // Here the 1000 are scaled down again

        // For a circular scattering pattern the range of possible values (rmin and rmax) for angleY is decreased:
        // r^2 - x^2 = y^2  =>  y = sqrt(r^2 - x^2), where r is the radius to stay within the maximum radius

        // Adjust rmin
        if (lf(angleX, rmin)) {
            rmin = sqrtf(subf(sqrf(rmin), sqrf(angleX)));
        } else {
            rmin = FLOATNULL;
        };

        // r_MinMax works with integers: scale up
        var int rminI; rminI = roundf(mulf(rmin, FLOAT1K));

        // Adjust rmax
        if (lf(angleX, rmax)) {
            rmax = sqrtf(subf(sqrf(rmax), sqrf(angleX)));
        } else {
            rmax = FLOATNULL;
        };
        // r_MinMax works with integers: scale up
        rmaxI = roundf(mulf(rmax, FLOAT1K));

        // Elevation scatter (vertical deviation from a perfect shot in degrees)
        angleY = fracf(r_MinMax(rminI, rmaxI), 1000); // Here the 1000 are scaled down again

        // Randomize the sign of scatter
        if (r_Max(1)) { // 0 or 1, approx. 50-50 chance
            angleX = negf(angleX);
        };
        if (r_Max(1)) {
            angleY = negf(angleY);
        };

        // Create the target position vector by taking the nearest ray intersection with world/objects
        var int distance; // Distance to camera (used for calculating target position)
        var int distPlayer; // Distance to player (used for debugging output to zSpy)
        freeAimRay(FREEAIM_MAX_DIST, TARGET_TYPE_NPCS, 0, 0, _@(distPlayer), _@(distance));
        var int localPos[3]; // Vector in local space. The angles calculated above will be applied to this vector
        localPos[0] = FLOATNULL;
        localPos[1] = FLOATNULL;
        localPos[2] = distance; // Distance into outVec (facing direction)

        // Rotate around x-axis by angleX (elevation scatter). Rotation equations are simplified, because x and y are 0
        SinCosApprox(Print_ToRadian(angleX));
        localPos[1] = mulf(negf(localPos[2]), sinApprox); //  y*cos - z*sin = y'
        localPos[2] = mulf(localPos[2], cosApprox);       //  y*sin + z*cos = z'

        // Rotate around y-axis by angleY (azimuth scatter)
        SinCosApprox(Print_ToRadian(angleY));
        localPos[0] = mulf(localPos[2], sinApprox);       //  x*cos + z*sin = x'
        localPos[2] = mulf(localPos[2], cosApprox);       // -x*sin + z*cos = z'

        // Get camera vob (not camera itself, because it does not offer a reliable position)
        var zCVob camVob; camVob = _^(MEM_Game._zCSession_camVob);
        var zMAT4 camPos; camPos = _^(_@(camVob.trafoObjToWorld[0]));

        // Translation into local coordinate system of camera (rotation): rightVec*x + upVec*y + outVec*z
        // rightVec*x
        pos[0] = mulf(camPos.v0[zMAT4_rightVec], localPos[0]);
        pos[1] = mulf(camPos.v1[zMAT4_rightVec], localPos[0]);
        pos[2] = mulf(camPos.v2[zMAT4_rightVec], localPos[0]);
        // rightVec*x + upVec*y
        pos[0] = addf(pos[0], mulf(camPos.v0[zMAT4_upVec], localPos[1]));
        pos[1] = addf(pos[1], mulf(camPos.v1[zMAT4_upVec], localPos[1]));
        pos[2] = addf(pos[2], mulf(camPos.v2[zMAT4_upVec], localPos[1]));
        // rightVec*x + upVec*y + outVec*z
        pos[0] = addf(pos[0], mulf(camPos.v0[zMAT4_outVec], localPos[2]));
        pos[1] = addf(pos[1], mulf(camPos.v1[zMAT4_outVec], localPos[2]));
        pos[2] = addf(pos[2], mulf(camPos.v2[zMAT4_outVec], localPos[2]));

        // Add the translated coordinates to the camera position (final target position expressed in world coordinates)
        pos[0] = addf(camPos.v0[zMAT4_position], pos[0]);
        pos[1] = addf(camPos.v1[zMAT4_position], pos[1]);
        pos[2] = addf(camPos.v2[zMAT4_position], pos[2]);

        // Hit chance determined by physical hits. If a hit occurs, the accuracy is 100
        freeAimLastAccuracy = 100;

    } else {
        // Default hit chance: Every shot is very accurate, hit chance calculation is done in freeAimDoNpcHit()
        freeAimRay(FREEAIM_MAX_DIST, TARGET_TYPE_NPCS, 0, _@(pos), _@(distPlayer), 0);
        angleX = FLOATNULL; // No scattering (only set for zSpy output at the end of this function)
        angleY = FLOATNULL;

        // Hit chance determined by accuracy in freeAimDoNpcHit() instead
        freeAimLastAccuracy = accuracy;
    };


    // 3rd: Set projectile drop-off (by draw force)
    // The curved trajectory of the projectile is achieved by setting a fixed gravity, but applying it only after a
    // certain air time. This air time is adjustable and depends on draw force: freeAimGetDrawForce().
    // First get rigidBody of the projectile which is responsible for gravity. The rigidBody object does not exist yet
    // at this point, so have it retrieved/created by calling this function:
    const int call = 0;
    if (CALL_Begin(call)) {
        CALL__thiscall(_@(projectilePtr), zCVob__GetRigidBody);
        call = CALL_End();
    };
    var int rBody; rBody = CALL_RetValAsInt(); // zCRigidBody*

    // Retrieve draw force percentage from which to calculate the drop time (time at which the gravity is applied)
    var int drawForce; drawForce = freeAimGetDrawForce_(); // Modify the draw force in that function, not here!

    // The gravity is a fixed value. An exception are very short draw times. There, the gravity is higher
    var int gravityMod; gravityMod = FLOATONE;
    if (drawForce < 25) {
        // Draw force below 25% (very short draw time) increases gravity
        gravityMod = castToIntf(3.0);
    };

    // Calculate the air time at which to apply the gravity, by the maximum air time FREEAIM_TRAJECTORY_ARC_MAX. Because
    // drawForce is a percentage, FREEAIM_TRAJECTORY_ARC_MAX is first multiplied by 100 and later divided by 10000
    var int dropTime; dropTime = (drawForce*(FREEAIM_TRAJECTORY_ARC_MAX*100))/10000;
    // Create a timed frame function to apply the gravity to the projectile after the calculated air time
    FF_ApplyOnceExtData(freeAimDropProjectile, dropTime, 1, rBody);
    // Set the gravity to the projectile. Again: The gravity does not take effect until it is activated
    MEM_WriteInt(rBody+zCRigidBody_gravity_offset, mulf(castToIntf(FREEAIM_PROJECTILE_GRAVITY), gravityMod));

    // Reset draw timer
    freeAimBowDrawOnset = MEM_Timer.totalTime + FREEAIM_DRAWTIME_RELOAD;


    // 4th: Add trail strip FX for better visibility
    // The horizontal position of the camera is aligned with the arrow trajectory, to counter the parallax effect and to
    // allow reasonable aiming. Unfortunately, when the projectile flies along the out vector of the camera (exactly
    // away from the camera), it is barely to not at all visible. To aid visibility, an additional trail strip FX is
    // applied. This is only necessary when the projectile does not have an FX anyway (e.g. magic arrows). The trail
    // strip FX will be removed later once the projectile stops moving.
    if (Hlp_StrCmp(projectile.effect, "")) { // Projectile has no FX
        projectile.effect = FREEAIM_TRAIL_FX;
        const int call2 = 0;
        if (CALL_Begin(call2)) {
            CALL__thiscall(_@(projectilePtr), oCItem__InsertEffect);
            call2 = CALL_End();
        };
    };


    // 5th: Reposition the aim vob and overwrite the target vob
    var int vobPtr; vobPtr = freeAimSetupAimVob(_@(pos));
    MEM_WriteInt(ESP+12, vobPtr); // Overwrite the third argument (target vob) passed to oCAIArrow::SetupAIVob

    // Print info to zSpy
    var int s; s = SB_New();
    SB("freeAimSetupProjectile: ");
    SB("distance="); SB(STR_Prefix(toStringf(divf(distPlayer, FLOAT1C)), 4)); SB("m ");
    SB("drawforce="); SBi(drawForce); SB("% ");
    SB("accuracy="); SBi(accuracy); SB("% ");
    if (FREEAIM_TRUE_HITCHANCE) {
        SB("scatter="); SB(STR_Prefix(toStringf(angleX), 5)); SBc(176 /* deg */);
        SB("/"); SB(STR_Prefix(toStringf(angleY), 5)); SBc(176 /* deg */); SB(" ");
    } else {
        SB("scatter disabled (standard hit chance) ");
    };
    SB("init-basedamage="); SBi(newBaseDamage); SB("/"); SBi(baseDamage);
    MEM_Info(SB_ToString());
    SB_Destroy();
};


/*
 * This is a frame function timed by draw force and is responsible for applying gravity to a projectile after a certain
 * air time as determined in freeAimSetupProjectile(). The gravity is merely turned on, the gravity value itself is set
 * in freeAimSetupProjectile().
 */
func void freeAimDropProjectile(var int rigidBody) {
    if (!rigidBody) {
        return;
    };

    // Check validity of the zCRigidBody pointer by its first class variable (value is always 10.0). This is necessary
    // for loading a saved game, as the pointer will not point to a zCRigidBody address anymore.
    if (roundf(MEM_ReadInt(rigidBody+zCRigidBody_mass_offset)) != 10) {
        return;
    };

    // Do not add gravity if projectile already stopped moving
    if (MEM_ReadInt(rigidBody+zCRigidBody_velocity_offset) == FLOATNULL) // zCRigidBody.velocity[3]
    && (MEM_ReadInt(rigidBody+zCRigidBody_velocity_offset+4) == FLOATNULL)
    && (MEM_ReadInt(rigidBody+zCRigidBody_velocity_offset+8) == FLOATNULL) {
        return;
    };

    // Turn on gravity
    var int bitfield; bitfield = MEM_ReadByte(rigidBody+zCRigidBody_bitfield_offset);
    MEM_WriteByte(rigidBody+zCRigidBody_bitfield_offset, bitfield | zCRigidBody_bitfield_gravityActive);
};


/*
 * This function resets the gravity back to its default value, after any collision occured. The function hooks
 * oCAIArrowBase::DoAI at an offset where a collision is detected (so its not called too often).
 * It is important to reset the gravity, because the projectile may bounce of walls (etc.), after which it would float
 * around with the previously set drop-off gravity (FREEAIM_PROJECTILE_GRAVITY).
 */
func void freeAimResetGravity() {
    var oCItem projectile; projectile = _^(EBP);
    if (!projectile._zCVob_rigidBody) {
        return;
    };
    var int rigidBody; rigidBody = projectile._zCVob_rigidBody;

    // Better safe than writing to an invalid address
    if (FF_ActiveData(freeAimDropProjectile, rigidBody)) {
        FF_RemoveData(freeAimDropProjectile, rigidBody);
    };

    // Reset projectile gravity (zCRigidBody.gravity) after collision (oCAIArrow.collision) to default
    MEM_WriteInt(rigidBody+zCRigidBody_gravity_offset, FLOATONE);
};
