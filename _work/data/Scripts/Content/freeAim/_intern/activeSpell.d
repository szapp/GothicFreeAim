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


/*
 * Retrieve the active spell instance of an NPC. Returns an empty instance if no spell is drawn. This function is
 * usually called in conjunction with freeAimSpellEligible(), see below. It might prove to be useful outside of
 * g2freeAim.
 */
func MEMINT_HelperClass freeAimGetActiveSpellInst(var C_Npc npc) {
    if (Npc_GetActiveSpell(npc) == -1) {
        // NPC does not have a spell drawn
        var C_Spell ret; ret = MEM_NullToInst();
        MEMINT_StackPushInst(ret);
        return;
    };

    // Get the magic book to retrieve the active spell
    var oCNpc npcOC; npcOC = Hlp_GetNpc(npc);
    var int magBookPtr; magBookPtr = npcOC.mag_book;
    const int call = 0;
    if (CALL_Begin(call)) {
        CALL__thiscall(_@(magBookPtr), oCMag_Book__GetSelectedSpell);
        call = CALL_End();
    };

    // This returns an oCSpell instance. Add an offset to retrieve the C_Spell instance
    _^(CALL_RetValAsPtr()+oCSpell_C_Spell_offset);
};


/*
 * Retrieve whether a spell is eligible for free aiming, that is supports free aiming by its properties. This function
 * is called to determine whether to activate free aiming, since not all spell need to have this feature, e.g. summoning
 * spells.
 * Do not change the properties that make a spell eligible! This is very well thought through and works for ALL Gothic 2
 * spells. For new spells, adjust their properties accordingly.
 */
func int freeAimSpellEligible(var C_Spell spell) {
    if (FREEAIM_DISABLE_SPELLS) || (!_@(spell)) {
        // If free aiming is disabled for spells or if the spell instance is invalid
        return FALSE;
    };

    if (spell.targetCollectAlgo != TARGET_COLLECT_FOCUS_FALLBACK_NONE) // Do not change this property!
    || (!spell.canTurnDuringInvest) || (!spell.canChangeTargetDuringInvest) {
        // If the target collection is not done by focus collection with fall back 'none' or if turning is disabled
        // It might be tempting to change TARGET_COLLECT_FOCUS_FALLBACK_NONE into something else, but free aiming will
        // break this way, as a focus NEEDS to be enabled, but not fixed. No other target collection algorithm suffices.
        return FALSE;
    };

    // All other cases
    return TRUE;
};
