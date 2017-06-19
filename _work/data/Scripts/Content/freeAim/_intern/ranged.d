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

    MEM_WriteInt(distancePtr, distance);
    MEM_WriteInt(targetPtr, target);
};


/*
 * Collect focus during shooting. Otherwise the focus collection changes during the shooting animation. This function
 * hooks oCAIHuman::BowMode at a position where the player model is carrying out the animation of shooting.
 */
func void freeAimRangedShooting() {
    var int target; var int distance; // Not necessary here
    freeAimRangedFocus(_@(target), _@(distance));
};


/*
 * Interpolate the ranged aiming animation. This function hooks oCAIHuman::BowMode just before
 * oCAniCtrl_Human::InterpolateCombineAni to adjust the direction the ranged weapon is pointed in. Also the focus
 * collection is overwritten.
 */
func void freeAimAnimation() {
    // Only free aiming is active
    if (FREEAIM_ACTIVE != FMODE_FAR) {
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
    // Get readied/equipped ranged weapon
    var C_Item weapon;
    if (Npc_IsInFightMode(hero, FMODE_FAR)) {
        weapon = Npc_GetReadiedWeapon(hero);
    } else if (Npc_HasEquippedRangedWeapon(hero)) {
        weapon = Npc_GetEquippedRangedWeapon(hero);
    } else {
        MEM_Error("freeAimGetWeaponTalent: No valid weapon equipped/readied!");
        return 0;
    };

    // Distinguish between (cross-)bow talent
    var int talent;
    if (weapon.flags & ITEM_BOW) {
        talent = hero.HitChance[NPC_TALENT_BOW];
    } else if (weapon.flags & ITEM_CROSSBOW) {
        talent = hero.HitChance[NPC_TALENT_CROSSBOW];
    } else {
        MEM_Error("freeAimGetWeaponTalent: No valid weapon equipped/readied!");
        return 0;
    };

    MEM_WriteInt(weaponPtr, _@(weapon));
    MEM_WriteInt(talentPtr, talent);
    return 1;
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
    var C_Npc shooter; shooter = _^(MEM_ReadInt(ESP+8)); // Second argument is the shooter
    if (!FREEAIM_ACTIVE) || (!Npc_IsPlayer(shooter)) {
        return;
    };

    var int projectilePtr; projectilePtr = MEM_ReadInt(ESP+4); // First argument is the projectile
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
    // The accuracy is supplied as a percentage. This percentage corresponds to the shots hitting within an area with
    // the radius FREEAIM_SCATTER_DEG, which is expressed as half the visual angle of the bounding box width (1.8m) from
    // a distance of 15m (RANGED_CHANCE_MINDIST): tan^-1(90/1500) in degrees = 3.434.
    // The size of the angles (azimuth and elevation) of deviation of the shot is thus scaled with the accuracy to
    // result in x% of the shots hitting within the mentioned hi area on average.

    // Retrieve accuracy percentage
    var int accuracy; accuracy = freeAimGetAccuracy_(); // Change the accuracy calculation in that function, not here!

    var int hitRadius; hitRadius = castToIntf(FREEAIM_SCATTER_DEG);
    var int hitArea; hitArea = mulf(PI, sqrf(hitRadius)); // Area of circle from radius
    // The hitArea corresponds to the percentage of shots hitting the bounding box of NPCs from the default distance of
    // 15 meters (RANGED_CHANCE_MINDIST).

    var int maxArea; maxArea = divf(hitArea, divf(mkf(accuracy), FLOAT1C));
    var int maxRadius; maxRadius = sqrtf(divf(maxArea, PI)); // Radius from area
    var int maxRadiusI; maxRadiusI = roundf(mulf(maxRadius, FLOAT1K)); // r_MinMax works with integers: scale value up

    // The azimuth is here the horizontal deviation from a perfect shot in degrees. It will be a random value between
    // -maxRadius and maxRadius.
    var int angleX; angleX = fracf(r_MinMax(-maxRadiusI, maxRadiusI), 1000); // Here the 1000 are scaled down again

    // The elevation is here the vertical deviation from a perfect shot in degrees. To end up with a circular scattering
    // pattern, the range of possible values for angleY is decreased: r^2 - x^2 = y^2 => y = sqrt(r^2 - y^2)
    maxRadius = subf(sqrf(maxRadius), sqrf(angleX)); // No square root yet, might be negative or 0
    var int angleY;
    if (lef(maxRadius, FLOATNULL)) {
        angleY = FLOATNULL;
    } else {
        maxRadius = sqrtf(maxRadius);
        maxRadiusI = roundf(mulf(maxRadius, FLOAT1K)); // r_MinMax works with integers: scale value up
        angleY = fracf(r_MinMax(-maxRadiusI, maxRadiusI), 1000); // Here the 1000 are scaled down again
    };

    // Create the target position vector by taking the nearest ray intersection with world/objects
    var int distance; // Distance to camera (used for calculating target position)
    var int distPlayer; // Distance to player (used for debugging output to zSpy)
    freeAimRay(FREEAIM_MAX_DIST, TARGET_TYPE_NPCS, 0, 0, _@(distPlayer), _@(distance));
    var int localPos[3]; // Vector in local space. The angles calculated above will be applied to this vector
    localPos[0] = FLOATNULL;
    localPos[1] = FLOATNULL;
    localPos[2] = distance; // Distance into outVec (facing direction)

    // Rotate around x-axis by angleX (elevation scatter). The rotation equations are simplified because x and y are 0
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
    var int pos[3];
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
    SB("scatter="); SB(STR_Prefix(toStringf(angleX), 5)); SBc(176 /* deg */);
    SB("/"); SB(STR_Prefix(toStringf(angleY), 5)); SBc(176 /* deg */); SB(" ");
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
    MEM_WriteByte(rigidBody+zCRigidBody_bitfield_offset, 1);
};
