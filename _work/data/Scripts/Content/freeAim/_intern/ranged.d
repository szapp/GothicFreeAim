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

/* Update aiming animation. Hook before oCAniCtrl_Human::InterpolateCombineAni */
func void freeAimAnimation() {
    if (freeAimIsActive() != FMODE_FAR) { return; };
    var int herPtr; herPtr = _@(hero);
    var int distance; var int target;
    if (FREEAIM_FOCUS_COLLECTION) { // Set focus npc if there is a valid one under the reticle
        freeAimRay(FREEAIM_MAX_DIST, TARGET_TYPE_NPCS, _@(target), 0, _@(distance), 0); // Shoot ray and retrieve info
        distance = roundf(divf(mulf(distance, FLOAT1C), mkf(FREEAIM_MAX_DIST))); // Distance scaled between [0, 100]
    } else { // More performance friendly. Here, there will be NO focus, otherwise it gets stuck on npcs.
        const int call4 = 0; var int null; // Set the focus vob properly: reference counter
        if (CALL_Begin(call4)) {
            CALL_PtrParam(_@(null)); // This will remove the focus
            CALL__thiscall(_@(herPtr), oCNpc__SetFocusVob);
            call4 = CALL_End();
        };
        const int call5 = 0; // Remove the enemy properly: reference counter
        if (CALL_Begin(call5)) {
            CALL_PtrParam(_@(null)); // Always remove oCNpc.enemy. Target will be set to aimvob when shooting
            CALL__thiscall(_@(herPtr), oCNpc__SetEnemy);
            call5 = CALL_End();
        };
        distance = 25; // No distance check ever. Set it to medium distance
        target = 0; // No focus target ever
    };
    var int autoAlloc[7]; var Reticle reticle; reticle = _^(_@(autoAlloc)); // Gothic takes care of freeing this ptr
    MEM_CopyWords(_@s(""), _@(autoAlloc), 5); // reticle.texture (reset string) // Do not show reticle by default
    reticle.color = -1; // Do not set color by default
    reticle.size = 75; // Medium size by default
    freeAimGetReticleRanged_(target, distance, _@(reticle)); // Retrieve reticle specs
    freeAimInsertReticle(_@(reticle)); // Draw/update reticle
    var zMAT4 camPos; camPos = _^(MEM_ReadInt(MEM_ReadInt(MEMINT_oGame_Pointer_Address)+20)+60); //0=right, 2=out, 3=pos
    var int pos[3]; // The position is calculated from the camera, not the player model
    distance = mkf(FREEAIM_MAX_DIST); // Take the max distance, otherwise it looks strange on close range targets
    pos[0] = addf(camPos.v0[3], mulf(camPos.v0[2], distance));
    pos[1] = addf(camPos.v1[3], mulf(camPos.v1[2], distance));
    pos[2] = addf(camPos.v2[3], mulf(camPos.v2[2], distance));
    // Get aiming angles
    var int angleX; var int angXptr; angXptr = _@(angleX);
    var int angleY; var int angYptr; angYptr = _@(angleY);
    var int posPtr; posPtr = _@(pos); // So many pointers because it is a recyclable call
    const int call3 = 0;
    if (CALL_Begin(call3)) {
        CALL_PtrParam(_@(angYptr));
        CALL_PtrParam(_@(angXptr)); // X angle not needed
        CALL_PtrParam(_@(posPtr));
        CALL__thiscall(_@(herPtr), oCNpc__GetAngles);
        call3 = CALL_End();
    };
    if (lf(absf(angleY), 1048576000)) { // Prevent multiplication with too small numbers. Would result in aim twitching
        if (lf(angleY, FLOATNULL)) { angleY =  -1098907648; } // -0.25
        else { angleY = 1048576000; }; // 0.25
    };
    // This following paragraph is inspired by oCAIHuman::BowMode (0x695F00 in g2)
    angleY = negf(subf(mulf(angleY, 1001786197), FLOATHALF)); // Scale and flip Y [-90° +90°] to [+1 0]
    if (lef(angleY, FLOATNULL)) { angleY = FLOATNULL; } // Maximum aim height (straight up)
    else if (gef(angleY, 1065353216)) { angleY = 1065353216; }; // Minimum aim height (down)
    // New aiming coordinates. Overwrite the arguments one and two passed to oCAniCtrl_Human::InterpolateCombineAni
    MEM_WriteInt(ESP+20, FLOATHALF); // First argument: Always aim at center (azimuth) (esp+44h-30h)
    ECX = angleY; // Second argument: New elevation
};

