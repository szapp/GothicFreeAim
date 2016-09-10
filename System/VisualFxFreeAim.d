/*
 * Free aim projectile trail strip for increase visibility
 */

INSTANCE freeAim_TRAIL (CFx_Base_Proto) {
    emFXLifeSpan            =   1.0;
};

// NPC is in focus
INSTANCE freeAim_TRAIL_KEY_INVEST_1 (C_ParticleFxEmitKey) { }; // Never reached. Do not remove!

// Projectile is shot
INSTANCE freeAim_TRAIL_KEY_INVEST_2 (C_ParticleFxEmitKey) {
    visname_s               = "FREEAIM_TRAIL";
};

// Projectile collides
INSTANCE freeAim_TRAIL_KEY_INVEST_3 (C_ParticleFxEmitKey) {
    visname_s               = ""; // Remove effect after collision
    pfx_ppsIsLoopingChg     = 1;
};
