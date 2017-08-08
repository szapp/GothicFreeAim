/*
 * Activate free aiming and set internal settings
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
 * Update internal settings when turning free aim on/off in the options menu. Settings include focus ranges/angles,
 * camera angles along with resetting some other settings. The constant GFA_ACTIVE will be updated accordingly.
 * This function is called from GFA_IsActive() nearly every frame.
 */
func void GFA_UpdateSettings(var int on) {
    if ((GFA_ACTIVE > 0) == on) {
        return; // No change necessary
    };

    MEM_Info(ConcatStrings("  OPT: GFA: freeAimingEnabled=", IntToString(on))); // Print to zSpy, same style as options

    if (on) {
        // Turn free aiming on

        if (GFA_RANGED) {
            // Set stricter focus collection
            Focus_Ranged.npc_azi = 15.0;

            // New camera mode (does not affect Gothic 1)
            MEM_WriteString(zString_CamModRanged, STR_Upper(GFA_CAMERA));

        };

        if (GFA_SPELLS) {
            // New camera mode (does not affect Gothic 1)
            MEM_WriteString(zString_CamModMagic, STR_Upper(GFA_CAMERA));
        };

    } else {
        // Reset ranged focus collection to standard
        Focus_Ranged.npc_azi = 45.0;
        Focus_Magic.npc_azi = 45.0;
        Focus_Magic.item_prio = -1;

        // Restore camera modes (does not affect Gothic 1)
        MEM_WriteString(zString_CamModRanged, "CAMMODRANGED");
        MEM_WriteString(zString_CamModMagic, "CAMMODMAGIC");

        // Reset to collision behavior of projectiles on NPCs to default (does not affect Gothic 1)
        GFA_CC_SetProjectileCollisionWithNpc(0);

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
    // Check if GFA and mouse controls are enabled
    if (!STR_ToInt(MEM_GetGothOpt("GFA", "freeAimingEnabled"))) || (!MEM_ReadInt(zCInput_Win32__s_mouseEnabled)) {
        // Disable if previously enabled
        GFA_UpdateSettings(0);
        GFA_DisableAutoTurning(0);
        GFA_SetCameraModes(0);
        GFA_UpdateSettingsG2Ctrl(0);

    } else {
        // Enable if previously disabled
        GFA_UpdateSettings(1);

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
 * GFA_ACTIVE is prior set to 0 in GFA_UpdateStatus() if free aiming is disabled.
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
        GFA_DisableAutoTurning(0);
        GFA_ACTIVE = 1;
        return;
    };

    // Before anything else, check if player is in magic or ranged fight mode
    var oCNpc her; her = Hlp_GetNpc(hero);
    if (her.fmode < FMODE_FAR) {
        GFA_SetCameraModes(0);
        GFA_DisableAutoTurning(0);
        GFA_ACTIVE = 1;
        return;
    };

    // Set aiming key depending on control scheme to either action or blocking key
    var String keyAiming; keyAiming = "keyAction"; // Gothic 1 controls
    if (GOTHIC_BASE_VERSION == 2) {
        if (!MEM_ReadInt(oCGame__s_bUseOldControls)) {
            // Gothic 2 controls
            keyAiming = "keyParade";
        };
    };
    var int keyStateAiming1; keyStateAiming1 = MEM_KeyState(MEM_GetKey(keyAiming));
    var int keyStateAiming2; keyStateAiming2 = MEM_KeyState(MEM_GetSecondaryKey(keyAiming));
    var int keyStateAiming3; // Gothic 1 has fixed bindings for the mouse buttons: LMB is always aiming

    if (GOTHIC_BASE_VERSION == 1) {
        // The _Cursor class from LeGo is used here. It is not necessarily a cursor: it holds mouse movement
        var _Cursor mouse; mouse = _^(Cursor_Ptr);
        Cursor_KeyState(_@(keyStateAiming3), mouse.keyLeft);
    };

    // Check if aiming button is pressed/held
    var int keyPressed; keyPressed = (keyStateAiming1 == KEY_PRESSED) || (keyStateAiming1 == KEY_HOLD)
                                  || (keyStateAiming2 == KEY_PRESSED) || (keyStateAiming2 == KEY_HOLD)
                                  || (keyStateAiming3 == KEY_PRESSED) || (keyStateAiming3 == KEY_HOLD);

    // Check fight mode
    if (her.fmode == FMODE_MAGIC) {
        // Check if free aiming for spells is disabled
        if (!GFA_SPELLS) {
            GFA_DisableAutoTurning(0);
            GFA_SetCameraModes(0);
            GFA_ACTIVE = 1;
            return;
        };

        // Gothic 1 does not differentiate between camera modes. Force/overwrite all to free aiming mode
        GFA_SetCameraModes(1);

        // Gothic 1 controls require action key to be pressed/held
        if (GOTHIC_BASE_VERSION == 2) {
            if (MEM_ReadInt(oCGame__s_bUseOldControls)) && (!keyPressed) {
                GFA_DisableAutoTurning(0);
                GFA_ACTIVE = 1;
                return;
            };
        } else if (!keyPressed) {
            GFA_DisableAutoTurning(0);
            GFA_ACTIVE = 1;
            return;
        };

        // Check if active spell supports free aiming
        var C_Spell spell; spell = GFA_GetActiveSpellInst(hero);
        if (!GFA_IsSpellEligible(spell)) {
            // Reset ranged focus collection
            Focus_Magic.npc_azi = 45.0;
            Focus_Magic.item_prio = -1;
            GFA_DisableAutoTurning(0);
            GFA_ACTIVE = 1;
            return;
        } else {
            // Spell uses free aiming: Set stricter focus collection
            Focus_Magic.npc_azi = 15.0;
            Focus_Magic.item_prio = 0;
            GFA_DisableAutoTurning(1);
            GFA_ACTIVE = FMODE_MAGIC;
        };

    } else if (her.fmode >= FMODE_FAR) { // Greater or equal: Crossbow has different fight mode!
        // Check if free aiming for ranged combat is disabled
        if (!GFA_RANGED) {
            GFA_DisableAutoTurning(0);
            GFA_SetCameraModes(0);
            GFA_ACTIVE = 1;
            return;
        };

        // Gothic 1 does not differentiate between camera modes. Force/overwrite all to free aiming mode
        GFA_SetCameraModes(1);

        if (GOTHIC_BASE_VERSION == 2) {
            // Set internally whether the aiming key is held or not (only if using Gothic 2 controls)
            if (!MEM_ReadInt(oCGame__s_bUseOldControls)) {
                MEM_WriteByte(oCAIHuman__PC_ActionMove_aimingKey+4, keyPressed);
            };
        };

        // Check if aiming key is not pressed/held
        if (!keyPressed) {
            GFA_DisableAutoTurning(0);
            GFA_ACTIVE = 1;
            return;
        } else {
            GFA_DisableAutoTurning(1);
            GFA_ACTIVE = FMODE_FAR; // Do not differentiate between bow and crossbow
        };

        // Get onset for drawing the bow - right when pressing down the aiming key
        if (keyStateAiming1 == KEY_PRESSED) || (keyStateAiming2 == KEY_PRESSED) || (keyStateAiming3 == KEY_PRESSED) {
            GFA_BowDrawOnset = MEM_Timer.totalTime + GFA_DRAWTIME_READY;
        };
    };
};