/* Internal helper function for freeAimGetDrawForce() */
func int freeAimGetDrawForce_() {
    var int talent; var C_Item weapon; // Retrieve the weapon first to distinguish between (cross-)bow talent
    if (Npc_IsInFightMode(hero, FMODE_FAR)) { weapon = Npc_GetReadiedWeapon(hero); }
    else if (Npc_HasEquippedRangedWeapon(hero)) { weapon = Npc_GetEquippedRangedWeapon(hero); }
    else { MEM_Error("freeAimGetDrawForce_: No valid weapon equipped/readied!"); return -1; }; // Should never happen
    if (weapon.flags & ITEM_BOW) { talent = hero.HitChance[NPC_TALENT_BOW]; } // Bow talent
    else if (weapon.flags & ITEM_CROSSBOW) { talent = hero.HitChance[NPC_TALENT_CROSSBOW]; } // Crossbow talent
    else { MEM_Error("freeAimGetDrawForce_: No valid weapon equipped/readied!"); return -1; };
    // Call customized function
    MEM_PushInstParam(weapon);
    MEM_PushIntParam(talent);
    MEM_Call(freeAimGetDrawForce); // freeAimGetDrawForce(weapon, talent);
    var int drawForce; drawForce = MEM_PopIntResult();
    if (drawForce > 100) { drawForce = 100; } else if (drawForce < 0) { drawForce = 0; }; // Must be in [0, 100]
    return drawForce;
};

/* Internal helper function for freeAimGetAccuracy() */
func int freeAimGetAccuracy_() {
    var int talent; var C_Item weapon; // Retrieve the weapon first to distinguish between (cross-)bow talent
    if (Npc_IsInFightMode(hero, FMODE_FAR)) { weapon = Npc_GetReadiedWeapon(hero); }
    else if (Npc_HasEquippedRangedWeapon(hero)) { weapon = Npc_GetEquippedRangedWeapon(hero); }
    else { MEM_Error("freeAimGetAccuracy_: No valid weapon equipped/readied!"); return -1; }; // Should never happen
    if (weapon.flags & ITEM_BOW) { talent = hero.HitChance[NPC_TALENT_BOW]; } // Bow talent
    else if (weapon.flags & ITEM_CROSSBOW) { talent = hero.HitChance[NPC_TALENT_CROSSBOW]; } // Crossbow talent
    else { MEM_Error("freeAimGetAccuracy_: No valid weapon equipped/readied!"); return -1; };
    // Call customized function
    MEM_PushInstParam(weapon);
    MEM_PushIntParam(talent);
    MEM_Call(freeAimGetAccuracy); // freeAimGetAccuracy(weapon, talent);
    var int accuracy; accuracy = MEM_PopIntResult();
    if (accuracy < 1) { accuracy = 1; } else if (accuracy > 100) { accuracy = 100; }; // Limit to [1, 100] // Div by 0!
    return accuracy;
};

