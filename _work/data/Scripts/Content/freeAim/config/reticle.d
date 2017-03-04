/*
 * This file contains all configurations for reticles.
 */

/*
 * This a list of available reticle textures by default. Feel free to extend this list with your own textures. Some of
 * them are animated as indicated. Animated textures can be passed to the following functions:
 *  reticle.texture = freeAimAnimateReticleByTime(textureFileName, framesPerSecond, numberOfFrames)
 *  reticle.texture = freeAimAnimateReticleByPercent(textureFileName, 100, numberOfFrames) // Where 100 is a percentage
 */
const string RETICLE_DOT           = "RETICLEDOT.TGA";
const string RETICLE_CROSSTWO      = "RETICLECROSSTWO.TGA";
const string RETICLE_CROSSTHREE    = "RETICLECROSSTHREE.TGA";
const string RETICLE_CROSSFOUR     = "RETICLECROSSFOUR.TGA";
const string RETICLE_X             = "RETICLEX.TGA";
const string RETICLE_CIRCLE        = "RETICLECIRCLE.TGA";
const string RETICLE_CIRCLECROSS   = "RETICLECIRCLECROSS.TGA";
const string RETICLE_DOUBLECIRCLE  = "RETICLEDOUBLECIRCLE.TGA";       // Can be animated (rotation)  10 Frames [00..09]
const string RETICLE_PEAK          = "RETICLEPEAK.TGA";
const string RETICLE_NOTCH         = "RETICLENOTCH.TGA";              // Can be animated (expanding) 17 Frames [00..16]
const string RETICLE_TRI_IN        = "RETICLETRIIN.TGA";              // Can be animated (expanding) 17 Frames [00..16]
const string RETICLE_TRI_IN_DOT    = "RETICLETRIINDOT.TGA";           // Can be animated (expanding) 17 Frames [00..16]
const string RETICLE_TRI_OUT_DOT   = "RETICLETRIOUTDOT.TGA";          // Can be animated (expanding) 17 Frames [00..16]
const string RETICLE_DROP          = "RETICLEDROP.TGA";               // Can be animated (expanding)  8 Frames [00..07]
const string RETICLE_FRAME         = "RETICLEFRAME.TGA";
const string RETICLE_EDGES         = "RETICLEEDGES.TGA";
const string RETICLE_BOWL          = "RETICLEBOWL.TGA";
const string RETICLE_HORNS         = "RETICLEHORNS.TGA";
const string RETICLE_BOLTS         = "RETICLEBOLTS.TGA";
const string RETICLE_BLAZE         = "RETICLEBLAZE.TGA";              // Can be animated (flames)    10 Frames [00..09]
const string RETICLE_WHIRL         = "RETICLEWHIRL.TGA";              // Can be animated (rotation)  10 Frames [00..09]
const string RETICLE_BRUSH         = "RETICLEBRUSH.TGA";
const string RETICLE_SPADES        = "RETICLESPADES.TGA";
const string RETICLE_SQUIGGLE      = "RETICLESQUIGGLE.TGA";

/*
 * This function is called continuously while aiming with a ranged weapon (bows and crossbows). It allows defining the
 * reticle texture, size and color at any point in time while aiming, based on a variety of properties. Reticle size is
 * represented as a percentage (100 is biggest size, 0 is smallest).
 * Here, the size is scaled by aiming distance. As indicated by the in-line comments basing the size (or color) on the
 * functions freeAimGetDrawForce and freeAimGetAccuracy is also possible.
 */
func void freeAimGetReticleRanged(var C_Npc target, var C_Item weapon, var int talent, var int dist, var int rtrnPtr) {
    var Reticle reticle; reticle = _^(rtrnPtr);
    // Color (do not set the color to preserve the original texture color)
    if (Hlp_IsValidNpc(target)) { // The argument 'target' might be empty!
        var int att; att = Npc_GetAttitude(target, hero);
        if (att == ATT_FRIENDLY) { reticle.color = Focusnames_Color_Friendly(); }
        else if (att == ATT_HOSTILE) { reticle.color = Focusnames_Color_Hostile(); };
    };
    // Size (scale between [0, 100]: 0 is smallest, 100 is biggest)
    reticle.size = -dist + 100; // Inverse aim distance: bigger for closer range: 100 for closest, 0 for most distance
    //  reticle.size = -freeAimGetDrawForce(weapon, talent) + 100; // Or inverse draw force: bigger for less draw force
    //  reticle.size = -freeAimGetAccuracy(weapon, talent) + 100; // Or inverse accuracy: bigger with lower accuracy
    // More sophisticated customization is also possible: change the texture by draw force, the size by accuracy, ...
    if (weapon.flags & ITEM_BOW) { // Change reticle texture by drawforce (irrespective of the reticle size set above)
        var int drawForce; drawForce = freeAimGetDrawForce(weapon, talent); // Already scaled between [0, 100]
        reticle.texture = freeAimAnimateReticleByPercent(RETICLE_NOTCH, drawForce, 17); // Animate reticle by draw force
    } else if (weapon.flags & ITEM_CROSSBOW) { // Change reticle texture by distance
        reticle.size = 75; // Keep the size fixed here
        reticle.texture = freeAimAnimateReticleByPercent(RETICLE_DROP, dist, 8); // Animate reticle by distance
    };
};

