/*
 * Critical hit detection for ranged combat
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
 * Wrapper function for the config function GFA_StartCriticalHitEvent(). It is called from GFA_CH_DetectCriticalHit().
 * This function supplies the readied weapon and checks whether free aiming is active.
 */
func void GFA_CH_StartCriticalHitEvent_(var C_Npc target) {
    // Get readied/equipped ranged weapon
    var int weaponPtr;
    GFA_GetWeaponAndTalent(hero, _@(weaponPtr), 0);
    var C_Item weapon; weapon = _^(weaponPtr);

    // Start an event from config
    GFA_StartCriticalHitEvent(target, weapon, (GFA_ACTIVE && (GFA_Flags & GFA_RANGED)));
};


/*
 * Wrapper function for the config function GFA_GetCriticalHitDefinitions(). It is called from
 * GFA_CH_DetectCriticalHit().
 * This function is necessary for error handling and to supply the readied weapon and respective talent value.
 */
func void GFA_CH_GetCriticalHitDefinitions_(var C_Npc target, var int damage, var int returnPtr) {
    // Get readied/equipped ranged weapon
    var int talent; var int weaponPtr;
    GFA_GetWeaponAndTalent(hero, _@(weaponPtr), _@(talent));
    var C_Item weapon; weapon = _^(weaponPtr);

    // Define a critical hit/weak spot in config
    GFA_GetCriticalHitDefinitions(target, weapon, talent, damage, returnPtr);

    // Correct the node string to be always upper case
    var Weakspot weakspot; weakspot = _^(returnPtr);
    weakspot.node = STR_Upper(weakspot.node);

    // Correct negative damage
    if (lf(weakspot.bDmg, FLOATNULL)) {
        weakspot.bDmg = FLOATNULL;
    };
};


/*
 * Wrapper function for the config function GFA_GetCriticalHitAutoAim(). It is called from GFA_CH_DetectCriticalHit().
 * This function is necessary to supply the readied weapon and respective talent value.
 */
