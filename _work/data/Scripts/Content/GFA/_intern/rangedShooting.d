/*
 * Free aiming mechanics for ranged combat shooting
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
 * Wrapper function for the config function GFA_GetDrawForce(). It is called from GFA_SetupProjectile().
 * This function is necessary for error handling and to supply the readied weapon and respective talent value.
 */
func int GFA_GetDrawForce_() {
    // Get readied/equipped ranged weapon
    var int talent; var int weaponPtr;
    if (!GFA_GetWeaponAndTalent(hero, _@(weaponPtr), _@(talent))) {
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
    if (!GFA_GetWeaponAndTalent(hero, _@(weaponPtr), _@(talent))) {
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
func int GFA_GetInitialBaseDamage_(var int baseDamage, var int damageType, var int aimingDistance) {
    // Get readied/equipped ranged weapon
    var int talent; var int weaponPtr;
    if (!GFA_GetWeaponAndTalent(hero, _@(weaponPtr), _@(talent))) {
        // On error return the base damage unaltered
        return baseDamage;
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
    baseDamage = GFA_GetInitialBaseDamage(baseDamage, damageType, weapon, talent, aimingDistance);

    // No negative damage
    if (baseDamage < 0) {
        baseDamage = 0;
    };
    return baseDamage;
};


/*
 * Wrapper function for the config function GFA_GetRecoil(). It is called from GFA_SetupProjectile().
 * This function is necessary for error handling and to supply the readied weapon and respective talent value.
 */
func int GFA_GetRecoil_() {
    // Get readied/equipped ranged weapon
    var int talent; var int weaponPtr;
    if (!GFA_GetWeaponAndTalent(hero, _@(weaponPtr), _@(talent))) {
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
 * Set the projectile direction. This function hooks oCAIArrow::SetupAIVob() to overwrite the target vob with the aim
 * vob that is placed in front of the camera at the nearest intersection with the world or an object.
 * Setting up the projectile involves several parts:
 *  1st: Set base damage of projectile:             GFA_GetInitialBaseDamage()
 *  2nd: Manipulate aiming accuracy (scatter):      GFA_GetAccuracy()
 *  3rd: Add recoil to mouse movement:              GFA_GetRecoil()
 *  4th: Set projectile drop-off (by draw force):   GFA_GetDrawForce()
 *  5th: Add trail strip FX for better visibility
 *  6th: Setup the aim vob and overwrite the target
 */
func void GFA_SetupProjectile() {
    // Only if shooter is the player and if free aiming is enabled
    var C_Npc shooter; shooter = _^(MEM_ReadInt(ESP+8)); // Second function argument is the shooter
    if (!GFA_ACTIVE) || (!Npc_IsPlayer(shooter)) {
        return;
    };

    var int projectilePtr; projectilePtr = MEM_ReadInt(ESP+4); // First function argument is the projectile
    if (!projectilePtr) {
        return;
    };
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
    var int focusDist;
    var oCNpc her; her = getPlayerInst();
    if (Hlp_Is_oCNpc(her.focus_vob)) {
        var C_Npc focusNpc; focusNpc = _^(her.focus_vob);
        focusDist = Npc_GetDistToPlayer(focusNpc);
    } else {
        focusDist = GFA_MAX_DIST;
    };
    if (lf(distPlayer, mkf(GFA_MIN_AIM_DIST))) || (focusDist < GFA_MIN_AIM_DIST) {
        distance = addf(distance, mkf(GFA_MIN_AIM_DIST));
    };

    // Remove projectile from any saves that might be written while the projectile is mid-air
    projectile._zCVob_bitfield[4] = projectile._zCVob_bitfield[4] | zCVob_bitfield4_dontWriteIntoArchive;


    // 1st: Modify the base damage of the projectile
    // This allows for dynamical adjustment of damage (e.g. based on draw force).
    var int baseDamage;
    var int newBaseDamage;
    // Do this for one damage type only. It gets too complicated for multiple damage types
    var int iterator; iterator = projectile.damageType;
    var int damageIndex; damageIndex = 0;
    // Find damage index from bit field
    while((iterator > 0) && ((iterator & 1) != 1)); // Check lower bit
        damageIndex += 1;
        // Cut off lower bit
        iterator = iterator >> 1;
    end;
    if (iterator > 1) || (damageIndex == DAM_INDEX_MAX) {
        if (GFA_DEBUG_PRINT) {
            MEM_Info("GFA_SetupProjectile (initial damage): Ignoring projectile due to multiple/invalid damage types.");
        };

        // Keep damage as is (the class variable damageTotal might be zero)
        baseDamage = projectile.damageTotal;
        newBaseDamage = baseDamage;
    } else {
        // Retrieve and update damage
        baseDamage = MEM_ReadStatArr(_@(projectile.damage), damageIndex);
        newBaseDamage = GFA_GetInitialBaseDamage_(baseDamage, damageIndex, distPlayer);

        // Apply new damage to projectile
        projectile.damageTotal = newBaseDamage;
        MEM_WriteStatArr(_@(projectile.damage), damageIndex, newBaseDamage);
    };


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
        if (r_Max(99) < accuracy) {

            // The projectile will land inside the hit radius scaled by the accuracy
            rmin = FLOATNULL;

            // The circle area from the radius scales better with accuracy
            var int hitRadius; hitRadius = castToIntf(GFA_SCATTER_HIT);
            var int hitArea; hitArea = mulf(PI, sqrf(hitRadius)); // Area of circle from radius

            // Scale the maximum area with minimum accuracy
            // (hitArea - 1) * (accuracy - 100)
            // --------------------------------  + 1
            //               -100
            var int maxArea;
            maxArea = addf(divf(mulf(subf(hitArea, FLOATONE), mkf(100-accuracy)), FLOAT1C), FLOATONE);

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

        // Azimuth scatter (horizontal deviation from a perfect shot in degrees)
        var int angleX; angleX = fracf(r_Max(rmaxI), 1000); // Here the 1000 are scaled down again

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
    // Add recoil to camera angle
    var int recoil; recoil = GFA_GetRecoil_(); // Modify the recoil in that function, not here!
    if (recoil) {
        var int recoilAngle; recoilAngle = fracf(GFA_MAX_RECOIL*recoil, 100);

        // Get game camera
        var int camAI; camAI = MEM_ReadInt(zCAICamera__current);

        // Vertical recoil: Classical upwards movement of the camera scaled by GFA_Recoil
        var int camYAngle; camYAngle = MEM_ReadInt(camAI+zCAICamera_elevation_offset);
        MEM_WriteInt(camAI+zCAICamera_elevation_offset, subf(camYAngle, recoilAngle));
    };


    // 4th: Set projectile drop-off (by draw force)
    // The curved trajectory of the projectile is achieved by setting a fixed gravity, but applying it only after a
    // certain air time. This air time is adjustable and depends on draw force: GFA_GetDrawForce().
    // First get the rigid body of the projectile which is responsible for gravity. The rigid body object does not exist
    // yet at this point, so it has to be retrieved/created by calling this function:
    const int call = 0;
    if (CALL_Begin(call)) {
        CALL__thiscall(_@(projectilePtr), zCVob__GetRigidBody);
        call = CALL_End();
    };
    var int rBody; rBody = CALL_RetValAsInt(); // zCRigidBody*

    // Retrieve draw force percentage from which to calculate the drop time (time at which the gravity is applied)
    var int drawForce; drawForce = GFA_GetDrawForce_(); // Modify the draw force in that function, not here!

    // The gravity is a fixed value. An exception are very short draw times. There, the gravity is higher
    var int gravityMod;
    if (drawForce < 25) {
        // Draw force below 25% (very short draw time) increases gravity
        gravityMod = castToIntf(3.0);
    } else {
        gravityMod = FLOATONE;
    };

    // Calculate the air time at which to apply the gravity, by the maximum air time GFA_TRAJECTORY_ARC_MAX. Because
    // drawForce is a percentage, GFA_TRAJECTORY_ARC_MAX is first multiplied by 100 and later divided by 10000
    var int dropTime; dropTime = (drawForce*(GFA_TRAJECTORY_ARC_MAX*100))/10000;
    if (dropTime < 2) {
        dropTime = 2; // Timer value should not be 1 or 0, otherwise gravity is never applied
    };
    // Use life time to apply gravity after the calculated air time, see GFA_EnableProjectileGravity()
    MEM_WriteInt(ECX+oCAIArrowBase_lifeTime_offset, negf(mkf(dropTime)));
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
    MEM_WriteInt(ESP+12, vobPtr); // Overwrite the third argument (target vob) passed to oCAIArrow::SetupAIVob()


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
                GFA_GetWeaponAndTalent(hero, 0, _@(hitchance));
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
 * This function applies gravity to a projectile after a certain air time as determined in GFA_SetupProjectile(). The
 * gravity is merely turned on, the gravity strength itself is set in GFA_SetupProjectile(). This function hooks
 * oCAIArrowBase::DoAI() at an address where the life time and projectile visibility is decreased. With EAX it is
 * later determined whether to decrease the life timer and visibility.
 */
func void GFA_EnableProjectileGravity() {
    var int projectilePtr; projectilePtr = EBP;
    if (!projectilePtr) {
        EAX = TRUE;
        return;
    };
    var zCVob projectile; projectile = _^(projectilePtr); // oCItem*

    var int arrowAI; arrowAI = ESI; // oCAIArrow*
    var int lifeTime; lifeTime = MEM_ReadInt(arrowAI+oCAIArrowBase_lifeTime_offset);
    // Gravity counter:     lifeTime < -1
    // Mid-flight:          lifeTime = -1
    // Visibility counter:  0 <= lifeTime <= 1

    if (gef(lifeTime, FLOATNULL)) {
        // lifeTime >= 0: Decrease visibility?
        if (MEM_ReadInt(arrowAI+oCAIArrow_destroyProjectile_offset) == 1)
        || (!(GFA_Flags & GFA_REUSE_PROJECTILES)) {
            // Yes (destroy or no collectable feature)
            if (gf(lifeTime, FLOATONE)) {
                // Reset life time to 1
                MEM_WriteInt(arrowAI+oCAIArrowBase_lifeTime_offset, FLOATONE);
            };
            // Decrease life time and visibility (default behavior)
            EAX = TRUE;
        } else {
            // No (collectable feature). Reset life time to -1
            MEM_WriteInt(arrowAI+oCAIArrowBase_lifeTime_offset, FLOATONE_NEG);
            EAX = FALSE;
        };
    } else if (!(projectile.bitfield[0] & zCVob_bitfield0_physicsEnabled)) {
        // Stopped moving: Decrease visibility?
        if (GFA_Flags & GFA_REUSE_PROJECTILES) {
            // No (collectable feature). Reset life time to -1
            MEM_WriteInt(arrowAI+oCAIArrowBase_lifeTime_offset, FLOATONE_NEG);
            EAX = FALSE;
        } else {
            // Yes (no collectable feature). Reset life time to 1
            MEM_WriteInt(arrowAI+oCAIArrowBase_lifeTime_offset, FLOATONE);
            // Decrease life time and visibility (default behavior)
            EAX = TRUE;
        };
    } else if (lf(lifeTime, FLOATONE_NEG)) {
        // lifeTime < -1: Continue counting flight time until gravity drop
        lifeTime = addf(lifeTime, MEM_Timer.frameTimeFloat);
        if (gef(lifeTime, FLOATONE_NEG)) {
            lifeTime = FLOATONE_NEG;
            // Apply gravity. Reset life time to -1
            var int rigidBody; rigidBody = projectile.rigidBody; // zCRigidBody*
            if (rigidBody) {
                var int bitfield; bitfield = MEM_ReadByte(rigidBody+zCRigidBody_bitfield_offset);
                MEM_WriteByte(rigidBody+zCRigidBody_bitfield_offset, bitfield | zCRigidBody_bitfield_gravityActive);
            };
        };
        MEM_WriteInt(arrowAI+oCAIArrowBase_lifeTime_offset, lifeTime);
        // Do not decrease visibility
        EAX = FALSE;
    } else { // Mid-flight: lifeTime == -1.0
        // Do not decrease visibility
        EAX = FALSE;
    };
};


/*
 * This function resets the gravity back to its default value, after any collision occurred. The function hooks
 * oCAIArrow::ReportCollisionToAI() at an offset where a valid collision was detected.
 * It is important to reset the gravity, because the projectile may bounce off of walls (etc.), after which it would
 * float around with the previously set drop-off gravity (GFA_PROJECTILE_GRAVITY).
 */
func void GFA_ResetProjectileGravity() {
    var int arrowAI; arrowAI = MEMINT_SwitchG1G2(ESI, ECX);
    var oCItem projectile; projectile = _^(MEM_ReadInt(arrowAI+oCAIArrowBase_hostVob_offset));
    var int rigidBody; rigidBody = projectile._zCVob_rigidBody;
    if (!rigidBody) {
        return;
    };

    // Reset projectile gravity (zCRigidBody.gravity) after collision (oCAIArrow.collision) to default
    MEM_WriteInt(rigidBody+zCRigidBody_gravity_offset, FLOATONE);
    if (lf(MEM_ReadInt(arrowAI+oCAIArrowBase_lifeTime_offset), FLOATONE_NEG)) {
        // Reset gravity timer
        MEM_WriteInt(arrowAI+oCAIArrowBase_lifeTime_offset, FLOATONE_NEG);
    };

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
 * Additionally, the shooting statistics are updated.
 * This function is only making changes if the shooter is the player.
 */
func void GFA_OverwriteHitChance() {
    var int arrowAI; arrowAI = MEMINT_SwitchG1G2(ESI, EBP);
    var C_Npc shooter; shooter = _^(MEM_ReadInt(arrowAI+oCAIArrow_origin_offset));

    // Only if shooter is the player and if free aiming is enabled for ranged combat
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
        // If accuracy/scattering is enabled, all shots that hit the target are always positive hits
        hit = TRUE;
        MEM_WriteInt(hitChancePtr, MEMINT_SwitchG1G2(FLOAT1C, 100)); // Overwrite to hit always
    };

    // Update the shooting statistics
    GFA_StatsHits += hit;
};


/*
 * For hit registration of projectiles with NPCs, Gothic only checks the bounding box of the collision vob. This results
 * in a large number of false positive hits when using free aiming with scattering. This function performs a refined
 * collision check once the bounding box collision was determined. This function is called from
 * GFA_ExtendCollisionCheck() only if GFA_TRUE_HITCHANCE is true.
 */
func int GFA_RefinedProjectileCollisionCheck(var int vobPtr, var int arrowAI) {
    if (!GFA_ACTIVE) {
        return TRUE;
    };

    // Retrieve projectile and rigid body
    var int projectilePtr; projectilePtr = MEM_ReadInt(arrowAI+oCAIArrowBase_hostVob_offset);
    if (!projectilePtr) {
        return TRUE;
    };
    var oCItem projectile; projectile = _^(projectilePtr);
    var int rBody; rBody = projectile._zCVob_rigidBody;
    if (!rBody) {
        return TRUE;
    };

    // Direction of collision line: projectile position subtracted from the last predicted position of the rigid body
    GFA_CollTrj[0] = projectile._zCVob_trafoObjToWorld[ 3];
    GFA_CollTrj[1] = projectile._zCVob_trafoObjToWorld[ 7];
    GFA_CollTrj[2] = projectile._zCVob_trafoObjToWorld[11];
    GFA_CollTrj[3] = subf(MEM_ReadInt(rBody+zCRigidBody_xPos_offset), GFA_CollTrj[0]);
    GFA_CollTrj[4] = subf(MEM_ReadInt(rBody+zCRigidBody_xPos_offset+4), GFA_CollTrj[1]);
    GFA_CollTrj[5] = subf(MEM_ReadInt(rBody+zCRigidBody_xPos_offset+8), GFA_CollTrj[2]);
    var int fromPosPtr; fromPosPtr = _@(GFA_CollTrj);
    var int dirPosPtr; dirPosPtr = _@(GFA_CollTrj)+sizeof_zVEC3;

    // Direction vector needs to be normalized
    const int call = 0;
    if (CALL_Begin(call)) {
        CALL__thiscall(_@(dirPosPtr), zVEC3__NormalizeSafe);
        call = CALL_End();
    };
    MEM_CopyBytes(CALL_RetValAsPtr(), dirPosPtr, sizeof_zVEC3);

    // Get maximum required length of trajectory inside the bounding box (diagonal of bounding box)
    var int bbox[6];
    MEM_CopyBytes(vobPtr+zCVob_bbox3D_offset, _@(bbox), sizeof_zTBBox3D);
    var int dist; // Distance from bbox.mins to bbox.max
    dist = sqrtf(addf(addf(sqrf(subf(bbox[3], bbox[0])), sqrf(subf(bbox[4], bbox[1]))), sqrf(subf(bbox[5], bbox[2]))));
    dist = addf(dist, FLOAT3C); // Add the 3m-shift of the start (see below)

    // Adjust length of ray (large models have huge bounding boxes)
    GFA_CollTrj[0] = subf(GFA_CollTrj[0], mulf(GFA_CollTrj[3], FLOAT3C)); // Start 3m behind projectile
    GFA_CollTrj[1] = subf(GFA_CollTrj[1], mulf(GFA_CollTrj[4], FLOAT3C));
    GFA_CollTrj[2] = subf(GFA_CollTrj[2], mulf(GFA_CollTrj[5], FLOAT3C));
    GFA_CollTrj[3] = mulf(GFA_CollTrj[3], dist); // Trace trajectory from the edge through the bounding box
    GFA_CollTrj[4] = mulf(GFA_CollTrj[4], dist);
    GFA_CollTrj[5] = mulf(GFA_CollTrj[5], dist);

    // Record the model node that was hit
    GFA_HitModelNode = ""; // Reset detected node name
    HookEngineF(zCModel__TraceRay_positiveNodeHit, 7, GFA_RecordHitNode);

    // Perform refined collision check
    GFA_AllowSoftSkinTraceRay(1);
    var int hit;
    var int flags; flags = zTraceRay_poly_normal | zTraceRay_poly_ignore_transp;
    var int trRep; trRep = MEM_Alloc(sizeof_zTTraceRayReport);
    const int call2 = 0;
    if (CALL_Begin(call2)) {
        CALL_PtrParam(_@(trRep));      // zTTraceRayReport (not needed)
        CALL_IntParam(_@(flags));      // Trace ray flags
        CALL_PtrParam(_@(dirPosPtr));  // Trace ray direction
        CALL_PtrParam(_@(fromPosPtr)); // Start vector
        CALL_PutRetValTo(_@(hit));     // Did the trace ray hit
        CALL__thiscall(_@(vobPtr), zCVob__TraceRay); // This is a vob specific trace ray
        call2 = CALL_End();
    };
    GFA_AllowSoftSkinTraceRay(0);

    // Remove checking for model node (remove hook completely from opcode)
    RemoveHookF(zCModel__TraceRay_positiveNodeHit, 7, GFA_RecordHitNode);

    // Also check dedicated head visual if present (not detected by model trace ray)
    if (GFA_AimRayHead(vobPtr, fromPosPtr, dirPosPtr, trRep+zTTraceRayReport_foundIntersection_offset)) {
        hit = TRUE;

        // Get head node name (should always be "BIP01 HEAD")
        var oCNpc npc; npc = _^(vobPtr);
        var zCAIPlayer playerAI; playerAI = _^(npc.anictrl);
        var int headNode; headNode = playerAI.modelHeadNode;
        var int node; node = MEM_ReadInt(headNode+zCModelNodeInst_protoNode_offset);
        GFA_HitModelNode = MEM_ReadString(node+zCModelNode_nodeName_offset);
    };

    // If the same positive hit has been determined before, Gothic has trouble reporting the collision: Do it manually
    if (hit) {
        if (lastVob == vobPtr) && (lastProj == projectilePtr) {
            var zCVob vob; vob = _^(vobPtr);

            // Create a minimal collision report
            var int report; report = MEM_Alloc(sizeof_zCCollisionReport);
            MEM_WriteInt(report, zCCollisionReport__vtbl);
            MEM_CopyBytes(trRep+zTTraceRayReport_foundIntersection_offset, report+zCCollisionReport_pos_offset,
                sizeof_zVEC3);
            MEM_WriteInt(report+zCCollisionReport_thisCollObj_offset, projectile._zCVob_m_poCollisionObject);
            MEM_WriteInt(report+zCCollisionReport_hitCollObj_offset, vob.m_poCollisionObject);

            // Manually report the collision
            const int call3 = 0;
            if (CALL_Begin(call3)) {
                CALL_PtrParam(_@(report));
                CALL__thiscall(_@(arrowAI), oCAIArrow__ReportCollisionToAI);
                call3 = CALL_End();
            };
            MEM_Free(report);
        } else {
            // Record the latest hit
            var int lastVob; lastVob = vobPtr;
            var int lastProj; lastProj = projectilePtr;
        };
    };

    // Free the trace ray report
    MEM_Free(trRep);

    // Add direction vector to position vector to form a line (for debug visualization)
    if (LineVisible(GFA_DebugCollTrj)) {
        UpdateLine3(GFA_DebugCollTrj,
                    GFA_CollTrj[0],
                    GFA_CollTrj[1],
                    GFA_CollTrj[2],
                    addf(GFA_CollTrj[0], GFA_CollTrj[3]),
                    addf(GFA_CollTrj[1], GFA_CollTrj[4]),
                    addf(GFA_CollTrj[2], GFA_CollTrj[5]));
    };

    return +hit;
};


/*
 * Store the name of the model node that was hit into a variable for later critical hit detection. This function hooks
 * at an address where zCModel::TraceRay() returns a positive intersection.
 */
func void GFA_RecordHitNode() {
    var int nodeInst; nodeInst = MEM_ReadInt(MEMINT_SwitchG1G2(/*esp+18Ch-16Ch*/ ESP+32, /*esp+260h-248h*/ ESP+24));
    var int node; node = MEM_ReadInt(nodeInst+zCModelNodeInst_protoNode_offset);
    GFA_HitModelNode = MEM_ReadString(node+zCModelNode_nodeName_offset);
};


/*
 * Enlarge the bounding box of human NPCs, because it does not include the head by default. Without the head inside
 * the bounding box, shots to the head would not be detected. This function hooks zCModel::CalcModelBBox3DWorld() just
 * before exiting the function. This hook might impact performance, since the bounding boxes of models is calculated
 * every frame for all unshrunk models.
 */
func void GFA_EnlargeHumanModelBBox() {
    // Prevent crash on startup
    if (!Hlp_IsValidNpc(hero)) || (!_@(MEM_Timer)) {
        return;
    };

    // Timer hack to draw player visual on loading
    if (MEM_Timer.totalTime < 5000) {
        return;
    };

    // Exit for non-NPC models
    var int model; model = EBX;
    var int vobPtr; vobPtr = MEM_ReadInt(model+zCModel_hostVob_offset);
    if (!Hlp_Is_oCNpc(vobPtr)) {
        return;
    };

    // Exit if NPC is shrunk
    var oCNpc slf; slf = _^(vobPtr);
    if (!Hlp_IsValidNpc(slf)) || (!slf._zCVob_homeWorld) {
        return;
    };

    // Exit if NPC is not fully initialized yet
    if (!slf.anictrl) {
        return;
    };

    // Exit if AI is not fully initialized yet
    var zCAIPlayer playerAI; playerAI = _^(slf.anictrl);
    if (!playerAI.modelHeadNode) {
        return;
    };

    // Only consider NPCs with a dedicated head visual
    var int headNode; headNode = playerAI.modelHeadNode;
    if (!MEM_ReadInt(headNode+zCModelNodeInst_visual_offset)) {
        return;
    };

    // Backup frame counter
    var int frameCtr; frameCtr = MEM_ReadInt(model+zCModel_masterFrameCtr_offset);

    // Calculate the head node bounding box. This will transform the local bounding box to world coordinates
    const int call = 0;
    if (CALL_Begin(call)) {
        CALL__thiscall(_@(model), zCModel__CalcNodeListBBoxWorld);
        call = CALL_End();
    };

    // Reset frame counter to allow reassessing the model again. Important for GFA_CH_VisualizeModelNode()
    MEM_WriteInt(model+zCModel_masterFrameCtr_offset, frameCtr);

    // Copy the bounding box of the head
    var int headBBox[6]; // sizeof_zTBBox3D/4
    var int headBBoxPtr; headBBoxPtr = _@(headBBox);
    MEM_CopyBytes(headNode+zCModelNodeInst_bbox3D_offset, headBBoxPtr, sizeof_zTBBox3D);

    // Subtract the world coordinates from the world-transformed bounding box.
    // There does not seem to be an easier way. It is not clear if the local offset of the head node is accessible
    // somewhere directly
    var zMAT4 trafo; trafo = _^(vobPtr+zCVob_trafoObjToWorld_offset);
    headBBox[0] = subf(headBBox[0], trafo.v0[zMAT4_position]);
    headBBox[1] = subf(headBBox[1], trafo.v1[zMAT4_position]);
    headBBox[2] = subf(headBBox[2], trafo.v2[zMAT4_position]);
    headBBox[3] = subf(headBBox[3], trafo.v0[zMAT4_position]);
    headBBox[4] = subf(headBBox[4], trafo.v1[zMAT4_position]);
    headBBox[5] = subf(headBBox[5], trafo.v2[zMAT4_position]);

    // Enlarge the model bounding box by including the head bounding box
    var int modelBBoxPtr; modelBBoxPtr = model+zCModel_bbox3d_offset;
    const int call2 = 0;
    if (CALL_Begin(call2)) {
        CALL_PtrParam(_@(headBBoxPtr));
        CALL__thiscall(_@(modelBBoxPtr), zTBBox3D__CalcGreaterBBox3D);
        call2 = CALL_End();
    };
};
