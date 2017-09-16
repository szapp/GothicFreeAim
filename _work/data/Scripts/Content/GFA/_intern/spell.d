/*
 * Free aiming mechanics for spell combat
 *
 * Gothic Free Aim (GFA) v1.0.0-beta - Free aiming for the video games Gothic 1 and Gothic 2 by Piranha Bytes
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
    var int aniCtrlPtr; aniCtrlPtr = ECX;

    // Only show reticle for spells that support free aiming and during aiming (Gothic 1 controls)
    if (GFA_ACTIVE != FMODE_MAGIC) {
        GFA_RemoveReticle();

        // Additional settings if free aiming is enabled
        if (GFA_ACTIVE) {
            if (GFA_IsSpellEligible(spell)) {
                // Remove FX from aim vob when casting is complete
                if (!GFA_InvestingOrCasting(hero)) {
                    GFA_AimVobDetachFX();
                };

                // Remove focus and target
                if (GFA_NO_AIM_NO_FOCUS) {
                    GFA_SetFocusAndTarget(0);
                };

                // Remove movement animations when not aiming
                GFA_AimMovement(0, "");

            } else if (spell.targetCollectAlgo != TARGET_COLLECT_FOCUS)
                   && (spell.targetCollectAlgo != TARGET_COLLECT_FOCUS_FALLBACK_CASTER) {
                // Remove focus for spells that do not need to collect a focus
                GFA_SetFocusAndTarget(0);
                GFA_AimVobDetachFX();
            };
        } else {
            GFA_AimVobDetachFX();
        };
        return;
    };

    // For safety: Clean up, in case custom spells are recklessly designed
    if (!GFA_InvestingOrCasting(hero)) {
        GFA_AimVobDetachFX();
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

    // Allow strafing
    GFA_Strafe();

    // Remove turning animations (player model sometimes gets stuck in turning animation)
    if (GOTHIC_CONTROL_SCHEME == 2) && (!GFA_STRAFING) {
        // Do not remove turning animations when strafing is disabled and player is not investing/casting
        if (!GFA_InvestingOrCasting(hero))
        && (!MEM_KeyPressed(MEM_GetKey("keyAction"))) && (!MEM_KeyPressed(MEM_GetSecondaryKey("keyAction"))) {
            return;
        };
    };
    var zCAIPlayer playerAI; playerAI = _^(aniCtrlPtr);
    var int model; model = playerAI.model;
    const int twenty = 20;
    const int call = 0;
    if (CALL_Begin(call)) {
        CALL_IntParam(_@(twenty));
        CALL_IntParam(_@(twenty));
        CALL__thiscall(_@(model), zCModel__FadeOutAnisLayerRange);
        call = CALL_End();
    };
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

    if (GOTHIC_CONTROL_SCHEME == 1) {
        // Set return value to one: Do not call any other movement functions
        EAX = 1;
        return;
    };

    // For Gothic 2 controls completely lock movement for spell combat with a few exceptions
    if (!GFA_InvestingOrCasting(hero)) {
        var oCNpc her; her = Hlp_GetNpc(hero);
        var int aniCtrlPtr; aniCtrlPtr = her.anictrl; // ESI is popped earlier and is not secure to use

        // Weapon switch when not investing or casting
        if (MEM_KeyPressed(MEM_GetKey("keyWeapon"))) || (MEM_KeyPressed(MEM_GetSecondaryKey("keyWeapon"))) {
            GFA_AimMovement(0, "");
            return;
        };

        // If sneaking when not investing or casting
        if (!MEM_KeyPressed(MEM_GetKey("keyAction"))) && (!MEM_KeyPressed(MEM_GetSecondaryKey("keyAction")))
        && (MEM_ReadInt(aniCtrlPtr+oCAniCtrl_Human_walkmode_offset) & NPC_SNEAK) {
            GFA_AimMovement(0, "");
            return;
        };

        // Running/walking forward when not investing or casting
        if (!MEM_KeyPressed(MEM_GetKey("keyAction")))      && (!MEM_KeyPressed(MEM_GetSecondaryKey("keyAction")))
        && (!MEM_KeyPressed(MEM_GetKey("keyStrafeLeft")))  && (!MEM_KeyPressed(MEM_GetSecondaryKey("keyStrafeLeft")))
        && (!MEM_KeyPressed(MEM_GetKey("keyStrafeRight"))) && (!MEM_KeyPressed(MEM_GetSecondaryKey("keyStrafeRight")))
        && ((MEM_KeyPressed(MEM_GetKey("keyUp")))          ||  (MEM_KeyPressed(MEM_GetSecondaryKey("keyUp")))) {
            GFA_AimMovement(0, "");
            return;
        };

        // Stop running/walking animation
        const int call = 0;
        if (CALL_Begin(call)) {
            CALL__thiscall(_@(aniCtrlPtr), oCAniCtrl_Human___Stand);
            call = CALL_End();
        };
    };

    // Set return value to one: Do not call any other movement functions
    EAX = 1;
};


/*
 * Reset the FX of the spell for invested spells. This function is necessary to reset the spell to its initial state if
 * the casting/investing is interrupted by strafing, falling, lying or sliding. This function is called from various
 * functions. The engine functions called here are the same the engine uses to reset the spell FX.
 */
func void GFA_ResetSpell() {
    // First check if resetting is necessary
    if (Npc_GetActiveSpellLevel(hero) <= 1) {
        return;
    };

    var C_Spell spell; spell = GFA_GetActiveSpellInst(hero);
    if (!_@(spell)) {
        return;
    };

    // Stop active spell (to remove higher spell level)
    var oCNpc her; her = Hlp_GetNpc(hero);
    var int magBookPtr; magBookPtr = her.mag_book;
    const int call = 0;
    if (CALL_Begin(call)) {
        CALL__thiscall(_@(magBookPtr), oCMag_Book__StopSelectedSpell);
        call = CALL_End();
    };

    // Re-open the spell with initial spell level FX
    var int spellPtr; spellPtr = _@(spell)-oCSpell_C_Spell_offset;
    const int call2 = 0;
    if (CALL_Begin(call2)) {
        CALL__thiscall(_@(spellPtr), oCSpell__Open);
        call2 = CALL_End();
    };
};
