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


/*
 * Set the spell FX shooting direction. This function hooks oCSpell::Setup to overwrite the target vob with the aim vob
 * that is placed in from of the camera at the nearest intersection with the world or an object.
 */
func void freeAimSetupSpell() {
    var int spellOC; spellOC = EBP;
    var int casterPtr; casterPtr = MEM_ReadInt(spellOC+oCSpell_spellCasterNpc_offset);
    if (!casterPtr) {
        return;
    };

    // Only if caster is player and if FA is enabled
    var C_Npc caster; caster = _^(casterPtr);
    if (!FREEAIM_ACTIVE) || (!Npc_IsPlayer(caster)) {
        return;
    };

    // Check if spell supports free aiming (is eligible)
    var C_Spell spell; spell = _^(spellOC+oCSpell_C_Spell_offset);
    if (!freeAimSpellEligible(spell)) {
        return;
    };

    // Determine the focus type. If focusType is 0, then no focus will be collect, but only an intersection with the
    // world
    var int focusType;
    if (!spell.targetCollectAlgo) {
        focusType = 0;
    } else {
        focusType = spell.targetCollectType;
    };

    // Shoot a trace ray to find the position of the nearest intersection
    var int pos[3];
    freeAimRay(spell.targetCollectRange, focusType, 0, _@(pos), 0, 0);

    // Setup the aim vob
    var int vobPtr; vobPtr = freeAimSetupAimVob(_@(pos));

    // Overwrite target vob
    MEM_WriteInt(ESP+4, vobPtr);
};


/*
 * Manage reticle style and focus collection for magic combat.
 */
func void freeAimSpellReticle() {
    // Only show reticle for spells that support free aiming
    if (FREEAIM_ACTIVE != FMODE_MAGIC) {
        freeAimRemoveReticle();
        return;
    };

    // Retrieve target NPC and the distance to it from the camera(!)
    var C_Spell spell; spell = freeAimGetActiveSpellInst(hero);
    var int distance; var int target;

    if (FREEAIM_FOCUS_COLLECTION) && (spell.targetCollectRange > 0) {
        // Determine the focus type. If focusType is 0, then no focus will be collect, but only an intersection with the
        // world; same if TARGET_COLLECT_NONE. The latter is good for spells like Blink, that do not concern targeting
        var int focusType;
        if (!spell.targetCollectAlgo) || (spell.targetCollectAzi <= 0) || (spell.targetCollectElev <= 0) {
            focusType = 0;
        } else {
            focusType = spell.targetCollectType;
        };

        // Shoot aim trace ray, to retrieve the distance to an intersection and a possible target
        freeAimRay(spell.targetCollectRange, focusType, _@(target), 0, _@(distance), 0);
        distance = roundf(divf(mulf(distance, FLOAT1C), mkf(spell.targetCollectRange))); // Distance scaled to [0, 100]

    } else {
        // FREEAIM_FOCUS_COLLECTION can be set to false (see INI-file) for weaker computers. However, it is not
        // recommended, as there will be NO focus at all (otherwise it would get stuck on NPCs)

        // Remove focus completely
        var oCNpc her; her = Hlp_GetNpc(hero);
        var int herPtr; herPtr = _@(her);
        const int call = 0; const int zero = 0; // Set the focus vob properly: reference counter
        if (CALL_Begin(call)) {
            CALL_PtrParam(_@(zero)); // This will remove the focus
            CALL__thiscall(_@(herPtr), oCNpc__SetFocusVob);
            call = CALL_End();
        };

        // Always remove oCNpc.enemy. With no focus, there is also no target NPC. Caution: This invalidates the use of
        // Npc_GetTarget()
        if (her.enemy) {
            const int call2 = 0; // Remove the enemy properly: reference counter
            if (CALL_Begin(call2)) {
                CALL_PtrParam(_@(zero));
                CALL__thiscall(_@(herPtr), oCNpc__SetEnemy);
                call2 = CALL_End();
            };
        };
        distance = 25; // No distance check ever. Set it to medium distance
        target = 0; // No focus target ever
    };

    // Create reticle
    var int reticlePtr; reticlePtr = MEM_Alloc(sizeof_Reticle);
    var Reticle reticle; reticle = _^(reticlePtr);
    reticle.texture = ""; // Do not show reticle by default
    reticle.color = -1; // Do not set color by default
    reticle.size = 75; // Medium size by default

    // Retrieve reticle specs and draw/update it on screen
    freeAimGetReticleSpell_(target, spell, distance, reticlePtr);
    freeAimInsertReticle(reticlePtr);
    MEM_Free(reticlePtr);
};
