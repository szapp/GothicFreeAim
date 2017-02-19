/*
 * This file contains all configurations for ranged combat (bows and crossbows).
 */

/*
 * This function is called at the point of shooting a bow or a crossbow. The return value scales the gravity of the
 * projectile in percent, where 0 is fast gravity drop-off and 100 is the straightest shot possible. Regardless of the
 * percentage, however, all shots are impacted by gravity at the latest after FREEAIM_TRAJECTORY_ARC_MAX milliseconds.
 * Here, bows are scaled with draw time, whereas crossbows always have 100% draw force (they are mechanical).
 * This function is also well-suited to be used by the other functions of this file defined below.
 */
func int freeAimGetDrawForce(var C_Item weapon, var int talent) {
    var int drawTime; drawTime = MEM_Timer.totalTime - freeAimBowDrawOnset;
    // Possibly incorporate more factors like e.g. a quick-draw talent, weapon-specific stats, ...
    if (weapon.flags & ITEM_CROSSBOW) { return 100; }; // Always full draw force on crossbows
    // For now the draw time is scaled by a maximum. Replace FREEAIM_DRAWTIME_MAX by a variable for a quick-draw talent
    var int drawForce; drawForce = (100 * drawTime) / FREEAIM_DRAWTIME_MAX;
    if (drawForce < 0) { drawForce = 0; } else if (drawForce > 100) { drawForce = 100; }; // Respect the ranges
    return drawForce;
};

/*
 * This function is called at the point of shooting a bow or a crossbow. The return value scales the accuracy of the
 * projectile in percent, where 0 is maximum scattering and 100 is precisely on target.
 * Here, the accuracy is scaled by talent and by draw force (see function above).
 */
func int freeAimGetAccuracy(var C_Item weapon, var int talent) {
    // Add any other factors here e.g. weapon-specific accuracy stats, weapon spread, accuracy talent, ...
    // Check if bow or crossbow with (weapon.flags & ITEM_BOW) or (weapon.flags & ITEM_CROSSBOW)
    // Here the talent is scaled by draw force: draw force=100% => accuracy=talent; draw force=0% => accuracy=talent/2
    var int drawForce; drawForce = freeAimGetDrawForce(weapon, talent); // Already scaled to [0, 100]
    var int accuracy; accuracy = (talent-talent/2)*drawForce/100+talent/2;
    if (accuracy < 0) { accuracy = 0; } else if (accuracy > 100) { accuracy = 100; }; // Respect the ranges
    return accuracy;
};

/*
 * This function is called at the point of shooting a bow or crossbow. It may be used to alter the base damage at time
 * of shooting (only DAM_POINT damage). This should never be necessary, as all damage specifications should be set in
 * the item script of the weapon. However, here the initial damage may be scaled by draw force or accuracy (see
 * functions above). The return value is the base damage (equivalent to the damage in the item script of the weapon).
 * Here, the damage is scaled by draw force to yield less damage when the bow is only briefly drawn.
 */
func int freeAimScaleInitialDamage(var int basePointDamage, var C_Item weapon, var int talent) {
    // This function should not be necessary, all damage specifications should be set in the item scripts. However,
    // here the initial damage (DAM_POINT) may be scaled by draw force, accuracy, ...
    // Check if bow or crossbow with (weapon.flags & ITEM_BOW) or (weapon.flags & ITEM_CROSSBOW)
    // Here the damage is scaled by draw force: draw force=100% => baseDamage; draw force=0% => baseDamage/2
    var int drawForce; drawForce = freeAimGetDrawForce(weapon, talent); // Already scaled to [0, 100]
    drawForce = 50 * drawForce / 100 + 50; // Re-scale the drawforce to [50, 100]
    return (basePointDamage * drawForce) / 100; // Scale initial point damage by draw force
};
