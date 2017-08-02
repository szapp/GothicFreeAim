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


/*
 * Wrapper function for the config function freeAimCriticalHitEvent(). It is called from freeAimDetectCriticalHit().
 * This function supplies the readied weapon.
 */
func void freeAimCriticalHitEvent_(var C_Npc target) {
    // Get readied/equipped ranged weapon
    var int weaponPtr;
    freeAimGetWeaponTalent(_@(weaponPtr), 0);
    var C_Item weapon; weapon = _^(weaponPtr);

    // Start an event from config
    freeAimCriticalHitEvent(target, weapon, (FREEAIM_ACTIVE && FREEAIM_RANGED));
};


/*
 * Wrapper function for the config function freeAimCriticalHitDef(). It is called from freeAimDetectCriticalHit().
 * This function is necessary for error handling and to supply the readied weapon.
 */
func void freeAimCriticalHitDef_(var C_Npc target, var int damage, var int returnPtr) {
    // Get readied/equipped ranged weapon
    var int talent; var int weaponPtr;
    freeAimGetWeaponTalent(_@(weaponPtr), _@(talent));
    var C_Item weapon; weapon = _^(weaponPtr);

    // Define a critical hit/weak spot in config
    freeAimCriticalHitDef(target, weapon, talent, damage, returnPtr);

    // Correct the node string to be always upper case
    var Weakspot weakspot; weakspot = _^(returnPtr);
    weakspot.node = STR_Upper(weakspot.node);

    // Correct negative damage
    if (lf(weakspot.bDmg, FLOATNULL)) {
        weakspot.bDmg = FLOATNULL;
    };
};


/*
 * Wrapper function for the config function freeAimCriticalHitAutoAim(). It is called from freeAimDetectCriticalHit().
 * This function is necessary to supply the readied weapon and respective talent value.
 */
func int freeAimCriticalHitAutoAim_(var C_Npc target) {
    // Get readied/equipped ranged weapon
    var int talent; var int weaponPtr;
    freeAimGetWeaponTalent(_@(weaponPtr), _@(talent));
    var C_Item weapon; weapon = _^(weaponPtr);

    // Retrieve auto aim critical hit chance from config
    var int criticalHitChance; criticalHitChance = freeAimCriticalHitAutoAim(target, weapon, talent);

    // Must be a percentage in range of [0, 100]
    if (criticalHitChance > 100) {
        criticalHitChance = 100;
    } else if (criticalHitChance < 0) {
        criticalHitChance = 0;
    };
    return criticalHitChance;
};

/*
 * Detect critical hits and adjust base damage. This function hooks the engine function responsible for hit registration
 * and dealing of damage. By walking along the trajectory line of the projectile in space, it is checked whether it hit
 * a defined critical node/bone or weak spot, as defined in freeAimCriticalHitDef(). If a critical hit is detected
 * the damage is adjusted and an event is called: freeAimCriticalHitEvent().
 */
