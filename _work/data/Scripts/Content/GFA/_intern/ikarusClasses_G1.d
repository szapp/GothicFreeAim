/*
 * Ikarus classes that are not supplied for Gothic 1
 *
 * Gothic Free Aim (GFA) v1.0.0-beta.16 - Free aiming for the video games Gothic 1 and Gothic 2 by Piranha Bytes
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
 * A minimal version of the class zCMaterial. Assumed to be the similar to Gothic 2
 */
class zCMaterial {
//zCObject {
    var int    _vtbl;                   // 0x0000
    var int    _zCObject_refCtr;        // 0x0004
    var int    _zCObject_hashIndex;     // 0x0008
    var int    _zCObject_hashNext;      // 0x000C
    var string _zCObject_objectName;    // 0x0010
//}
    var int    data1[4];                // 0x0024 unknown

    var int    texture;                 // 0x0034 zCTexture*
    var int    color;                   // 0x0038 zCOLOR
    var int    smoothAngle;             // 0x003C zREAL
    var int    matGroup;                // 0x0040 enum zTMat_Group { UNDEF, METAL, STONE, WOOD, EARTH, WATER }

    var int    data3[20];               // 0x0044 unknown
};                                      // 0x0094
