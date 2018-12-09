/*
 * Free aiming mechanics for spell combat
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
 * Set the spell FX shooting direction. This function hooks oCSpell::Setup() to overwrite the target vob with the aim
 * vob that is placed in front of the camera at the nearest intersection with the world or an object.
 */
func void GFA_SetupSpell() {
    var int spellOC; spellOC = MEMINT_SwitchG1G2(ESI, EBP);
    var int casterPtr; casterPtr = MEM_ReadInt(spellOC+oCSpell_spellCasterNpc_offset);
    if (!casterPtr) {
        return;
    };

    // Only if caster is player and if free aiming is enabled for that spell
    var C_Npc caster; caster = _^(casterPtr);
    if (!(GFA_ACTIVE & GFA_ACT_FREEAIM)) || (!Npc_IsPlayer(caster)) {
        return;
    };

    // Determine focus type. For TARGET_COLLECT_NONE no focus will be collect, but only an intersection with the world
    var C_Spell spell; spell = _^(spellOC+oCSpell_C_Spell_offset);
    var int focusType;
    if (spell.targetCollectAlgo == TARGET_COLLECT_NONE) {
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
    if (!(GFA_ACTIVE & GFA_ACT_FREEAIM)) {
        GFA_RemoveReticle();

        // Additional settings if free aiming is enabled
        if (GFA_ACTIVE) {
            if (!(GFA_ACTIVE & GFA_ACT_MOVEMENT)) {
                // Remove movement animations when not aiming
                GFA_AimMovement(0, "");
            };

            if (GFA_IsSpellEligible(spell) & GFA_ACT_FREEAIM) {
                // Remove focus and target
                if (GFA_NO_AIM_NO_FOCUS) {
                    GFA_SetFocusAndTarget(0);
                };

                // Do not remove FX from aim vob when casting is not yet completed
                if (GFA_InvestingOrCasting(hero) > 0) {
                    return;
                };

            } else {
                // Remove focus for spells that do not need to collect a focus
                if (spell.targetCollectAlgo == TARGET_COLLECT_NONE)
                || (spell.targetCollectAlgo == TARGET_COLLECT_CASTER) {
                    GFA_SetFocusAndTarget(0);
                };
            };
        };

        // Remove FX from aim vob
        GFA_AimVobDetachFX();
        return;
    };

    // For safety: Clean up, in case custom spells are recklessly designed
    if (GFA_InvestingOrCasting(hero) <= 0) {
        GFA_AimVobDetachFX();
    };

    var int distance;
    var int target;

    if (spell.targetCollectRange > 0) {
        // Determine the focus type. For TARGET_COLLECT_NONE no focus will be collected, but only an intersection with
        // the world. This is good for spells like Blink, that are not concerned with targeting but only with aiming
        // distance
        var int focusType;
        if (spell.targetCollectAlgo == TARGET_COLLECT_NONE)
        || (spell.targetCollectAzi <= 0)
        || (spell.targetCollectElev <= 0) {
            focusType = 0;
        } else {
            focusType = spell.targetCollectType;
        };

        // Shoot aim ray, to retrieve the distance to an intersection and a possible target
        GFA_AimRay(spell.targetCollectRange, focusType, _@(target), 0, _@(distance), 0);
        distance = roundf(divf(mulf(distance, FLOAT1C), mkf(spell.targetCollectRange))); // Distance scaled to [0, 100]

    } else {
        // No focus collection
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
};


/*
 * Lock the player in place and prevent movement during aiming in spell combat. This function hooks the end of
 * oCAIHuman::MagicMode() to overwrite, whether casting is active or not, to disable any consecutive movement in
 * oCAIHuman::_WalkCycle().
 */
func void GFA_SpellLockMovement() {
    // Only lock movement for eligible spells
    if (!(GFA_ACTIVE & GFA_ACT_MOVEMENT)) {
        return;
    };

    var oCNpc her; her = getPlayerInst();
    var int model; model = her._zCVob_visual;
    if (!objCheckInheritance(model, zCModel__classDef)) {
        return;
    };

    // For Gothic 1 controls, lock movement always for all eligible spells
    if (GFA_ACTIVE_CTRL_SCHEME == 1) {
        var int aniCtrlPtr; aniCtrlPtr = her.anictrl;
        // Disallow sneaking (messes up the perception and the animations)
        if (MEM_ReadInt(aniCtrlPtr+oCAniCtrl_Human_walkmode_offset) & NPC_SNEAK) {
            // Set up and check new walk mode as NPC_RUN (see Constants.d)
            const int call = 0;
            if (CALL_Begin(call)) {
                CALL_IntParam(_@(NPC_RUN));
                CALL__thiscall(_@(aniCtrlPtr), oCAniCtrl_Human__CanToggleWalkModeTo);
                call = CALL_End();
            };

            // Toggle walk mode
            if (CALL_RetValAsInt()) {
                const int negOne = -1;
                const int call2 = 0;
                if (CALL_Begin(call2)) {
                    CALL_IntParam(_@(negOne));
                    CALL__thiscall(_@(aniCtrlPtr), oCAniCtrl_Human__ToggleWalkMode);
                    call2 = CALL_End();
                };
            };
        };

        // Allow strafing
        GFA_Strafe();

        // Set return value to one: Do not call any other movement functions
        EAX = 1;
    } else {
        // Gothic 2 controls: Aim movement while investing/casting as well as allowing to cast from running

        // Do not allow any of the below when the player is lying after a fall
        MEM_PushInstParam(hero);
        MEM_PushIntParam(BS_LIE);
        MEM_Call(C_BodyStateContains);
        if (MEM_PopIntResult()) {
            return;
        };

        var int spellInUse; spellInUse = GFA_InvestingOrCasting(hero);
        var int castKeyDownLastFrame; castKeyDownLastFrame = castKeyDown;
        var int castKeyDown; castKeyDown = (MEM_KeyPressed(MEM_GetKey("keyAction")))
                                        || (MEM_KeyPressed(MEM_GetSecondaryKey("keyAction")));

        // At aiming onset stop running/walking/sneaking animation
        if (castKeyDown) && (!castKeyDownLastFrame) && (!spellInUse) {
            // Stop active animation (except if casting failed animation started)
            const int call3 = 0; const int one = 1;
            if (CALL_Begin(call3)) {
                CALL_IntParam(_@(one));
                CALL_IntParam(_@(one));
                CALL__thiscall(_@(model), zCModel__StopAnisLayerRange);
                call3 = CALL_End();
            };

            // Set return value to one: Do not call any other movement functions
            EAX = 1;
        };

        // Aim movement while investing or casting and for a short period afterwards
        if (spellInUse)
        || ((GFA_SpellPostCastDelay > MEM_Timer.totalTime) && (GFA_IsStrafing)) {
            // Set return value to one: Do not call any other movement functions
            EAX = 1;

            // Allow strafing
            GFA_Strafe();

            // Update post-casting delay to allow bridging consecutive casting without stopping aim movement in between
            if (spellInUse) {
                GFA_SpellPostCastDelay = MEM_Timer.totalTime+GFA_STRAFE_POSTCAST;
            };
        } else {
            GFA_AimMovement(0, "");
        };

        // Do not remove turn animations for Gothic 2 controls, if not using the spell
        if (!spellInUse) && (!castKeyDown) {
            return;
        };
    };

    // Remove turning animations (player model sometimes gets stuck in turning animation)
    const int twenty = 20;
    const int call4 = 0;
    if (CALL_Begin(call4)) {
        CALL_IntParam(_@(twenty));
        CALL_IntParam(_@(twenty));
        CALL__thiscall(_@(model), zCModel__FadeOutAnisLayerRange);
        call4 = CALL_End();
    };
};


/*
 * Update reticle when in Gothic default strafing int Gothic 2 controls. This function hooks oCNpc::EV_Strafe() at an
 * offset where the Gothic 2 controls are used.
 */
func void GFA_SpellStrafeReticle() {
    if (GFA_ACTIVE_CTRL_SCHEME == 2) && (GFA_ACTIVE == FMODE_MAGIC) {
        // Use existing function to update reticle. Set ECX and back it up first
        var int ecxBak; ecxBak = ECX;
        var oCNpc her; her = getPlayerInst();
        ECX = her.anictrl;

        GFA_SpellAiming();

        ECX = ecxBak;
    };
};


/*
 * If a spell is cast with no focus, the collision vob will not match the spell target and the script function
 * C_CanNpcCollideWithSpell() is not consulted, causing unintended behaviors. This function sets the collision vob
 * to be the spell target under certain conditions. The function hooks oCVisualFX::ProcessCollision() at an offset
 * before the spell target is checked.
 * Since C_CanNpcCollideWithSpell() only exists in Gothic 2, this function is not called for Gothic 1.
 */
func void GFA_SpellFixTarget() {
    var int visualFX; visualFX = EBP;

    // Only if player is caster and free aiming is enabled
    if (!GFA_ACTIVE) || (MEM_ReadInt(visualFX+oCVisualFX_originVob_offset) != MEM_ReadInt(oCNpc__player)) {
        return;
    };

    // Get collision vob and target vob
    var int collisionVob; collisionVob = MEM_ReadInt(MEM_ReadInt(ESP+360)); // esp+164h+4h
    var int target; target = MEM_ReadInt(visualFX+oCVisualFX_targetVob_offset);

    // Update target (increase/decrease reference counters properly)
    if (Hlp_Is_oCNpc(collisionVob)) && (collisionVob != target) {
        const int call = 0; var int zero;
        if (CALL_Begin(call)) {
            if (GOTHIC_BASE_VERSION == 2) {
                CALL_IntParam(_@(zero)); // Do not re-calculate new trajectory
            };
            CALL_PtrParam(_@(collisionVob));
            CALL__thiscall(_@(visualFX), oCVisualFX__SetTarget);
            call = CALL_End();
        };
    };
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
    var oCNpc her; her = getPlayerInst();
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
