/*
 * Auxiliary functions including finding the active spell instance and ranged weapon and offering animated reticles
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
 * Overwrite opcode with nop at a span of addresses
 */
func void writeNOP(var int addr, var int len) {
    if (IsHooked(addr)) {
        MEM_Error("Trying to overwrite hook");
        return;
    };
    MemoryProtectionOverride(addr, len);
    repeat(i, len); var int i;
        MEM_WriteByte(addr+i, ASMINT_OP_nop);
    end;
};


/*
 * Return the current NPC instance of the player. If the player is not initialized, return a null pointer. It is
 * recommended to use Hlp_IsValidNpc() afterwards.
 */
func MEMINT_HelperClass getPlayerInst() {
    if (!MEM_ReadInt(oCNpc__player)) {
        var oCNpc ret; ret = MEM_NullToInst();
        MEMINT_StackPushInst(ret);
        return;
    };
    _^(MEM_ReadInt(oCNpc__player));
};


/*
 * Check the inheritance of a zCObject against a zCClassDef. Emulating zCObject::CheckInheritance() at 0x476E30 in G2.
 * This function is used in Wld_StopEffect_Ext().
 *
 * Taken from http://forum.worldofplayers.de/forum/threads/1495001?p=25548652
 */
func int objCheckInheritance(var int objPtr, var int classDef) {
    if (!objPtr) || (!classDef) {
        return 0;
    };

    // Iterate over base classes
    var int curClassDef; curClassDef = MEM_GetClassDef(objPtr);
    while((curClassDef) && (curClassDef != classDef));
        curClassDef = MEM_ReadInt(curClassDef+zCClassDef_baseClassDef_offset);
    end;

    return (curClassDef == classDef);
};


/*
 * Retrieve the active spell instance of an NPC. Returns an empty instance if no spell is drawn. This function is
 * usually called in conjunction with GFA_IsSpellEligible(), see below. It might prove to also be useful outside of GFA.
 */