/* Internal helper function for freeAimScaleInitialDamage() */
func int freeAimScaleInitialDamage_(var int basePointDamage) {
    var int talent; var C_Item weapon; // Retrieve the weapon first to distinguish between (cross-)bow talent
    if (Npc_IsInFightMode(hero, FMODE_FAR)) { weapon = Npc_GetReadiedWeapon(hero); }
    else if (Npc_HasEquippedRangedWeapon(hero)) { weapon = Npc_GetEquippedRangedWeapon(hero); }
    else { MEM_Error("freeAimScaleInitialDamage_: No valid weapon equipped/readied!"); return basePointDamage; };
    if (weapon.flags & ITEM_BOW) { talent = hero.HitChance[NPC_TALENT_BOW]; } // Bow talent
    else if (weapon.flags & ITEM_CROSSBOW) { talent = hero.HitChance[NPC_TALENT_CROSSBOW]; } // Crossbow talent
    else { MEM_Error("freeAimScaleInitialDamage_: No valid weapon equipped/readied!"); return basePointDamage; };
    // Call customized function
    MEM_PushIntParam(basePointDamage);
    MEM_PushInstParam(weapon);
    MEM_PushIntParam(talent);
    MEM_Call(freeAimScaleInitialDamage); // freeAimScaleInitialDamage(basePointDamage, weapon, talent);
    basePointDamage = MEM_PopIntResult();
    if (basePointDamage < 0) { basePointDamage = 0; }; // No negative damage
    return basePointDamage;
};

