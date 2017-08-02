/*
 * This file contains all configurations for ranged combat (bows and crossbows).
 *
 * Supported: Gothic 1 and Gothic 2
 */


/*
 * This function is called at the point of shooting a bow or a crossbow. The return value scales the gravity of the
 * projectile in percent, where 0 is fast gravity drop-off and 100 is the straightest shot possible. Regardless of the
 * percentage, however, all shots are impacted by gravity at the latest after FREEAIM_TRAJECTORY_ARC_MAX milliseconds.
 * Here, bows are scaled with draw time, whereas crossbows always have 100% draw force (they are mechanical).
 * This function is also well-suited to be used by the other functions of this file defined below.
 *
 * Ideas: Incorporate more factors like e.g. a quick-draw talent, weapon-specific stats, ...
 */
func int freeAimGetDrawForce(var C_Item weapon, var int talent) {
    if (weapon.flags & ITEM_CROSSBOW) {
        // Always full draw force on crossbows
        return 100;
    };

    // Get the current draw time (how long has the shot been drawn)
    var int drawTime; drawTime = MEM_Timer.totalTime - freeAimBowDrawOnset;

    // For now the draw time is scaled by a maximum. Replace FREEAIM_DRAWTIME_MAX by a variable for a quick-draw talent
    var int drawForce; drawForce = (100 * drawTime) / FREEAIM_DRAWTIME_MAX;

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
 * Add any other factors here e.g. weapon-specific accuracy stats, weapon spread, accuracy talent, ...
 * Check if bow or crossbow with (weapon.flags & ITEM_BOW) or (weapon.flags & ITEM_CROSSBOW).
 *
 * Here, the accuracy is scaled by talent and by draw force (see function above). Note, for Gothic 1, instead of the
 * talent, the dexterity is used.
 *
 * Note: This function is only used, if FREEAIM_TRUE_HITCHANCE is true. Otherwise, Gothic's default hit chance
 * calculation (based on skill and distance from target) is used and the accuracy defined here does not take effect!
 */
func int freeAimGetAccuracy(var C_Item weapon, var int talent) {
    // Here, the hit chance is scaled by draw force, where hit chance is talent for Gothic 2 and dexterity for Gothic 1
    //  Draw force = 100% -> accuracy = hit chance
    //  Draw force =   0% -> accuracy = hit chance/2

    // Get draw force from the function above. Already scaled to [0, 100]
    var int drawForce; drawForce = freeAimGetDrawForce(weapon, talent);

    // In Gothic 1, the hit chance is actually the dexterity (for both bows and crossbows), NOT the talent!
    if (GOTHIC_BASE_VERSION == 1) {
        talent = hero.attribute[ATR_DEXTERITY];
    };

    // Calculate the accuracy as described in the comment a few lines above
    var int accuracy; accuracy = (talent-talent/2)*drawForce/100+talent/2;

    // Respect the percentage ranges
    if (accuracy < 0) {
        accuracy = 0;
    } else if (accuracy > 100) {
        accuracy = 100;
    };

    return accuracy;
};


/*
 * This function is called at the point of shooting a bow or a crossbow. The return value scales the recoil of the
 * weapon in percent, where 0 is no recoil and 100 is maximum recoil.
 *
 * Add any other factors here e.g. weapon-specific accuracy stats, weapon spread, accuracy talent, ...
 * Check if bow or crossbow with (weapon.flags & ITEM_BOW) or (weapon.flags & ITEM_CROSSBOW).
 *
 * Here, the recoil is scaled with strength and only active for crossbows, to counterbalance the lack of draw force.
 */
func int freeAimGetRecoil(var C_Item weapon, var int talent) {
    if (weapon.flags & ITEM_BOW) {
        // No recoil for bows
        return 0;
    };

    // Here, the recoil is scaled by strengh:
    //  Strength >= 120 -> recoil =  20
    //  Strength <=  20 -> recoil = 100
    var int recoil; recoil = (80*(hero.attribute[ATR_STRENGTH]-120)/-100)+20;

    /*
    // Alternatively, inversely scale with draw force. Keep in mind, that by default, draw force is always 100% for
    // crossbows, see freeAimGetDrawForce() above.
    var int recoil; recoil = -freeAimGetDrawForce(weapon, talent)+100; */

    // Respect the percentage ranges
    if (recoil < 20) {
        // Personal preference: always add at least a bit of recoil (20%)
        recoil = 20;
    } else if (recoil > 100) {
        recoil = 100;
    };

    return recoil;
};


/*
 * This function is called at the point of shooting a bow or crossbow. It may be used to alter the base damage at time
 * of shooting (only DAM_POINT damage). This should never be necessary, as all damage specifications should be set in
 * the item script of the weapon. However, here the initial damage may be scaled by draw force or accuracy (see
 * functions above). The return value is the base damage (equivalent to the damage in the item script of the weapon).
 *
 * Check if bow or crossbow with (weapon.flags & ITEM_BOW) or (weapon.flags & ITEM_CROSSBOW)
 *
 * Here, the damage is scaled by draw force to yield less damage when the bow is only briefly drawn.
 */
func int freeAimScaleInitialDamage(var int basePointDamage, var C_Item weapon, var int talent, var int aimingDistance) {
    // Here the damage is scaled by draw force:
    //  Draw force = 100% -> baseDamage
    //  Draw force =   0% -> baseDamage/2

    // Get draw force from the function above. Already scaled to [0, 100]
    var int drawForce; drawForce = freeAimGetDrawForce(weapon, talent);

    // Re-scale the drawforce to [50, 100]
    drawForce = 50 * drawForce / 100 + 50;

    // Scale initial point damage by draw force
    basePointDamage = (basePointDamage * drawForce) / 100;

    /*
    // Optionally, it is possible to decrease the damage with distance. Note, however, that the aimingDistance argument
    // is the aiming distance, not the actual distance between the object and the shooter, because at time of shooting
    // it is not clear which/whether an NPC will be hit. The argument aimingDistance is scaled between
    // 0 (<= RANGED_CHANCE_MINDIST) and 100 (>= RANGED_CHANCE_MAXDIST), see AI_Constants.d.
    aimingDistance = (-aimingDistance+100); // Inverse distance percentage
    basePointDamage = (basePointDamage * aimingDistance) / 100; */

    return basePointDamage;
};
