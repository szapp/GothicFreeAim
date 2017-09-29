/*
 * This file contains all configurations for critical hits for bows and crossbows.
 *
 * Requires the feature GFA_CRITICALHITS (see config\settings.d).
 *
 * List of included functions:
 *  func void GFA_GetCriticalHitDefinitions(C_Npc target, C_Item weapon, int talent, int damage, int damageType, ...)
 *  func int GFA_GetCriticalHitAutoAim(C_Npc target, C_Item weapon, int talent)
 *  func void GFA_StartCriticalHitEvent(C_Npc target, C_Item weapon, int freeAimingIsEnabled)
 */


/*
 * This function is called every time (any kind of) NPC is hit by a projectile (arrows and bolts) to determine, whether
 * a critical hit occurred; but only if free aiming is enabled and GFA_TRUE_HITCHANCE == true. For critical hits without
 * free aiming (or scattering) see GFA_GetCriticalHitAutoAim() below.
 *
 * This function here returns a definition of the critical hit zone (weak spot) based on the NPC that it hit or the
 * weapon used. A weak spot is defined by the name of a bone of the model, dimensions and modified damage.
 * This function is dynamic: It is called on every hit and the weak spot and damage can be calculated individually.
 * The damage is a float and represents the new base damage (damage of weapon), not the final damage!
 *
 * Note: This function is specific to free aiming. For critical hits without free aiming see GFA_GetCriticalHitAutoAim()
 *       below.
 *
 * Note: This function only DEFINES the critical hits. It is called every time an NPC is hit. To start an event when a
 *       critical hit actually occurs, see GFA_StartCriticalHitEvent() below.
 *
 * Ideas: incorporate weapon-specific stats, head shot talent, dependency on target, ...
 * Examples are written below and commented out and serve as inspiration of what is possible.
 *
 * Here, preliminary weak spots for almost all Gothic 1 and Gothic 2 monsters are defined (all head shots).
 */
