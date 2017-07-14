/*
 * Projectile trail strip for increased visibility
 *
 * G2 Free Aim v1.0.0-alpha - Free aiming for the video game Gothic 2 by Piranha Bytes
 * Copyright (C) 2016-2017  mud-freak (@szapp)
 *
 * This file is part of G2 Free Aim.
 * <http://github.com/szapp/g2freeAim>
 *
 * G2 Free Aim is free software: you can redistribute it and/or modify
 * it under the terms of the MIT License.
 * On redistribution this notice must remain intact and all copies must
 * identify the original author.
 *
 * G2 Free Aim is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * MIT License for more details.
 *
 * You should have received a copy of the MIT License
 * along with G2 Free Aim.  If not, see <http://opensource.org/licenses/MIT>.
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

INSTANCE freeAim_DESTROY (CFx_Base_Proto) {
    visname_s               = "FREEAIM_IMPACT";
    emTrjOriginNode         = "BIP01";
    sfxid                   = "PICKLOCK_BROKEN";
    sfxisambient            = 1;
};
