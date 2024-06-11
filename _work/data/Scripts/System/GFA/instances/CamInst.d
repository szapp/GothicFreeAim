/*
 * Free aim camera mode
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

instance CamModGFA(GFA_CCamSys) {
    bestRange           = 1.8; // Decreased from 2.5
    minRange            = 1.4;
    maxRange            = 5.0; // Decreased from 10.0
    bestElevation       = 23.0; // Decreased from 35.0
    minElevation        = 0.0;
    maxElevation        = 89.0;
    bestAzimuth         = 0.0;
    minAzimuth          = -5.0;
    maxAzimuth          = 5.0;
    bestRotZ            = 0.0;
    minRotZ             = 0.0;
    maxRotZ             = 0.0;
    rotOffsetX          = 23.0; // Increased from 20.0
    rotOffsetY          = 0.0;
    rotOffsetZ          = 0.0;
    targetOffsetY       = 40.0;  // A little up for more visibility
    targetOffsetX       = 15.0;  // A little to the right (make the projectile fly in a straigh line). Most important
    targetOffsetZ       = 0.0;
    translate           = 1;
    rotate              = 1;
    collision           = 1;
    veloTrans           = 40;
    veloRot             = 10000; // More responsive mouse movement (value from CamModFirstPerson)
};
