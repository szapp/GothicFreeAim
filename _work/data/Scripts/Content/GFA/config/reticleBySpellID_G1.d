/*
 * This file is optional and supplementary to the configurations for reticles (see config\reticle.d). It contains
 * exemplary reticles for spells. It is outsourced to maintain compatibility across Gothic 1 and Gothic 2 that have
 * different spells. For a list of reticle textures, see config\reticleTextures.d.
 */


/*
 * This function defines reticles based on spellID for all Gothic 1 specific spells. This is just an example of how to
 * display different reticles.
 *
 * Note: Only spells are listed that are eligible for free aiminig. All other spells will not have a reticle anyways.
 */
func string reticleBySpellID(var int spellID) {
    if (spellID == SPL_Thunderbolt)
    || (spellID == SPL_Icecube) {
        // Ice spells
        return RETICLE_SPADES;
    }
    else if (spellID == SPL_Windfist) {
        // Wind spells
        return GFA_AnimateReticleByTime(RETICLE_WHIRL, 30, 10); // Animate reticle with 30 FPS (10 Frames)
    }
    else if (spellID == SPL_Firebolt)
    || (spellID == SPL_Fireball)
    || (spellID == SPL_Firestorm)
    || (spellID == SPL_Pyrokinesis) {
        // Fire spells
        return RETICLE_HORNS;
    }
    else if (spellID == SPL_Thunderball) {
        // Electric spells
        return RETICLE_BOLTS;
    }
    else if (spellID == SPL_Breathofdeath)
    || (spellID == SPL_Destroyundead)
    || (spellID == SPL_New1) {
        // Evil spells
        return RETICLE_BOWL;
    }
    else if (spellID == SPL_Charm)
    || (spellID == SPL_Sleep)
    || (spellID == SPL_Control)
    || (spellID == SPL_Berzerk)
    || (spellID == SPL_Shrink) {
        // Psyonic spells
        return RETICLE_EDGES;
    } else {
        // Set this as 'default' texture here (if none of the conditions above is met)
        return RETICLE_EDGES;
    };
};
