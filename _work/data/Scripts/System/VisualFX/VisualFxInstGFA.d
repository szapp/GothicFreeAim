/*
 * Projectile trail strip for increased visibility
 *
 * Gothic Free Aim (GFA) v1.1.0 - Free aiming for the video games Gothic 1 and Gothic 2 by Piranha Bytes
 * Copyright (C) 2016-2018  mud-freak (@szapp)
 *
 * This file is part of Gothic Free Aim.
 * <http://github.com/szapp/GothicFreeAim>
 *
 * Gothic Free Aim is free software: you can redistribute it and/or
 * modify it under the terms of the MIT License.
 * On redistribution this notice must remain intact and all copies must
 * identify the original author.
 *
 * Gothic Free Aim is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * MIT License for more details.
 *
 * You should have received a copy of the MIT License along with
 * Gothic Free Aim.  If not, see <http://opensource.org/licenses/MIT>.
 */

INSTANCE GFA_TRAIL_VFX (CFx_Base_Proto) {
    emFXLifeSpan            = 2.0;
};

// NPC is in focus
INSTANCE GFA_TRAIL_VFX_KEY_INVEST_1 (C_ParticleFxEmitKey) { }; // Never reached. Do not remove!

// Projectile is shot
INSTANCE GFA_TRAIL_VFX_KEY_INVEST_2 (C_ParticleFxEmitKey) {
    visname_s               = "GFA_TRAIL";
};

// Projectile collides
INSTANCE GFA_TRAIL_VFX_KEY_INVEST_3 (C_ParticleFxEmitKey) {
    visname_s               = ""; // Remove effect after collision
    pfx_ppsIsLoopingChg     = 1;
};

// Same but simplified for Wld_PlayEffect (used for Gothic 1)
INSTANCE GFA_TRAIL_INST_VFX (CFx_Base_Proto) {
    visname_s               = "GFA_TRAIL";
    emTrjOriginNode         = "BIP01";
    emFXLifeSpan            = 2.0;
};

INSTANCE GFA_DESTROY_VFX (CFx_Base_Proto) {
    visname_s               = "GFA_IMPACT";
    emTrjOriginNode         = "BIP01";
    sfxid                   = "PICKLOCK_BROKEN";
    sfxisambient            = 1;
};
