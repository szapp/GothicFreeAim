/*
 * Activate free aiming and set internal settings
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
 * Update internal settings when turning free aim on/off in the options menu. Settings include focus ranges/angles and
 * camera angles. The constant GFA_ACTIVE will be updated accordingly. This function is called from GFA_UpdateStatus()
 * if the menu is closed.
 */
func void GFA_UpdateSettings(var int on) {
    if ((GFA_ACTIVE > 0) == on) {
        return; // No change necessary
    };

    MEM_Info(ConcatStrings("  OPT: GFA: freeAimingEnabled=", IntToString(on))); // Print to zSpy, same style as options

    if (on) {
        // Turn free aiming on
        if (GFA_Flags & GFA_RANGED) {
            if (GFA_NO_AIM_NO_FOCUS) {
                // Set stricter focus collection
                Focus_Ranged.npc_azi = castFromIntf(castToIntf(GFA_FOCUS_FAR_NPC)); // Cast twice for, Deadalus floats
            };

            // New camera mode (does not affect Gothic 1)
            MEM_WriteString(zString_CamModRanged, STR_Upper(GFA_CAMERA));
        };

        if (GFA_Flags & GFA_SPELLS) {
            // New camera mode (does not affect Gothic 1)
            MEM_WriteString(zString_CamModMagic, STR_Upper(GFA_CAMERA));
        };

    } else {
        // Reset focus collection to default
        Focus_Ranged.npc_azi = castFromIntf(GFA_FOCUS_FAR_NPC_DFT);
        Focus_Magic.npc_azi = castFromIntf(GFA_FOCUS_SPL_NPC_DFT);
        Focus_Magic.item_prio = GFA_FOCUS_SPL_ITM_DFT;

        // Restore camera modes (does not affect Gothic 1)
        MEM_WriteString(zString_CamModRanged, "CAMMODRANGED");
        MEM_WriteString(zString_CamModMagic, "CAMMODMAGIC");
    };
    GFA_ACTIVE = !GFA_ACTIVE;
};


/*
 * This function updates the settings when free aiming or the Gothic 2 controls are enabled or disabled. It is called
 * every time when the Gothic settings are updated (after leaving the game menu), as well as during loading and level
 * changes. The function hooks cGameManager::ApplySomeSettings() at the very end (after all other menu settings!).
 * The constant GFA_ACTIVE is modified in the subsequent function GFA_UpdateSettings().
 */
func void GFA_UpdateStatus() {
    // Check if free aiming and mouse controls are enabled
    if (!STR_ToInt(MEM_GetGothOpt("GFA", "freeAimingEnabled"))) || (!MEM_ReadInt(zCInput_Win32__s_mouseEnabled)) {
        // Disable if previously enabled
        GFA_UpdateSettings(0);
        GFA_DisableAutoTurning(0);
        GFA_SetCameraModes(0);
        GFA_DisableToggleFocusRanged(0);
        GFA_DisableToggleFocusSpells(0);
        GFA_DisableMagicDuringStrafing(0);
        GFA_SetControlSchemeRanged(0);
        GFA_SetControlSchemeSpells(0);

        // Clean up
        GFA_RemoveReticle();
        GFA_AimVobDetachFX();
    } else {
        // Enable if previously disabled
        GFA_UpdateSettings(1);
        GFA_DisableToggleFocusRanged(GFA_Flags & GFA_RANGED);
        GFA_DisableMagicDuringStrafing(GFA_Flags & GFA_SPELLS);

        // Apply control schemes for ranged and spell combat free aiming
        if (GOTHIC_BASE_VERSION == 2) {
            // Get control scheme and overrides
            var int schemeAcross; schemeAcross = -(MEM_ReadInt(oCGame__s_bUseOldControls))+2; // G1 == 1, G2 == 2
            var int schemeRanged; schemeRanged = STR_ToInt(MEM_GetGothOpt("GFA", "overwriteControlSchemeRanged"));
            var int schemeSpells; schemeSpells = STR_ToInt(MEM_GetGothOpt("GFA", "overwriteControlSchemeSpells"));

            // If override is disabled, use general (across) control scheme (as from the game menu settings)
            if (schemeRanged < 1) || (schemeRanged > 2) {
                schemeRanged = schemeAcross;
            };
            if (schemeSpells < 1) || (schemeSpells > 2) {
                schemeSpells = schemeAcross;
            };

            GFA_SetControlSchemeRanged(schemeRanged);
            GFA_SetControlSchemeSpells(schemeSpells);
        } else {
            // Gothic 1 has always G1 controls
            GFA_CTRL_SCHEME_RANGED = 1;
            GFA_CTRL_SCHEME_SPELLS = 1;
        };
    };
};


