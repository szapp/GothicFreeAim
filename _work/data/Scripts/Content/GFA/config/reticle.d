/*
 * This file contains all configurations for reticles. For a list of reticle textures, see config\reticleTextures.d.
 *
 * Requires the feature GFA_RANGED and/or GFA_SPELLS (see config\settings.d).
 *
 * List of included functions:
 *  func void GFA_GetRangedReticle(C_Npc target, C_Item weapon, int talent, int dist, int returnPtr)
 *  func void GFA_GetSpellReticle(C_Npc target, int spellID, C_Spell spellInst, int spellLevel, ... )
 *
 * Related functions that can be used:
 *  func string GFA_AnimateReticleByTime(string textureFileName, int framesPerSecond, int numberOfFrames)
 *  func string GFA_AnimateReticleByPercent(string textureFileName, int percent, int numberOfFrames)
 */


/*
 * This function is called continuously while aiming with a ranged weapon (bows and crossbows). It allows defining the
 * reticle texture, size and color at any point in time while aiming, based on a variety of properties. Reticle size is
 * represented as a percentage (100 is biggest size, 0 is smallest).
 *
 * Ideas: more sophisticated customization like e.g. change the texture by draw force, the size by accuracy, ...
 * Examples are written below and commented out and serve as inspiration of what is possible.
 *
 * Here, for example, the size is scaled by aiming distance. As indicated by the in-line comments, basing the size (or
 * color) on the functions GFA_GetDrawForce() and GFA_GetAccuracy() is also possible.
 */
func void GFA_GetRangedReticle(var C_Npc target, var C_Item weapon, var int talent, var int dist, var int returnPtr) {
    // Get reticle instance from call-by-reference argument
    var Reticle reticle; reticle = _^(returnPtr);

    // Color (do not set the color to preserve the original texture color)
    if (Hlp_IsValidNpc(target)) {
        // The argument 'target' might be empty!

        /*
        // For now, do not color friendly/angry NPCs color. The reticle stays white (design choice)
        var int att; att = Npc_GetAttitude(target, hero);
        if (att == ATT_HOSTILE) || (att == ATT_ANGRY) {
            reticle.color = Focusnames_Color_Hostile();
        } else if (att == ATT_FRIENDLY) {
            reticle.color = Focusnames_Color_Friendly();
        }; */

    } else {
        // If no NPC is in focus color it slightly gray
        reticle.color = RGBA(175, 175, 175, 255);
    };

    // Size (scale between [0, 100]: 0 is smallest, 100 is biggest)
    reticle.size = -dist + 100; // Inverse aim distance: bigger for closer range: 100 for closest, 0 for most distance
    //  reticle.size = -GFA_GetDrawForce(weapon, talent) + 100; // Or inverse draw force: bigger for less draw force
    //  reticle.size = -GFA_GetAccuracy(weapon, talent) + 100; // Or inverse accuracy: bigger with lower accuracy

    // Change reticle texture by draw force (irrespective of size), but differentiate texture depending on weapon type
    if (weapon.flags & ITEM_BOW) {
        // Get draw force. Already scaled to [0, 100]
        var int drawForce; drawForce = GFA_GetDrawForce(weapon, talent);

        // Animate reticle by draw force
        reticle.texture = GFA_AnimateReticleByPercent(RETICLE_NOTCH, drawForce, 17);

    } else if (weapon.flags & ITEM_CROSSBOW) {
        // Get draw force. Already scaled to [0, 100]
        var int steadyAim; steadyAim = GFA_GetDrawForce(weapon, talent);

        // Animate reticle by draw force
        reticle.texture = GFA_AnimateReticleByPercent(RETICLE_PEAK, steadyAim, 17);

        /*
        // Alternatively, keep the reticle fixed, only resized with distance
        reticle.texture = RETICLE_PEAK; */

        /*
        // Alternatively, change the reticle texture with distance
        reticle.size = 75; // Keep the size fixed here
        reticle.texture = GFA_AnimateReticleByPercent(RETICLE_DROP, dist, 8); // Animate reticle with distance */
    };
};


/*
 * This function is called continuously while aiming with a spells. It allows defining the reticle texture, size and
 * color at any point in time while aiming, based on a variety of spell properties. Reticle size is represented as a
 * percentage (100 is biggest size, 0 is smallest).
 * To hide the reticle (might be of interest for certain spells), set the texture to an empty string.
 *
 * Ideas: more sophisticated customization like e.g. change the texture by spellID, the size by spellLevel, ...
 * Examples are written below and commented out and serve as inspiration of what is possible.
 *
 * Here, for example, the size is scaled by aiming distance. As indicated by the in-line comments, basing the size (or
 * color) on the any provided spell properties is easily possible.
 */
