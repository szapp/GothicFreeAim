/*
 * Reticle handling
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
 * Hide the reticle. This function is called from various functions to ensure that the reticle disappears.
 */
func void GFA_RemoveReticle() {
    if (GFA_RETICLE_PTR) {
        ViewPtr_Close(GFA_RETICLE_PTR);
    };
};


/*
 * Draw the reticle. This function is called from various functions to draw or update the reticle. During aiming this
 * function is in fact called every frame to update the reticle color, texture and size smoothly. The function
 * parameter is a pointer to the reticle instance.
 */
func void GFA_InsertReticle(var int reticlePtr) {
    // Get reticle instance from call-by-reference argument
    var Reticle reticle; reticle = _^(reticlePtr);
    var int size;

    // Only draw the reticle if the texture is specified. An empty texture removes the reticle
    if (!Hlp_StrCmp(reticle.texture, "")) {
        // The reticle size percentage is scaled with the minimum and maximum pixel dimensions
        size = GFA_ScaleRanges(reticle.size, 0, 100, GFA_RETICLE_MIN_SIZE, GFA_RETICLE_MAX_SIZE);

        // Corrected the ranges in stay within [0, 100]
        if (size > GFA_RETICLE_MAX_SIZE) {
            size = GFA_RETICLE_MAX_SIZE;
        } else if (size < GFA_RETICLE_MIN_SIZE) {
            size = GFA_RETICLE_MIN_SIZE;
        };

        if (!GFA_RETICLE_PTR) {
            // Create reticle if it does not exist
            Print_GetScreenSize(); // Necessary for Print_Screen
            GFA_RETICLE_PTR = ViewPtr_CreateCenterPxl(Print_Screen[PS_X]/2, Print_Screen[PS_Y]/2, size, size);
            ViewPtr_SetTexture(GFA_RETICLE_PTR, reticle.texture);
            ViewPtr_SetColor(GFA_RETICLE_PTR, reticle.color);
            ViewPtr_Open(GFA_RETICLE_PTR);
        } else {
            // If the reticle already exists adjust it to the new texture, size and color
            if (!Hlp_StrCmp(ViewPtr_GetTexture(GFA_RETICLE_PTR), reticle.texture)) {
                // Update its texture
                ViewPtr_SetTexture(GFA_RETICLE_PTR, reticle.texture);
            };

            if (ViewPtr_GetColor(GFA_RETICLE_PTR) != reticle.color) {
                // Update its color
                ViewPtr_SetColor(GFA_RETICLE_PTR, reticle.color);
            };

            if (csize != size) || (Print_Screen[PS_X]/2 != centerX) {
                // Update its size and re-position it to center
                Print_GetScreenSize(); // Necessary for Print_Screen
                var int csize; csize = size;
                var int centerX; centerX = Print_Screen[PS_X]/2;
                ViewPtr_ResizePxl(GFA_RETICLE_PTR, size, size);
                ViewPtr_MoveToPxl(GFA_RETICLE_PTR, Print_Screen[PS_X]/2-size/2, Print_Screen[PS_Y]/2-size/2);
            };

            var zCView crsHr; crsHr = _^(GFA_RETICLE_PTR);
            if (!crsHr.isOpen) {
                // Show the reticle if it is not visible
                ViewPtr_Open(GFA_RETICLE_PTR);
            };
        };
    } else {
        // Remove the reticle if no texture is specified
        GFA_RemoveReticle();
    };
};


/*
 * Reset settings when changing the weapon. This function hooks oCNpc::SetWeaponMode() at an offset that is player
 * specific to remove the reticle, remove the aim vob FX and reset the draw force of ranged weapons.
 */
func void GFA_ResetOnWeaponSwitch() {
    GFA_AimVobDetachFX();
    GFA_RemoveReticle();

    // Reset draw force, because aiming button may be held
    GFA_BowDrawOnset = MEM_Timer.totalTime + GFA_DRAWTIME_READY;
    GFA_MouseMovedLast = MEM_Timer.totalTime + GFA_DRAWTIME_READY;
};


/*
 * Wrapper function for the config function GFA_GetRangedReticle(). It is called from GFA_RangedAiming().
 * This function is necessary for error handling and to supply the readied weapon and respective talent value.
 */
func void GFA_GetRangedReticle_(var int target, var int distance, var int returnPtr) {
    // Get readied/equipped ranged weapon
    var int talent; var int weaponPtr;
    if (!GFA_GetWeaponAndTalent(hero, _@(weaponPtr), _@(talent))) {
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
    GFA_GetRangedReticle(targetNpc, weapon, talent, distance, returnPtr);
};


/*
 * Wrapper function for the config function GFA_GetSpellReticle(). It is called from GFA_SpellAiming().
 * This function supplies a lot of spell properties.
 */
func void GFA_GetSpellReticle_(var int target, var C_Spell spellInst, var int distance, var int returnPtr) {
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
    GFA_GetSpellReticle(targetNpc, spellID, spellInst, spellLvl, isScroll, manaInvested, distance, returnPtr);
};