func MEMINT_HelperClass GFA_GetActiveSpellInst(var C_Npc npc) {
    if (Npc_GetActiveSpell(npc) == -1) {
        // NPC does not have a spell drawn
        var C_Spell ret; ret = MEM_NullToInst();
        MEMINT_StackPushInst(ret);
        return;
    };

    var int npcPtr; npcPtr = _@(npc);
    var oCNpc npcOC; npcOC = _^(npcPtr);

    // Get the magic book to retrieve the active spell
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
 * Retrieve whether a spell is eligible for free aiming (GFA_SPL_FREEAIM), that is, it supports free aiming by its
 * properties, or eligible for free movement (GFA_ACT_MOVEMENT). This function is called to determine whether to
 * activate free aiming or free movement, since not all spells need to have these features, e.g. summoning spells (no
 * free aiming), heal (no free movement).
 * Do not change the properties that make a spell eligible! This is very well thought through and works for ALL Gothic 1
 * and Gothic 2 spells. For new spells, adjust THEIR properties accordingly.
 */
func int GFA_IsSpellEligible(var C_Spell spell) {
    // Exit if the spell instance is invalid
    if (!_@(spell)) {
        return FALSE;
    };

    var int eligibleFor; eligibleFor = 0;
    if (spell.canTurnDuringInvest) && (spell.targetCollectAlgo != TARGET_COLLECT_FOCUS) { // Focus spells face the focus
        // If turning is allowed, the spell supports free movement
        eligibleFor = GFA_ACT_MOVEMENT;

        // Targeting spells support free aiming
        if (spell.canChangeTargetDuringInvest) && (spell.targetCollectAlgo == TARGET_COLLECT_FOCUS_FALLBACK_NONE) {
            eligibleFor = eligibleFor | GFA_SPL_FREEAIM; // == FMODE_MAGIC
        };
    };

    return eligibleFor;
};


/*
 * Returns whether an NPC is currently investing (1), casting (2) or failing (-1) a spell, otherwise 0.
 */
func int GFA_InvestingOrCasting(var C_Npc npc) {
    var int npcPtr; npcPtr = _@(npc);
    var oCNpc npcOC; npcOC = _^(npcPtr);

    // Investing (when the cast fails, the release status is stuck, so also check dontKnowAniPlayed)
    if (!(MEM_ReadInt(npcOC.anictrl+oCAIHuman_bitfield_offset) & oCAIHuman_bitfield_spellReleased))
    && (!(MEM_ReadInt(npcOC.anictrl+oCAIHuman_bitfield_offset) & oCAIHuman_bitfield_dontKnowAniPlayed)) {
        return 1;
    };

    // Casting or failing (check by active animations)
    var int model; model = npcOC._zCVob_visual;
    if (!objCheckInheritance(model, zCModel__classDef)) {
        MEM_Warn("GFA_InvestingOrCasting: NPC has no model visual.");
        return FALSE;
    };

    // Get ID of fail animation
    var int failAniID;
    if (!failAniID) {
        var int aniNamePtr; aniNamePtr = _@s("T_CASTFAIL");
        var zCArray protoTypes; protoTypes = _^(model+zCModel_prototypes_offset);
        var int modelPrototype; modelPrototype = MEM_ReadInt(protoTypes.array);
        const int call = 0;
        if (CALL_Begin(call)) {
            CALL_PutRetValTo(_@(failAniID));
            CALL__fastcall(_@(modelPrototype), _@(aniNamePtr), zCModelPrototype__SearchAniIndex);
            call = CALL_End();
        };
    };

    // Pointer to list of active animations
    var int actAniOffset; actAniOffset = model+zCModel_actAniList_offset;

    // Iterate over active animations
    repeat(i, MEM_ReadInt(model+zCModel_numActAnis_offset)); var int i;
        var int aniID; aniID = MEM_ReadInt(MEM_ReadInt(MEM_ReadInt(actAniOffset))+zCModelAni_aniID_offset);

        if (aniID == MEM_ReadInt(npcOC.anictrl+oCAniCtrl_Human_t_stand_2_cast_offset))
        || (aniID == MEM_ReadInt(npcOC.anictrl+oCAniCtrl_Human_s_cast_offset))
        || (aniID == MEM_ReadInt(npcOC.anictrl+oCAniCtrl_Human_t_cast_2_shoot_offset))
        || (aniID == MEM_ReadInt(npcOC.anictrl+oCAniCtrl_Human_s_shoot_offset))
        || (aniID == MEM_ReadInt(npcOC.anictrl+oCAniCtrl_Human_t_shoot_2_stand_offset)) {
            return 2;
        };

        if (aniID == failAniID) {
            return -1;
        };

        actAniOffset += 4;
    end;

    // Else
    return FALSE;
};


/*
 * This function updates the focus (oCNpc.focus_vob) and the target (oCNpc.enemy) of the player with a new focus. The
 * focus and target can be set to empty, by passing zero as argument.
 */
func void GFA_SetFocusAndTarget(var int focusPtr) {
    var oCNpc her; her = getPlayerInst();
    var int herPtr; herPtr = _@(her);

    // Update the focus vob (properly, mind the reference counter)
    if (focusPtr != her.focus_vob) {
        const int call = 0;
        if (CALL_Begin(call)) {
            CALL_PtrParam(_@(focusPtr)); // If no focus is supplied, this will remove the focus (focusPtr == 0)
            CALL__thiscall(_@(herPtr), oCNpc__SetFocusVob);
            call = CALL_End();
        };
    };

    // Update the enemy NPC (also properly with an engine call)
    if (focusPtr != her.enemy) {
        const int call2 = 0;
        if (CALL_Begin(call2)) {
            CALL_PtrParam(_@(focusPtr));
            CALL__thiscall(_@(herPtr), oCNpc__SetEnemy);
            call2 = CALL_End();
        };
    };

};


/*
 * Wrapper function to retrieve the readied weapon and the respective talent value. This function is called by several
 * other wrapper functions.
 *
 * For Gothic 2, the learned skill level of the respective weapon type is returned as talent, for Gothic 1 the critical
 * hit chance is returned, instead. This is not the hit chance! In Gothic 1 the hit chance is determined by dexterity.
 *
 * Returns 1 on success, 0 otherwise.
 */
func int GFA_GetWeaponAndTalent(var C_Npc slf, var int weaponPtr, var int talentPtr) {
    var int error; error = 0;

    // Get readied/equipped ranged weapon
    var C_Item weapon;
    if (Npc_IsInFightMode(slf, FMODE_FAR)) {
        weapon = Npc_GetReadiedWeapon(slf);
    } else if (Npc_HasEquippedRangedWeapon(slf)) {
        weapon = Npc_GetEquippedRangedWeapon(slf);
    } else {
        MEM_SendToSpy(zERR_TYPE_WARN, "GFA_GetWeaponAndTalent: No valid weapon equipped/readied!");
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
            if (weapon.flags & ITEM_BOW) {
                talent = NPC_TALENT_BOW;
            } else if (weapon.flags & ITEM_CROSSBOW) {
                talent = NPC_TALENT_CROSSBOW;
            } else {
                MEM_SendToSpy(zERR_TYPE_WARN, "GFA_GetWeaponAndTalent: No valid weapon equipped/readied!");
                error = 1;
            };

            if (talent) {
                if (GOTHIC_BASE_VERSION == 1) {
                    // Caution: The hit chance in Gothic 1 is defined by dexterity (same for bow and crossbow). This
                    // function, however, returns the critical hit chance!
                    talent = Npc_GetTalentValue(slf, talent);
                } else {
                    // In Gothic 2 the hit chance is the skill level
                    // talent = slf.hitChance[NPC_TALENT_BOW]; // Cannot write this, because of Gothic 1 compatibility
                    var int slfPtr; slfPtr = _@(slf);
                    var oCNpc slfOC; slfOC = _^(slfPtr);
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
 * for the config functions of GFA. It allows for animated reticles dependent on time.
 * 'numFrames' files must exist with the postfix '_[frameNo].tga', e.g. 'TEXTURE_00.TGA', 'TEXTURE_01.TGA',...
 */
func string GFA_AnimateReticleByTime(var string fileName, var int fps, var int numFrames) {
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
 * for the config functions of GFA. It allows for animated reticles dependent on a given percentage. This is useful to
 * indicate progress of draw force or distance to target or any other gradual property.
 * 'numFrames' files must exist with the postfix '_[frameNo].tga', e.g. 'TEXTURE_00.TGA', 'TEXTURE_01.TGA',...
 */
func string GFA_AnimateReticleByPercent(var string fileName, var int percent, var int numFrames) {
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


/*
 * Scale value x from range [min, max] to range [a, b]. This function is useful for the config functions to scale
 * attributes to a percentage.
 */
func int GFA_ScaleRanges(var int x, var int min, var int max, var int a, var int b) {
    // (b - a) * (x - min)
    // ------------------- + a
    //     max - min
    var int scaled; scaled = (b-a)*(x-min)/(max-min)+a;

    // Correct values falling out of bounce
    if (scaled < a) {
        scaled = a;
    } else if (scaled > b) {
        scaled = b;
    };

    return scaled;
};


/*
 * Emulate the Gothic 2 external function Wld_StopEffect(), with additional settings: Usually it is not clear which
 * effect will be stopped, leading to effects getting "stuck". Here, Wld_StopEffect is extended with additional checks
 * for origin and/or target vob and whether to stop all matching FX or only the first one found (like in Wld_StopEffect)
 * The function returns the number of stopped effects, or zero if none was found or an error occurred.
 * Compatible with Gothic 1 and Gothic 2.
 *
 * Taken from http://forum.worldofplayers.de/forum/threads/1495001?p=25548652
 */
func int Wld_StopEffect_Ext(var string effectName, var int originInst, var int targetInst, var int all) {
    var int worldPtr; worldPtr = _@(MEM_World);
    if (!worldPtr) {
        return 0;
    };

    // Create array from all oCVisualFX vobs
    var int vobArrayPtr; vobArrayPtr = MEM_ArrayCreate();
    var zCArray vobArray; vobArray = _^(vobArrayPtr);
    const int call = 0; var int zero;
    if (CALL_Begin(call)) {
        CALL_PtrParam(_@(zero));                 // Vob tree (0 == globalVobTree)
        CALL_PtrParam(_@(vobArrayPtr));          // Array to store found vobs in
        CALL_PtrParam(_@(oCVisualFX__classDef)); // Class definition
        CALL__thiscall(_@(worldPtr), zCWorld__SearchVobListByClass);
        call = CALL_End();
    };

    if (!vobArray.numInArray) {
        MEM_ArrayFree(vobArrayPtr);
        return 0;
    };

    effectName = STR_Upper(effectName);

    var zCPar_Symbol symb;

    // Validate origin vob instance
    if (originInst) {
        // Get pointer from instance symbol
        if (originInst > 0) && (originInst < MEM_Parser.symtab_table_numInArray) {
            symb = _^(MEM_ReadIntArray(contentSymbolTableAddress, originInst));
            originInst = symb.offset;
        } else {
            originInst = 0;
        };

        if (!objCheckInheritance(originInst, zCVob__classDef)) {
            MEM_Warn("Wld_StopEffect_Ext: Origin is not a valid vob");
            return 0;
        };
    };

    // Validate target vob instance
    if (targetInst) {
        // Get pointer from instance symbol
        if (targetInst > 0) && (targetInst < MEM_Parser.symtab_table_numInArray) {
            symb = _^(MEM_ReadIntArray(contentSymbolTableAddress, targetInst));
            targetInst = symb.offset;
        } else {
            targetInst = 0;
        };

        if (!objCheckInheritance(targetInst, zCVob__classDef)) {
            MEM_Warn("Wld_StopEffect_Ext: Target is not a valid vob");
            return 0;
        };
    };

    // Search all vobs for the matching name
    var int stopped; stopped = 0; // Number of FX stopped
    repeat(i, vobArray.numInArray); var int i;
        var int vobPtr; vobPtr = MEM_ArrayRead(vobArrayPtr, i);
        if (!vobPtr) {
            continue;
        };

        // Search for FX with matching name
        if (!Hlp_StrCmp(effectName, "")) {
            var string effectInst; effectInst = MEM_ReadString(vobPtr+oCVisualFX_instanceName_offset);
            if (!Hlp_StrCmp(effectInst, effectName)) {
                continue;
            };
        };

        // Search for a specific origin vob
        if (originInst) {
            var int originVob; originVob = MEM_ReadInt(vobPtr+oCVisualFX_originVob_offset);
            if (originVob != originInst) {
                continue;
            };
        };

        // Search for a specific target vob
        if (targetInst) {
            var int targetVob; targetVob = MEM_ReadInt(vobPtr+oCVisualFX_targetVob_offset);
            if (targetVob != targetInst) {
                continue;
            };
        };

        // Stop the oCVisualFX
        const int call2 = 0; const int one = 1;
        if (CALL_Begin(call2)) {
            CALL_PtrParam(_@(one));
            CALL__thiscall(_@(vobPtr), oCVisualFX__Stop);
            call2 = CALL_End();
        };
        stopped += 1;

        if (!all) {
            break;
        };
    end;
    MEM_ArrayFree(vobArrayPtr);

    return stopped;
};


/*
 * When dropping dead or unconscious while having a ranged weapon readied, the dropped projectile will not dereference
 * its AI properly, causing an annoying error message box on any consecutive loading (only with GothicStarter_mod.exe)
 * in Gothic 2. Mind, that this bug has nothing to do with GFA, it is already present in the original Gothic 2!
 * Here, the AI will be released (how it should be done), fixing the problem.
 * The problem is not known to affect Gothic 1 (no error message), but the fix does not hurt.
 *
 * In order to hook the engine at this offset, some opcode had to be overwritten to make room for the jump (see init.d).
 * This overwritten code is first rewritten (beginning of this function, labeled 'old').
 */
func void GFA_FixDroppedProjectileAI() {
    // Old: Re-write what has been overwritten with nop (for means of a working hook in constrained address space)
    // .text:0069FA14  028   6A 01             push    1
    // .text:0069FA16  02C   E8 15 2F F6 FF    call    zCVob::SetSleeping(int)
    var int vobPtr; vobPtr = MEM_ReadInt(ESP+40); // esp+28h
    const int call = 0; const int one = 1;
    if (CALL_Begin(call)) {
        CALL_IntParam(_@(one));
        CALL__thiscall(_@(vobPtr), zCVob__SetSleeping);
        call = CALL_End();
    };


    // New: Fix dropped projectile AI bug
    if (!Hlp_Is_oCItem(vobPtr)) {
        return;
    };
    var C_Item itm; itm = _^(vobPtr);

    if (itm.mainflag & ITEM_KAT_MUN) {
        // Release AI of dropped projectiles to fix illegal reference on loading
        const int call3 = 0; var int zero;
        if (CALL_Begin(call3)) {
            CALL_IntParam(_@(zero));
            CALL__thiscall(_@(vobPtr), zCVob__SetAI);
            call3 = CALL_End();
        };
    };
};
