/*
 * Projectile trail strip for increased visibility
 *
 * Gothic Free Aim (GFA) v1.2.0 - Free aiming for the video games Gothic 1 and Gothic 2 by Piranha Bytes
 * Copyright (C) 2016-2019  mud-freak (@szapp)
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

// A copy of the default CFx_Base_Proto, to ensure the defaults
Prototype GFA_CFx_Proto(CFx_Base) {
    visAlpha                = 1;
    emTrjMode_S             = "FIXED";
    emTrjOriginNode         = "ZS_RIGHTHAND";
    emTrjTargetRange        = 10;
    emTrjTargetAzi          = 0;
    emTrjTargetElev         = 0;
    emTrjNumKeys            = 10;
    emTrjNumKeysVar         = 0;
    emTrjAngleElevVar       = 0;
    emTrjAngleHeadVar       = 0;
    emTrjKeyDistVar         = 0;
    emTrjLoopMode_S         = "NONE";
    emTrjEaseFunc_S         = "LINEAR";
    emTrjEaseVel            = 100;
    emTrjDynUpdateDelay     = 2000000;
    emTrjDynUpdateTargetOnly = 0;
    emFXTriggerDelay        = 0;
    emFXCreatedOwnTrj       = 0;
    emCheckCollision        = 0;
    emAdjustShpToOrigin     = 0;
    emInvestNextKeyDuration = 0;
    emFlyGravity            = 0;
    emFXLifeSpan            = -1;
    emSelfRotVel_S          = "0 0 0";
    sendAssessMagic         = 0;
    secsPerDamage           = -1;
};

// Base FX
Instance GFA_TRAIL_VFX (GFA_CFx_Proto) {
    emFXLifeSpan            = 2.0;
};

// NPC is in focus
Instance GFA_TRAIL_VFX_KEY_INVEST_1 (C_ParticleFxEmitKey) { }; // Never reached. Do not remove!

// Projectile is shot
Instance GFA_TRAIL_VFX_KEY_INVEST_2 (C_ParticleFxEmitKey) {
    visname_s               = "GFA_TRAIL";
};

// Projectile collides
Instance GFA_TRAIL_VFX_KEY_INVEST_3 (C_ParticleFxEmitKey) {
    visname_s               = ""; // Remove effect after collision
    pfx_ppsIsLoopingChg     = 1;
};

// Same but simplified for Wld_PlayEffect (used for Gothic 1)
Instance GFA_TRAIL_INST_VFX (GFA_CFx_Proto) {
    visname_s               = "GFA_TRAIL";
    emTrjOriginNode         = "BIP01";
    emFXLifeSpan            = 2.0;
};

// Breaking in impact
Instance GFA_DESTROY_VFX (GFA_CFx_Proto) {
    visname_s               = "GFA_IMPACT";
    emTrjOriginNode         = "BIP01";
    sfxid                   = "GFA_COLLISION_BREAK";
    sfxisambient            = 1;
};