func void GFA_GetCriticalHitDefinitions(var C_Npc target, var C_Item weapon, var int talent, var int damage,
        var int damageType, var int returnPtr) {
    // Get weak spot instance from call-by-reference argument
    var Weakspot weakspot; weakspot = _^(returnPtr);

    // Only allow critical hits, if a non-critical shot would cause damage. Gothic 2 only, Gothic 1 allows critical hits
    // always. This is part of the fighting mechanics
    if (GOTHIC_BASE_VERSION == 2) {
        // Gothic 2: (damage + dexterity > protection of target)
        if (roundf(damage)+hero.attribute[ATR_DEXTERITY] < target.protection[PROT_POINT]) { // G2 takes point protection
            weakspot.debugInfo = "Damage does not exceed protection"; // Debugging info for zSpy (see GFA_DEBUG_PRINT)
            return;
        };
    } else {
        // Gothic 1: Do not signal a critical hit, if the total damage would still not cause damage:
        // (damage * 2 < protection of target)

        // Get protection values from target depending on damage type (is static array)
        var int protection; protection = MEM_ReadStatArr(_@(target.protection), damageType);

        if (roundf(damage)*2 < protection) {
            weakspot.debugInfo = "Critical hit would not exceed protection";
            return;
        };
    };

    // Incorporate the critical hit chance (talent value) for Gothic 1. By aiming and targeting, the talent value in
    // Gothic 1 (which is responsible for the critical hit chance) becomes obsolete. To still have an incentive to
    // learn the higher stages of ranged weapons, an additional probability for critical hits can be imposed here. Keep
    // in mind that critical hits are still determined by aiming, but hits are not considered critical 100% of the time
    if (GOTHIC_BASE_VERSION == 1) {
        if (!talent) {
            // With no learned skill level, there are no critical hits (just like in the original Gothic 1)
            weakspot.debugInfo = "Critical hits not yet learned, critical hit chance = 0% (see character menu)";
            return;
        } else if (talent < 25) {
            // Stage 1: Only 50% of the positive hits are in fact critical
            weakspot.debugInfo = "First level critical hit chance (see character menu), adjusted to 50-50 chance";
            if (Hlp_Random(100) < 50) { // Approx. 50-50 chance
                return;
            };
        }; // Else stage 2: All positive hits on the weak spot are critical hits (no change)
    };

    // In case this helps with differentiating between NPC types:
    var zCPar_Symbol sym; sym = _^(MEM_GetSymbolByIndex(Hlp_GetInstanceID(target)));
    var string instName; instName = sym.name; // Exact instance name in upper case, e.g. "ORCWARRIOR_LOBART1"

    /*
    // The damage may depend on the target NPC (e.g. different damage for monsters). Make use of 'target' for that
    if (target.guild < GIL_SEPERATOR_HUM) {
        // ...
    }; */

    /*
    // The weapon can also be considered (e.g. weapon specific damage). Make use of 'weapon' for that
    // Caution: Weapon may have been unequipped already at this time (unlikely)! Use Hlp_IsValidItem(weapon)
    if (Hlp_IsValidItem(weapon)) {
        if (weapon.certainProperty > 10) { // E.g. special case for weapon property
            // ...
        };
    }; */

    // Here, simply increase the base damage for ALL creatures. Keep in mind: This could be individual, however.
    if (GOTHIC_BASE_VERSION == 1) {
        // In Gothic 1, critical hits receive weapon damage x2 (this is the default)
        weakspot.bDmg = mulf(damage, castToIntf(2.0)); // This is a float
    } else {
        // In Gothic 2, there are no critical hits for ranged combat by default. Here, x1.5 seems more reasonable,
        // because in Gothic 2, the dexterity is added to weapon damage.
        weakspot.bDmg = mulf(damage, castToIntf(1.5)); // This is a float
    };


    // For example, define the critical hits as head shots for all creatures.
    // Keep in mind: This is just a suggestion. In fact, critical hits can be of any bone of the model and completely
    // different for all creatures. So can the damage. Feel free to create more interesting weak spots.
    weakspot.node = "Bip01 Head"; // Upper/lower case is not important, but spelling and spaces are

    // Add an exception for metal armors (paladin armor) - Gothic 2 only, because there are no helmets in Gothic 1
    if (GOTHIC_BASE_VERSION == 2) && (target.guild < GIL_SEPERATOR_HUM) && (Npc_HasEquippedArmor(target)) {
        var C_Item armor; armor = Npc_GetEquippedArmor(target);
        if (armor.material == MAT_METAL)    // Armor is made out of metal
        && (!Npc_CanSeeNpc(target, hero)) { // Target is not facing the player (helmets do not cover the face)
            weakspot.node = ""; // Disable the critical hit his way
            weakspot.debugInfo = "Metal armors protect from head shots (except for the face)";
        };
    };
};


/*
 * This function is called every time (any kind of) NPC is hit by a projectile (arrows and bolts) to determine, whether
 * a critical hit occurred; but only if free aiming is disabled, not active (game settings) or
 * GFA_TRUE_HITCHANCE == false. For critical hits with free aiming see GFA_GetCriticalHitDefinitions() above.
 *
 * This function here allows to define a critical hit chance even for the standard auto aiming. Although not existing in
 * the original Gothic 2, this is important here to balance the damage output between free aim and auto aim, as free aim
 * can be disabled in the game options during a running game.
 *
 * Note: This is not necessary for Gothic 1, as it already has critical hits for auto aiming by default. Nevertheless,
 *       the original critical hit calculation of Gothic 1 is disabled and replaced by this function. This way, the
 *       critical hit chance can be manipulated if desired. The lines of code below for Gothic 1 are the same as default
 *       by Gothic.
 *
 * The return value is a percentage (chance level or hit chance), where 0 is no critical hit ever and and 100 always
 * causes a critical hit. Everything in between is dependent on a respective probability.
 * To disable this feature, simply have the function always return 0.
 *
 * Note: This function is only called if free aiming is disabled, not active (game settings) or
 *       GFA_TRUE_HITCHANCE == false. For critical hits with free aiming see GFA_GetCriticalHitDefinitions() above.
 *
 * Ideas: scale critical hit chance with player skill and distance, ...
 * Some examples are written below (section of Gothic 2) and commented out and serve as inspiration of what is possible.
 */
