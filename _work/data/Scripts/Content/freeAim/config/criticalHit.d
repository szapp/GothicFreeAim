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
func void freeAimCriticalHitDef(var C_Npc target, var C_Item weapon, var int damage, var int rtrnPtr) {
    // Get weak spot instance from call-by-reference argument
    var Weakspot weakspot; weakspot = _^(rtrnPtr);

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

    // Here, set the head to the default weak spot
    weakspot.node = "Bip01 Head"; // Upper/lower case is not important, but spelling and spaces are

    // Here, simply increase the base damage for all creatures
    weakspot.bDmg = mulf(damage, castToIntf(1.5)); // This is a float

    // Here, there are preliminary definitions for nearly all Gothic 2 creatures for headshots
    if (target.guild < GIL_SEPERATOR_HUM)
    || ((target.guild > GIL_SEPERATOR_ORC) && (target.guild < GIL_DRACONIAN))
    || (target.guild == GIL_ZOMBIE)
    || (target.guild == GIL_SUMMONEDZOMBIE) {
        // Here is also room for story-dependent exceptions (e.g. a specific NPC may have a different weak spot)

        weakspot.dimX = -1; // Retrieve the dimensions automatically from model. This works only on humanoids AND only
        weakspot.dimY = -1; // for head node! All other creatures need actual hard coded bounding box dimensions

    } else if (target.guild == GIL_BLOODFLY) // Bloodflys and meatbugs don't have a head node
    || (target.guild == GIL_MEATBUG)
    || (target.guild == GIL_STONEGUARDIAN) // Stoneguardians have too large heads (head node is not centered)
    || (target.guild == GIL_SUMMONEDGUARDIAN)
    || (target.guild == GIL_STONEGOLEM) // Same for golems
    || (target.guild == GIL_FIREGOLEM)
    || (target.guild == GIL_ICEGOLEM)
    || (target.guild == GIL_SUMMONED_GOLEM)
    || (target.guild == GIL_SWAMPGOLEM)
    || (target.guild == GIL_SKELETON) // Skeletons are only bones, there is no critical hit
    || (target.guild == GIL_SUMMONED_SKELETON)
    || (target.guild == GIL_SKELETON_MAGE)
    || (target.guild == GIL_GOBBO_SKELETON)
    || (target.guild == GIL_SUMMONED_GOBBO_SKELETON)
    || (target.guild == GIL_SHADOWBEAST_SKELETON) {
        // Disable critical hits this way
        weakspot.node = "";

    } else if (target.aivar[AIV_MM_REAL_ID] == ID_BLATTCRAWLER) {
        // Blattcrawler has a tiny head that is not centered. ZM_Fuehler_01 is, though
        weakspot.node = "ZM_Fuehler_01";
        weakspot.dimX = 45;
        weakspot.dimY = 35;
    } else if (target.aivar[AIV_MM_REAL_ID] == ID_BLOODHOUND) {
        weakspot.dimX = 55;
        weakspot.dimY = 50;
    } else if (target.aivar[AIV_MM_REAL_ID] == ID_ORCBITER) {
        weakspot.dimX = 45;
        weakspot.dimY = 40;
    } else if (target.aivar[AIV_MM_REAL_ID] == ID_RAZOR)
           || (target.aivar[AIV_MM_REAL_ID] == ID_DRAGONSNAPPER) {
        weakspot.dimX = 40;
        weakspot.dimY = 40;
    } else if (target.aivar[AIV_MM_REAL_ID] == ID_GARGOYLE) {
        // Both panther and fire beast
        weakspot.dimX = 65;
        weakspot.dimY = 60;
    } else if (target.aivar[AIV_MM_REAL_ID] == ID_SNAPPER) {
        weakspot.dimX = 40;
        weakspot.dimY = 35;
    } else if (target.aivar[AIV_MM_REAL_ID] == ID_TROLL) {
        weakspot.dimX = 90;
        weakspot.dimY = 100;
    } else if (target.aivar[AIV_MM_REAL_ID] == ID_TROLL_BLACK) {
        weakspot.dimX = 70;
        weakspot.dimY = 80;
    } else if (target.aivar[AIV_MM_REAL_ID] == ID_KEILER) {
        weakspot.dimX = 60;
        weakspot.dimY = 65;
    } else if (target.aivar[AIV_MM_REAL_ID] == ID_WARG)
           || (target.aivar[AIV_MM_REAL_ID] == ID_ICEWOLF) {
        weakspot.dimX = 40;
        weakspot.dimY = 45;
    } else if (target.guild == GIL_SWAMPSHARK) {
        // Harder to hit
        weakspot.node = "ZS_MOUTH";
        weakspot.dimX = 30;
        weakspot.dimY = 30;
    } else if (target.guild == GIL_ALLIGATOR) {
        weakspot.dimX = 80;
        weakspot.dimY = 60;
    } else if (target.guild == GIL_GIANT_RAT) {
        // All rats (desert, swamp, normal)
        weakspot.dimX = 40;
        weakspot.dimY = 35;
    } else if (target.guild == GIL_GOBBO) {
        weakspot.dimX = 25;
        weakspot.dimY = 25;
    } else if (target.guild == GIL_DEMON)
           || (target.guild == GIL_SUMMONED_DEMON) {
        // Both demon and demon lord
        weakspot.dimX = 35;
        weakspot.dimY = 40;
    } else if (target.guild == GIL_DRACONIAN) {
        weakspot.dimX = 40;
        weakspot.dimY = 40;
    } else if (target.guild == GIL_DRAGON) {
        weakspot.dimX = 60;
        weakspot.dimY = 70;
    } else if (target.guild == GIL_WARAN) {
        weakspot.dimX = 50;
        weakspot.dimY = 50;
    } else if (target.guild == GIL_GIANT_BUG) {
        weakspot.dimX = 30;
        weakspot.dimY = 40;
    } else if (target.guild == GIL_HARPY) {
        weakspot.dimX = 25;
        weakspot.dimY = 25;
    } else if (target.guild == GIL_LURKER) {
        weakspot.dimX = 30;
        weakspot.dimY = 30;
    } else if (target.guild == GIL_MINECRAWLER) {
        weakspot.dimX = 50;
        weakspot.dimY = 50;
    } else if (target.guild == GIL_MOLERAT) {
        weakspot.dimX = 35;
        weakspot.dimY = 30;
    } else if (target.guild == GIL_SCAVENGER) {
        weakspot.dimX = 35;
        weakspot.dimY = 40;
    } else if (target.guild == GIL_SHADOWBEAST) {
        weakspot.dimX = 60;
        weakspot.dimY = 60;
    } else if (target.guild == GIL_SHEEP) {
        weakspot.dimX = 20;
        weakspot.dimY = 25;
    } else if (target.guild == GIL_WOLF)
           || (target.guild == GIL_SUMMONED_WOLF) {
        weakspot.dimX = 25;
        weakspot.dimY = 40;

    } else {
        // Default size for any non-listed monster
        weakspot.dimX = 50; // 50x50cm size
        weakspot.dimY = 50;
    };
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


/*
 * This function is called when a critical hit occurred; but only if free aiming is disabled. It allows to define a
 * critical hit chance even for the standard auto aiming.
 * Although not existing in the original Gothic 2, this is important here to balance the damage output between free aim
 * and auto aim.
 * The return value is a percentage (chance level or hit chance), where 0 is no critical hit ever and and 100 always
 * causes a critical hit. Everything in between is dependent on a respective probability.
 * To disable this feature, simply have the function always return 0.
 *
 * Examples are written below and commented out and serve as inspiration of what is possible.
 */
func int freeAimCriticalHitAutoAim(var C_Npc target, var C_Item weapon, var int talent) {

    // Here, scale the critical hit chance between MIN (0% skill) and MAX (100% skill)
    const int MIN = 10; // With   0% skill, 10% of the hits are critical hits
    const int MAX = 35; // With 100% skill, 35% of the hits are critical hits
    var int critChance; critChance = (MAX-MIN)*talent/100+MIN;

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
