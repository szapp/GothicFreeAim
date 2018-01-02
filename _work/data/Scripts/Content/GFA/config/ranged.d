/*
 * This file contains all configurations for free aiming in ranged combat (bows and crossbows). See config\reticle.d for
 * reticle configurations.
 *
 * Requires the feature GFA_RANGED (see config\settings.d).
 *
 * List of included functions:
 *  func int GFA_GetDrawForce(C_Item weapon, int talent)
 *  func int GFA_GetAccuracy(C_Item weapon, int talent)
 *  func int GFA_GetRecoil(C_Item weapon, int talent)
 *  func int GFA_GetInitialBaseDamage(int baseDamage, int damageType, C_Item weapon, int talent, int aimingDistance)
 */


/*
 * This function is called at the point of shooting a bow or a crossbow. The return value scales the gravity of the
 * projectile in percent, where 0 is fast gravity drop-off and 100 is the straightest shot possible. Regardless of the
 * percentage, however, all shots are impacted by gravity at the latest after GFA_TRAJECTORY_ARC_MAX milliseconds.
 * This function is also well-suited to be used by the other functions of this file defined below.
 *
 * Ideas: incorporate factors like e.g. a quick-draw talent, weapon-specific stats, ...
 * Check if bow or crossbow with (weapon.flags & ITEM_BOW) or (weapon.flags & ITEM_CROSSBOW).
 *
 * Here, for example, bows are scaled with longer draw time (how long has the bow been drawn), whereas crossbows are
 * scaled with shorter aiming time (how long was the aim held steady). This results in slower build up once per aiming
 * for bows and faster build up for crossbows, but restarts every time the mouse moves. Additionally, crossbows have
 * recoil, see GFA_GetRecoil() below. All of this is a design choice and can be changed in the functions in this file.
 */
func int GFA_GetDrawForce(var C_Item weapon, var int talent) {
    var int drawForce;

    // Differentiate between bows and crossbows
    if (weapon.flags & ITEM_BOW) {
        // Bows: Calculate draw time (how long has the shot been drawn)
        var int drawTime; drawTime = MEM_Timer.totalTime - GFA_BowDrawOnset;

        // For now, the draw time is scaled by a maximum. Replace 1200 with a variable for adjustable quick-draw talent
        drawForce = (100 * drawTime) / 1200; // 1200 ms is the draw time with which full draw force is reached

    } else {
        // Crossbows: Calculate steady aiming time (how long since the last mouse movement)
        var int steadyTime; steadyTime = MEM_Timer.totalTime - GFA_MouseMovedLast;

        // For now, the steady time is scaled by a maximum. Replace 550 with a variable for adjustable steady-aim talent
        drawForce = (100 * steadyTime) / 550; // 550 ms is the steady aiming time with which full draw force is reached
    };

    // Respect the percentage ranges
    if (drawForce < 0) {
        drawForce = 0;
    } else if (drawForce > 100) {
        drawForce = 100;
    };

    return drawForce;
};


/*
 * This function is called at the point of shooting a bow or a crossbow. The return value scales the accuracy of the
 * projectile in percent, where 0 is maximum scattering and 100 is precisely on target.
 *
 * Note: This function is only used, if GFA_TRUE_HITCHANCE == true. Otherwise, Gothic's default hit chance calculation
 *       (based on skill and distance from target) is used and the accuracy defined here does not take effect!
 *
 * Ideas: incorporate factors like e.g. weapon-specific accuracy stats, weapon spread, accuracy talent, ...
 * Check if bow or crossbow with (weapon.flags & ITEM_BOW) or (weapon.flags & ITEM_CROSSBOW).
 *
 * Here, for example, the accuracy is scaled by talent and by draw force (see function above).
 * Note: For Gothic 1, instead of the talent, the dexterity is used (as is default for Gothic 1)
 */
func int GFA_GetAccuracy(var C_Item weapon, var int talent) {
    // Here, the 'hit chance' is scaled by draw force, where 'hit chance' is talent (Gothic 2) or dexterity (Gothic 1)
    //  Draw force = 100% -> accuracy = hit chance
    //  Draw force =   0% -> accuracy = hit chance * 0.8

    // In Gothic 1, the hit chance is actually the dexterity (for both bows and crossbows), NOT the talent!
    if (GOTHIC_BASE_VERSION == 1) {
        talent = hero.attribute[ATR_DEXTERITY];
    };

    // Get draw force from the function above and re-scale it from [0, 100] to [80, 100]
    var int drawForce; drawForce = GFA_GetDrawForce(weapon, talent);
    drawForce = GFA_ScaleRanges(drawForce, 0, 100, 80, 100);

    // Scale accuracy by draw force
    var int accuracy; accuracy = (talent * drawForce) / 100;

    // Decrease accuracy if moving by 0.2
    if (GFA_IsStrafing) {
        accuracy = accuracy*(4/5);
    };

    return accuracy;
};