/*
 * This function is called continuously while aiming with a spells. It allows defining the reticle texture, size and
 * color at any point in time while aiming, based on a variety of spell properties. Reticle size is represented as a
 * percentage (100 is biggest size, 0 is smallest).
 * Here, the size is scaled by aiming distance. As indicated by the in-line comments basing the size (or color) on the
 * any provided spell property is easily possible.
 */
func void freeAimGetReticleSpell(var C_Npc target, var int spellID, var C_Spell spellInst, var int spellLevel,
        var int isScroll, var int manaInvested, var int dist, var int rtrnPtr) {
    var Reticle reticle; reticle = _^(rtrnPtr);
    // 1. Texture (needs to be set, otherwise reticle will not be displayed)
    //  if (spellInst.spellType == SPELL_GOOD) { reticle.texture = RETICLE_CIRCLECROSS; }
    //  else if (spellInst.spellType == SPELL_NEUTRAL) { reticle.texture = RETICLE_CIRCLECROSS; }
    //  else if (spellInst.spellType == SPELL_BAD) { reticle.texture = RETICLE_CIRCLECROSS; };
    // 2. Color (do not set the color to preserve the original texture color)
    if (Hlp_IsValidNpc(target)) { // The argument 'target' might be empty!
        var int att; att = Npc_GetAttitude(target, hero);
        if (att == ATT_FRIENDLY) { reticle.color = Focusnames_Color_Friendly(); }
        else if (att == ATT_HOSTILE) { reticle.color = Focusnames_Color_Hostile(); };
    };
    // 3. Size (scale between [0, 100]: 0 is smallest, 100 is biggest)
    reticle.size = -dist + 100; // Inverse aim distance: bigger for closer range: 100 for closest, 0 for most distance
    // More sophisticated customization is also possible: change the texture by spellID, the size by spellLevel, ...
    // Size by spell level for invest spells (e.g. increase size by invest level)
    //  if (spellLevel < 2) { reticle.size = 75; }
    //  else if (spellLevel >= 2) { reticle.size = 100; };
    // Different reticle for scrolls
    //  if (isScroll) { reticle.color = RGBA(125, 200, 250, 255); }; // Light blue
    // Scale size by the amount of mana invested
    //  reticle.size = manaInvested; // This should be scaled between [0, 100]
    // One possibility is to set the reticle texture by grouping the spells, as it is done below
    // Ice spells
    if (spellID == SPL_Icebolt)
    || (spellID == SPL_IceCube)
    || (spellID == SPL_IceLance) {
        reticle.texture = RETICLE_SPADES;
    } // Water spells
    else if (spellID == SPL_WaterFist)
    || (spellID == SPL_Inflate)
    || (spellID == SPL_Geyser)
    || (spellID == SPL_Waterwall) {
        reticle.texture = freeAimAnimateReticleByTime(RETICLE_WHIRL, 30, 10); // Animate reticle with 30 FPS (10 Frames)
    } // Fire spells
    else if (spellID == SPL_Firebolt)
    || (spellID == SPL_InstantFireball)
    || (spellID == SPL_ChargeFireball)
    || (spellID == SPL_Pyrokinesis)
    || (spellID == SPL_Firestorm) {
        reticle.texture = RETICLE_HORNS;
    } // Electric spells
    else if (spellID == SPL_Zap)
    || (spellID == SPL_LightningFlash)
    || (spellID == SPL_ChargeZap) {
        reticle.texture = freeAimAnimateReticleByTime(RETICLE_BLAZE, 15, 10); // Animate reticle with 15 FPS (10 Frames)
    } // Paladin spells
    else if (spellID == SPL_PalHolyBolt)
    || (spellID == SPL_PalRepelEvil)
    || (spellID == SPL_PalDestroyEvil) {
        reticle.texture = RETICLE_FRAME;
    } // Evil spells
    else if (spellID == SPL_BreathOfDeath)
    || (spellID == SPL_MasterOfDisaster)
    || (spellID == SPL_Energyball)
    || (spellID == SPL_Skull) {
        reticle.texture = RETICLE_BOWL;
    } else {
        reticle.texture = RETICLE_EDGES; // Set this as "default" texture here (if none of the conditions above is met)
    };
};
