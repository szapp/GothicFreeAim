/*
 * Critical hit detection for ranged combat
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
 * Wrapper function for the config functions GFA_GetCriticalHit() and GFA_GetCriticalHitAutoAim(). It is called from
 * GFA_CH_DetectCriticalHit().
 * This function is necessary for error handling and to supply the readied weapon and respective talent value.
 */
func void GFA_CH_GetCriticalHit_(var C_Npc target, var int dmgMsgPtr) {
    // Get readied/equipped ranged weapon
    var int talent; var int weaponPtr; var C_Item weapon;
    if (GFA_GetWeaponAndTalent(hero, _@(weaponPtr), _@(talent))) {
        weapon = _^(weaponPtr);
    } else {
        weapon = MEM_NullToInst();
    };

    // Define new damage in config
    if (GFA_ACTIVE) && (GFA_Flags & GFA_RANGED) {
        GFA_GetCriticalHit(target, GFA_HitModelNode, weapon, talent, dmgMsgPtr);
    } else {
        // Critical hits cause an advantage when playing with free aiming enabled compared to auto aim. This is, because
        // there are no critical hits for ranged combat in Gothic 2. Here, they are introduced for balancing reasons.
        // Note: Gothic 1 already has critical hits for auto aiming. This is replaced here.
        GFA_GetCriticalHitAutoAim(target, weapon, talent, dmgMsgPtr);
        GFA_HitModelNode = "";
    };

    // Correct negative damage
    var DmgMsg damage; damage = _^(dmgMsgPtr);
    if (lf(damage.value, FLOATNULL)) {
        damage.value = FLOATNULL;
    };

    // Verify damage behavior
    if (damage.behavior < DMG_NO_CHANGE) || (damage.behavior > DMG_BEHAVIOR_MAX) {
        MEM_SendToSpy(zERR_TYPE_WARN, "GFA_CH_GetCriticalHit_: Invalid damage behavior!");
        damage.behavior = DMG_NO_CHANGE;
    };

    return;
};


/*
 * Visualize a model node of an NPC. This function is called from GFA_CH_DetectCriticalHit().
 */
func void GFA_CH_VisualizeModelNode(var int npcPtr, var string nodeName) {
    const int emptyBBox = 0;
    if (!emptyBBox) {
        emptyBBox = MEM_Alloc(sizeof_zTBBox3D);
    };
    const int emptyOBBox = 0;
    if (!emptyOBBox) {
        emptyOBBox = MEM_Alloc(sizeof_zCOBBox3D);
    };

    // Reset (remove) visualizations
    if (BBoxVisible(GFA_DebugBoneBBox)) {
        UpdateBBoxAddr(GFA_DebugBoneBBox, emptyBBox);
    };

    if (OBBoxVisible(GFA_DebugBoneOBBox)) {
        UpdateOBBoxAddr(GFA_DebugBoneOBBox, emptyOBBox);
    };

    // Exit if nodeName is empty
    if (Hlp_StrCmp(nodeName, "")) {
        return;
    };

    // Retrieve model of the NPC
    var zCVob npc; npc = _^(npcPtr);
    var int model; model = npc.visual;
    if (!objCheckInheritance(model, zCModel__classDef)) {
        MEM_SendToSpy(zERR_TYPE_WARN, "GFA_CH_VisualizeModelNode: NPC visual is not a model");
        return;
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
        MEM_SendToSpy(zERR_TYPE_WARN, "GFA_CH_VisualizeModelNode: Node not found in NPC model");
        return;
    };

    // Calculate node bounding boxes and world coordinates
    const int call = 0;
    if (CALL_Begin(call)) {
        CALL__thiscall(_@(model), zCModel__CalcNodeListBBoxWorld);
        call = CALL_End();
    };

    // Use node visual directly if it exists
    if (MEM_ReadInt(nodeInst+zCModelNodeInst_visual_offset)) { // zCVisual*
        var int bboxPtr; bboxPtr = nodeInst+zCModelNodeInst_bbox3D_offset;

        // Debug visualization
        if (BBoxVisible(GFA_DebugBoneBBox)) {
            UpdateBBoxAddr(GFA_DebugBoneBBox, bboxPtr);
        };

        return;
    };

    // Check model for soft skin list
    var zCArray skins; skins = _^(model+zCModel_meshSoftSkinList_offset); // zCArray<zCMeshSoftSkin*>
    if (skins.numInArray <= 0) {
        MEM_SendToSpy(zERR_TYPE_WARN, "GFA_CH_VisualizeModelNode: No soft skins in NPC model");
        return;
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
        MEM_SendToSpy(zERR_TYPE_WARN, "GFA_CH_VisualizeModelNode: Node index was not found in model soft skin");
        return;
    };

    // Obtain matching oriented bounding box from oriented bounding box list
    var zCArray nodeObbList; nodeObbList = _^(skin+zCMeshSoftSkin_nodeObbList_offset); // zCArray<zCOBBox3D*>
    if (nodeObbList.numInArray <= nodeIdxS) {
        MEM_SendToSpy(zERR_TYPE_WARN, "GFA_CH_VisualizeModelNode: Node index exceeds soft skin OBBox list");
        return;
    };
    var int obboxPtr; obboxPtr = MEM_ReadIntArray(nodeObbList.array, nodeIdxS);

    // Copy OBBox to transform it
    var int obboxTrf; obboxTrf = MEM_Alloc(sizeof_zCOBBox3D);
    MEM_CopyBytes(obboxPtr, obboxTrf, sizeof_zCOBBox3D);
    obboxPtr = obboxTrf;

    // Transform OBBox to world coordinates
    var int trafoPtr; trafoPtr = nodeInst+zCModelNodeInst_trafoObjToCam_offset;
    const int call3 = 0;
    if (CALL_Begin(call3)) {
        CALL_PtrParam(_@(trafoPtr)); // zMAT4*
        CALL__thiscall(_@(obboxPtr), zCOBBox3D__Transform);
        call3 = CALL_End();
    };

    // Debug visualization
    if (OBBoxVisible(GFA_DebugBoneOBBox)) {
        UpdateOBBoxAddr(GFA_DebugBoneOBBox, obboxPtr);
    };

    MEM_Free(obboxPtr);
};


