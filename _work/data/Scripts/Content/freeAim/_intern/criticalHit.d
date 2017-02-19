/*
 * Critical hits for projectiles
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

/* Internal helper function for freeAimCriticalHitEvent() */
func void freeAimCriticalHitEvent_(var C_Npc target) {
    var C_Item weapon; weapon = MEM_NullToInst(); // Daedalus pseudo locals
    if (Npc_IsInFightMode(hero, FMODE_FAR)) { weapon = Npc_GetReadiedWeapon(hero); }
    else if (Npc_HasEquippedRangedWeapon(hero)) { weapon = Npc_GetEquippedRangedWeapon(hero); };
    // Call customized function
    MEM_PushInstParam(target);
    MEM_PushInstParam(weapon);
    MEM_Call(freeAimCriticalHitEvent); // freeAimCriticalHitEvent(target, weapon);
};

/* Internal helper function for freeAimCriticalHitDef() */
func void freeAimCriticalHitDef_(var C_Npc target, var int damage, var int returnPtr) {
    var C_Item weapon; weapon = MEM_NullToInst(); // Daedalus pseudo locals
    if (Npc_IsInFightMode(hero, FMODE_FAR)) { weapon = Npc_GetReadiedWeapon(hero); }
    else if (Npc_HasEquippedRangedWeapon(hero)) { weapon = Npc_GetEquippedRangedWeapon(hero); };
    // Call customized function
    MEM_PushInstParam(target);
    MEM_PushInstParam(weapon);
    MEM_PushIntParam(damage);
    MEM_PushIntParam(returnPtr);
    MEM_Call(freeAimCriticalHitDef); // freeAimCriticalHitDef(target, weapon, damage, returnPtr);
    MEM_WriteString(returnPtr, STR_Upper(MEM_ReadString(returnPtr))); // Nodes are always upper case
    if (lf(MEM_ReadInt(returnPtr+28), FLOATNULL)) { MEM_WriteInt(returnPtr+28, FLOATNULL); }; // Correct negative damage
};

