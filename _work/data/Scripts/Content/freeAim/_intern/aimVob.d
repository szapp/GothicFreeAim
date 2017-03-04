/*
 * Definition and manipulation of aim vob (targeting system)
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

/* Attach an FX to the aim vob */
func void freeAimAttachFX(var string effectInst) {
    var int vobPtr; vobPtr = MEM_SearchVobByName("AIMVOB");
    if (!vobPtr) { return; };
    MEM_WriteString(vobPtr+564, effectInst); // oCItem.effect
    const int call = 0;
    if (CALL_Begin(call)) {
        CALL__thiscall(_@(vobPtr), oCItem__InsertEffect);
        call = CALL_End();
    };
};

/* Detach the FX of the aim vob */
func void freeAimDetachFX() {
    var int vobPtr; vobPtr = MEM_SearchVobByName("AIMVOB");
    if (!vobPtr) { return; };
    if (Hlp_StrCmp(MEM_ReadString(vobPtr+564), "")) { return; };
    const int call = 0;
    if (CALL_Begin(call)) {
        CALL__thiscall(_@(vobPtr), oCItem__RemoveEffect);
        call = CALL_End();
    };
    MEM_WriteString(vobPtr+564, ""); // oCItem.effect
};

/* Manipulate the position of the aim vob (only for spells) */
func void freeAimManipulateAimVobPos(var int posPtr) {
    var int spell; spell = Npc_GetActiveSpell(hero);
    if (spell == -1) { return; };
    MEM_PushIntParam(spell);
    MEM_Call(freeAimShiftAimVob);
    var int pushed; pushed = MEM_PopIntResult();
    if (pushed) {
        pushed = mkf(pushed); // Amount to push the aim vob along the out vector of the camera
        var zMAT4 camPos; camPos = _^(MEM_ReadInt(MEM_ReadInt(MEMINT_oGame_Pointer_Address)+20)+60);
        MEM_WriteInt(posPtr+0, addf(MEM_ReadInt(posPtr+0), mulf(camPos.v0[2], pushed)));
        MEM_WriteInt(posPtr+4, addf(MEM_ReadInt(posPtr+4), mulf(camPos.v1[2], pushed)));
        MEM_WriteInt(posPtr+8, addf(MEM_ReadInt(posPtr+8), mulf(camPos.v2[2], pushed)));
    };
};

/* Create and set aim vob to position */
func int freeAimSetupAimVob(var int posPtr) {
    var int vobPtr; vobPtr = MEM_SearchVobByName("AIMVOB"); // Arrow needs target vob
    if (!vobPtr) { // Does not exist
        MEM_Info("freeAimSetupAimVob: Creating aim vob."); // Should be printed only once ever
        CALL__cdecl(oCItem___CreateNewInstance); // This actually allocates the memory, so no need to care about freeing
        vobPtr = CALL_RetValAsPtr();
        MEM_WriteString(vobPtr+16, "AIMVOB"); // zCVob._zCObject_objectName
        CALL_PtrParam(_@(MEM_Vobtree));
        CALL_PtrParam(vobPtr);
        CALL__thiscall(_@(MEM_World), oCWorld__AddVobAsChild);
        MEM_WriteInt(vobPtr+260, 3105); // zCVob.bitfield[0] (ignored by trace ray, no collision)
    };
    MEM_CopyBytes(_@(hero)+60, vobPtr+60, 64); // Include rotation
    freeAimManipulateAimVobPos(posPtr); // Shift the aim vob (if desired)
    const int call4 = 0; // Set position to aim vob
    if (CALL_Begin(call4)) {
        CALL_PtrParam(_@(posPtr)); // Update aim vob position
        CALL__thiscall(_@(vobPtr), zCVob__SetPositionWorld);
        call4 = CALL_End();
    };
    return vobPtr;
};
