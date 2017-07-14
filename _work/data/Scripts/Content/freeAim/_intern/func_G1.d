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
 * Emulate the Gothic 2 external function
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
