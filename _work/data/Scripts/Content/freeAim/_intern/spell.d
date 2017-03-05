/*
 * Magic combat mechanics
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

/* Set the spell fx direction and trajectory. Hook oCSpell::Setup */
func void freeAimSetupSpell() {
    var int casterPtr; casterPtr = MEM_ReadInt(EBP+52); //0x0034 oCSpell.spellCasterNpc
    if (!casterPtr) { return; }; // No caster
    var C_Npc caster; caster = _^(casterPtr);
    if (FREEAIM_ACTIVE_PREVFRAME != 1) || (!Npc_IsPlayer(caster)) { return; }; // Only if player and if fa WAS active
    var C_Spell spell; spell = _^(EBP+128); //0x0080 oCSpell.C_Spell
    if (!freeAimSpellEligible(spell)) { return; }; // Only with eligible spells
    var int focusType; // No focus display for TARGET_COLLECT_NONE (still focus collection though)
    if (!spell.targetCollectAlgo) { focusType = 0; } else { focusType = spell.targetCollectType; };
    var int pos[3]; freeAimRay(spell.targetCollectRange, focusType, 0, _@(pos), 0, 0);
    var int vobPtr; vobPtr = freeAimSetupAimVob(_@(pos)); // Setup the aim vob
    MEM_WriteInt(ESP+4, vobPtr); // Overwrite target vob
};

/* Manage reticle style and focus collection for magic combat */
func void freeAimSpellReticle() {
    if (!freeAimIsActive()) { freeAimRemoveReticle(); return; }; // Only with eligible spells
    var C_Spell spell; spell = freeAimGetActiveSpellInst(hero);
    var int distance; var int target;
    if (FREEAIM_FOCUS_COLLECTION) && (spell.targetCollectRange > 0) { // Set focus npc if there is a valid one
        var int focusType; // No focus display for TARGET_COLLECT_NONE (still focus collection though)
        if (!spell.targetCollectAlgo) || (spell.targetCollectAzi <= 0) || (spell.targetCollectElev <= 0)
        { focusType = 0; } else { focusType = spell.targetCollectType; };
        freeAimRay(spell.targetCollectRange, focusType, _@(target), 0, _@(distance), 0); // Shoot ray
        distance = roundf(divf(mulf(distance, FLOAT1C), mkf(spell.targetCollectRange))); // Distance scaled to [0, 100]
    } else { // More performance friendly. Here, there will be NO focus, otherwise it gets stuck on npcs.
        var int herPtr; herPtr = _@(hero);
        const int call2 = 0; var int null; // Set the focus vob properly: reference counter
        if (CALL_Begin(call2)) {
            CALL_PtrParam(_@(null)); // This will remove the focus
            CALL__thiscall(_@(herPtr), oCNpc__SetFocusVob);
            call2 = CALL_End();
        };
        if (!MEM_ReadInt(herPtr+1176)) { //0x0498 oCNpc.enemy
            const int call3 = 0; // Remove the enemy properly: reference counter
            if (CALL_Begin(call3)) {
                CALL_PtrParam(_@(null)); // Always remove oCNpc.enemy. With no focus, there is also no target npc
                CALL__thiscall(_@(herPtr), oCNpc__SetEnemy);
                call3 = CALL_End();
            };
        };
        distance = 25; // No distance check ever. Set it to medium distance
        target = 0; // No focus target ever
    };
    var int autoAlloc[7]; var Reticle reticle; reticle = _^(_@(autoAlloc)); // Gothic takes care of freeing this ptr
    MEM_CopyWords(_@s(""), _@(autoAlloc), 5); // reticle.texture (reset string) // Do not show reticle by default
    reticle.color = -1; // Do not set color by default
    reticle.size = 75; // Medium size by default
    freeAimGetReticleSpell_(target, spell, distance, _@(reticle)); // Retrieve reticle specs
    freeAimInsertReticle(_@(reticle)); // Draw/update reticle
};