/* Set the projectile direction and trajectory. Hook oCAIArrow::SetupAIVob */
func void freeAimSetupProjectile() {
    var int projectilePtr; projectilePtr = MEM_ReadInt(ESP+4);  // First argument is the projectile
    if (!projectilePtr) { return; };
    var oCItem projectile; projectile = _^(projectilePtr);
    var C_Npc shooter; shooter = _^(MEM_ReadInt(ESP+8)); // Second argument is shooter
    if (FREEAIM_ACTIVE_PREVFRAME != 1) || (!Npc_IsPlayer(shooter)) { return; }; // Only if player and if fa WAS active
    // 1st: Set base damage of projectile
    var int baseDamage; baseDamage = projectile.damage[DAM_INDEX_POINT];
    var int newBaseDamage; newBaseDamage = freeAimScaleInitialDamage_(baseDamage);
    projectile.damage[DAM_INDEX_POINT] = newBaseDamage;
    // 2nd: Manipulate aiming accuracy (scatter): Rotate target position (azimuth, elevation)
    var int distance; freeAimRay(FREEAIM_MAX_DIST, TARGET_TYPE_NPCS, 0, 0, 0, _@(distance)); // Trace ray intersection
    var int accuracy; accuracy = freeAimGetAccuracy_(); // Change the accuracy calculation in that function, not here!
    if (accuracy > 100) { accuracy = 100; } else if (accuracy < 1) { accuracy = 1; }; // Prevent devision by zero
    var int bias; bias = castToIntf(FREEAIM_SCATTER_DEG);
    var int slope; slope = negf(divf(castToIntf(FREEAIM_SCATTER_DEG), FLOAT1C));
    var int angleMax; angleMax = roundf(mulf(addf(mulf(slope, mkf(accuracy)), bias), FLOAT1K)); // y = slope*acc+bias
    var int angleY; angleY = fracf(r_MinMax(-angleMax, angleMax), 1000); // Degrees azimuth
    angleMax = roundf(sqrtf(subf(sqrf(mkf(angleMax)), sqrf(mulf(angleY, FLOAT1K))))); // sqrt(angleMax^2-angleY^2)
    var int angleX; angleX = fracf(r_MinMax(-angleMax, angleMax), 1000); // Degrees elevation (restrict to circle)
    var zMAT4 camPos; camPos = _^(MEM_ReadInt(MEM_ReadInt(MEMINT_oGame_Pointer_Address)+20)+60); //0=right, 2=out, 3=pos
    var int pos[3]; pos[0] = FLOATNULL; pos[1] = FLOATNULL; pos[2] = distance;
    SinCosApprox(Print_ToRadian(angleX)); // Rotate around x-axis (elevation scatter)
    pos[1] = mulf(negf(pos[2]), sinApprox); // y*cos - z*sin = y'
    pos[2] = mulf(pos[2], cosApprox);       // y*sin + z*cos = z'
    SinCosApprox(Print_ToRadian(angleY)); // Rotate around y-axis (azimuth scatter)
    pos[0] = mulf(pos[2], sinApprox); //  x*cos + z*sin = x'
    pos[2] = mulf(pos[2], cosApprox); // -x*sin + z*cos = z'
    var int newPos[3]; // Rotation (translation into local coordinate system of camera)
    newPos[0] = addf(addf(mulf(camPos.v0[0], pos[0]), mulf(camPos.v0[1], pos[1])), mulf(camPos.v0[2], pos[2]));
    newPos[1] = addf(addf(mulf(camPos.v1[0], pos[0]), mulf(camPos.v1[1], pos[1])), mulf(camPos.v1[2], pos[2]));
    newPos[2] = addf(addf(mulf(camPos.v2[0], pos[0]), mulf(camPos.v2[1], pos[1])), mulf(camPos.v2[2], pos[2]));
    pos[0] = addf(camPos.v0[3], newPos[0]);
    pos[1] = addf(camPos.v1[3], newPos[1]);
    pos[2] = addf(camPos.v2[3], newPos[2]);
    // 3rd: Set projectile drop-off (by draw force)
    const int call2 = 0;
    if (CALL_Begin(call2)) {
        CALL__thiscall(_@(projectilePtr), zCVob__GetRigidBody); // Get ridigBody this way, it will be properly created
        call2 = CALL_End();
    };
    var int rBody; rBody = CALL_RetValAsInt(); // zCRigidBody*
    var int drawForce; drawForce = freeAimGetDrawForce_(); // Modify the draw force in that function, not here!
    var int gravityMod; gravityMod = FLOATONE; // Gravity only modified on short draw time
    if (drawForce < 25) { gravityMod = castToIntf(3.0); }; // Very short draw time increases gravity
    var int dropTime; dropTime = (drawForce*(FREEAIM_TRAJECTORY_ARC_MAX*100))/10000;
    FF_ApplyOnceExtData(freeAimDropProjectile, dropTime, 1, rBody); // When to hit the projectile with gravity
    freeAimBowDrawOnset = MEM_Timer.totalTime + FREEAIM_DRAWTIME_RELOAD; // Reset draw timer
    MEM_WriteInt(rBody+zCRigidBody_gravity_offset, mulf(castToIntf(FREEAIM_PROJECTILE_GRAVITY), gravityMod)); // Gravity
    if (Hlp_Is_oCItem(projectilePtr)) && (Hlp_StrCmp(projectile.effect, "")) { // Projectile has no FX
        projectile.effect = FREEAIM_TRAIL_FX; // Set trail strip fx for better visibility
        const int call3 = 0;
        if (CALL_Begin(call3)) {
            CALL__thiscall(_@(projectilePtr), oCItem__InsertEffect);
            call3 = CALL_End();
        };
    };
    // 4th: Setup the aim vob
    var int vobPtr; vobPtr = freeAimSetupAimVob(_@(pos));
    // Print info to zSpy
    var int s; s = SB_New();
    SB("freeAimSetupProjectile: ");
    SB("drawforce="); SBi(drawForce); SB("% ");
    SB("accuracy="); SBi(accuracy); SB("% ");
    SB("scatter="); SB(STR_Prefix(toStringf(angleX), 5)); SBc(176 /* deg */);
    SB("/"); SB(STR_Prefix(toStringf(angleY), 5)); SBc(176 /* deg */); SB(" ");
    SB("init-basedamage="); SBi(newBaseDamage); SB("/"); SBi(baseDamage);
    MEM_Info(SB_ToString()); SB_Destroy();
    MEM_WriteInt(ESP+12, vobPtr); // Overwrite the third argument (target vob) passed to oCAIArrow::SetupAIVob
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
