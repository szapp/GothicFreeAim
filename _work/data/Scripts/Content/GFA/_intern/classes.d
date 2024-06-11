/*
 * GFA Classes
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


/*
 * Class: Critical hit damage message
 */
const int sizeof_GFA_DmgMsg = 36;

class GFA_DmgMsg {
    var int value;      // Base damage (float)
    var int type;       // Damage type (read-only)
    var int protection; // Protection of target to GFA_DmgMsg.type (read-only)
    var int behavior;   // Damage behavior as defined in const.d (DMG_*)
    var string info;    // Optional debug information
};


/*
 * Class: Reticle definitions
 */
const int sizeof_GFA_Reticle = 28;

class GFA_Reticle {
    var string texture;
    var int size;
    var int color;
};


/*
 * Class: Re-define the C_Spell class under a different name
 */
const int sizeof_GFA_C_Spell = 48;

class GFA_C_Spell {
    var float time_per_mana;
    var int damage_per_level;
    var int damageType;
    var int spellType;
    var int canTurnDuringInvest;
    var int canChangeTargetDuringInvest;
    var int isMultiEffect;
    var int targetCollectAlgo;
    var int targetCollectType;
    var int targetCollectRange;
    var int targetCollectAzi;
    var int targetCollectElev;
};