func int GFA_CH_GetCriticalHitAutoAim_(var C_Npc target) {
    // Get readied/equipped ranged weapon
    var int talent; var int weaponPtr;
    GFA_GetWeaponAndTalent(hero, _@(weaponPtr), _@(talent));
    var C_Item weapon; weapon = _^(weaponPtr);

    // Retrieve auto aim critical hit chance from config
    var int criticalHitChance; criticalHitChance = GFA_GetCriticalHitAutoAim(target, weapon, talent);

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
 * a defined critical node/bone or weak spot, as defined in GFA_GetCriticalHitDefinitions(). If a critical hit is
 * detected the damage is adjusted and an event is called: GFA_StartCriticalHitEvent().
 */
func void GFA_CH_DetectCriticalHit() {
    // First check if shooter is player
    var int arrowAI; arrowAI = MEMINT_SwitchG1G2(ESI, EBP);
    var C_Npc shooter; shooter = _^(MEM_ReadInt(arrowAI+oCAIArrow_origin_offset));
    if (!Npc_IsPlayer(shooter)) {
        return;
    };

    // Do this for DAM_POINT only (relevant for Gothic 1, in Gothic 2 EVERYTHING counts as DAM_POINT for projectiles)
    var oCItem projectile; projectile = _^(MEM_ReadInt(arrowAI+oCAIArrowBase_hostVob_offset));
    if (projectile.damageType != DAM_POINT) {
        if (GFA_DEBUG_PRINT) {
            MEM_Info("GFA_CH_DetectCriticalHit: Ignoring projectile: Does not have pure POINT damage.");
        };
        return;
    };

    var int damagePtr; damagePtr = MEMINT_SwitchG1G2(/*esp+48h-48h*/ ESP, /*esp+1ACh-C8h*/ ESP+228); // zREAL*
    var int targetPtr; targetPtr = MEMINT_SwitchG1G2(EBX, MEM_ReadInt(/*esp+1ACh-190h*/ ESP+28)); // oCNpc*
    var C_Npc targetNpc; targetNpc = _^(targetPtr);

    // Check if NPC is down, function is not yet defined at time of parsing
    MEM_PushInstParam(targetNpc);
    MEM_Call(C_NpcIsDown); // C_NpcIsDown(targetNpc);
    if (MEM_PopIntResult()) {
        return;
    };

    // Get weak spot node from target model
    var int weakspotPtr; weakspotPtr = MEM_Alloc(sizeof_Weakspot);
    var Weakspot weakspot; weakspot = _^(weakspotPtr);
    GFA_CH_GetCriticalHitDefinitions_(targetNpc, MEM_ReadInt(damagePtr), weakspotPtr); // Retrieve weak spot specs

    var int criticalHit; // Variable that holds whether a critical hit was detected
    var string debugInfo; debugInfo = ""; // Internal debugging info string to display in zSpy (see GFA_DEBUG_PRINT)

    if (Hlp_StrCmp(weakspot.node, "")) {
        criticalHit = 0;
        debugInfo = "No weak spot defined in config";
    } else if (!GFA_ACTIVE) || (!(GFA_Flags & GFA_RANGED)) {
        // Critical hits cause an advantage when playing with free aiming enabled compared to auto aim. This is, because
        // there are no critical hits for ranged combat in Gothic 2. Here, they are introduced for balancing reasons.
        // Note: Gothic 1 already has critical hits for auto aiming. This is replaced here.
        var int critChance; critChance = GFA_CH_GetCriticalHitAutoAim_(targetNpc);
        criticalHit = (r_MinMax(1, 100) <= critChance); // Allow critChance=0 to disable this feature

        debugInfo = "Auto aiming: critical hit by probability (critical hit chance)";
    } else {
        // When free aiming is enabled the critical hit is determined by the actual node/bone that the projectile hits

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
            MEM_Warn("GFA_CH_DetectCriticalHit: Node not found!");
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
                MEM_CopyBytes(nodeBBoxPtr, _@(GFA_DebugWSBBox), sizeof_zTBBox3D);
                MEM_Free(nodeBBoxPtr);
            } else {
                // This is an error (instead of a warning), because it is a reckless design flaw if defining a weak spot
                // with dimensions -1 for a model that does not have a designated node visual (this only works with the
                // head node of humanoids). This error should thus only appear during development. If it does in the
                // released mod, get some better beta testers
                MEM_Error("GFA_CH_DetectCriticalHit: Node has no bounding box!");
                MEM_Free(weakspotPtr);
                return;
            };

        } else if (weakspot.dimX < 0) || (weakspot.dimY < 0) {
            MEM_Error("GFA_CH_DetectCriticalHit: Bounding box dimensions invalid!");
            MEM_Free(weakspotPtr);
            return;

        } else {
            // Create bounding box by dimensions
            var int dimX; dimX = mkf(weakspot.dimX/2); // Do not overwrite weak spot properties, needed for zSpy output
            var int dimY; dimY = mkf(weakspot.dimY/2);

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
            GFA_DebugWSBBox[0] = subf(nodePos[0], dimX);
            GFA_DebugWSBBox[1] = subf(nodePos[1], dimY);
            GFA_DebugWSBBox[2] = subf(nodePos[2], dimX);
            GFA_DebugWSBBox[3] = addf(nodePos[0], dimX);
            GFA_DebugWSBBox[4] = addf(nodePos[1], dimY);
            GFA_DebugWSBBox[5] = addf(nodePos[2], dimX);
        };

        // The internal engine functions are not accurate enough for detecting a shot through a bounding box. Instead
        // check here if 'any' point along the line of the projectile direction lies inside the bounding box of the node

        // Direction of collision line by subtracting the last position of the rigid body from the projectile position
        var int rBody; rBody = projectile._zCVob_rigidBody;
        if (!rBody) {
            return;
        };
        var int dir[3];
        dir[0] = subf(projectile._zCVob_trafoObjToWorld[ 3], MEM_ReadInt(rBody+zCRigidBody_xPos_offset));
        dir[1] = subf(projectile._zCVob_trafoObjToWorld[ 7], MEM_ReadInt(rBody+zCRigidBody_xPos_offset+4));
        dir[2] = subf(projectile._zCVob_trafoObjToWorld[11], MEM_ReadInt(rBody+zCRigidBody_xPos_offset+8));

        // Direction vector needs to be normalized
        var int dirPtr; dirPtr = _@(dir);
        const int call3 = 0;
        if (CALL_Begin(call3)) {
            CALL__thiscall(_@(dirPtr), zVEC3__NormalizeSafe);
            call3 = CALL_End();
        };
        MEM_CopyBytes(CALL_RetValAsPtr(), dirPtr, sizeof_zVEC3);

        // Trajectory starts 3 meters (FLOAT3C) behind the projectile position, to detect bounding boxes at close range
        GFA_DebugWSTrj[0] = addf(projectile._zCVob_trafoObjToWorld[ 3], mulf(dir[0], FLOAT3C));
        GFA_DebugWSTrj[1] = addf(projectile._zCVob_trafoObjToWorld[ 7], mulf(dir[1], FLOAT3C));
        GFA_DebugWSTrj[2] = addf(projectile._zCVob_trafoObjToWorld[11], mulf(dir[2], FLOAT3C));

        // Loop to walk along the trajectory of the projectile
        criticalHit = 0;
        var int i; i=0; // Loop index
        var int iter; iter = 700/5; // 7m: Max distance from model bounding box edge to node bounding box (e.g. troll)
        while(i <= iter); i += 1; // Walk along the line in steps of 5 cm
            // Next point along the collision line
            GFA_DebugWSTrj[3] = subf(GFA_DebugWSTrj[0], mulf(dir[0], mkf(i*5)));
            GFA_DebugWSTrj[4] = subf(GFA_DebugWSTrj[1], mulf(dir[1], mkf(i*5)));
            GFA_DebugWSTrj[5] = subf(GFA_DebugWSTrj[2], mulf(dir[2], mkf(i*5)));

            // Check if current point is inside the node bounding box, but stay in loop for complete line (debugging)
            if (lef(GFA_DebugWSBBox[0], GFA_DebugWSTrj[3])) && (lef(GFA_DebugWSBBox[1], GFA_DebugWSTrj[4]))
            && (lef(GFA_DebugWSBBox[2], GFA_DebugWSTrj[5])) && (gef(GFA_DebugWSBBox[3], GFA_DebugWSTrj[3]))
            && (gef(GFA_DebugWSBBox[4], GFA_DebugWSTrj[4])) && (gef(GFA_DebugWSBBox[5], GFA_DebugWSTrj[5])) {
                criticalHit = 1;
            };
        end;
    };

    if (GFA_DEBUG_PRINT) {
        MEM_Info("GFA_CH_DetectCriticalHit:");
        var int s; s = SB_New();

        SB("   critical hit:      ");
        var int shotDamage;
        if (criticalhit) {
            SB("yes");
            shotDamage = roundf(weakspot.bDmg);
        } else {
            SB("no");
            shotDamage = roundf(MEM_ReadInt(damagePtr));
        };
        MEM_Info(SB_ToString());
        SB_Clear();

        SB("   base damage:       ");
        SBi(roundf(MEM_ReadInt(damagePtr)));
        MEM_Info(SB_ToString());
        SB_Clear();

        SB("   critical damage:   ");
        SBi(roundf(weakspot.bDmg));
        MEM_Info(SB_ToString());
        SB_Clear();

        SB("   damage on target:  ");
        // Calculate damage by formula (incl. protection of target, etc.)
        if (GOTHIC_BASE_VERSION == 1) {
            SB("(");
            SBi(shotDamage);
            SB(" - ");
            SBi(targetNpc.protection[PROT_POINT]);
            SB(") = ");
            shotDamage = shotDamage-targetNpc.protection[PROT_POINT];
            if (shotDamage < 0) {
                shotDamage = 0;
            };
            SBi(shotDamage);
        } else {
            SB("max[ (");
            SBi(shotDamage);
            SB(" + ");
            SBi(hero.attribute[ATR_DEXTERITY]);
            SB(" - ");
            SBi(targetNpc.protection[PROT_POINT]);
            SB("), ");
            SBi(NPC_MINIMAL_DAMAGE);
            SB(" ] = ");
            shotDamage = (shotDamage+hero.attribute[ATR_DEXTERITY])-targetNpc.protection[PROT_POINT];
            if (shotDamage < NPC_MINIMAL_DAMAGE) {
                shotDamage = NPC_MINIMAL_DAMAGE; // Minimum damage in Gothic 2 as defined in AI_Constants.d
            };
            SBi(shotDamage);
        };
        MEM_Info(SB_ToString());
        SB_Clear();

        SB("   weak spot:         '");
        SB(weakspot.node);
        SB("' (");
        SBi(weakspot.dimX);
        SB("x");
        SBi(weakspot.dimY);
        SB(")");
        MEM_Info(SB_ToString());
        SB_Destroy();

        // Internal debug info
        if (!Hlp_StrCmp(debugInfo, "")) {
            MEM_Info(ConcatStrings("   ", debugInfo));
        };

        // Config debug info
        if (!Hlp_StrCmp(weakspot.debugInfo, "")) {
            MEM_Info(ConcatStrings("   ", weakspot.debugInfo));
        };
    };

    // Create an event, if a critical hit was detected
    if (criticalHit) {
        MEM_WriteInt(damagePtr, weakspot.bDmg); // Base damage not final damage
        GFA_LastHitCritical = TRUE; // Used for GFA_CC_SetDamageBehavior(), will be reset to FALSE immediately
        GFA_StatsCriticalHits += 1; // Update shooting statistics
        GFA_CH_StartCriticalHitEvent_(targetNpc); // Use this function to add an event, e.g. a print or a sound
    };
    MEM_Free(weakspotPtr);
};


/*
 * Disable ranged critical hits in Gothic 1. This mechanic is replaced by GFA_GetCriticalHitAutoAim(). This function
 * hooks oCNpc::OnDamage_Hit() at an offset where the critical hit chance is retrieved. This value is replaced with
 * zero to disable internal critical hits for ranged combat.
 * This function is only called for Gothic 1, as there are no internal critical hits in Gothic 2 for ranged weapons.
 */
func void GFA_CH_DisableDefaultCriticalHits() {
    // Check if shooter is player or if not in ranged combat
    var int dmgDescriptor; dmgDescriptor = MEM_ReadInt(ESP+548); // esp+220h+4h // oCNpc::oSDamageDescriptor*
    var C_Npc shooter; shooter = _^(MEM_ReadInt(dmgDescriptor+oSDamageDescriptor_origin_offset)); // oCNpc*
    if (Npc_IsPlayer(shooter)) && (Npc_IsInFightMode(shooter, FMODE_FAR)) {
        // 99 % 100 + 1 = 100 and 100 is always higher than the critical hit talent, if (100 > talent): no critical hit
        EAX = 99;
    };
};
