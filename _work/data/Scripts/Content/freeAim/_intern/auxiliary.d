/*
 * Auxiliary functions for finding active spell instances, weapons and offering animated reticles
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
    if (!FREEAIM_SPELLS) || (!_@(spell)) {
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


/*
 * Wrapper function to retrieve the readied weapon and the respective talent value. This function is called by several
 * other wrapper functions.
 * Returns 1 on success, 0 otherwise.
 */
func int freeAimGetWeaponTalent(var int weaponPtr, var int talentPtr) {
    var C_Npc slf; slf = Hlp_GetNpc(hero);
    var int error; error = 0;

    // Get readied/equipped ranged weapon
    var C_Item weapon;
    if (Npc_IsInFightMode(slf, FMODE_FAR)) {
        weapon = Npc_GetReadiedWeapon(slf);
    } else if (Npc_HasEquippedRangedWeapon(slf)) {
        weapon = Npc_GetEquippedRangedWeapon(slf);
    } else {
        MEM_Warn("freeAimGetWeaponTalent: No valid weapon equipped/readied!");
        weapon = MEM_NullToInst();
        error = 1;
    };
    if (weaponPtr) {
        MEM_WriteInt(weaponPtr, _@(weapon));
    };

    // Distinguish between (cross-)bow talent
    if (talentPtr) {
        var int talent; talent = 0;
        if (!error) {

            // Difference between Gothic 1 and Gothic 2: Hit chance is dexterity or talent value, respectively
            if (GOTHIC_BASE_VERSION == 1) {
                // Gothic 1: Hit chance is dexterity (same for bow and crossbow)
                talent = hero.attribute[ATR_DEXTERITY];

            } else {
                // Gothic 2: Hit chance is talent value (differentiate between bow and crossbow)
                if (weapon.flags & ITEM_BOW) {
                    talent = NPC_TALENT_BOW;
                } else if (weapon.flags & ITEM_CROSSBOW) {
                    talent = NPC_TALENT_CROSSBOW;
                } else {
                    MEM_Warn("freeAimGetWeaponTalent: No valid weapon equipped/readied!");
                    error = 1;
                };

                if (talent) {
                    // talent = slf.hitChance[NPC_TALENT_BOW]; // Cannot write this, because of Gothic 1 compatibility
                    var oCNpc slfOC; slfOC = Hlp_GetNpc(slf);
                    talent = MEM_ReadStatArr(_@(slfOC)+oCNpc_hitChance_offset, talent);
                };
            };
        };
        MEM_WriteInt(talentPtr, talent);
    };

    return !error;
};


/*
 * Return texture file name for an animated texture. This function is not used internally, but is offered as a feature
 * for the config functions of g2freeAim. It allows for animated reticles dependent on time.
 * 'numFrames' files must exist with the postfix '_[frameNo].tga', e.g. 'TEXTURE_00.TGA', 'TEXTURE_01.TGA',...
 */
func string freeAimAnimateReticleByTime(var string fileName, var int fps, var int numFrames) {
    // Time of one frame
    var int frameTime; frameTime = 1000/fps;

    // Cycle through [0, numFrames-1] by time
    var int cycle; cycle = (MEM_Timer.totalTime % (frameTime*numFrames)) / frameTime;

    // Base name (without extension)
    var string prefix; prefix = STR_SubStr(fileName, 0, STR_Len(fileName)-4);

    // Add leading zero
    var string postfix;
    if (cycle < 10) {
        postfix = ConcatStrings("0", IntToString(cycle));
    } else {
        postfix = IntToString(cycle);
    };

    return ConcatStrings(ConcatStrings(ConcatStrings(prefix, "_"), postfix), ".TGA");
};


/*
 * Return texture file name for an animated texture. This function is not used internally, but is offered as a feature
 * for the config functions of g2freeAim. It allows for animated reticles dependent on a given percentage. This is
 * useful to indicate progress of draw force or distance to target or any gradual spell property.
 * 'numFrames' files must exist with the postfix '_[frameNo].tga', e.g. 'TEXTURE_00.TGA', 'TEXTURE_01.TGA',...
 */
func string freeAimAnimateReticleByPercent(var string fileName, var int percent, var int numFrames) {
    // Cycle through [0, numFrames-1] by percentage
    var int cycle; cycle = roundf(mulf(mkf(percent), divf(mkf(numFrames-1), FLOAT1C)));

    // Base name (without extension)
    var string prefix; prefix = STR_SubStr(fileName, 0, STR_Len(fileName)-4);

    // Add leading zero
    var string postfix;
    if (cycle < 10) {
        postfix = ConcatStrings("0", IntToString(cycle));
    } else {
        postfix = IntToString(cycle);
    };

    return ConcatStrings(ConcatStrings(ConcatStrings(prefix, "_"), postfix), ".TGA");
};
