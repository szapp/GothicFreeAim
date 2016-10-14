/*
 * Free aim projectile trail strip for increase visibility
 *
 * G2 Free Aim - Free aiming for the video game Gothic 2 by Piranha Bytes
 * Copyright (C) 2016  mud-freak (@szapp)
 *
 * This file is part of G2 Free Aim.
 * http://github.com/szapp/g2freeAim
 *
 * G2 Free Aim is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * On redistribution this notice must remain intact and all copies must
 * identify the original author.
 *
 * G2 Free Aim is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with G2 Free Aim.  If not, see <http://www.gnu.org/licenses/>.
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
