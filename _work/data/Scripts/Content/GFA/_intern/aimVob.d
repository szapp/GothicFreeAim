/*
 * Definition and manipulation of aim vob (targeting system)
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
 * Detach the visual FX from the aim vob. This function should go hand in hand with attaching a visual FX: If you attach
 * an FX, you should make sure to remove the FX, when it is no longer needed. Some precautions are already taken from
 * the side of GFA. This function is called on every weapon change, specifically in GFA_ResetOnWeaponSwitch().
 */
func void GFA_AimVobDetachFX() {
    if (!GFA_AimVobHasFX) {
        // This check increases performance (at least for Gothic 1)
        return;
    };

    // Retrieve vob by name
    var int vobPtr; vobPtr = MEM_SearchVobByName("AIMVOB");
    if (!vobPtr) {
        return;
    };

    if (GOTHIC_BASE_VERSION == 1) {
        // In Gothic 1 there are no item effects
        var C_Item vob; vob = _^(vobPtr);
        Wld_StopEffect_Ext("", vob, 0, TRUE); // Remove all effects "from" the aim vob
        Wld_StopEffect_Ext("", 0, vob, TRUE); // Remove all effects "to" the aim vob
    } else {
        // Remove item FX immediately
        const int call = 0;
        if (CALL_Begin(call)) {
            CALL__thiscall(_@(vobPtr), oCItem__RemoveEffect);
            call = CALL_End();
        };

        // Clear the FX property
        MEM_WriteString(vobPtr+oCItem_effect_offset, "");
    };

    GFA_AimVobHasFX = 0;
};


/*
 * Attach a visual FX to the aim vob. This function is never used internally, but is useful for spells that visualize
 * the aim vob. An example is the spell blink.
 */
func void GFA_AimVobAttachFX(var string effectInst) {
    // Retrieve vob by name
    var int vobPtr; vobPtr = MEM_SearchVobByName("AIMVOB");
    if (!vobPtr) {
        return;
    };

    if (GFA_AimVobHasFX) {
        GFA_AimVobDetachFX();
    };

    if (GOTHIC_BASE_VERSION == 1) {
        // In Gothic 1 there are no item effects
        var C_Item vob; vob = _^(vobPtr);
        Wld_PlayEffect(effectInst, vob, vob, 0, 0, 0, FALSE);
    } else {
        // Gothic 2: Set the oCItem FX property
        MEM_WriteString(vobPtr+oCItem_effect_offset, effectInst);

        // Start the FX
        const int call = 0;
        if (CALL_Begin(call)) {
            CALL__thiscall(_@(vobPtr), oCItem__InsertEffect);
            call = CALL_End();
        };
    };

    GFA_AimVobHasFX = 1;
};


/*
 * Manipulate the position of the aim vob (only for spells). This function is called from GFA_SetupAimVob() and only
 * works for spells, as they might incorporate the aim vob into the spell's mechanics or visuals. An example is the
 * spell blink, which shifts the aim vob away from walls. To do this, adjust the config: GFA_ShiftAimVob().
 */
func void GFA_AimVobManipulatePos(var int posPtr) {
    var int spell; spell = Npc_GetActiveSpell(hero);
    if (spell == -1) {
        return;
    };

    // Check whether aim vob should be shifted
    var int shifted; shifted = GFA_ShiftAimVob(spell, posPtr);

    if (shifted) {
        shifted = mkf(shifted); // Amount to shift the aim vob along the out vector of the camera

        // Get camera vob
        var zCVob camVob; camVob = _^(MEM_Game._zCSession_camVob);
        var zMAT4 camPos; camPos = _^(_@(camVob.trafoObjToWorld[0]));

        // Manipulate the position
        MEM_WriteInt(posPtr, addf(MEM_ReadInt(posPtr), mulf(camPos.v0[zMAT4_outVec], shifted)));
        MEM_WriteInt(posPtr+4, addf(MEM_ReadInt(posPtr+4), mulf(camPos.v1[zMAT4_outVec], shifted)));
        MEM_WriteInt(posPtr+8, addf(MEM_ReadInt(posPtr+8), mulf(camPos.v2[zMAT4_outVec], shifted)));
    };
};


/*
 * Retrieve/create aim vob and optionally update its position. This function is constantly called to get the pointer of
 * the aim vob and to reposition it. Manipulating the aim vob from outside of free aiming SHOULD NOT BE DONE. This is
 * an internal mechanic and it should not be touched.
 * The aim vob is acutally an oCItem, to be focusable for spells.
 */
func int GFA_SetupAimVob(var int posPtr) {
    // Retrieve vob by name
    var int vobPtr; vobPtr = MEM_SearchVobByName("AIMVOB");

    // Create vob if it does not exit
    if (!vobPtr) {
        if (GFA_DEBUG_PRINT) {
            MEM_Info("GFA_SetupAimVob: Creating aim vob."); // Should be printed only once ever (each world)
        };

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
        // Copy rotation from the player model (not necessary for free aiming, but might be important for some spells)
        var oCNpc her; her = getPlayerInst();
        MEM_CopyBytes(_@(her)+zCVob_trafoObjToWorld_offset, vobPtr+zCVob_trafoObjToWorld_offset, sizeof_zMAT4);

        // Additionally shift the vob (for certain spells, adjust in GFA_ShiftAimVob())
        GFA_AimVobManipulatePos(posPtr);

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
