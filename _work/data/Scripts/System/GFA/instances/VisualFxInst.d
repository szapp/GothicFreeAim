/*
 * Projectile trail strip for increased visibility
 *
 * This file is part of Gothic Free Aim.
 * Copyright (C) 2016-2024  Sören Zapp (aka. mud-freak, szapp)
 * https://github.com/szapp/GothicFreeAim
 *
 * Gothic Free Aim is free software: you can redistribute it and/or
 * modify it under the terms of the MIT License.
 * On redistribution this notice must remain intact and all copies must
 * identify the original author.
 */

// Base FX
instance GFA_TRAIL_VFX(GFA_CFx_Base) {
    emFXLifeSpan            = 2.0;
    // Basics
    visAlpha                = 1;
    emTrjMode_S             = "FIXED";
    emTrjOriginNode         = "ZS_RIGHTHAND";
    emTrjTargetRange        = 10;
    emTrjNumKeys            = 10;
    emTrjLoopMode_S         = "NONE";
    emTrjEaseFunc_S         = "LINEAR";
    emTrjEaseVel            = 100;
    emTrjDynUpdateDelay     = 2000000;
    emFXLifeSpan            = -1;
    emSelfRotVel_S          = "0 0 0";
    secsPerDamage           = -1;
};

// NPC is in focus
instance GFA_TRAIL_VFX_KEY_INVEST_1(GFA_C_ParticleFxEmitKey) { }; // Never reached. Do not remove!

// Projectile is shot
instance GFA_TRAIL_VFX_KEY_INVEST_2(GFA_C_ParticleFxEmitKey) {
    visname_s               = "GFA_TRAIL";
};

// Projectile collides
instance GFA_TRAIL_VFX_KEY_INVEST_3(GFA_C_ParticleFxEmitKey) {
    visname_s               = ""; // Remove effect after collision
    pfx_ppsIsLoopingChg     = 1;
};

// Same but simplified for Wld_PlayEffect (used for Gothic 1)
instance GFA_TRAIL_INST_VFX(GFA_CFx_Base) {
    visname_s               = "GFA_TRAIL";
    emTrjOriginNode         = "BIP01";
    emFXLifeSpan            = 2.0;
    // Basics
    visAlpha                = 1;
    emTrjMode_S             = "FIXED";
    emTrjOriginNode         = "ZS_RIGHTHAND";
    emTrjTargetRange        = 10;
    emTrjNumKeys            = 10;
    emTrjLoopMode_S         = "NONE";
    emTrjEaseFunc_S         = "LINEAR";
    emTrjEaseVel            = 100;
    emTrjDynUpdateDelay     = 2000000;
    emFXLifeSpan            = -1;
    emSelfRotVel_S          = "0 0 0";
    secsPerDamage           = -1;
};

// Breaking in impact
instance GFA_DESTROY_VFX(GFA_CFx_Base) {
    visname_s               = "GFA_IMPACT";
    emTrjOriginNode         = "BIP01";
    sfxid                   = "GFA_COLLISION_BREAK";
    sfxisambient            = 1;
    // Basics
    visAlpha                = 1;
    emTrjMode_S             = "FIXED";
    emTrjOriginNode         = "ZS_RIGHTHAND";
    emTrjTargetRange        = 10;
    emTrjNumKeys            = 10;
    emTrjLoopMode_S         = "NONE";
    emTrjEaseFunc_S         = "LINEAR";
    emTrjEaseVel            = 100;
    emTrjDynUpdateDelay     = 2000000;
    emFXLifeSpan            = -1;
    emSelfRotVel_S          = "0 0 0";
    secsPerDamage           = -1;
};
