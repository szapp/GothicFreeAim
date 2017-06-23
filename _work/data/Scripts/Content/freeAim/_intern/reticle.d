/*
 * Reticle handling
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
    if (!_@(MEM_Timer)) { // Cheap check if Ikarus was initialized
        MEM_InitAll(); // Important, as this here function is called during level change before any initialization
    };
    freeAimBowDrawOnset = MEM_Timer.totalTime + FREEAIM_DRAWTIME_READY; // Reset draw force onset
    freeAimManageReticle();
};


/*
 * Return texture file name for an animated texture. This function is not used internally, but is offered as a feature
 * for the config functions of g2freeAim. It allows for animated reticles dependent on time.
 * 'numFrames' files must exist with the postfix '_[frameNo].tga', e.g. 'TEXTURE_00.TGA', 'TEXTURE_01.TGA',...
 */
func string freeAimAnimateReticleByTime(var string fileName, var int fps, var int numFrames) {
    // Time of one frame
    var int frameTime; frameTime = 1000/fps;

    // Cycle through [0, numFrames-1] by time
    var int cycle; cycle = (MEM_Timer.totalTime % (frameTime*numFrames)) / frameTime;

    // Base name (without extension)
    var string prefix; prefix = STR_SubStr(fileName, 0, STR_Len(fileName)-4);

    // Add leading zero
    var string postfix;
    if (cycle < 10) {
        postfix = ConcatStrings("0", IntToString(cycle));
    } else {
        postfix = IntToString(cycle);
    };

    return ConcatStrings(ConcatStrings(ConcatStrings(prefix, "_"), postfix), ".TGA");
};


/*
 * Return texture file name for an animated texture. This function is not used internally, but is offered as a feature
 * for the config functions of g2freeAim. It allows for animated reticles dependent on a given percentage. This is
 * useful to indicate progress of draw force or distance to target or any gradual spell property.
 * 'numFrames' files must exist with the postfix '_[frameNo].tga', e.g. 'TEXTURE_00.TGA', 'TEXTURE_01.TGA',...
 */
func string freeAimAnimateReticleByPercent(var string fileName, var int percent, var int numFrames) {
    // Cycle through [0, numFrames-1] by percentage
    var int cycle; cycle = roundf(mulf(mkf(percent), divf(mkf(numFrames-1), FLOAT1C)));

    // Base name (without extension)
    var string prefix; prefix = STR_SubStr(fileName, 0, STR_Len(fileName)-4);

    // Add leading zero
    var string postfix;
    if (cycle < 10) {
        postfix = ConcatStrings("0", IntToString(cycle));
    } else {
        postfix = IntToString(cycle);
    };

    return ConcatStrings(ConcatStrings(ConcatStrings(prefix, "_"), postfix), ".TGA");
};


/*
 * Internal helper function for freeAimGetReticleRanged() for ranged combat. It is called from freeAimAnimation().
 * This function is necessary for error handling and to supply the readied weapon and respective talent value.
 */
func void freeAimGetReticleRanged_(var int target, var int distance, var int returnPtr) {
    // Get readied/equipped ranged weapon
    var int talent; var int weaponPtr;
    MEM_PushIntParam(_@(weaponPtr));
    MEM_PushIntParam(_@(talent));
    MEM_Call(freeAimGetWeaponTalent); // freeAimGetWeaponTalent(_@(weaponPtr), _@(talent));
    if (!MEM_PopIntResult()) {
        return;
    };
    var C_Item weapon; weapon = _^(weaponPtr);

    var C_Npc targetNpc;
    if (Hlp_Is_oCNpc(target)) {
        targetNpc = _^(target);
    } else {
        targetNpc = MEM_NullToInst();
    };

    // Call customized function to retrieve reticle specifications
    MEM_PushInstParam(targetNpc);
    MEM_PushInstParam(weapon);
    MEM_PushIntParam(talent);
    MEM_PushIntParam(distance);
    MEM_PushIntParam(returnPtr);
    MEM_Call(freeAimGetReticleRanged); // freeAimGetReticleRanged(targetNpc, weapon, talent, distance, returnPtr);
};


/*
 * Internal helper function for freeAimGetReticleSpell() for magic combat. It is called from freeAimSpellReticle().
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

    // Call customized function to retrieve reticle specifications
    MEM_PushInstParam(targetNpc);
    MEM_PushIntParam(spellID);
    MEM_PushInstParam(spellInst);
    MEM_PushIntParam(spellLvl);
    MEM_PushIntParam(isScroll);
    MEM_PushIntParam(manaInvested);
    MEM_PushIntParam(distance);
    MEM_PushIntParam(returnPtr);
    MEM_Call(freeAimGetReticleSpell); // freeAimGetReticleSpell(target, spellID, spellInst, spellLvl, isScroll, ...);
};
