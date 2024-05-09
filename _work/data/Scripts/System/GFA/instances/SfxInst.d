/*
 * Critical hit sound for projectiles
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

instance GFA_CRITICALHIT_SFX(GFA_C_SFX) {
    file        = "BOW_FIRE_02.WAV";
    vol         = 60;
    reverbLevel = 1;
};

instance GFA_COLLISION_BREAK(GFA_C_SFX) {
    file        = "PICKLOCK_BROKEN.WAV";
    vol         = 50;
    reverbLevel = 1;
};
