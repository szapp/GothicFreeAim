/*
 * This file contains supplements the configurations for critical hits for bows and crossbows (see config\criticalHit.d)
 * The function freeAimCriticalHitAutoAim() is outsourced into this file, because it is only applicable for Gothic 2
 */


/*
 * This function is called when a critical hit occurred; but only if free aiming is disabled. It allows to define a
 * critical hit chance even for the standard auto aiming.
 * Although not existing in the original Gothic 2, this is important here to balance the damage output between free aim
 * and auto aim. Note, that this is not necessary for Gothic 1, as it already has critical hits for auto aiming.
 * The return value is a percentage (chance level or hit chance), where 0 is no critical hit ever and and 100 always
 * causes a critical hit. Everything in between is dependent on a respective probability.
 * To disable this feature, simply have the function always return 0.
 *
 * Examples are written below and commented out and serve as inspiration of what is possible.
 */
func int freeAimCriticalHitAutoAim(var C_Npc target, var C_Item weapon, var int talent) {
    // Here, scale the critical hit chance between MIN (0% skill) and MAX (100% skill)
    var int min; // With   0% skill, min% of the hits are critical hits
    var int max; // With 100% skill, max% of the hits are critical hits

    // Also take the distance into account
    var int distance; distance = Npc_GetDistToPlayer(target);
    if (distance <= FloatToInt(RANGED_CHANCE_MINDIST)/2) {
        // Close range
        min = 3;
        max = 30;
    } else if (distance <= FloatToInt(RANGED_CHANCE_MINDIST)) {
        // Medium range
        min = 2;
        max = 20;
    } else if (distance < FloatToInt(RANGED_CHANCE_MAXDIST)) {
        // Far range
        min = 1;
        max = 10;
    } else {
        // To far away for critical hits
        min = 0;
        max = 0;
    };

    // Scale the critical hit chance between min and max
    var int critChance; critChance = (max-min)*talent/100+min;

    /*
    if (target.guild < GIL_SEPERATOR_HUM) {
        // The critical hit chance may depend on the target NPC. Make use of 'target' argument
        // ...
    };*/

    /*
    if (Hlp_IsValidItem(weapon)) {
        // The weapon can also be considered (e.g. weapon specific print). Make use of 'weapon' for that
        // Caution: Weapon may have been unequipped already at this time (unlikely)! Use Hlp_IsValidItem(weapon)
        if (weapon.certainProperty > 10) {
            // E.g. special case for weapon property
        };
    }; */

    // Respect the percentage ranges
    if (critChance < 0) {
        critChance = 0;
    } else if (critChance > 100) {
        critChance = 100;
    };

    return critChance;
};
