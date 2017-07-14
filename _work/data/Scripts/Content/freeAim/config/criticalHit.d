/*
 * This file contains all configurations for critical hits for bows and crossbows.
 */


/*
 * This function is called every time (any kind of) NPC is hit by a projectile (arrows and bolts) to determine, whether
 * a critical hit occurred. This function returns a definition of the critical hit area (weak spot) based on the NPC
 * that it hit or the weapon used. A weak spot is defined by its bone, size and modified damage.
 * This function is dynamic: It is called on every hit and the weak spot and damage can be calculated individually.
 * The damage is a float and represents the new base damage (damage of weapon), not the final damage!
 *
 * Ideas: Incorporate weapon-specific stats, headshot talent, dependency on target, ...
 * Examples are written below and commented out and serve as inspiration of what is possible.
 * Here, preliminary weak spots for almost all Gothic 2 monsters are defined (all headshots).
 */
func void freeAimCriticalHitDef(var C_Npc target, var C_Item weapon, var int talent, var int damage, var int rtrnPtr) {
    // Get weak spot instance from call-by-reference argument
    var Weakspot weakspot; weakspot = _^(rtrnPtr);

    // Only allow critical hits, if a non-critical shot would cause damage
    if (GOTHIC_BASE_VERSION == 1) {
        // Gothic 1: (damage > protection of target)
        if (roundf(damage) < target.protection[PROT_POINT]) {
            return;
        };
    } else {
        // Gothic 2: (damage + dexterity > protection of target)
        if (roundf(damage)+hero.attribute[ATR_DEXTERITY] < target.protection[PROT_POINT]) {
            return;
        };
    };

    /*
    if (target.guild < GIL_SEPERATOR_HUM) {
        // The damage may depend on the target NPC (e.g. different damage for monsters). Make use of 'target' argument
        // ...
    }; */

    /*
    if (Hlp_IsValidItem(weapon)) {
        // The weapon can also be considered (e.g. weapon specific damage). Make use of 'weapon' for that
        // Caution: Weapon may have been unequipped already at this time (unlikely)! Use Hlp_IsValidItem(weapon)
        if (weapon.certainProperty > 10) {
            // E.g. special case for weapon property
        };
    }; */

    // Here, simply increase the base damage for all critical hits (for all creatures)
    weakspot.bDmg = mulf(damage, castToIntf(1.5)); // This is a float

    // For examples for cricital hit definitions, see this function in config\headshots_G1.d or config\headshots_G2.d
    headshots(target, rtrnPtr);
};


/*
 * This function is called when a critical hit occurred and can be used to print something to the screen, play a sound
 * jingle or, as done here by default, show a hitmarker. Leave this function blank for no event.
 * This function is also called when free aiming is disabled, depending on the configuration in
 * freeAimCriticalHitAutoAim(), see below.
 *
 * Idea: The critical hits could be counted here to give an XP reward after 25 headshots
 * Examples are written below and commented out and serve as inspiration of what is possible.
 */
func void freeAimCriticalHitEvent(var C_Npc target, var C_Item weapon, var int freeAimingIsEnabled) {

    /*
    if (target.guild < GIL_SEPERATOR_HUM) {
        // The event may depend on the target NPC (e.g. different sound for monsters). Make use of 'target' argument
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

    /*
    // Simple screen notification
    PrintS("Critical hit");*/

    // Shooter-like hit marker
    if (freeAimingIsEnabled) {
        // Only show the hit marker if free aiming is enabled (this function is also called for auto aim critical hits)
        var int hitmark;
        if (!Hlp_IsValidHandle(hitmark)) {
            // Create hitmark if it does not exist
            var zCView screen; screen = _^(MEM_Game._zCSession_viewport);

            // Create it in the center of the screen
            hitmark = View_CreateCenterPxl(screen.psizex/2, screen.psizey/2, 64, 64);

            // Get 7th frame of animated texture as static texture
            View_SetTexture(hitmark, freeAimAnimateReticleByPercent(RETICLE_TRI_IN, 100, 7));
        };
        View_Open(hitmark);

        // Close the hit marker after 300 ms
        FF_ApplyExtData(View_Close, 300, 1, hitmark);
    };

    // Sound notification
    Snd_Play3D(target, "FREEAIM_CRITICALHIT");
};