/*
 * This function is called at the point of shooting a bow or a crossbow. The return value scales the recoil of the
 * weapon in percent, where 0 is no recoil and 100 is maximum recoil.
 *
 * Ideas: incorporate factors like e.g. weapon-specific recoil stats, weapon draw force, strength attribute, ...
 * Check if bow or crossbow with (weapon.flags & ITEM_BOW) or (weapon.flags & ITEM_CROSSBOW).
 *
 * Here, for example, the recoil is scaled with strength and is only active for crossbows, to counterbalance the shorter
 * aiming time (better draw force), see GFA_GetDrawForce() above.
 */
func int GFA_GetRecoil(var C_Item weapon, var int talent) {
    // No recoil for bows, since they have longer draw time, see GFA_GetDrawForce() above.
    if (weapon.flags & ITEM_BOW) {
        return 0;
    };

    // Here, the recoil is scaled by strength and steady aim
    //  Strength >= 120 -> recoil =  20% * steady aim
    //  Strength <=  20 -> recoil = 100% * steady aim

    // Scale strength form [20, 120] to [0, 80] (will be inversed to [100, 20] later)
    var int scaledStrength; scaledStrength = hero.attribute[ATR_STRENGTH];
    scaledStrength = GFA_ScaleRanges(scaledStrength, 20, 120, 0, 80);

    // Get draw force (steady aim) from the function above and re-scale it from [0, 100] to [80, 100]
    var int steadyAim; steadyAim = GFA_GetDrawForce(weapon, talent);
    steadyAim = GFA_ScaleRanges(steadyAim, 0, 100, 80, 100);

    // Apply steady aim to scaled strength and inverse result to obtain recoil percentage
    var int recoil; recoil = (scaledStrength * steadyAim) / 100;
    recoil = -recoil+100;

    // Personal design choice: Even with maximum strength and steady aim, add at least a bit of recoil (20%)
    if (recoil < 20) {
        recoil = 20;
    };

    return recoil;
};


/*
 * This function is called at the point of shooting a bow or crossbow. It may be used to alter the base damage at time
 * of shooting (if weapon has one damage type only). This should never be necessary, as all damage specifications should
 * be set in the item script of the weapon. However, here the initial damage may be scaled by draw force or accuracy
 * (see functions above). The return value is the base damage (equivalent to the damage in the item script of the
 * weapon).
 *
 * Ideas: incorporate factors like e.g. weapon-specific damage stats, draw force, ...
 * Check if bow or crossbow with (weapon.flags & ITEM_BOW) or (weapon.flags & ITEM_CROSSBOW).
 *
 * Here, for example, the damage is scaled by draw force to yield less damage when the bow is only briefly drawn, or the
 * crossbow only briefly held steady.
 */
func int GFA_GetInitialBaseDamage(var int baseDamage, var int damageType, var C_Item weapon, var int talent,
        var int aimingDistance) {
    // Here the damage is scaled by draw force:
    //  Draw force = 100% -> baseDamage
    //  Draw force =   0% -> baseDamage * 0.8

    /*
    // Optionally, it is possible to exclude certain damage types
    if (damageType == DAM_INDEX_MAGIC) {
        // No changes for magical damage
        return baseDamage;
    }; */

    // Get draw force from the function above and re-scale it from [0, 100] to [80, 100]
    var int drawForce; drawForce = GFA_GetDrawForce(weapon, talent);
    drawForce = GFA_ScaleRanges(drawForce, 0, 100, 80, 100);

    // Scale initial damage with adjusted draw force
    baseDamage = (baseDamage * drawForce) / 100;

    /*
    // Optionally, it is possible to decrease the damage with distance. Note, however, that the aimingDistance parameter
    // is the aiming distance, not the actual distance between the object and the shooter, because at time of shooting
    // it is not clear which/whether an NPC will be hit. The parameter aimingDistance is scaled between
    // 0 (<= RANGED_CHANCE_MINDIST) and 100 (>= RANGED_CHANCE_MAXDIST), see AI_Constants.d.
    aimingDistance = (-aimingDistance+100); // Inverse distance percentage
    baseDamage = (baseDamage * aimingDistance) / 100; */

    return baseDamage;
};