/*
 * This function is called nearly every frame by GFA_TurnPlayerModel(), providing the mouse is enabled, to check
 * whether free aiming is active (player in either magic or ranged combat). It sets the constant GFA_ACTIVE
 * accordingly:
 *  1 if not active (not currently aiming)
 *  4 if currently using a spell that supports aim movement (GFA_ACT_MOVEMENT)
 *  5 if currently aiming in ranged fight mode (FMODE_FAR)
 *  7 if currently aiming in magic fight mode with free aiming supported spell (FMODE_MAGIC)
 *
 * GFA_ACTIVE is prior set to 0 in GFA_UpdateStatus() if free aiming is disabled in the menu.
 *
 * Different checks are performed in performance-favoring order (exiting the function as early as possible) to set the
 * constant, which is subsequently used in a lot of functions to determine the state of free aiming.
 */
func void GFA_IsActive() {
    if (!GFA_ACTIVE) {
        return;
    };

    // Check if currently in a menu or in a dialog
    if (MEM_Game.pause_screen) || (!InfoManager_HasFinished()) {
        if (MEM_Timer.totalTime) && (Hlp_IsValidNpc(hero)) {
            GFA_SetCameraModes(0);
            GFA_AimMovement(0, "");
            GFA_DisableAutoTurning(0);
        };
        GFA_ACTIVE = 1;
        return;
    };

    // Before anything else, check if player is in magic or ranged fight mode
    var oCNpc her; her = getPlayerInst();
    if (her.fmode < FMODE_FAR) {
        GFA_SetCameraModes(0);
        GFA_AimMovement(0, "");
        GFA_DisableAutoTurning(0);
        GFA_RemoveReticle(); // Necessary for SPL_Control
        GFA_ACTIVE = 1;
        return;
    };

    // Check if falling (body state BS_FALL is unreliable, because it is set after the falling animation has started)
    var zCAIPlayer playerAI; playerAI = _^(her.anictrl);
    if (gef(playerAI.aboveFloor, mkf(50))) {
        GFA_ResetSpell();
        GFA_AimMovement(0, "");
        GFA_RemoveReticle();
        GFA_AimVobDetachFX();
        GFA_ACTIVE = 1;
        return;
    };

    // Set active control scheme for current fight mode
    if (her.fmode == FMODE_MAGIC) {
        GFA_ACTIVE_CTRL_SCHEME = GFA_CTRL_SCHEME_SPELLS;
    } else {
        GFA_ACTIVE_CTRL_SCHEME = GFA_CTRL_SCHEME_RANGED;
    };

    // Set aiming key depending on control scheme to either action or blocking key
    var String keyAiming;
    if (GFA_ACTIVE_CTRL_SCHEME == 1) {
        keyAiming = "keyAction";
    } else {
        keyAiming = "keyParade";
    };

    // Check if aiming buttons are held
    var _Cursor mouse; mouse = _^(Cursor_Ptr); // The _Cursor class from LeGo holds mouse properties
    var int keyPressed; keyPressed = (MEM_KeyPressed(MEM_GetKey(keyAiming)))
                                  || (MEM_KeyPressed(MEM_GetSecondaryKey(keyAiming)))
                                  || (MEMINT_SwitchG1G2(mouse.keyLeft, FALSE)); // Additional key binding for Gothic 1

    // Body state checks
    var int standing;
    var int stumbling;

    // Check fight mode
    if (her.fmode == FMODE_MAGIC) {
        // Check if free aiming for spells is disabled
        if (!(GFA_Flags & GFA_SPELLS)) {
            GFA_SetCameraModes(0);
            GFA_DisableAutoTurning(0);
            GFA_ACTIVE = 1;
            return;
        };

        // Gothic 1 does not differentiate between camera modes. Force/overwrite all to free aiming mode
        GFA_SetCameraModes(1);

        // Check if active spell supports free aiming
        var C_Spell spell; spell = GFA_GetActiveSpellInst(hero);
        var int eligible; eligible = GFA_IsSpellEligible(spell);
        if (!(eligible & GFA_ACT_FREEAIM)) {
            // Reset spell focus collection
            Focus_Magic.npc_azi = castFromIntf(GFA_FOCUS_SPL_NPC_DFT);
            Focus_Magic.item_prio = GFA_FOCUS_SPL_ITM_DFT;

            // Basic spells, that use neither free aiming nor movement
            if (!(eligible & GFA_ACT_MOVEMENT)) {
                GFA_DisableAutoTurning(0);
                GFA_DisableToggleFocusSpells(0);
                GFA_AimMovement(0, ""); // Might have switched directly from other spell while still in movement
                GFA_ACTIVE = 1;
                return;
            };
        } else {
            if (GFA_NO_AIM_NO_FOCUS) {
                // Spell uses free aiming: Set stricter focus collection
                Focus_Magic.npc_azi = castFromIntf(castToIntf(GFA_FOCUS_SPL_NPC)); // Cast twice for Deadalus floats
            };
            Focus_Magic.item_prio = GFA_FOCUS_SPL_ITM;
        };

        // Movement spells disable auto turning
        if (eligible & GFA_ACT_MOVEMENT) {
            GFA_DisableToggleFocusSpells(1);
            GFA_DisableAutoTurning(1);
        };

        // Disable reticle when holding the action key while running (will also disable turning!)
        if (GFA_ACTIVE_CTRL_SCHEME == 1) {
            if (!keyPressed) {
                GFA_ACTIVE = 1;
                return;
            };

            // Check if standing
            MEM_PushInstParam(hero);
            MEM_PushIntParam(BS_STAND);
            MEM_Call(C_BodyStateContains);
            standing = MEM_PopIntResult();

            // Exception: receiving damage removes standing body state
            MEM_PushInstParam(hero);
            MEM_PushIntParam(BS_STUMBLE);
            MEM_Call(C_BodyStateContains);
            stumbling = MEM_PopIntResult();

            if (!standing) && (!stumbling) && (!GFA_InvestingOrCasting(hero)) {
                GFA_ACTIVE = 1;
                return;
            };
        };

        // If this is reached, free aiming or at least free movement for the spell is active
        GFA_ACTIVE = eligible;

    } else if (her.fmode >= FMODE_FAR) { // Greater or equal: Crossbow has different fight mode!
        // Check if free aiming for ranged combat is disabled
        if (!(GFA_Flags & GFA_RANGED)) {
            GFA_DisableAutoTurning(0);
            GFA_SetCameraModes(0);
            GFA_ACTIVE = 1;
            return;
        };

        // Gothic 1 does not differentiate between camera modes. Force/overwrite all to free aiming mode
        GFA_SetCameraModes(1);
        GFA_DisableAutoTurning(1);

        // Set internally whether the aiming key is held or not (only if using Gothic 2 controls)
        if (GFA_ACTIVE_CTRL_SCHEME == 2) {
            MEM_WriteByte(oCAIHuman__PC_ActionMove_aimingKey+4, keyPressed);
        };

        // Aiming key is required to be held
        if (!keyPressed) {
            GFA_ACTIVE = 1;
            return;
        };

        // Disable focus collection while running
        if (GFA_ACTIVE_CTRL_SCHEME == 1) || (!GFA_STRAFING) {
            // Check if standing
            MEM_PushInstParam(hero);
            MEM_PushIntParam(BS_STAND);
            MEM_Call(C_BodyStateContains);
            standing = MEM_PopIntResult();

            // Exception: receiving damage removes standing body state
            MEM_PushInstParam(hero);
            MEM_PushIntParam(BS_STUMBLE);
            MEM_Call(C_BodyStateContains);
            stumbling = MEM_PopIntResult();

            if (!standing) && (!stumbling) {
                GFA_ACTIVE = 1;
                return;
            };
        };

        // If this is reached, free aiming for ranged weapons is currently active
        GFA_ACTIVE = FMODE_FAR; // Do not differentiate between bow and crossbow
    };
};
