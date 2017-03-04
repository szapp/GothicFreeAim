/*
 * Identifying active spell instances and determine if they are eligible for free aiming
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

/* Return the active spell instance */
func MEMINT_HelperClass freeAimGetActiveSpellInst(var C_Npc npc) {
    if (Npc_GetActiveSpell(npc) == -1) {
        var C_Spell ret; ret = MEM_NullToInst();
        MEMINT_StackPushInst(ret);
        return;
    };
    var int magBookPtr; magBookPtr = MEM_ReadInt(_@(npc)+2324); //0x0914 oCNpc.mag_book
    const int call = 0;
    if (CALL_Begin(call)) {
        CALL__thiscall(_@(magBookPtr), oCMag_Book__GetSelectedSpell);
        call = CALL_End();
    };
    _^(CALL_RetValAsPtr()+128); //0x0080 oCSpell.C_Spell
};

/* Return whether a spell is eligible for free aiming */
func int freeAimSpellEligible(var C_Spell spell) {
    if (FREEAIM_DISABLE_SPELLS) || (!_@(spell)) { return FALSE; };
    if (spell.targetCollectAlgo != TARGET_COLLECT_FOCUS_FALLBACK_NONE)
    || (!spell.canTurnDuringInvest) || (!spell.canChangeTargetDuringInvest) {
        return FALSE;
    };
    return TRUE; // All other cases
};
