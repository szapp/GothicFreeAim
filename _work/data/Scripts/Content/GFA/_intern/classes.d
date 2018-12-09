/*
 * GFA Classes
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


/*
 * Class: Critical hit damage message
 */
const int sizeof_DmgMsg = 36;

class DmgMsg {
    var int value;      // Base damage (float)
    var int type;       // Damage type (read-only)
    var int protection; // Protection of target to DmgMsg.type (read-only)
    var int behavior;   // Damage behavior as defined in const.d (DMG_*)
    var string info;    // Optional debug information
};


/*
 * Class: Reticle definitions
 */
const int sizeof_Reticle = 28;

class Reticle {
    var string texture;
    var int size;
    var int color;
};
