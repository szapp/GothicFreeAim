/*
 * Constants and (external) functions that do not exist in Gothic 1
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
 * Missing/rename constants in Gothic 1
 */
const int   FIGHT_DIST_CANCEL        = HAI_DIST_ABORT_RANGED; // Same, just different name in Gothic 1
const float RANGED_CHANCE_MINDIST    = 1500;                  // Taken from Gothic 2 (does not exist in Gothic 1)
const float RANGED_CHANCE_MAXDIST    = 4500;
const int   ITEM_NFOCUS              = 1<<23;                 // Same as in Gothic 2 (just not defined in the scripts)


/*
 * Emulate the Gothic 2 external function Npc_GetActiveSpellIsScroll()
 * Gothic 2: oCNpc::GetActiveSpellIsScroll() 0x73D020
 */
func int Npc_GetActiveSpellIsScroll(var C_Npc slf) {
    var int slfPtr; slfPtr = _@(slf);
    var oCNpc slfOC; slfOC = _^(slfPtr);

    if (slfOC.fmode != FMODE_MAGIC) {
        return 0;
    };

    // Get magic book
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
 * Emulate the Gothic 2 external function Wld_StopEffect()
 * Gothic 2: sub_006E32B0() 0x6E32B0
 */
func void Wld_StopEffect(var string effectName) {
    Wld_StopEffect_Ext(effectName, 0, 0, 0);
};


/*
 * Emulate the Gothic 2 deadalus function C_NpcIsUndead(), based on the specifications in
 * Gothic 1: oCSpell::IsTargetTypeValid()+149h 0x47DD09
 */
func int C_NpcIsUndead(var C_Npc slf) {
    if (slf.guild == GIL_ZOMBIE)
    || (slf.guild == GIL_UNDEADORC)
    || (slf.guild == GIL_SKELETON) {
        return TRUE;
    };
};