/*
 * Detect critical hits and adjust base damage. This function hooks the engine function responsible for hit registration
 * and dealing of damage. The model node that was hit with the shot is passed to the config-function
 * GFA_GetCriticalHit() to alter the damage. Additionally, the damage behavior can be adjusted: Normal damage (kill or
 * knockout), instant kill or instant knockout.
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
    var int protection; protection = MEMINT_SwitchG1G2(MEM_ReadStatArr(_@(targetNpc.protection), damageIndex),
                                                       targetNpc.protection[PROT_POINT]); // G2: always point protection

    // Check if NPC is down, function is not yet defined at time of parsing
    MEM_PushInstParam(targetNpc);
    MEM_Call(C_NpcIsDown); // C_NpcIsDown(targetNpc);
    if (MEM_PopIntResult()) {
        return;
    };

    // Create damage message
    var int dmgMsgPtr; dmgMsgPtr = MEM_Alloc(sizeof_DmgMsg);
    var DmgMsg damage; damage = _^(dmgMsgPtr);
    damage.value      = MEM_ReadInt(damagePtr);
    damage.type       = damageIndex;
    damage.protection = protection; // G1: depends on damage type, G2: always point protection
    damage.behavior   = DMG_NO_CHANGE;
    damage.info       = "";

    // Update damage message in config
    GFA_CH_GetCriticalHit_(targetNpc, dmgMsgPtr);

    // Adjust damage for damage behavior
    var string damageBehaviorStr; // Debug output on zSpy
    if (damage.behavior) && (protection == /*IMMUNE*/ -1) { // Gothic 2 only
        damageBehaviorStr = "Target immune: Damage behavior not applied";
    } else if (damage.behavior) {
        var int baseDamage; baseDamage = roundf(damage.value);

        // Calculate final damage (to be applied to the target) from base damage
        var int finalDamage;
        if (GOTHIC_BASE_VERSION == 1) {
            finalDamage = baseDamage-protection;
            if (finalDamage < 0) {
                finalDamage = 0;
            };
        } else {
            finalDamage = (baseDamage+hero.attribute[ATR_DEXTERITY])-protection;
            if (finalDamage < NPC_MINIMAL_DAMAGE) {
                finalDamage = NPC_MINIMAL_DAMAGE;
            };
        };

        // Manipulate final damage
        var int newFinalDamage; newFinalDamage = finalDamage;
        if (damage.behavior == DMG_DO_NOT_KNOCKOUT) {
            damageBehaviorStr = "Normal damage, prevent knockout (HP != 1)";
            if (finalDamage == targetNpc.attribute[ATR_HITPOINTS]-1) {
                newFinalDamage = targetNpc.attribute[ATR_HITPOINTS]; // Never 1 HP
            };
        } else if (damage.behavior == DMG_DO_NOT_KILL) {
            damageBehaviorStr = "Normal damage, prevent kill (HP > 0)";
            if (finalDamage >= targetNpc.attribute[ATR_HITPOINTS]) {
                newFinalDamage = targetNpc.attribute[ATR_HITPOINTS]-1; // Never 0 HP
            };
        } else if (damage.behavior == DMG_INSTANT_KNOCKOUT) {
            damageBehaviorStr = "Instant knockout (1 HP)";
            newFinalDamage = targetNpc.attribute[ATR_HITPOINTS]-1; // 1 HP
        } else if (damage.behavior == DMG_INSTANT_KILL) {
            damageBehaviorStr = "Instant kill (0 HP)";
            newFinalDamage = targetNpc.attribute[ATR_HITPOINTS]; // 0 HP
        };

        // Adjustment for minimal damage in Gothic 2
        if (GOTHIC_BASE_VERSION == 2) && (newFinalDamage < NPC_MINIMAL_DAMAGE) {
            targetNpc.attribute[ATR_HITPOINTS] += NPC_MINIMAL_DAMAGE;
            newFinalDamage += NPC_MINIMAL_DAMAGE;
        };

        // Calculate new base damage from adjusted newFinalDamage
        var int newBaseDamage;
        if (GOTHIC_BASE_VERSION == 1) {
            // If new final damage is zero, the new base damage is also
            if (newFinalDamage) {
                newBaseDamage = newFinalDamage+protection;
            } else if (baseDamage-protection <= 0) {
                newBaseDamage = baseDamage;
            } else {
                newBaseDamage = 0;
            };
        } else {
            // If new final damage is less that NPC_MINIMAL_DAMAGE, the new base damage stays zero
            if (newFinalDamage > NPC_MINIMAL_DAMAGE) {
                newBaseDamage = (newFinalDamage+protection)-hero.attribute[ATR_DEXTERITY];
            } else if ((baseDamage+hero.attribute[ATR_DEXTERITY])-protection <= NPC_MINIMAL_DAMAGE) {
                newBaseDamage = baseDamage;
            } else {
                newBaseDamage = 0;
            };
        };

        // If the new base damage is below zero, increase the hit points to balance out the final damage
        if (newBaseDamage < 0) {
            targetNpc.attribute[ATR_HITPOINTS] += -newBaseDamage;
            newBaseDamage = 0;
        };

        // Overwrite base damage to yield damage behavior
        damage.value = mkf(newBaseDamage);
    };

    // Debug visualization
    if (BBoxVisible(GFA_DebugBoneBBox)) || (OBBoxVisible(GFA_DebugBoneOBBox)) {
        GFA_CH_VisualizeModelNode(targetPtr, GFA_HitModelNode);
    };

    if (GFA_DEBUG_PRINT) {
        MEM_Info("GFA_CH_DetectCriticalHit:");
        var int s; s = SB_New();

        if (damage.behavior) {
            SB("   damage behavior:   ");
            SB(damageBehaviorStr);
            MEM_Info(SB_ToString());
            SB_Clear();
        };

        var int newDamageInt; newDamageInt = roundf(damage.value);
        SB("   base damage (n/o): ");
        SBi(newDamageInt);
        SB("/");
        SBi(roundf(MEM_ReadInt(damagePtr)));
        MEM_Info(SB_ToString());
        SB_Clear();

        SB("   damage on target:  ");
        // Calculate damage by formula (incl. protection of target, etc.)
        if (GOTHIC_BASE_VERSION == 1) {
            SB("(");
            SBi(newDamageInt);
            SB(" - ");
            SBi(protection);
            SB(") = ");
            newDamageInt = newDamageInt-protection;
            if (newDamageInt < 0) {
                newDamageInt = 0;
            };
            SBi(newDamageInt);
        } else {
            SB("max[ (");
            SBi(newDamageInt);
            SB(" + ");
            SBi(hero.attribute[ATR_DEXTERITY]);
            SB(" - ");
            SBi(protection);
            SB("), ");
            SBi(NPC_MINIMAL_DAMAGE);
            SB(" ] = ");
            newDamageInt = (newDamageInt+hero.attribute[ATR_DEXTERITY])-protection;
            if (protection == /*IMMUNE*/ -1) { // Gothic 2 only
                newDamageInt = 0;
            } else if (newDamageInt < NPC_MINIMAL_DAMAGE) {
                newDamageInt = NPC_MINIMAL_DAMAGE; // Minimum damage in Gothic 2 as defined in AI_Constants.d
            };
            SBi(newDamageInt);
        };
        MEM_Info(SB_ToString());
        SB_Clear();

        SB("   hit model bone:    '");
        SB(GFA_HitModelNode);
        SB("'");
        MEM_Info(SB_ToString());
        SB_Destroy();

        // Config debug info
        if (!Hlp_StrCmp(damage.info, "")) {
            MEM_Info(ConcatStrings("   ", damage.info));
        };
    };

    // Overwrite base damage value
    MEM_WriteInt(damagePtr, damage.value);
    MEM_Free(dmgMsgPtr);
};


/*
 * Disable ranged critical hits in Gothic 1. This mechanic is replaced by GFA_GetCriticalHitAutoAim(). This function
 * hooks oCNpc::OnDamage_Hit() at an offset where the critical hit chance is retrieved. This value is replaced with
 * zero to disable internal critical hits for ranged combat.
 * This function is only called for Gothic 1, as there are no internal critical hits in Gothic 2 for ranged weapons.
 */
func void GFA_CH_DisableDefaultCriticalHits() {
    // Check if shooter is player and if in ranged combat
    var int dmgDescriptor; dmgDescriptor = MEM_ReadInt(ESP+548); // esp+220h+4h // oCNpc::oSDamageDescriptor*
    var C_Npc shooter; shooter = _^(MEM_ReadInt(dmgDescriptor+oSDamageDescriptor_origin_offset)); // oCNpc*
    if (Npc_IsPlayer(shooter)) && (Npc_IsInFightMode(shooter, FMODE_FAR)) {
        // 99 % 100 + 1 = 100 and 100 is always higher than the critical hit talent, if (100 > talent): no critical hit
        EAX = 99;
    };
};
