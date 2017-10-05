/*
 * Critical hit detection for ranged combat
 *
 * Gothic Free Aim (GFA) v1.0.0-beta.20 - Free aiming for the video games Gothic 1 and Gothic 2 by Piranha Bytes
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
func void GFA_CH_GetCriticalHitDefinitions_(var C_Npc target, var int damage, var int damageType, var int returnPtr) {
    // Get readied/equipped ranged weapon
    var int talent; var int weaponPtr;
    GFA_GetWeaponAndTalent(hero, _@(weaponPtr), _@(talent));
    var C_Item weapon; weapon = _^(weaponPtr);

    // Define a critical hit/weak spot in config
    GFA_GetCriticalHitDefinitions(target, weapon, talent, damage, damageType, returnPtr);

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
 * Detect intersection of the projectile trajectory (defined in GFA_DebugCollTrj) with a node of an npc. This function
 * is called from GFA_CH_DetectCriticalHit().
 */
func int GFA_CH_DetectIntersectionWithNode(var int npcPtr, var string nodeName, var int debugInfoPtr) {
    // Allow empty string pointer
    if (!debugInfoPtr) {
        debugInfoPtr = _@s("");
    };

    // Retrieve model of the NPC
    var zCVob npc; npc = _^(npcPtr);
    var int model; model = npc.visual;
    if (!objCheckInheritance(model, zCModel__classDef)) {
        MEM_WriteString(debugInfoPtr, "NPC visual is not a model");
        return FALSE;
    };

    // Find node by string in model node list
    var zCArray nodes; nodes = _^(model+zCModel_modelNodeInstArray_offset); // zCArray<zCModelNodeInst*>
    repeat(nodeIdx, nodes.numInArray); var int nodeIdx;
        var int nodeInst; nodeInst = MEM_ReadIntArray(nodes.array, nodeIdx); // zCModelNodeInst*
        var int node; node = MEM_ReadInt(nodeInst+zCModelNodeInst_protoNode_offset); // zCModelNode*
        if (Hlp_StrCmp(MEM_ReadString(node+zCModelNode_nodeName_offset), nodeName)) {
            break;
        };
    end;
    if (nodeIdx == nodes.numInArray) {
        MEM_WriteString(debugInfoPtr, "Node not found in NPC model");
        return FALSE;
    };

    // Set up vectors from projectile trajectory for detection trace rays
    var int fromPosPtr; fromPosPtr = _@(GFA_DebugCollTrj);
    var int dir[3];
    dir[0] = subf(GFA_DebugCollTrj[3], GFA_DebugCollTrj[0]);
    dir[1] = subf(GFA_DebugCollTrj[4], GFA_DebugCollTrj[1]);
    dir[2] = subf(GFA_DebugCollTrj[5], GFA_DebugCollTrj[2]);
    var int dirPosPtr; dirPosPtr = _@(dir);
    var int criticalhit;

    // Calculate node bounding boxes and world coordinates
    const int call = 0;
    if (CALL_Begin(call)) {
        CALL__thiscall(_@(model), zCModel__CalcNodeListBBoxWorld);
        call = CALL_End();
    };

    // Use node visual directly if it exists
    if (MEM_ReadInt(nodeInst+zCModelNodeInst_visual_offset)) { // zCVisual*
        // Copy node bounding box
        MEM_CopyBytes(nodeInst+zCModelNodeInst_bbox3D_offset, _@(GFA_DebugWSBBox), sizeof_zTBBox3D);
        var int bboxPtr; bboxPtr = _@(GFA_DebugWSBBox);

        // Prevent debug drawing of oriented bounding box
        GFA_DebugWSOBBox[0] = 0;

        // Detect collision
        const int call2 = 0;
        if (CALL_Begin(call2)) {
            CALL_PtrParam(_@(dirPosPtr));      // Intersection vector (not needed)
            CALL_PtrParam(_@(dirPosPtr));      // Trace ray direction
            CALL_PtrParam(_@(fromPosPtr));     // Start vector
            CALL_PutRetValTo(_@(criticalhit)); // Did the trace ray hit
            CALL__thiscall(_@(bboxPtr), zTBBox3D__TraceRay); // This is a bounding box specific trace ray
            call2 = CALL_End();
        };
        return +criticalhit;
    };

    // Check model for soft skin list
    var zCArray skins; skins = _^(model+zCModel_meshSoftSkinList_offset); // zCArray<zCMeshSoftSkin*>
    if (skins.numInArray <= 0) {
        MEM_WriteString(debugInfoPtr, "No soft skins in NPC model");
        return FALSE;
    };

    // Some models seem to have several skins with different numbers of nodes, iterate over all skins until index found
    repeat(i, skins.numInArray); var int i;
        var int skin; skin = MEM_ReadIntArray(skins.array, i);

        // Find matching node index in this soft skin
        var zCArray nodeIndexList; nodeIndexList = _^(skin+zCMeshSoftSkin_nodeIndexList_offset); // zCArray<int>
        repeat(nodeIdxS, nodeIndexList.numInArray); var int nodeIdxS;
            if (MEM_ReadIntArray(nodeIndexList.array, nodeIdxS) == nodeIdx) {
                break;
            };
        end;
        if (nodeIdxS != nodeIndexList.numInArray) {
            // Found the index
            break;
        };
    end;
    if (i == skins.numInArray) {
        MEM_WriteString(debugInfoPtr, "Node index was not found in model soft skin");
        return FALSE;
    };

    // Obtain matching oriented bounding box from oriented bounding box list
    var zCArray nodeObbList; nodeObbList = _^(skin+zCMeshSoftSkin_nodeObbList_offset); // zCArray<zCOBBox3D*>
    if (nodeObbList.numInArray <= nodeIdxS) {
        MEM_WriteString(debugInfoPtr, "Node index exceeds soft skin OBBox list");
        return FALSE;
    };
    var int obboxPtr; obboxPtr = MEM_ReadIntArray(nodeObbList.array, nodeIdxS);

    // Copy OBBox to transform it and for debug visualization
    MEM_CopyBytes(obboxPtr, _@(GFA_DebugWSOBBox), sizeof_zCOBBox3D);
    obboxPtr = _@(GFA_DebugWSOBBox);

    // Prevent debug drawing of bounding box
    GFA_DebugWSBBox[0] = 0;

    // Transform OBBox to world coordinates
    var int trafoPtr; trafoPtr = nodeInst+zCModelNodeInst_trafoObjToCam_offset;
    const int call3 = 0;
    if (CALL_Begin(call3)) {
        CALL_PtrParam(_@(trafoPtr)); // zMAT4*
        CALL__thiscall(_@(obboxPtr), zCOBBox3D__Transform);
        call3 = CALL_End();
    };

    // Detect collision
    const int call4 = 0;
    if (CALL_Begin(call4)) {
        CALL_PtrParam(_@(dirPosPtr));      // Intersection vector (not needed)
        CALL_PtrParam(_@(dirPosPtr));      // Trace ray direction
        CALL_PtrParam(_@(fromPosPtr));     // Start vector
        CALL_PutRetValTo(_@(criticalhit)); // Did the trace ray hit
        CALL__thiscall(_@(obboxPtr), zCOBBox3D__TraceRay); // This is an oriented bounding box specific trace ray
        call4 = CALL_End();
    };
    return +criticalhit;
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

    // Do this for one damage type only. It gets too complicated for multiple damage types
    var oCItem projectile; projectile = _^(MEM_ReadInt(arrowAI+oCAIArrowBase_hostVob_offset));
    var int iterator; iterator = projectile.damageType;
    var int damageIndex; damageIndex = 0;
    // Find damage index from bit field
    while((iterator > 0) && ((iterator & 1) != 1)); // Check lower bit
        damageIndex += 1;
        // Cut off lower bit
        iterator = iterator >> 1;
    end;
    if (iterator > 1) || (damageIndex == DAM_INDEX_MAX) {
        if (GFA_DEBUG_PRINT) {
            MEM_Info("GFA_CH_DetectCriticalHit: Ignoring projectile due to multiple/invalid damage types.");
        };
        return;
    };

    var int damagePtr; damagePtr = MEMINT_SwitchG1G2(/*esp+48h-48h*/ ESP, /*esp+1ACh-C8h*/ ESP+228); // zREAL*
    var int targetPtr; targetPtr = MEMINT_SwitchG1G2(EBX, MEM_ReadInt(/*esp+1ACh-190h*/ ESP+28)); // oCNpc*
    var C_Npc targetNpc; targetNpc = _^(targetPtr);
    var int protection;
    if (GOTHIC_BASE_VERSION == 1) {
        protection = MEM_ReadStatArr(_@(targetNpc.protection), damageIndex);
    } else {
        // Gothic 2 always considers point protection
        protection = targetNpc.protection[PROT_POINT];
    };

    // Check if NPC is down, function is not yet defined at time of parsing
    MEM_PushInstParam(targetNpc);
    MEM_Call(C_NpcIsDown); // C_NpcIsDown(targetNpc);
    if (MEM_PopIntResult()) {
        return;
    };

    // Get weak spot node from target model
    var int weakspotPtr; weakspotPtr = MEM_Alloc(sizeof_Weakspot);
    var Weakspot weakspot; weakspot = _^(weakspotPtr);
    GFA_CH_GetCriticalHitDefinitions_(targetNpc, MEM_ReadInt(damagePtr), damageIndex, weakspotPtr); // Get weak spot

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
        criticalHit = GFA_CH_DetectIntersectionWithNode(targetPtr, weakspot.node, _@s(debugInfo));
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
            SBi(protection);
            SB(") = ");
            shotDamage = shotDamage-protection;
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
            SBi(protection);
            SB("), ");
            SBi(NPC_MINIMAL_DAMAGE);
            SB(" ] = ");
            shotDamage = (shotDamage+hero.attribute[ATR_DEXTERITY])-protection;
            if (protection == /*IMMUNE*/ -1) { // Gothic 2 only
                shotDamage = 0;
            } else if (shotDamage < NPC_MINIMAL_DAMAGE) {
                shotDamage = NPC_MINIMAL_DAMAGE; // Minimum damage in Gothic 2 as defined in AI_Constants.d
            };
            SBi(shotDamage);
        };
        MEM_Info(SB_ToString());
        SB_Clear();

        SB("   weak spot:         '");
        SB(weakspot.node);
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
