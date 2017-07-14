/*
 * Functions that do not exist in Gothic 1 are defined/emulated here
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
 * Constants missing/renamed in Gothic 1
 */
const int   FIGHT_DIST_CANCEL        = HAI_DIST_ABORT_RANGED; // Same, just different name in Gothic 1
const float RANGED_CHANCE_MINDIST    = 1500;                  // For now, taken from Gothic 2, needs to be adjusted:
const float RANGED_CHANCE_MAXDIST    = 4500;                  // How is the hit chance calculated in Gothic 1?
const int   ITEM_NFOCUS              = 1<<23;                 // Same as in Gothic 2 (just not defined in the scripts)


/*
 * Emulate the Gothic 2 external function Npc_GetActiveSpellIsScroll(), oCNpc::GetActiveSpellIsScroll() 0x73D020
 */
func int Npc_GetActiveSpellIsScroll(var C_Npc slf) {
    if (!Npc_IsInFightMode(slf, FMODE_MAGIC)) {
        return 0;
    };

    // Get magic book
    var oCNpc slfOC; slfOC = Hlp_GetNpc(slf);
    if (!slfOC.mag_book) {
        return 0;
    };

    // Retrieve selected spell number from magic book
    const int call = 0;
    var int magBookPtr; magBookPtr = slfOC.mag_book;
    var int spellNr;
    if (CALL_Begin(call)) {
        CALL_PutRetValTo(_@(spellNr));
        CALL__thiscall(_@(magBookPtr), oCMag_Book__GetSelectedSpellNr);
        call = CALL_End();
    };

    // Retrieve spell item from spell number
    const int call2 = 0;
    var int itemPtr;
    if (CALL_Begin(call2)) {
        CALL_IntParam(_@(spellNr));
        CALL_PutRetValTo(_@(itemPtr));
        CALL__thiscall(_@(magBookPtr), oCMag_Book__GetSpellItem);
        call2 = CALL_End();
    };
    if (!itemPtr) {
        return 0;
    };

    // If item is stackable, it is a scroll
    const int call3 = 0;
    if (CALL_Begin(call3)) {
        CALL__thiscall(_@(itemPtr), oCItem__MultiSlot);
        call3 = CALL_End();
    };

    return CALL_RetValAsInt();
};


/*
 * Emulate the Gothic 2 external function Wld_StopEffect(), sub_006E32B0() 0x6E32B0
 */
func void Wld_StopEffect(var string effectName) {
    var int worldPtr; worldPtr = _@(MEM_World);
    if (!worldPtr) {
        return;
    };

    // Create array from all oCVisualFX vobs
    var int vobArrayPtr; vobArrayPtr = MEM_ArrayCreate();
    var zCArray vobArray; vobArray = _^(vobArrayPtr);
    const int call = 0; var int zero;
    if (CALL_Begin(call)) {
        CALL_PtrParam(_@(zero));
        CALL_PtrParam(_@(vobArrayPtr));
        CALL_PtrParam(_@(oCVisualFX__classDef));
        CALL__thiscall(_@(worldPtr), zCWorld__SearchVobListByClass);
        call = CALL_End();
    };

    if (!vobArray.numInArray) {
        MEM_ArrayFree(vobArrayPtr);
        return;
    };

    effectName = STR_Upper(effectName);

    // Search all vobs for the matching name
    var int effectVob; effectVob = 0;
    repeat(i, vobArray.numInArray); var int i;
        var int vobPtr; vobPtr = MEM_ArrayRead(vobArrayPtr, i);
        if (!vobPtr) {
            continue;
        };

        if (Hlp_StrCmp(MEM_ReadString(vobPtr+oCVisualFX_instanceName_offset), effectName)) {
            effectVob = vobPtr;
            break;
        };
    end;
    MEM_ArrayFree(vobArrayPtr);

    // No matching effect found
    if (!effectVob) {
        return;
    };

    // Stop the oCVisualFX
    const int call2 = 0; const int one = 1;
    if (CALL_Begin(call2)) {
        CALL_PtrParam(_@(one));
        CALL__thiscall(_@(effectVob), oCVisualFX__Stop);
        call2 = CALL_End();
    };
};


/*
 * Emulate the Gothic 2 deadalus function C_NpcIsUndead(), based on the specifications in
 * oCSpell::IsTargetTypeValid()+149h 0x47DD09 of Gothic 1
 */
func int C_NpcIsUndead(var C_Npc slf) {
    if (slf.guild == GIL_ZOMBIE)
    || (slf.guild == GIL_UNDEADORC)
    || (slf.guild == GIL_SKELETON) {
        return TRUE;
    };
};
