/*
 * Free aim camera mode
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

INSTANCE CamModGFA (CCamSys_Def)
{
    bestRange           = 1.8; // Decreased from 2.5
    minRange            = 1.4;
    maxRange            = 5.0; // Decreased from 10.0
    bestElevation       = 23.0; // Decreased from 35.0
    minElevation        = 0.0;
    maxElevation        = 89.0;
    bestAzimuth         = 0.0;
    minAzimuth          = -5.0;
    maxAzimuth          = 5.0;
    rotOffsetX          = 23.0; // Increased from 20.0
    rotOffsetY          = 0.0;
    targetOffsetY       = 40.0;  // A little up for more visibility
    targetOffsetX       = 15.0;  // A little to the right (make the projectile fly in a straigh line). Most important
    veloTrans           = 40;
    veloRot             = 10000; // More responsive mouse movement (value from CamModFirstPerson)
};
