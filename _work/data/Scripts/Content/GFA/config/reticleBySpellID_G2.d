/*
 * This file is optional and supplementary to the configurations for reticles (see config\reticle.d). It contains
 * exemplary reticles for spells. It is outsourced to maintain compatibility across Gothic 1 and Gothic 2 that have
 * different spells. For a list of reticle textures, see config\reticleTextures.d.
 */


/*
 * This function defines reticles based on spellID for all Gothic 2 specific spells. This is just an example of how to
 * display different reticles.
 *
 * Note: Only spells are listed that are eligible for free aiminig. All other spells will not have a reticle anyways.
 */
func string reticleBySpellID(var int spellID) {
    if (spellID == SPL_Icebolt)
    || (spellID == SPL_IceCube)
    || (spellID == SPL_IceLance) {
        // Ice spells
        return RETICLE_SPADES;
    }
    else if (spellID == SPL_Whirlwind)
    || (spellID == SPL_WaterFist)
    || (spellID == SPL_Inflate)
    || (spellID == SPL_Geyser)
    || (spellID == SPL_Waterwall) {
        // Water spells
        return GFA_AnimateReticleByTime(RETICLE_WHIRL, 30, 10); // Animate reticle with 30 FPS (10 Frames)
    }
    else if (spellID == SPL_Firebolt)
    || (spellID == SPL_InstantFireball)
    || (spellID == SPL_ChargeFireball)
    || (spellID == SPL_Pyrokinesis)
    || (spellID == SPL_Firestorm) {
        // Fire spells
        return RETICLE_HORNS;
    }
    else if (spellID == SPL_Zap)
    || (spellID == SPL_LightningFlash)
    || (spellID == SPL_ChargeZap) {
        // Electric spells
        return RETICLE_BOLTS;
    }
    else if (spellID == SPL_PalHolyBolt)
    || (spellID == SPL_PalRepelEvil)
    || (spellID == SPL_PalDestroyEvil) {
        // Paladin spells
        return RETICLE_FRAME;
    }
    else if (spellID == SPL_BreathOfDeath)
    || (spellID == SPL_MasterOfDisaster)
    || (spellID == SPL_Swarm)
    || (spellID == SPL_GreenTentacle)
    || (spellID == SPL_Energyball)
    || (spellID == SPL_SuckEnergy)
    || (spellID == SPL_Skull) {
        // Evil spells
        return RETICLE_BOWL;
    } else {
        // Set this as 'default' texture here (if none of the conditions above is met)
        return RETICLE_EDGES;
    };
};
