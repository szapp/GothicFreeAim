/*
 * GFA Classes
 *
 * Gothic Free Aim (GFA) v1.0.0-beta.17 - Free aiming for the video games Gothic 1 and Gothic 2 by Piranha Bytes
 * Copyright (C) 2016-2017  mud-freak (@szapp)
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
 * Class: Critical hit definitions
 */
const int sizeof_Weakspot = 64;

class Weakspot {
    var string node;
    var int dimX;
    var int dimY;
    var int offset[3]; // Offsets in local space X, Y and Z
    var int bDmg;
    var string debugInfo;
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