func void freeAimDetectCriticalHit() {
    // First check if shooter is player and if FA is enabled
    var int arrowAI; arrowAI = MEMINT_SwitchG1G2(ESI, EBP);
    var C_Npc shooter; shooter = _^(MEM_ReadInt(arrowAI+oCAIArrow_origin_offset));
    if (!Npc_IsPlayer(shooter)) {
        return;
    };

    var int damagePtr; damagePtr = MEMINT_SwitchG1G2(/*esp+48h-48h*/ ESP, /*esp+1B0h-C8h*/ ESP+232); // zREAL*
    var int targetPtr; targetPtr = MEMINT_SwitchG1G2(EBX, MEM_ReadInt(/*esp+1ACh-190h*/ ESP+28)); // oCNpc*
    var C_Npc targetNpc; targetNpc = _^(targetPtr);

    // Get weak spot node from target model
    var int weakspotPtr; weakspotPtr = MEM_Alloc(sizeof_Weakspot);
    var Weakspot weakspot; weakspot = _^(weakspotPtr);
    freeAimCriticalHitDef_(targetNpc, MEM_ReadInt(damagePtr), weakspotPtr); // Retrieve weak spot specs

    var int criticalHit; // Variable that holds whether a critical hit was detected

    if (Hlp_StrCmp(weakspot.node, "")) {
        // No critical node defined
        criticalHit = 0;

    } else if (!FREEAIM_ACTIVE) || (!FREEAIM_RANGED) {

        // Critical hits cause an advantage when playing with free aiming enabled compared to auto aim. This is, because
        // there are not critical hits for ranged combat in Gothic 2. Here, they are introduced for balancing reasons.
        // Note: Gothic 1 already has critical hits for auto aiming. This is replaced here.
        var int critChance; critChance = freeAimCriticalHitAutoAim_(targetNpc);
        criticalHit = (r_MinMax(1, 100) <= critChance); // Allow critChance=0 to disable this feature

    } else {
        // When free aiming is enabled the critical hit is determined by the actual node/bone, the projectile hits

        // Get model from target NPC
        const int call = 0;
        if (CALL_Begin(call)) {
            CALL__thiscall(_@(targetPtr), oCNpc__GetModel);
            call = CALL_End();
        };
        var int model; model = CALL_RetValAsPtr();

        // Retrieve model node from node name
        var int nodeStrPtr; nodeStrPtr = _@s(weakspot.node);
        const int call2 = 0;
        if (CALL_Begin(call2)) {
            CALL_PtrParam(_@(nodeStrPtr));
            CALL__thiscall(_@(model), zCModel__SearchNode);
            call2 = CALL_End();
        };
        var int node; node = CALL_RetValAsPtr(); // zCModelNodeInst*
        if (!node) {
            MEM_Warn("freeAimDetectCriticalHit: Node not found!");
            MEM_Free(weakspotPtr);
            return;
        };

        // Retrieve/create bounding box from dimensions
        if (weakspot.dimX == -1) && (weakspot.dimY == -1) {
            // If the model node has a dedicated visual and hence its own bounding box, the dimensions may be retrieved
            // automatically, by specifying dimensions of -1. (Only works for heads of humanoids.)
            if (MEM_ReadInt(node+zCModelNodeInst_visual_offset)) {

                // Although zCModelNodeInst has a zTBBox3D class variable, it is empty the first time and needs to be
                // retrieved by calling this engine function:
                // No recyclable call possible, because the return value is a structure (needs to be freed manually).
                CALL_PtrParam(node);
                CALL_RetValIsStruct(sizeof_zTBBox3D);
                CALL__thiscall(model, zCModel__GetBBox3DNodeWorld);
                var int nodeBBoxPtr; nodeBBoxPtr = CALL_RetValAsPtr();

                // Copy the positions in order to free the retrieved bounding box immediately
                MEM_CopyBytes(nodeBBoxPtr, _@(freeAimDebugWSBBox), sizeof_zTBBox3D);
                MEM_Free(nodeBBoxPtr);
            } else {

                // This is an error (instead of a warning), because it is a reckless design flaw if defining a weak spot
                // with dimensions -1 for a model that does not have a designated node visual (this only works with the
                // head node of humanoids). This error should thus only appear during development. If it does in the
                // released mod, get some better beta testers
                MEM_Error("freeAimDetectCriticalHit: Node has no bounding box!");
                MEM_Free(weakspotPtr);
                return;
            };

        } else if (weakspot.dimX < 0) || (weakspot.dimY < 0) {
            // Bounding box dimensions must be positive
            MEM_Error("freeAimDetectCriticalHit: Bounding box dimensions invalid!");
            MEM_Free(weakspotPtr);
            return;

        } else {
            // Create bounding box by dimensions
            weakspot.dimX /= 2;
            weakspot.dimY /= 2;

            // Although zCModelNodeInst has a position class variable, it is empty the first time and needs to be
            // retrieved by calling this engine function:
            // No recyclable call possible, because the return value is a structure (needs to be freed manually).
            CALL_PtrParam(node);
            CALL_RetValIsStruct(sizeof_zVEC3);
            CALL__thiscall(model, zCModel__GetNodePositionWorld);
            var int nodPosPtr; nodPosPtr = CALL_RetValAsPtr();

            // Copy the positions in order to free the retrieved vector immediately
            var int nodePos[3];
            MEM_CopyBytes(nodPosPtr, _@(nodePos), sizeof_zVEC3);
            MEM_Free(nodPosPtr);

            // Build a bounding box by the passed node dimensions
            freeAimDebugWSBBox[0] = subf(nodePos[0], mkf(weakspot.dimX));
            freeAimDebugWSBBox[1] = subf(nodePos[1], mkf(weakspot.dimY));
            freeAimDebugWSBBox[2] = subf(nodePos[2], mkf(weakspot.dimX));
            freeAimDebugWSBBox[3] = addf(nodePos[0], mkf(weakspot.dimX));
            freeAimDebugWSBBox[4] = addf(nodePos[1], mkf(weakspot.dimY));
            freeAimDebugWSBBox[5] = addf(nodePos[2], mkf(weakspot.dimX));
        };

        // The internal engine functions are not accurate enough for detecting a shot through a bounding box. Instead
        // check here if "any" point along the line of projectile direction lies inside the bounding box of the node
        var oCItem projectile; projectile = _^(MEM_ReadInt(arrowAI+oCAIArrowBase_hostVob_offset));

        // Direction of collision line along the right-vector of the projectile (projectile flies sideways)
        var int dir[3];
        dir[0] = projectile._zCVob_trafoObjToWorld[0];
        dir[1] = projectile._zCVob_trafoObjToWorld[4];
        dir[2] = projectile._zCVob_trafoObjToWorld[8];

        // Trajectory starts 3 meters (FLOAT3C) behind the projectile position, to detect bounding boxes at close range
        freeAimDebugWSTrj[0] = addf(projectile._zCVob_trafoObjToWorld[ 3], mulf(dir[0], FLOAT3C));
        freeAimDebugWSTrj[1] = addf(projectile._zCVob_trafoObjToWorld[ 7], mulf(dir[1], FLOAT3C));
        freeAimDebugWSTrj[2] = addf(projectile._zCVob_trafoObjToWorld[11], mulf(dir[2], FLOAT3C));


        // Loop to walk along the trajectory of the projectile
        criticalHit = 0;
        var int i; i=0; // Loop increment
        var int iter; iter = 700/5; // 7m: Max distance from model bounding box edge to node bounding box (e.g. troll)
        while(i <= iter); i += 1; // Walk along the line in steps of 5 cm
            // Next point along the collision line
            freeAimDebugWSTrj[3] = subf(freeAimDebugWSTrj[0], mulf(dir[0], mkf(i*5)));
            freeAimDebugWSTrj[4] = subf(freeAimDebugWSTrj[1], mulf(dir[1], mkf(i*5)));
            freeAimDebugWSTrj[5] = subf(freeAimDebugWSTrj[2], mulf(dir[2], mkf(i*5)));

            // Check if current point is inside the node bounding box, but stay in loop for complete line (debugging)
            if (lef(freeAimDebugWSBBox[0], freeAimDebugWSTrj[3])) && (lef(freeAimDebugWSBBox[1], freeAimDebugWSTrj[4]))
            && (lef(freeAimDebugWSBBox[2], freeAimDebugWSTrj[5])) && (gef(freeAimDebugWSBBox[3], freeAimDebugWSTrj[3]))
            && (gef(freeAimDebugWSBBox[4], freeAimDebugWSTrj[4])) && (gef(freeAimDebugWSBBox[5], freeAimDebugWSTrj[5])){
                criticalHit = 1;
            };
        end;
    };

    // Print info to zSpy
    MEM_Info("freeAimDetectCriticalHit:");
    var int s; s = SB_New();

    SB("   criticalhit=");
    SBi(criticalHit);
    MEM_Info(SB_ToString());
    SB_Clear();

    SB("   basedamage=");
    SBi(roundf(MEM_ReadInt(damagePtr)));
    MEM_Info(SB_ToString());
    SB_Clear();

    SB("   critdamage=");
    SBi(roundf(weakspot.bDmg));
    MEM_Info(SB_ToString());
    SB_Clear();

    SB("   criticalnode='");
    SB(weakspot.node);
    SB("' (");
    SBi(weakspot.dimX);
    SB("x");
    SBi(weakspot.dimY);
    SB(")");
    MEM_Info(SB_ToString());
    SB_Destroy();

    // Create an event, if a critical hit was detected
    if (criticalHit) {
        freeAimCriticalHitEvent_(targetNpc); // Use this function to add an event, e.g. a print or a sound
        MEM_WriteInt(damagePtr, weakspot.bDmg); // Base damage not final damage
    };
    MEM_Free(weakspotPtr);
};


/*
 * Disable ranged critical hits in Gothic 1. This mechanic is replaced by freeAimCriticalHitAutoAim(). This function
 * hooks oCNpc::OnDamage_Hit() at an offset where the critical hit chance is retrieved. This value is replaced with
 * zero to disable internal critical hits for ranged combat.
 * This function is only called for Gothic 1, as there are no internal critical hits in Gothic 2 for ranged weapons.
 */
func void freeAimDisableDefaultCriticalHits() {
    // Check if shooter is player or if not in ranged combat
    var int dmgDescriptor; dmgDescriptor = MEM_ReadInt(ESP+548); // esp+220h+4h // oCNpc::oSDamageDescriptor*
    var C_Npc shooter; shooter = _^(MEM_ReadInt(dmgDescriptor+oSDamageDescriptor_origin_offset)); // oCNpc*
    if (Npc_IsPlayer(shooter)) && (Npc_IsInFightMode(shooter, FMODE_FAR)) {
        EBP = 0;
    };
};