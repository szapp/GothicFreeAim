/*
 * Free aim camera mode
 *
 * G2 Free Aim v0.1.1 - Free aiming for the video game Gothic 2 by Piranha Bytes
 * Copyright (C) 2016  mud-freak (@szapp)
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

INSTANCE CamModFreeAim (CCamSys_Def)
{
    bestRange           = 1.8; // Decrease from 2.5
    minRange            = 1.4;
    maxRange            = 5.0; // Decreased from 10.0
    bestElevation       = 23.0; // Decreased from 35.0
    minElevation        = 0.0;
    maxElevation        = 89.0;
    bestAzimuth         = 0.0;
    minAzimuth          = -90.0;
    maxAzimuth          = 90.0;
    rotOffsetX          = 23.0; // Increased from 20.0
    rotOffsetY          = 0.0;
    targetOffsetY       = 40.0;  // A little up for more visibility
    targetOffsetX       = 15.0;  // A little to the right (make the projectile fly in a straigh line). Most important
};
