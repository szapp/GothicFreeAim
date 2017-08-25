/*
 * Free aiming mechanics for spell combat
 *
 * Gothic Free Aim (GFA) v1.0.0-alpha - Free aiming for the video games Gothic 1 and Gothic 2 by Piranha Bytes
 * Copyright (C) 2016-2017  mud-freak (@szapp)
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
 * Set the spell FX shooting direction. This function hooks oCSpell::Setup() to overwrite the target vob with the aim
 * vob that is placed in front of the camera at the nearest intersection with the world or an object.
 */
func void GFA_SetupSpell() {
    var int spellOC; spellOC = MEMINT_SwitchG1G2(ESI, EBP);
    var int casterPtr; casterPtr = MEM_ReadInt(spellOC+oCSpell_spellCasterNpc_offset);
    if (!casterPtr) {
        return;
    };

    // Only if caster is player and if free aiming is enabled
    var C_Npc caster; caster = _^(casterPtr);
    if (!GFA_ACTIVE) || (!Npc_IsPlayer(caster)) {
        return;
    };

    // Check if spell supports free aiming (is eligible)
    var C_Spell spell; spell = _^(spellOC+oCSpell_C_Spell_offset);
    if (!GFA_IsSpellEligible(spell)) {
        return;
    };

    // Determine focus type. If focusType == 0, then no focus will be collect, but only an intersection with the world
    var int focusType;
    if (!spell.targetCollectAlgo) {
        focusType = 0;
    } else {
        focusType = spell.targetCollectType;
    };

    // Shoot a trace ray to find the position of the nearest intersection
    var int pos[3];
    GFA_AimRay(spell.targetCollectRange, focusType, 0, _@(pos), 0, 0);

    // Setup the aim vob
    var int vobPtr; vobPtr = GFA_SetupAimVob(_@(pos));

    // Overwrite target vob
    MEM_WriteInt(ESP+4, vobPtr);
};


/*
 * Manage reticle style and focus collection for spell combat during aiming. This function hooks oCAIHuman::MagicMode(),
 * but exits right away if the active spell does not support free aiming or if the player is not currently aiming.
 */
func void GFA_SpellAiming() {
    var C_Spell spell; spell = GFA_GetActiveSpellInst(hero);

    // Only show reticle for spells that support free aiming and during aiming (Gothic 1 controls)
    if (GFA_ACTIVE != FMODE_MAGIC) {
        GFA_RemoveReticle();
        GFA_AimVobDetachFX();
        if (GFA_ACTIVE) {
            if (GFA_IsSpellEligible(spell)) {
                if (GFA_NO_AIM_NO_FOCUS) {
                    GFA_SetFocusAndTarget(0);
                };

                // Allow to stop strafing (not to start strafing, that causes weird behavior)
                if (GFA_IsStrafing) {
                    GFA_Strafe();
                };

            } else if (spell.targetCollectAlgo != TARGET_COLLECT_FOCUS)
                   && (spell.targetCollectAlgo != TARGET_COLLECT_FOCUS_FALLBACK_CASTER) {
                // Remove focus for spells that do not need to collect a focus
                GFA_SetFocusAndTarget(0);
            };
        };
        return;
    };

    var int distance;
    var int target;

    if (spell.targetCollectRange > 0) {
        // Determine the focus type. If focusType == 0, then no focus will be collected, but only an intersection with
        // the world; same for TARGET_COLLECT_NONE. The latter is good for spells like Blink, that are not concerned
        // with targeting but only with aiming distance
        var int focusType;
        if (!spell.targetCollectAlgo) || (spell.targetCollectAzi <= 0) || (spell.targetCollectElev <= 0) {
            focusType = 0;
        } else {
            focusType = spell.targetCollectType;
        };

        // Shoot aim ray, to retrieve the distance to an intersection and a possible target
        GFA_AimRay(spell.targetCollectRange, focusType, _@(target), 0, _@(distance), 0);
        distance = roundf(divf(mulf(distance, FLOAT1C), mkf(spell.targetCollectRange))); // Distance scaled to [0, 100]

    } else {
        // No focus collection (this condition is necessary for light and teleport spells)
        GFA_SetFocusAndTarget(0);

        // No distance check ever. Set it to medium distance
        distance = 25;
        target = 0;
    };

    // Create reticle
    var int reticlePtr; reticlePtr = MEM_Alloc(sizeof_Reticle);
    var Reticle reticle; reticle = _^(reticlePtr);
    reticle.texture = ""; // Do not show reticle by default
    reticle.color = -1; // Do not set color by default
    reticle.size = 75; // Medium size by default

    // Retrieve reticle specs and draw/update it on screen
    GFA_GetSpellReticle_(target, spell, distance, reticlePtr);
    GFA_InsertReticle(reticlePtr);
    MEM_Free(reticlePtr);

    // Allow strafing only for Gothic 1 controls or when investing the spell (Gothic 2 controls)
    if (GOTHIC_CONTROL_SCHEME == 2) {
        var oCAniCtrl_Human aniCtrl; aniCtrl = _^(ECX);
        if (aniCtrl.oCAIHuman_bitfield & oCAIHuman_bitfield_spellReleased) {
            return;
        };
    };
    GFA_Strafe();
};


/*
 * Lock the player in place and prevent movement during aiming in spell combat. This function hooks the end of
 * oCAIHuman::MagicMode() to overwrite, whether casting is active or not, to disable any consecutive movement in
 * oCAIHuman::_WalkCycle().
 */
func void GFA_SpellLockMovement() {
    if (GFA_ACTIVE != FMODE_MAGIC) {
        return;
    };

    // When using Gothic 2 controls, do not lock movement when not investing the spell (free to move)
    if (GOTHIC_CONTROL_SCHEME == 2) {
        var oCAniCtrl_Human aniCtrl; aniCtrl = _^(ESI);
        if (aniCtrl.oCAIHuman_bitfield & oCAIHuman_bitfield_spellReleased) {
            EAX = 0;
            return;
        };
    };

    // Set return value to one: Do not call any other movement functions
    EAX = 1;
};
