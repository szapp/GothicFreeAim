/*
 * Reticle handling
 *
 * G2 Free Aim v1.0.0-alpha - Free aiming for the video games Gothic 1 and Gothic 2 by Piranha Bytes
 * Copyright (C) 2016-2017  mud-freak (@szapp)
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
 * Hide reticle. This function is called from various functions to ensure that the reticle disappears.
 */
func void freeAimRemoveReticle() {
    if (Hlp_IsValidHandle(freeAimReticleHndl)) {
        View_Close(freeAimReticleHndl);
    };
};


/*
 * Draw reticle. This function is called from various functions to draw or update the reticle. During aiming this
 * function is in fact called every frame to update the reticle color, texture and size smoothly. The function
 * parameter is a pointer to the reticle instance.
 */
func void freeAimInsertReticle(var int reticlePtr) {
    // Get reticle instance from call-by-reference argument
    var Reticle reticle; reticle = _^(reticlePtr);
    var int size;

    // Only draw the reticle if the texture is specified. An empty texture removes the reticle
    if (!Hlp_StrCmp(reticle.texture, "")) {
        // Scale the reticle size percentage is scaled with the minimum and maximum pixel sizes
        size = (((FREEAIM_RETICLE_MAX_SIZE-FREEAIM_RETICLE_MIN_SIZE)*(reticle.size))/100)+FREEAIM_RETICLE_MIN_SIZE;

        // The ranges are corrected should the percentage lie out of [0, 100]
        if (size > FREEAIM_RETICLE_MAX_SIZE) {
            size = FREEAIM_RETICLE_MAX_SIZE;
        } else if (size < FREEAIM_RETICLE_MIN_SIZE) {
            size = FREEAIM_RETICLE_MIN_SIZE;
        };

        // Get the screen to retrieve the center
        var zCView screen; screen = _^(MEM_Game._zCSession_viewport);

        if (!Hlp_IsValidHandle(freeAimReticleHndl)) {
            // Create reticle if it does not exist
            freeAimReticleHndl = View_CreateCenterPxl(screen.psizex/2, screen.psizey/2, size, size);
            View_SetTexture(freeAimReticleHndl, reticle.texture);
            View_SetColor(freeAimReticleHndl, reticle.color);
            View_Open(freeAimReticleHndl);
        } else {
            // If the reticle already exist adjust it to the new texture, size and color
            if (!Hlp_StrCmp(View_GetTexture(freeAimReticleHndl), reticle.texture)) {
                // Update its texture
                View_SetTexture(freeAimReticleHndl, reticle.texture);
            };

            if (View_GetColor(freeAimReticleHndl) != reticle.color) {
                // Update its color
                View_SetColor(freeAimReticleHndl, reticle.color);
            };

            var zCView crsHr; crsHr = _^(getPtr(freeAimReticleHndl));
            if (crsHr.psizex != size) || (screen.psizex/2 != centerX) {
                // Update its size and re-position it to center
                var int centerX; centerX = screen.psizex/2;
                View_ResizePxl(freeAimReticleHndl, size, size);
                View_MoveToPxl(freeAimReticleHndl, screen.psizex/2-(size/2), screen.psizey/2-(size/2));
            };

            if (!crsHr.isOpen) {
                // Show the reticle if it is not visible
                View_Open(freeAimReticleHndl);
            };
        };
    } else {
        // Remove the reticle if no texture is specified
        freeAimRemoveReticle();
    };
};


/*
 * Decide when to draw reticle or when to hide it. This function is called from various functions to ensure that the
 * reticle disappears if changing the weapon or stopping to aim.
 */
func void freeAimManageReticle() {
    if (FREEAIM_ACTIVE < FMODE_FAR) {
        // Remove the visual FX from the aim vob (if present)
        freeAimDetachFX();
        // Hide reticle
        freeAimRemoveReticle();
    };
};


/*
 * Switching between weapon modes (sometimes called several times in a row). This function hooks
 * oCNpcFocus::SetFocusMode to call freeAimManageReticle() and to reset the draw force of ranged weapons. This function
 * is called during loading of a level change before Ikarus, LeGo or g2freeAim are initialized.
 */
func void freeAimSwitchMode() {
    if (!_@(MEM_Timer)) {
        // This function is called multiple times during level change prior to any initialization
        return;
    };

    freeAimBowDrawOnset = MEM_Timer.totalTime + FREEAIM_DRAWTIME_READY; // Reset draw force onset
    freeAimManageReticle();
};


/*
 * Wrapper function for the config function freeAimGetReticleRanged(). It is called from freeAimAnimation().
 * This function is necessary for error handling and to supply the readied weapon and respective talent value.
 */
func void freeAimGetReticleRanged_(var int target, var int distance, var int returnPtr) {
    // Get readied/equipped ranged weapon
    var int talent; var int weaponPtr;
    if (!freeAimGetWeaponTalent(_@(weaponPtr), _@(talent))) {
        return;
    };
    var C_Item weapon; weapon = _^(weaponPtr);

    var C_Npc targetNpc;
    if (Hlp_Is_oCNpc(target)) {
        targetNpc = _^(target);
    } else {
        targetNpc = MEM_NullToInst();
    };

    // Retrieve reticle specifications from config
    freeAimGetReticleRanged(targetNpc, weapon, talent, distance, returnPtr);
};


/*
 * Wrapper function for the config function freeAimGetReticleSpell(). It is called from freeAimSpellReticle().
 * This function supplies a lot of spell properties.
 */
func void freeAimGetReticleSpell_(var int target, var C_Spell spellInst, var int distance, var int returnPtr) {
    // Define spell properties
    var int spellID; spellID = Npc_GetActiveSpell(hero);
    var int spellLvl; spellLvl = Npc_GetActiveSpellLevel(hero);
    var int isScroll; isScroll = Npc_GetActiveSpellIsScroll(hero);

    // Getting the amount of mana invested takes a bit more effort
    var int spellOC; spellOC = _@(spellInst)-oCSpell_C_Spell_offset;
    var int manaInvested; manaInvested = MEM_ReadInt(spellOC+oCSpell_manaInvested_offset);

    var C_Npc targetNpc;
    if (Hlp_Is_oCNpc(target)) {
        targetNpc = _^(target);
    } else {
        targetNpc = MEM_NullToInst();
    };

    // Retrieve reticle specifications from config
    freeAimGetReticleSpell(targetNpc, spellID, spellInst, spellLvl, isScroll, manaInvested, distance, returnPtr);
};