func int GFA_GetCriticalHitAutoAim(var C_Npc target, var C_Item weapon, var int talent) {
    if (GOTHIC_BASE_VERSION == 1) {
        // Gothic 1 already has a critical hit chance by default. Here, it is just preserved
        return talent;

    } else {
        // For Gothic 2 the critical hit chance for auto aim can be introduced here

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
        var int critChance; critChance = GFA_ScaleRanges(talent, 0, 100, min, max);

        /*
        // The critical hit chance may depend on the target NPC. Make use of 'target' for that
        if (target.guild < GIL_SEPERATOR_HUM) {
            // ...
        }; */

        /*
        // The weapon can also be considered (e.g. weapon specific print). Make use of 'weapon' for that
        // Caution: Weapon may have been unequipped already at this time (unlikely)! Use Hlp_IsValidItem(weapon)
        if (Hlp_IsValidItem(weapon)) {
            if (weapon.certainProperty > 10) { // E.g. special case for weapon property
                // ...
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
};


/*
 * This function is called when a critical hit occurred and can be used to print something to the screen, play a sound
 * jingle or, as done here by default, show a hit marker. Leave this function blank for no event.
 * This function is also called when free aiming is disabled, depending on the configuration in
 * GFA_GetCriticalHitAutoAim(), see above. It can be checked, whether free aiming is enabled with 'freeAimingIsEnabled'.
 *
 * Idea: The critical hits could be counted here to give an XP reward after 25 head shots, print to screen, ...
 * Examples are written below and commented out and serve as inspiration of what is possible.
 */
func void GFA_StartCriticalHitEvent(var C_Npc target, var C_Item weapon, var int freeAimingIsEnabled) {
    /*
    // The event may depend on the target NPC (e.g. different sound for monsters). Make use of 'target' for that
    if (target.guild < GIL_SEPERATOR_HUM) {
        // ...
    }; */

    /*
    // The weapon can also be considered (e.g. weapon specific print). Make use of 'weapon' for that
    // Caution: Weapon may have been unequipped already at this time (unlikely)! Use Hlp_IsValidItem(weapon)
    if (Hlp_IsValidItem(weapon)) {
        if (weapon.certainProperty > 10) { // E.g. special case for weapon property
            // ...
        };
    }; */

    /*
    // Simple screen notification
    PrintS("Critical hit"); */

    // Shooter-like hit marker
    if (freeAimingIsEnabled) {
        // Only show the hit marker if free aiming is enabled (this function is also called for auto aim critical hits)
        var int hitMarker;
        if (!Hlp_IsValidHandle(hitMarker)) {
            // Create it (if it does not exist) in the center of the screen
            var zCView screen; screen = _^(MEM_Game._zCSession_viewport);
            hitMarker = View_CreateCenterPxl(screen.psizex/2, screen.psizey/2, // Coordinates
                GFA_RETICLE_MAX_SIZE, GFA_RETICLE_MAX_SIZE);                   // Dimensions

            // Get 7th frame of animated texture as static texture
            View_SetTexture(hitMarker, GFA_AnimateReticleByPercent(RETICLE_TRI_IN, 100, 7));
        };
        View_Open(hitMarker);

        // Hide the hit marker after 300 ms
        FF_ApplyExtData(View_Close, 300, 1, hitMarker);
    };

    // Sound notification
    Snd_Play3D(target, "GFA_CRITICALHIT_SFX");
};