/* Detect critical hits and increase base damage. Modify the weak spot in freeAimCriticalHitDef() */
func void freeAimDetectCriticalHit() {
    var int damagePtr; damagePtr = ESP+228; // esp+1ACh+C8h // zREAL*
    var int target; target = MEM_ReadInt(ESP+28); // esp+1ACh+190h // oCNpc*
    var int projectile; projectile = MEM_ReadInt(EBP+88); // ebp+58h // oCItem*
    var C_Npc shooter; shooter = _^(MEM_ReadInt(EBP+92)); // ebp+5Ch // oCNpc*
    if (FREEAIM_ACTIVE_PREVFRAME != 1) || (!Npc_IsPlayer(shooter)) { return; }; // Only if player and if fa WAS active
    var C_Npc targetNpc; targetNpc = _^(target);
    // Get model from target npc
    const int call = 0;
    if (CALL_Begin(call)) {
        CALL__thiscall(_@(target), oCNpc__GetModel);
        call = CALL_End();
    };
    var int model; model = CALL_RetValAsPtr();
    // Get weak spot node from target model
    var int autoAlloc[8]; var Weakspot weakspot; weakspot = _^(_@(autoAlloc)); // Gothic takes care of freeing this ptr
    MEM_CopyWords(_@s(""), _@(autoAlloc), 5); // weakspot.node (reset string)
    freeAimCriticalHitDef_(targetNpc, MEM_ReadInt(damagePtr), _@(weakspot)); // Retrieve weakspot specs
    var int nodeStrPtr; nodeStrPtr = _@(weakspot);
    if (Hlp_StrCmp(MEM_ReadString(nodeStrPtr), "")) { return; }; // No critical node defined
    const int call2 = 0;
    if (CALL_Begin(call2)) {
        CALL_PtrParam(_@(nodeStrPtr));
        CALL__thiscall(_@(model), zCModel__SearchNode);
        call2 = CALL_End();
    };
    var int node; node = CALL_RetValAsPtr();
    if (!node) { MEM_Warn("freeAimDetectCriticalHit: Node not found!"); return; };
    if (weakspot.dimX == -1) && (weakspot.dimY == -1) { // Retrieve the bbox by model
        if (MEM_ReadInt(node+8)) { // node->nodeVisual // If the node has a dedicated visual, retrieve bbox
            // Get the bbox of the node (although zCModelNodeInst has a zTBBox3D property, it is empty the first time)
            CALL_PtrParam(node); CALL_RetValIsStruct(24); // sizeof_zTBBox3D // No recyclable call possible
            CALL__thiscall(model, zCModel__GetBBox3DNodeWorld);
            var int nodeBBoxPtr; nodeBBoxPtr = CALL_RetValAsPtr();
            MEM_CopyWords(nodeBBoxPtr, _@(freeAimDebugWSBBox), 6); // zTBBox3D
            MEM_Free(nodeBBoxPtr); // Free memory
        } else {
            MEM_Error("freeAimDetectCriticalHit: Node has no boundingbox!");
            return;
        };
    } else if (weakspot.dimX < 0) || (weakspot.dimY < 0) { // Bbox dimensions must be positive
        MEM_Error("freeAimDetectCriticalHit: Boundingbox dimensions illegal!");
        return;
    } else { // Create bbox by dimensions
        weakspot.dimX /= 2; weakspot.dimY /= 2;
        // Get the position of the node (although zCModelNodeInst has a position property, it is empty the first time)
        CALL_PtrParam(node); CALL_RetValIsStruct(12); // sizeof_zVEC3 // No recyclable call possible bc of structure
        CALL__thiscall(model, zCModel__GetNodePositionWorld);
        var int nodPosPtr; nodPosPtr = CALL_RetValAsInt();
        var int nodePos[3]; MEM_CopyWords(nodPosPtr, _@(nodePos), 3);
        MEM_Free(nodPosPtr); // Free memory
        freeAimDebugWSBBox[0] = subf(nodePos[0], mkf(weakspot.dimX)); // Build an own bbox by the passed node dimensions
        freeAimDebugWSBBox[1] = subf(nodePos[1], mkf(weakspot.dimY));
        freeAimDebugWSBBox[2] = subf(nodePos[2], mkf(weakspot.dimX));
        freeAimDebugWSBBox[3] = addf(nodePos[0], mkf(weakspot.dimX));
        freeAimDebugWSBBox[4] = addf(nodePos[1], mkf(weakspot.dimY));
        freeAimDebugWSBBox[5] = addf(nodePos[2], mkf(weakspot.dimX));
    };
    // The internal engine functions are not accurate enough for detecting a shot through a bbox
    // Instead check here if "any" point along the line of projectile direction lies inside the bbox of the node
    var int dir[3]; // Direction of collision line along the right-vector of the projectile (projectile flies sideways)
    dir[0] = MEM_ReadInt(projectile+60); dir[1] = MEM_ReadInt(projectile+76); dir[2] = MEM_ReadInt(projectile+92);
    freeAimDebugWSTrj[0] = addf(MEM_ReadInt(projectile+ 72), mulf(dir[0], FLOAT3C)); // Start 3m behind the projectile
    freeAimDebugWSTrj[1] = addf(MEM_ReadInt(projectile+ 88), mulf(dir[1], FLOAT3C)); // So far bc bbox at close range
    freeAimDebugWSTrj[2] = addf(MEM_ReadInt(projectile+104), mulf(dir[2], FLOAT3C));
    var int intersection; intersection = 0; // Critical hit detected
    var int i; i=0; var int iter; iter = 700/5; // 7meters: Max distance from model bbox edge to node bbox (e.g. troll)
    while(i <= iter); i += 1; // Walk along the line in steps of 5cm
        freeAimDebugWSTrj[3] = subf(freeAimDebugWSTrj[0], mulf(dir[0], mkf(i*5))); // Next point along the collision line
        freeAimDebugWSTrj[4] = subf(freeAimDebugWSTrj[1], mulf(dir[1], mkf(i*5)));
        freeAimDebugWSTrj[5] = subf(freeAimDebugWSTrj[2], mulf(dir[2], mkf(i*5)));
        if (lef(freeAimDebugWSBBox[0], freeAimDebugWSTrj[3])) && (lef(freeAimDebugWSBBox[1], freeAimDebugWSTrj[4]))
        && (lef(freeAimDebugWSBBox[2], freeAimDebugWSTrj[5])) && (gef(freeAimDebugWSBBox[3], freeAimDebugWSTrj[3]))
        && (gef(freeAimDebugWSBBox[4], freeAimDebugWSTrj[4])) && (gef(freeAimDebugWSBBox[5], freeAimDebugWSTrj[5])) {
            intersection = 1; }; // Current point is inside the node bbox, but stay in loop for debugging the line
    end;
    var int s; s = SB_New(); // Print info to zSpy
    SB("freeAimDetectCriticalHit: ");
    SB("criticalhit="); SBi(intersection); SB(" ");
    SB("basedamage="); SBi(roundf(weakspot.bDmg)); SB("/"); SBi(roundf(MEM_ReadInt(damagePtr))); SB(" ");
    SB("ciriticalnode='"); SB(weakspot.node); SB("' ");
    SB(" ("); SBi(weakspot.dimX); SB("x"); SBi(weakspot.dimY); SB(")");
    MEM_Info(SB_ToString()); SB_Destroy();
    if (intersection) { // Critical hit detected
        freeAimCriticalHitEvent_(targetNpc); // Use this function to add an event, e.g. a print or a sound
        MEM_WriteInt(damagePtr, weakspot.bDmg); // Base damage not final damage
    };
};