func void GFA_GetSpellReticle(var C_Npc target, var int spellID, var C_Spell spellInst, var int spellLevel,
        var int isScroll, var int manaInvested, var int dist, var int returnPtr) {
    // Get reticle instance from call-by-reference argument
    var Reticle reticle; reticle = _^(returnPtr);

    /*
    // Different reticles by spell type
    if (spellInst.spellType == SPELL_GOOD) {
        reticle.texture = RETICLE_CIRCLECROSS;
    } else if (spellInst.spellType == SPELL_NEUTRAL) {
        reticle.texture = RETICLE_CIRCLECROSS;
    } else if (spellInst.spellType == SPELL_BAD) {
        reticle.texture = RETICLE_CIRCLECROSS;
    }; */

    // The color (do not set the color to preserve the original texture color)
    if (Hlp_IsValidNpc(target)) {
        // The argument 'target' might be empty!

        /*
        // For now, do not color friendly/angry NPCs color. The reticle stays white (design choice)
        var int att; att = Npc_GetAttitude(target, hero);
        if (att == ATT_HOSTILE) || (att == ATT_ANGRY) {
            reticle.color = Focusnames_Color_Hostile();
        } else if (att == ATT_FRIENDLY) {
            reticle.color = Focusnames_Color_Friendly();
        }; */

    } else {
        // If no NPC is in focus color it slightly gray
        reticle.color = RGBA(175, 175, 175, 255);
    };

    // The size (scale between [0, 100]: 0 is smallest, 100 is biggest)
    reticle.size = -dist + 100; // Inverse aim distance: bigger for closer range: 100 for closest, 0 for most distance

    /*
    // Size by spell level for invest spells (e.g. increase size by invest level)
    if (spellLevel < 2) {
        reticle.size = 75;
    } else if (spellLevel >= 2) {
        reticle.size = 100;
    }; */

    /*
    // Different reticle for scrolls
    if (isScroll) {
        reticle.color = RGBA(125, 200, 250, 255); // Light blue
    }; */

    /*
    // Scale size by the amount of mana invested
    reticle.size = manaInvested; // This should still adjusted to be scaled between [0, 100] */

    // Here are examples for reticle textures based on spell names.
    // Keep in mind: This is just a suggestion. In fact, reticles can be defined completely differently, see examples
    // above. Feel free to create more interesting reticles.
    // Note: Only spells are listed that are eligible for free aiming. All other spells will not have a reticle anyways.

    // Exact spell name, e.g. "FIREBOLT"
    var string spellName; spellName = STR_Upper(MEM_ReadStatStringArr(spellFxInstanceNames, spellID));

    if (STR_IndexOf(spellName, "ICE") != -1)
    || (STR_IndexOf(spellName, "THUNDERBOLT") != -1) {
        // Ice spells
        reticle.texture = RETICLE_SPADES;
    } else if (STR_IndexOf(spellName, "WATER") != -1)
    || (STR_IndexOf(spellName, "INFLATE") != -1)
    || (STR_IndexOf(spellName, "GEYSER") != -1)
    || (STR_IndexOf(spellName, "WIND") != -1)
    || (STR_IndexOf(spellName, "STORM") != -1) {
        // Water/wind spells
        reticle.texture = GFA_AnimateReticleByTime(RETICLE_WHIRL, 30, 10); // Animate reticle with 30 FPS (10 Frames)
    } else if (STR_IndexOf(spellName, "FIRE") != -1)
    || (STR_IndexOf(spellName, "PYRO") != -1) {
        // Fire spells
        reticle.texture = RETICLE_HORNS;
    } else if (STR_IndexOf(spellName, "ZAP") != -1)
    || (STR_IndexOf(spellName, "LIGHTNING") != -1)
    || (STR_IndexOf(spellName, "FLASH") != -1)
    || (STR_IndexOf(spellName, "THUNDER") != -1) {
        // Electric spells
        reticle.texture = RETICLE_BOLTS;
    } else if (STR_IndexOf(spellName, "PAL") != -1) {
        // Paladin spells
        reticle.texture = RETICLE_FRAME;
    } else if (STR_IndexOf(spellName, "DEATH") != -1)
    || (STR_IndexOf(spellName, "DESTROYUNDEAD") != -1)
    || (STR_IndexOf(spellName, "MASTEROFDISASTER") != -1)
    || (STR_IndexOf(spellName, "SWARM") != -1)
    || (STR_IndexOf(spellName, "GREENTENTACLE") != -1)
    || (STR_IndexOf(spellName, "ENERGYBALL") != -1)
    || (STR_IndexOf(spellName, "SUCKENERGY") != -1)
    || (STR_IndexOf(spellName, "SKULL") != -1) {
        // Evil spells
        reticle.texture = RETICLE_BOWL;
    } else if (STR_IndexOf(spellName, "CHARM") != -1)
    || (STR_IndexOf(spellName, "SLEEP") != -1)
    || (STR_IndexOf(spellName, "CONTROL") != -1)
    || (STR_IndexOf(spellName, "BERZERK") != -1)
    || (STR_IndexOf(spellName, "SHRINK") != -1) {
        // Psyonic spells
        reticle.texture = RETICLE_EDGES;
    } else {
        // Set this as 'default' texture here (if none of the conditions above is met)
        reticle.texture = RETICLE_EDGES;
    };
};
