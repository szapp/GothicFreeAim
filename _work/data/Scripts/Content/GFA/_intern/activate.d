/*
 * Activate free aiming and set internal settings
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
            // Set stricter focus collection
            Focus_Ranged.npc_azi = castFromIntf(castToIntf(GFA_FOCUS_FAR_NPC)); // Cast twice, Deadalus floats are dumb

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
        GFA_UpdateSettingsG2Ctrl(0);

        // Clean up
        GFA_RemoveReticle();
        GFA_AimVobDetachFX();
    } else {
        // Enable if previously disabled
        GFA_UpdateSettings(1);
        GFA_DisableToggleFocusRanged(GFA_Flags & GFA_RANGED);
        GFA_DisableMagicDuringStrafing(GFA_Flags & GFA_SPELLS);

        if (GOTHIC_BASE_VERSION == 2) {
            GFA_UpdateSettingsG2Ctrl(!MEM_ReadInt(oCGame__s_bUseOldControls)); // G1 controls = 0, G2 controls = 1
        };
    };
};


/*
 * This function is called nearly every frame by GFA_TurnPlayerModel(), providing the mouse is enabled, to check
 * whether free aiming is active (player in either magic or ranged combat). It sets the constant GFA_ACTIVE
 * accordingly:
 *  1 if not active (not currently aiming)
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
        GFA_SetCameraModes(0);
        GFA_AimMovement(0, "");
        GFA_DisableAutoTurning(0);
        GFA_ACTIVE = 1;
        return;
    };

    // Before anything else, check if player is in magic or ranged fight mode
    var oCNpc her; her = Hlp_GetNpc(hero);
    if (her.fmode < FMODE_FAR) {
        GFA_SetCameraModes(0);
        GFA_AimMovement(0, "");
        GFA_DisableAutoTurning(0);
        GFA_ACTIVE = 1;
        return;
    };

    // Check if falling (body state BS_FALL is unreliable, because it is set after the falling animation has started)
    var zCAIPlayer playerAI; playerAI = _^(her.anictrl);
    if (gef(playerAI.aboveFloor, mkf(12))) {
        GFA_ResetSpell();
        GFA_AimMovement(0, "");
        GFA_RemoveReticle();
        GFA_AimVobDetachFX();
        GFA_ACTIVE = 1;
        return;
    };

    // Set aiming key depending on control scheme to either action or blocking key
    var String keyAiming;
    if (GOTHIC_CONTROL_SCHEME == 1) {
        keyAiming = "keyAction";
    } else {
        keyAiming = "keyParade";
    };

    // Check if aiming buttons are held
    var _Cursor mouse; mouse = _^(Cursor_Ptr); // The _Cursor class from LeGo holds mouse properties
    var int keyPressed; keyPressed = (MEM_KeyPressed(MEM_GetKey(keyAiming)))
                                  || (MEM_KeyPressed(MEM_GetSecondaryKey(keyAiming)))
                                  || (MEMINT_SwitchG1G2(mouse.keyLeft, FALSE)); // Additional key binding for Gothic 1

    // Variables for checking body states
    var int standing;
    var int casting;
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
        if (!GFA_IsSpellEligible(spell)) {
            // Reset spell focus collection
            Focus_Magic.npc_azi = castFromIntf(GFA_FOCUS_SPL_NPC_DFT);
            Focus_Magic.item_prio = GFA_FOCUS_SPL_ITM_DFT;
            GFA_DisableAutoTurning(0);
            GFA_DisableToggleFocusSpells(0);
            GFA_AimMovement(0, ""); // Might have switched directly from other spell while still in movement
            GFA_ACTIVE = 1;
            return;
        } else {
            // Spell uses free aiming: Set stricter focus collection
            Focus_Magic.npc_azi = castFromIntf(castToIntf(GFA_FOCUS_SPL_NPC)); // Cast twice, Deadalus floats are dumb
            Focus_Magic.item_prio = GFA_FOCUS_SPL_ITM;
            GFA_DisableToggleFocusSpells(1);
            GFA_DisableAutoTurning(1);
        };

        // Disable reticle when holding the action key while running (will also disable turning!)
        if (GOTHIC_CONTROL_SCHEME == 1) {
            // Check if standing
            MEM_PushInstParam(hero);
            MEM_PushIntParam(BS_STAND);
            MEM_Call(C_BodyStateContains);
            standing = MEM_PopIntResult();

            // Exception: casting removes standing body state
            MEM_PushInstParam(hero);
            MEM_PushIntParam(BS_CASTING);
            MEM_Call(C_BodyStateContains);
            casting = MEM_PopIntResult();

            // Exception: receiving damage removes standing body state
            MEM_PushInstParam(hero);
            MEM_PushIntParam(BS_STUMBLE);
            MEM_Call(C_BodyStateContains);
            stumbling = MEM_PopIntResult();

            // Additionally, Gothic 1 controls require action key to be held
            if ((!standing) && (!casting) && (!stumbling)) || (!keyPressed) {
                GFA_ACTIVE = 1;
                return;
            };
        };

        // If this is reached, free aiming for the spell is active
        GFA_ACTIVE = FMODE_MAGIC;

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
        if (GOTHIC_CONTROL_SCHEME == 2) {
            MEM_WriteByte(oCAIHuman__PC_ActionMove_aimingKey+4, keyPressed);
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

        // Additionally, action key is required to be held
        if ((!standing) && (!stumbling)) || (!keyPressed) {
            GFA_ACTIVE = 1;
            return;
        };

        // Get onset for drawing the bow, if aiming starts
        if (GFA_ACTIVE != FMODE_FAR) {
            GFA_BowDrawOnset = MEM_Timer.totalTime + GFA_DRAWTIME_READY;
            GFA_MouseMovedLast = MEM_Timer.totalTime + GFA_DRAWTIME_READY;
        };

        // If this is reached, free aiming for ranged weapons is currently active
        GFA_ACTIVE = FMODE_FAR; // Do not differentiate between bow and crossbow
    };
};
