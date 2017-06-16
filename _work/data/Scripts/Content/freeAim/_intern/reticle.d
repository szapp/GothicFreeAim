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

/* Hide reticle */
func void freeAimRemoveReticle() {
    if (Hlp_IsValidHandle(freeAimReticleHndl)) { View_Close(freeAimReticleHndl); };
};

/* Draw reticle */
func void freeAimInsertReticle(var int reticlePtr) {
    var Reticle reticle; reticle = _^(reticlePtr); var int size;
    if (!Hlp_StrCmp(reticle.texture, "")) {
        size = (((FREEAIM_RETICLE_MAX_SIZE-FREEAIM_RETICLE_MIN_SIZE)*(reticle.size))/100)+FREEAIM_RETICLE_MIN_SIZE;
        if (size > FREEAIM_RETICLE_MAX_SIZE) { size = FREEAIM_RETICLE_MAX_SIZE; }
        else if (size < FREEAIM_RETICLE_MIN_SIZE) { size = FREEAIM_RETICLE_MIN_SIZE; };
        var zCView screen; screen = _^(MEM_Game._zCSession_viewport);
        if (!Hlp_IsValidHandle(freeAimReticleHndl)) { // Create reticle if it does not exist
            freeAimReticleHndl = View_CreateCenterPxl(screen.psizex/2, screen.psizey/2, size, size);
            View_SetTexture(freeAimReticleHndl, reticle.texture);
            View_SetColor(freeAimReticleHndl, reticle.color);
            View_Open(freeAimReticleHndl);
        } else {
            if (!Hlp_StrCmp(View_GetTexture(freeAimReticleHndl), reticle.texture)) { // Update its texture
                View_SetTexture(freeAimReticleHndl, reticle.texture);
            };
            if (View_GetColor(freeAimReticleHndl) != reticle.color) { // Update its color
                View_SetColor(freeAimReticleHndl, reticle.color);
            };
            var zCView crsHr; crsHr = _^(getPtr(freeAimReticleHndl));
            if (crsHr.psizex != size) || (screen.psizex/2 != centerX) { // Update its size and re-position it to center
                var int centerX; centerX = screen.psizex/2;
                View_ResizePxl(freeAimReticleHndl, size, size);
                View_MoveToPxl(freeAimReticleHndl, screen.psizex/2-(size/2), screen.psizey/2-(size/2));
            };
            if (!crsHr.isOpen) { View_Open(freeAimReticleHndl); };
        };
    } else { freeAimRemoveReticle(); };
};

/* Decide when to draw reticle or when to hide it */
func void freeAimManageReticle() {
    if (FREEAIM_ACTIVE < FMODE_FAR) {
        freeAimDetachFX();
        freeAimRemoveReticle();
    };
};

/* Switching between weapon modes (sometimes called several times in a row) */
func void freeAimSwitchMode() {
    freeAimBowDrawOnset = MEM_Timer.totalTime + FREEAIM_DRAWTIME_READY; // Reset draw force onset
    freeAimManageReticle();
};

/* Return texture file name for an animated texture. numFrames files must exist with the postfix '_[frameNo].tga' */
func string freeAimAnimateReticleByTime(var string fileName, var int fps, var int numFrames) {
    var int frameTime; frameTime = 1000/fps; // Time of one frame
    var int cycle; cycle = (MEM_Timer.totalTime % (frameTime*numFrames)) / frameTime; // Cycle through [0, numFrames]
    var string prefix; prefix = STR_SubStr(fileName, 0, STR_Len(fileName)-4); // Base name (without extension)
    var string postfix;
    if (cycle < 10) { postfix = ConcatStrings("0", IntToString(cycle)); } else { postfix = IntToString(cycle); };
    return ConcatStrings(ConcatStrings(ConcatStrings(prefix, "_"), postfix), ".TGA");
};

/* Return texture file name for an animated texture. numFrames files must exist with the postfix '_[frameNo].tga' */
func string freeAimAnimateReticleByPercent(var string fileName, var int percent, var int numFrames) {
    var int cycle; cycle = roundf(mulf(mkf(percent), divf(mkf(numFrames-1), FLOAT1C)));
    var string prefix; prefix = STR_SubStr(fileName, 0, STR_Len(fileName)-4); // Base name (without extension)
    var string postfix;
    if (cycle < 10) { postfix = ConcatStrings("0", IntToString(cycle)); } else { postfix = IntToString(cycle); };
    return ConcatStrings(ConcatStrings(ConcatStrings(prefix, "_"), postfix), ".TGA");
};

/* Internal helper function for freeAimGetReticleRanged() for ranged combat */
func void freeAimGetReticleRanged_(var int target, var int distance, var int returnPtr) {
    var C_Npc targetNpc; var int talent; var C_Item weapon; // Retrieve target npc, weapon and talent
    if (Npc_IsInFightMode(hero, FMODE_FAR)) { weapon = Npc_GetReadiedWeapon(hero); }
    else if (Npc_HasEquippedRangedWeapon(hero)) { weapon = Npc_GetEquippedRangedWeapon(hero); }
    else { MEM_Error("freeAimGetReticleRanged_: No valid weapon equipped/readied!"); return; }; // Should never happen
    if (weapon.flags & ITEM_BOW) { talent = hero.HitChance[NPC_TALENT_BOW]; } // Bow talent
    else if (weapon.flags & ITEM_CROSSBOW) { talent = hero.HitChance[NPC_TALENT_CROSSBOW]; } // Crossbow talent
    else { MEM_Error("freeAimGetReticleRanged_: No valid weapon equipped/readied!"); return; };
    if (Hlp_Is_oCNpc(target)) { targetNpc = _^(target); } else { targetNpc = MEM_NullToInst(); };
    // Call customized function
    MEM_PushInstParam(targetNpc);
    MEM_PushInstParam(weapon);
    MEM_PushIntParam(talent);
    MEM_PushIntParam(distance);
    MEM_PushIntParam(returnPtr);
    MEM_Call(freeAimGetReticleRanged); // freeAimGetReticleRanged(targetNpc, weapon, talent, distance, returnPtr);
};

/* Internal helper function for freeAimGetReticleSpell() for magic combat */
func void freeAimGetReticleSpell_(var int target, var C_Spell spellInst, var int distance, var int returnPtr) {
    var C_Npc targetNpc; var int spellID; var int spellLvl; var int isScroll; var int manaInvested;
    spellID = Npc_GetActiveSpell(hero);
    spellLvl = Npc_GetActiveSpellLevel(hero);
    isScroll = Npc_GetActiveSpellIsScroll(hero);
    manaInvested = MEM_ReadInt(_@(spellInst)-56); // 0x0048 oCSpell.manaInvested
    if (Hlp_Is_oCNpc(target)) { targetNpc = _^(target); } else { targetNpc = MEM_NullToInst(); };
    // Call customized function
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
