/*
 * Ranged combat shooting mechanics
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
 * Wrapper function for the config function GFA_GetDrawForce(). It is called from GFA_SetupProjectile().
 * This function is necessary for error handling and to supply the readied weapon and respective talent value.
 */
func int GFA_GetDrawForce_() {
    // Get readied/equipped ranged weapon
    var int talent; var int weaponPtr;
    if (!GFA_GetWeaponAndTalent(_@(weaponPtr), _@(talent))) {
        // On error return 50% draw force
        return 50;
    };
    var C_Item weapon; weapon = _^(weaponPtr);

    // Retrieve draw force value from config
    var int drawForce; drawForce = GFA_GetDrawForce(weapon, talent);

    // Must be a percentage in range of [0, 100]
    if (drawForce > 100) {
        drawForce = 100;
    } else if (drawForce < 0) {
        drawForce = 0;
    };
    return drawForce;
};


/*
 * Wrapper function for the config function GFA_GetAccuracy(). It is called from GFA_SetupProjectile().
 * This function is necessary for error handling and to supply the readied weapon and respective talent value.
 */
func int GFA_GetAccuracy_() {
    // Get readied/equipped ranged weapon
    var int talent; var int weaponPtr;
    if (!GFA_GetWeaponAndTalent(_@(weaponPtr), _@(talent))) {
        // On error return 50% accuracy
        return 50;
    };
    var C_Item weapon; weapon = _^(weaponPtr);

    // Retrieve accuracy value from config
    var int accuracy; accuracy = GFA_GetAccuracy(weapon, talent);

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
 * Wrapper function for the config function GFA_GetInitialBaseDamage(). It is called from GFA_SetupProjectile().
 * This function is necessary for error handling and to supply the readied weapon and respective talent value.
 */
func int GFA_GetInitialBaseDamage_(var int basePointDamage, var int aimingDistance) {
    // Get readied/equipped ranged weapon
    var int talent; var int weaponPtr;
    if (!GFA_GetWeaponAndTalent(_@(weaponPtr), _@(talent))) {
        // On error return the base damage unaltered
        return basePointDamage;
    };
    var C_Item weapon; weapon = _^(weaponPtr);

    // Scale distance between [0, 100] for [RANGED_CHANCE_MINDIST, RANGED_CHANCE_MAXDIST], see AI_Constants.d
    // For readability: 100*(aimingDistance-RANGED_CHANCE_MINDIST)/(RANGED_CHANCE_MAXDIST-RANGED_CHANCE_MINDIST)
    aimingDistance = roundf(divf(mulf(FLOAT1C, subf(aimingDistance, castToIntf(RANGED_CHANCE_MINDIST))),
                                 subf(castToIntf(RANGED_CHANCE_MAXDIST), castToIntf(RANGED_CHANCE_MINDIST))));
    // Clip to range [0, 100]
    if (aimingDistance > 100) {
        aimingDistance = 100;
    } else if (aimingDistance < 0) {
        aimingDistance = 0;
    };

    // Retrieve adjusted damage value from config
    basePointDamage = GFA_GetInitialBaseDamage(basePointDamage, weapon, talent, aimingDistance);

    // No negative damage
    if (basePointDamage < 0) {
        basePointDamage = 0;
    };
    return basePointDamage;
};


/*
 * Wrapper function for the config function GFA_GetRecoil(). It is called from GFA_SetupProjectile().
 * This function is necessary for error handling and to supply the readied weapon and respective talent value.
 */
func int GFA_GetRecoil_() {
    // Get readied/equipped ranged weapon
    var int talent; var int weaponPtr;
    if (!GFA_GetWeaponAndTalent(_@(weaponPtr), _@(talent))) {
        // On error return 0% recoil
        return 0;
    };
    var C_Item weapon; weapon = _^(weaponPtr);

    // Retrieve recoil value from config
    var int recoil; recoil = GFA_GetRecoil(weapon, talent);

    // Must be a percentage in range of [0, 100]
    if (recoil > 100) {
        recoil = 100;
    } else if (recoil < 0) {
        recoil = 0;
    };
    return recoil;
};


/*
 * Set the projectile direction. This function hooks oCAIArrow::SetupAIVob to overwrite the target vob with the aim vob
 * that is placed in front of the camera at the nearest intersection with the world or an object.
 * Setting up the projectile involves several parts:
 *  1st: Set base damage of projectile:             GFA_GetInitialBaseDamage()
 *  2nd: Manipulate aiming accuracy (scatter):      GFA_GetAccuracy()
 *  3rd: Add recoil to mouse movement:              GFA_GetRecoil()
 *  4th: Set projectile drop-off (by draw force):   GFA_GetDrawForce()
 *  5th: Add trial strip FX for better visibility
 *  6th: Setup the aim vob and overwrite the target
 */
func void GFA_SetupProjectile() {
    // Only if shooter is the player and if FA is enabled
    var C_Npc shooter; shooter = _^(MEM_ReadInt(ESP+8)); // Second function argument is the shooter
    if (!GFA_ACTIVE) || (!Npc_IsPlayer(shooter)) {
        return;
    };

    var int projectilePtr; projectilePtr = MEM_ReadInt(ESP+4); // First function argument is the projectile
    if (!Hlp_Is_oCItem(projectilePtr)) {
        return;
    };
    var oCItem projectile; projectile = _^(projectilePtr);

    // Before anything: Create target position vector for shot by taking the nearest ray intersection with world/objects
    var int pos[3]; // Position of the target shot
    var int distance; // Distance to camera (used for calculating position of target shot in local space)
    var int distPlayer; // Distance to player (used for debugging output in zSpy)
    GFA_AimRay(GFA_MAX_DIST, TARGET_TYPE_NPCS, 0, _@(pos), _@(distPlayer), _@(distance));

    // When the target is too close, shots go vertically up, because the reticle is targeted. To solve this problem,
    // restrict the minimum distance
    if (lf(distPlayer, mkf(GFA_MIN_AIM_DIST))) {
        distance = addf(distance, mkf(GFA_MIN_AIM_DIST));
    };

    // 1st: Modify the base damage of the projectile
    // This allows for dynamical adjustment of damage (e.g. based on draw force).
    var int baseDamage; baseDamage = projectile.damage[DAM_INDEX_POINT]; // Only point damage is considered
    var int newBaseDamage; newBaseDamage = GFA_GetInitialBaseDamage_(baseDamage, distPlayer);
    projectile.damage[DAM_INDEX_POINT] = newBaseDamage;


    // 2nd: Manipulate aiming accuracy (scatter)
    // The scattering is optional: If disabled, the default hit chance from Gothic is used, where shots are always
    // accurate, but register damage in a fraction of shots only, depending on skill and distance
    if (GFA_TRUE_HITCHANCE) {
        // The accuracy is first used as a probability to decide whether a projectile should hit or not. Depending on
        // this, the minimum (rmin) and maximum (rmax) scattering angles (half the visual angle) are designed by which
        // the shot is deviated.
        // Not-a-hit results in rmin=GFA_SCATTER_MISS and rmax=GFA_SCATTER_MAX.
        // A positive hit results in rmin=0 and rmax=GFA_SCATTER_HIT*(-accuracy+100).
        var int rmin;
        var int rmax;

        // Retrieve accuracy percentage
        var int accuracy; accuracy = GFA_GetAccuracy_(); // Change the accuracy in that function, not here!

        // Determine whether it is considered accurate enough for a positive hit
        if (r_MinMax(0, 99) < accuracy) {

            // The projectile will land inside the hit radius scaled by the accuracy
            rmin = FLOATNULL;

            // The circle area from the radius scales better with accuracy
            var int hitRadius; hitRadius = castToIntf(GFA_SCATTER_HIT);
            var int hitArea; hitArea = mulf(PI, sqrf(hitRadius)); // Area of circle from radius

            // Scale the maximum area with minimum acurracy
            // (hitArea - 1) * (accuracy - 100)
            // --------------------------------  + 1
            //               -100
            var int maxArea;
            maxArea = addf(divf(mulf(subf(hitArea, FLOATONE), mkf(accuracy-100)), negf(FLOAT1C)), FLOATONE);

            // Convert back to a radius
            rmax = sqrtf(divf(maxArea, PI));

            if (rmax > hitRadius) {
                rmax = hitRadius;
            };

        } else {
            // The projectile will land outside of the hit radius
            rmin = castToIntf(GFA_SCATTER_MISS);
            rmax = castToIntf(GFA_SCATTER_MAX);
        };

        // r_MinMax works with integers: scale up
        var int rmaxI; rmaxI = roundf(mulf(rmax, FLOAT1K));

        // Azimiuth scatter (horizontal deviation from a perfect shot in degrees)
        var int angleX; angleX = fracf(r_MinMax(FLOATNULL, rmaxI), 1000); // Here the 1000 are scaled down again

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
        var int angleY; angleY = fracf(r_MinMax(rminI, rmaxI), 1000); // Here the 1000 are scaled down again

        // Randomize the sign of scatter
        if (r_Max(1)) { // 0 or 1, approx. 50-50 chance
            angleX = negf(angleX);
        };
        if (r_Max(1)) {
            angleY = negf(angleY);
        };

        // Create vector in local space from distance. The angles calculated above will be applied to this vector
        var int localPos[3];
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

        // Get camera vob
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
    };


    // 3rd: Add recoil
    var int recoil; recoil = GFA_GetRecoil_();
    GFA_Recoil = (GFA_MAX_RECOIL*recoil)/100;


    // 4th: Set projectile drop-off (by draw force)
    // The curved trajectory of the projectile is achieved by setting a fixed gravity, but applying it only after a
    // certain air time. This air time is adjustable and depends on draw force: GFA_GetDrawForce().
    // First get rigidBody of the projectile which is responsible for gravity. The rigidBody object does not exist yet
    // at this point, so have it retrieved/created by calling this function:
    const int call = 0;
    if (CALL_Begin(call)) {
        CALL__thiscall(_@(projectilePtr), zCVob__GetRigidBody);
        call = CALL_End();
    };
    var int rBody; rBody = CALL_RetValAsInt(); // zCRigidBody*

    // Retrieve draw force percentage from which to calculate the drop time (time at which the gravity is applied)
    var int drawForce; drawForce = GFA_GetDrawForce_(); // Modify the draw force in that function, not here!

    // The gravity is a fixed value. An exception are very short draw times. There, the gravity is higher
    var int gravityMod; gravityMod = FLOATONE;
    if (drawForce < 25) {
        // Draw force below 25% (very short draw time) increases gravity
        gravityMod = castToIntf(3.0);
    };

    // Calculate the air time at which to apply the gravity, by the maximum air time GFA_TRAJECTORY_ARC_MAX. Because
    // drawForce is a percentage, GFA_TRAJECTORY_ARC_MAX is first multiplied by 100 and later divided by 10000
    var int dropTime; dropTime = (drawForce*(GFA_TRAJECTORY_ARC_MAX*100))/10000;
    // Create a timed frame function to apply the gravity to the projectile after the calculated air time
    FF_ApplyOnceExtData(GFA_EnableProjectileGravity, dropTime, 1, rBody);
    // Set the gravity to the projectile. Again: The gravity does not take effect until it is activated
    MEM_WriteInt(rBody+zCRigidBody_gravity_offset, mulf(castToIntf(GFA_PROJECTILE_GRAVITY), gravityMod));

    // Reset draw timer
    GFA_BowDrawOnset = MEM_Timer.totalTime + GFA_DRAWTIME_RELOAD;


    // 5th: Add trail strip FX for better visibility
    // The horizontal position of the camera is aligned with the arrow trajectory, to counter the parallax effect and to
    // allow reasonable aiming. Unfortunately, when the projectile flies along the out vector of the camera (exactly
    // away from the camera), it is barely to not at all visible. To aid visibility, an additional trail strip FX is
    // applied. This is only necessary when the projectile does not have an FX anyway (e.g. magic arrows). The trail
    // strip FX will be removed later once the projectile stops moving.
    if (GOTHIC_BASE_VERSION == 2) {
        // Gothic 1 does not offer effects on items
        if (Hlp_StrCmp(MEM_ReadString(projectilePtr+oCItem_effect_offset), "")) { // Projectile has no FX
            MEM_WriteString(projectilePtr+oCItem_effect_offset, GFA_TRAIL_FX);
            const int call2 = 0;
            if (CALL_Begin(call2)) {
                CALL__thiscall(_@(projectilePtr), oCItem__InsertEffect);
                call2 = CALL_End();
            };
        };
    } else {
        // Simplified mechanics for Gothic 1
        Wld_PlayEffect(GFA_TRAIL_FX_SIMPLE, projectile, projectile, 0, 0, 0, FALSE);
    };

    // 6th: Reposition the aim vob and overwrite the target vob
    var int vobPtr; vobPtr = GFA_SetupAimVob(_@(pos));
    MEM_WriteInt(ESP+12, vobPtr); // Overwrite the third argument (target vob) passed to oCAIArrow::SetupAIVob

    // Update the shooting statistics
    GFA_StatsShots += 1;


    if (GFA_DEBUG_PRINT) {
        MEM_Info("GFA_SetupProjectile:");
        var int s; s = SB_New();

        SB("   aiming distance:   ");
        SB(STR_Prefix(toStringf(divf(distPlayer, FLOAT1C)), 4));
        SB("m");
        MEM_Info(SB_ToString());
        SB_Clear();

        SB("   draw force:        ");
        SBi(drawForce);
        SB("%");
        MEM_Info(SB_ToString());
        SB_Clear();

        if (GFA_TRUE_HITCHANCE) {
            SB("   accuracy:          ");
            SBi(accuracy);
            SB("%");
            MEM_Info(SB_ToString());
            SB_Clear();

            SB("   scatter:           (");
            SB(STR_Prefix(toStringf(angleX), 5));
            SBc(176 /* deg */);
            SB(", ");
            SB(STR_Prefix(toStringf(angleY), 5));
            SBc(176 /* deg */);
            SB(") visual angles");
            MEM_Info(SB_ToString());
            SB_Clear();
        } else {
            var int hitchance;
            if (GOTHIC_BASE_VERSION == 1) {
                // In Gothic 1, the hit chance is determined by dexterity (for both bows and crossbows)
                hitchance = hero.attribute[ATR_DEXTERITY];
            } else {
                // In Gothic 2, the hit chance is the learned skill value (talent)
                GFA_GetWeaponAndTalent(0, _@(hitchance));
            };
            SB("   hit chance:        ");
            SBi(hitchance);
            SB("% (standard hit chance, scattering disabled)");
            MEM_Info(SB_ToString());
            SB_Clear();
        };

        SB("   recoil:            ");
        SBi(recoil);
        SB("%");
        MEM_Info(SB_ToString());
        SB_Clear();

        SB("   base damage:       ");
        SBi(newBaseDamage);
        SB(" (of ");
        SBi(baseDamage);
        SB(" normal base damage)");
        MEM_Info(SB_ToString());
        SB_Destroy();
    };
};


/*
 * This is a frame function timed by draw force and is responsible for applying gravity to a projectile after a certain
 * air time as determined in GFA_SetupProjectile(). The gravity is merely turned on, the gravity value itself is set in
 * GFA_SetupProjectile().
 */
func void GFA_EnableProjectileGravity(var int rigidBody) {
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
 * oCAIArrow::ReportCollisionToAI at an offset where a valid collision was detected.
 * It is important to reset the gravity, because the projectile may bounce of walls (etc.), after which it would float
 * around with the previously set drop-off gravity (GFA_PROJECTILE_GRAVITY).
 */
func void GFA_ResetProjectileGravity() {
    var int arrowAI; arrowAI = MEMINT_SwitchG1G2(ESI, ECX);
    var oCItem projectile; projectile = _^(MEM_ReadInt(arrowAI+oCAIArrowBase_hostVob_offset));
    if (!projectile._zCVob_rigidBody) {
        return;
    };
    var int rigidBody; rigidBody = projectile._zCVob_rigidBody;

    // Better safe than writing to an invalid address
    if (FF_ActiveData(GFA_EnableProjectileGravity, rigidBody)) {
        FF_RemoveData(GFA_EnableProjectileGravity, rigidBody);
    };

    // Reset projectile gravity (zCRigidBody.gravity) after collision (oCAIArrow.collision) to default
    MEM_WriteInt(rigidBody+zCRigidBody_gravity_offset, FLOATONE);

    // Remove trail strip FX
    if (GOTHIC_BASE_VERSION == 1) {
        Wld_StopEffect_Ext(GFA_TRAIL_FX_SIMPLE, projectile, projectile, 0);
    };
};


/*
 * Manipulate the hit chance when shooting NPCs. This function hooks oCAIArrow::ReportCollisionToAI() at the offset
 * where the hit chance of the NPC is checked.
 * Depending on GFA_TRUE_HITCHANCE, the resulting hit chance is either the Gothic default hit chance or always 100%.
 * For the latter (GFA_TRUE_HITCHANCE == true) the hit chance is instead determined earlier by scattering in
 * GFA_SetupProjectile().
 * Additionally, the trial strip is removed (Gothic 1) and the shooting statistics are updated.
 * This function is only making changes if the shooter is the player.
 */
func void GFA_OverwriteHitChance() {
    var int arrowAI; arrowAI = MEMINT_SwitchG1G2(ESI, EBP);
    var C_Npc shooter; shooter = _^(MEM_ReadInt(arrowAI+oCAIArrow_origin_offset));

    // Only if shooter is the player and if FA is enabled for ranged combat
    if (!GFA_ACTIVE) || (!Npc_IsPlayer(shooter)) {
        return;
    };

    var oCItem projectile; projectile = _^(MEM_ReadInt(arrowAI+oCAIArrowBase_hostVob_offset));

    // Hit chance, calculated from skill (or dexterity in Gothic 1) and distance
    var int hitChancePtr; hitChancePtr = MEMINT_SwitchG1G2(/*esp+3Ch-28h*/ ESP+20, /*esp+1ACh-194h*/ ESP+24);
    var int hit;

    if (!GFA_TRUE_HITCHANCE) {
        // If accuracy/scattering is disabled, stick to the hit chance calculation from Gothic

        // G1: float, G2: integer
        var int hitChance; hitChance = MEMINT_SwitchG1G2(MEM_ReadInt(hitChancePtr), mkf(MEM_ReadInt(hitChancePtr)));

        // The random number by which a hit is determined (integer)
        var int rand; rand = EAX % 100;

        // Determine if positive hit
        hit = lf(mkf(rand), hitChance); // rand < hitChance
    } else {
        // If accuracy/scattering is enabled, all shots that hit the target are a positive hit
        hit = TRUE;
        MEM_WriteInt(hitChancePtr, MEMINT_SwitchG1G2(FLOAT1C, 100)); // Overwrite to hit always
    };

    // Update the shooting statistics
    GFA_StatsHits += hit;
};
