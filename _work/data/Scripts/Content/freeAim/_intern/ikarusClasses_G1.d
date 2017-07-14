/*
 * Ikarus classes that are not supplied for Gothic 1
 *
 * G2 Free Aim v0.1.2 - Free aiming for the video game Gothic 2 by Piranha Bytes
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


/*
 * A minimal version of the class zCMaterial. Assumed to be the same size as in Gothic 2
 */
class zCMaterial {
//zCObject {
    var int    _vtbl;                   // 0x0000
    var int    _zCObject_refCtr;        // 0x0004
    var int    _zCObject_hashIndex;     // 0x0008
    var int    _zCObject_hashNext;      // 0x000C
    var string _zCObject_objectName;    // 0x0010
//}
    var int data1[4];                   // 0x0024 unkown

    var int texture;                    // 0x0034 zCTexture*
    var int data2;                      // 0x0038 unkown
    var int matGroup;                   // 0x0040 zTMat_Group

    var int data3[20];                  // 0x0044 unkown
};                                      // 0x0094
