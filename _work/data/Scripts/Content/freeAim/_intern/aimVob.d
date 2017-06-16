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

/*
 * Retrieve/create aim vob and optionally update its position.
 */
func int freeAimSetupAimVob(var int posPtr) {
    // Retrieve vob by name
    var int vobPtr; vobPtr = MEM_SearchVobByName("AIMVOB");

    // Create vob if it does not exit
    if (!vobPtr) {
        MEM_Info("freeAimSetupAimVob: Creating aim vob."); // Should be printed only once ever (each world)

        // This actually allocates the memory, so no need to care about freeing
        CALL__cdecl(oCItem___CreateNewInstance);
        vobPtr = CALL_RetValAsPtr();

        // Set up vob properties
        var zCVob vob; vob = _^(vobPtr);
        vob._zCObject_objectName = "AIMVOB";

        // Insert into world
        CALL_PtrParam(_@(MEM_Vobtree));
        CALL_PtrParam(vobPtr);
        CALL__thiscall(_@(MEM_World), oCWorld__AddVobAsChild);

        // Ignored by trace ray, no collision
        vob.bitfield[0] = 3105;
    };

    // Update position and rotation
    if (posPtr) {
        MEM_CopyBytes(_@(hero)+60, vobPtr+60, 64); // Copy rotation from player model
        freeAimManipulateAimVobPos(posPtr); // Additionally shift the vob (for certain spells)

        // Reposition the vob
        const int call = 0;
        if (CALL_Begin(call)) {
            CALL_PtrParam(_@(posPtr));
            CALL__thiscall(_@(vobPtr), zCVob__SetPositionWorld);
            call = CALL_End();
        };
    };
    return vobPtr;
};
