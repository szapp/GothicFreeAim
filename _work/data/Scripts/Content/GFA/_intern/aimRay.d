/*
 * Aim-specific trace ray and focus collection
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
 * Temporarily allow model trace ray for soft skin mesh.
 * For more information, see: https://github.com/szapp/GothicFreeAim/issues/159#issuecomment-331067324
 */
func void GFA_AllowSoftSkinTraceRay(var int on) {
    const int SET = 0;
    if (on == SET) {
        return; // No change necessary
    };

    if (on) {
        // Skip first soft skin check, and first only!
        // The opcode for G1 and G2 is functionally identical. However, the instruction in G2 is 6 bytes long
        MEM_WriteByte(zCModel__TraceRay_softSkinCheck, ASMINT_OP_nop);
        if (GOTHIC_BASE_VERSION == 1) {
            MEM_WriteByte(zCModel__TraceRay_softSkinCheck+1, /*33*/ 51); // xor  eax, eax
            MEM_WriteByte(zCModel__TraceRay_softSkinCheck+2, /*C0*/ 192);
        } else {
            MEM_WriteByte(zCModel__TraceRay_softSkinCheck+1, /*B8*/ 184); // mov  eax, 0
            MEM_WriteByte(zCModel__TraceRay_softSkinCheck+2, 0);
        };
    } else {
        // Disallow soft skin model trace ray (revert to default)
        // G1:  8B 43 78         mov  eax, [ebx+78h]
        // G2:  8B 86 84 0 0 0   mov  eax, [esi+84h]
        MEM_WriteByte(zCModel__TraceRay_softSkinCheck, /*8B*/ 139);
        MEM_WriteByte(zCModel__TraceRay_softSkinCheck+1, MEMINT_SwitchG1G2(/*43*/ 67, /*86*/ 134)); // EBX/ESI zCModel*
        MEM_WriteByte(zCModel__TraceRay_softSkinCheck+2, zCModel_meshSoftSkinList_numInArray_offset);
    };
    SET = !SET;
};


/*
 * Cast a specific ray to detect intersection with the head node of NPCs. This is necessary, because for NPCs with
 * dedicated head visuals (like all humans and some orcs), the model trace ray used in GFA_AimRay() does not include the
 * head node. This function is thus supplementary to GFA_AimRay() but also called from
 * GFA_RefinedProjectileCollisionCheck().
 */
func int GFA_AimRayHead(var int npcPtr, var int fromPosPtr, var int dirPosPtr, var int vecPtr) {
    var int hit; hit = FALSE;
    var oCNpc npc; npc = _^(npcPtr);
    if (!Hlp_StrCmp(npc.head_visualName, "") && (npc.anictrl)) {
        // Perform a lot of safety checks, to prevent crashes
        var zCAIPlayer playerAI; playerAI = _^(npc.anictrl);
        if (playerAI.modelHeadNode) {
            // Check if head has indeed a dedicated visual
            var int headNode; headNode = playerAI.modelHeadNode;
            if (MEM_ReadInt(headNode+zCModelNodeInst_visual_offset))
            && (objCheckInheritance(npc._zCVob_visual, zCModel__classDef)) {
                // Calculate bounding boxes of model nodes
                var int model; model = npc._zCVob_visual;
                const int call = 0;
                if (CALL_Begin(call)) {
                    CALL__thiscall(_@(model), zCModel__CalcNodeListBBoxWorld);
                    call = CALL_End();
                };
                var int headBBoxPtr; headBBoxPtr = headNode+zCModelNodeInst_bbox3D_offset;

                // If information about the intersection is not requeted, create disposable vector
                if (!vecPtr) {
                    var int vec[3];
                    vecPtr = _@(vec);
                };

                // Detect intersection with head bounding box
                const int call2 = 0;
                if (CALL_Begin(call2)) {
                    CALL_PtrParam(_@(vecPtr));     // Intersection vector
                    CALL_PtrParam(_@(dirPosPtr));  // Trace ray direction
                    CALL_PtrParam(_@(fromPosPtr)); // Start vector
                    CALL_PutRetValTo(_@(hit));     // Did the trace ray hit
                    CALL__thiscall(_@(headBBoxPtr), zTBBox3D__TraceRay); // This is a bounding box specific trace ray
                    call2 = CALL_End();
                };
            };
        };
    };
    return +hit;
};


/*
 * Shoot a trace ray to retrieve the point of intersection with the nearest object in the world and the distance, and to
 * overwrite the focus collection with a desired focus type. This function is customized for aiming and it is not
 * recommended to use for any other matter.
 * This function is rather complex, but well tested. It does not replace Gothic's focus collection, but builds on top of
 * if. Gothic's collected focus is necessary and acts as a 'suggestion', this function is validating.
 *
 * To increase performance, increase the value of GFA.focusUpdateIntervalMS in the Gothic INI-file. It determines the
 * interval in milliseconds in which the trace ray is recomputed. The upper bound is 500ms, which already introduces
 * a significant lag in the focus collection and reticle size (if applicable). A recommended value is below 50ms.
 */
func int GFA_AimRay(var int distance, var int focusType, var int vobPtr, var int posPtr, var int distPtr,
        var int trueDistPtr) {
    // Only run full trace ray machinery every so often (see GFA_RAY_INTERVAL) to allow weaker machines to run this
    var int curTime; curTime = MEM_Timer.totalTime; // Get current time
    if (curTime-GFA_AimRayPrevCalcTime >= GFA_RAY_INTERVAL) { // If the interval has passed, recompute trace ray
        // Update time of previous calculation
        GFA_AimRayPrevCalcTime = curTime;

        // The trace ray is cast along the camera viewing angle from a start point towards a direction/length vector

        // Get camera vob and player
        var zCVob camVob; camVob = _^(MEM_Game._zCSession_camVob);
        var zMAT4 camPos; camPos = _^(_@(camVob.trafoObjToWorld[0]));
        var oCNpc her; her = getPlayerInst();
        var int herPtr; herPtr = _@(her);

        // Shift the start point for the trace ray beyond the player model. This is necessary, because if zooming out
        //  (a) there might be something between camera and hero (unlikely) and
        //  (b) the maximum aiming distance is off and does not correspond to the parameter 'distance'
        // To do so, the distance between camera and player is computed:
        var int distCamToPlayer; distCamToPlayer = sqrtf(addf(addf( // Does not care about camera X shift, see below
            sqrf(subf(her._zCVob_trafoObjToWorld[ 3], camPos.v0[zMAT4_position])),
            sqrf(subf(her._zCVob_trafoObjToWorld[ 7], camPos.v1[zMAT4_position]))),
            sqrf(subf(her._zCVob_trafoObjToWorld[11], camPos.v2[zMAT4_position]))));

        // Shifting camera (shoulderview) is NOT RECOMMENDED. Because of the parallax effect, aiming becomes inaccurate
        if (GFA_CAMERA_X_SHIFT) {
            // This makes the distance mentioned above more complex and requires calculation of a point-line distance
            // between the camera and the player without taking any diagonal distance into account.
            // For illustration: http://mathworld.wolfram.com/Point-LineDistance3-Dimensional.html
            // There x0 is the camera, x1 (or x2) is the player model, and d is what is being calculated.

            // Line consisting of two points: Left and right of the player model along the camera right vector
            var int line[6];
            line[0] = subf(her._zCVob_trafoObjToWorld[ 3], mulf(camPos.v0[zMAT4_rightVec], FLOAT1K)); // Left
            line[1] = subf(her._zCVob_trafoObjToWorld[ 7], mulf(camPos.v1[zMAT4_rightVec], FLOAT1K));
            line[2] = subf(her._zCVob_trafoObjToWorld[11], mulf(camPos.v2[zMAT4_rightVec], FLOAT1K));
            line[3] = addf(her._zCVob_trafoObjToWorld[ 3], mulf(camPos.v0[zMAT4_rightVec], FLOAT1K)); // Right
            line[4] = addf(her._zCVob_trafoObjToWorld[ 7], mulf(camPos.v1[zMAT4_rightVec], FLOAT1K));
            line[5] = addf(her._zCVob_trafoObjToWorld[11], mulf(camPos.v2[zMAT4_rightVec], FLOAT1K));

            // Subtract both points of the line from the camera position
            var int u[3]; var int v[3];
            u[0] = subf(camPos.v0[zMAT4_position], line[0]);
            u[1] = subf(camPos.v1[zMAT4_position], line[1]);
            u[2] = subf(camPos.v2[zMAT4_position], line[2]);
            v[0] = subf(camPos.v0[zMAT4_position], line[3]);
            v[1] = subf(camPos.v1[zMAT4_position], line[4]);
            v[2] = subf(camPos.v2[zMAT4_position], line[5]);

            // Calculate the cross-product
            var int crossProd[3];
            crossProd[0] = subf(mulf(u[1], v[2]), mulf(u[2], v[1]));
            crossProd[1] = subf(mulf(u[2], v[0]), mulf(u[0], v[2]));
            crossProd[2] = subf(mulf(u[0], v[1]), mulf(u[1], v[0]));

            distCamToPlayer = sqrtf(addf(addf(sqrf(crossProd[0]), sqrf(crossProd[1])), sqrf(crossProd[2])));
            distCamToPlayer = divf(distCamToPlayer, mkf(2000)); // Divide area of triangle by length between the points
        };

        // The distance is used to create the direction vector in which to cast the trace ray
        distance = mkf(distance);

        // This array holds the start vector (world coordinates) and the direction vector (local coordinates)
        var int traceRayVec[6];
        traceRayVec[0] = addf(camPos.v0[zMAT4_position], mulf(camPos.v0[zMAT4_outVec], distCamToPlayer));
        traceRayVec[1] = addf(camPos.v1[zMAT4_position], mulf(camPos.v1[zMAT4_outVec], distCamToPlayer));
        traceRayVec[2] = addf(camPos.v2[zMAT4_position], mulf(camPos.v2[zMAT4_outVec], distCamToPlayer));
        traceRayVec[3] = mulf(camPos.v0[zMAT4_outVec], distance); // Direction-/to-vector of ray
        traceRayVec[4] = mulf(camPos.v1[zMAT4_outVec], distance);
        traceRayVec[5] = mulf(camPos.v2[zMAT4_outVec], distance);

        // The trace ray uses certain flags. These are very important the way they are and have been carefully chosen
        // and tested. Although the descriptions might be misleading, they should not be changed under any circumstances
        // especially the flag to ignore alpha polygons is counter intuitive, since that means that gates and fences
        // will be ignored although they have collision. However, this flag is buggy. It NEEDS to be present otherwise
        // artifacts will arise, like pseudo-random ignoring of walls and objects.
        var int flags; flags = zTRACERAY_vob_ignore_no_cd_dyn
                             | zTraceRay_poly_normal
                             | zTRACERAY_poly_ignore_transp // Do not change (will make trace ray unstable)
                             | zTRACERAY_poly_test_water
                             | zTRACERAY_vob_ignore_projectiles;
        var int fromPosPtr; fromPosPtr = _@(traceRayVec);
        var int dirPosPtr; dirPosPtr = _@(traceRayVec)+sizeof_zVEC3;
        var int worldPtr; worldPtr = _@(MEM_World);
        GFA_AllowSoftSkinTraceRay(1);
        const int call = 0;
        if (CALL_Begin(call)) {
            CALL_IntParam(_@(flags));     // Trace ray flags
            CALL_PtrParam(_@(herPtr));    // Ignore player model
            CALL_PtrParam(_@(dirPosPtr)); // Trace ray direction
            CALL_PutRetValTo(_@(hit));    // Did the trace ray hit
            CALL__fastcall(_@(worldPtr), _@(fromPosPtr), zCWorld__TraceRayNearestHit_Vob);
            call = CALL_End();
        };
        GFA_AllowSoftSkinTraceRay(0);

        // Retrieve trace ray report
        var int foundVob; foundVob = MEM_World.foundVob;
        var int intersection[3];
        MEM_CopyBytes(_@(MEM_World.foundIntersection), _@(intersection), sizeof_zVEC3);

        // Correct the focus collection. Since the focus collection in Gothic is designed by angles, manipulating the
        // instances in Focus.d, will lead nowhere, when aiming at a distance as angles become wider. Instead, if a
        // focus vob was collected by the engine, it will be checked whether it was hit by the trace ray which means
        // the camera is looking directly at it.
        var int foundFocus; foundFocus = 0;
        if (her.focus_vob) && (focusType) {
            // Check if collected focus matches the desired focus type (see function parameter 'focusType')

            if (focusType != TARGET_TYPE_ITEMS) && (Hlp_Is_oCNpc(her.focus_vob)) {
                // If an NPC focus is desired, more detailed checks are necessary

                // Check if NPC is undead, function is not yet defined at time of parsing
                var C_Npc target; target = _^(her.focus_vob);
                MEM_PushInstParam(target);
                MEM_Call(C_NpcIsUndead); // C_NpcIsUndead(target);
                var int npcIsUndead; npcIsUndead = MEM_PopIntResult();

                // More detailed focus type tests
                if (focusType == TARGET_TYPE_NPCS)                                           // Focus any NPC
                || ((focusType == TARGET_TYPE_ORCS) && (target.guild > GIL_SEPERATOR_ORC))   // Only focus orcs
                || ((focusType == TARGET_TYPE_HUMANS) && (target.guild < GIL_SEPERATOR_HUM)) // Only focus humans
                || ((focusType == TARGET_TYPE_UNDEAD) && (npcIsUndead)) {                    // Only focus undead NPCs
                    // If focus was already found
                    if (her.focus_vob == foundVob) {
                        foundFocus = her.focus_vob;
                    } else if (GFA_AimRayHead(her.focus_vob, fromPosPtr, dirPosPtr, _@(intersection))) {
                        // Otherwise, additionally detect head node (not included in model trace ray)
                        foundVob = her.focus_vob;
                        foundFocus = her.focus_vob;
                    };
                };
            } else if (focusType <= TARGET_TYPE_ITEMS) && (Hlp_Is_oCItem(her.focus_vob)) {
                // If an item focus is desired, perform another rougher trace ray (by bounding box). This ensures a
                // stable focus, because items might be rather small
                flags = flags | zTRACERAY_vob_bbox;
                var int focusVobPtr; focusVobPtr = her.focus_vob; // Write to variable, otherwise crash on new game
                var int trRep; trRep = MEM_Alloc(sizeof_zTTraceRayReport);
                const int call2 = 0;
                if (CALL_Begin(call2)) {
                    CALL_PtrParam(_@(trRep));      // zTTraceRayReport
                    CALL_IntParam(_@(flags));      // Trace ray flags
                    CALL_PtrParam(_@(dirPosPtr));  // Trace ray direction
                    CALL_PtrParam(_@(fromPosPtr)); // Start vector
                    CALL__thiscall(_@(focusVobPtr), zCVob__TraceRay); // This is a vob specific trace ray
                    call2 = CALL_End();
                };
                if (CALL_RetValAsInt()) {
                    // Got a hit: Update trace ray report
                    foundVob = her.focus_vob;
                    MEM_CopyBytes(trRep+zTTraceRayReport_foundIntersection_offset, _@(intersection), sizeof_zVEC3);
                    foundFocus = her.focus_vob; // Confirmed focus vob
                };
                MEM_Free(trRep); // Free the report
            };
        };

        // Calculate the distance to the player
        var int distHitToPlayer;
        if (!hit) && (!foundVob) {
            // Fix the intersection if there was no hit (trace ray is inconsistent)
            intersection[0] = addf(traceRayVec[0], traceRayVec[3]);
            intersection[1] = addf(traceRayVec[1], traceRayVec[4]);
            intersection[2] = addf(traceRayVec[2], traceRayVec[5]);
            distHitToPlayer = distance; // Maximum distance of trace ray
        } else {
            // Correct distance from the trace ray intersection to the player just now, because of secondary trace ray
            distHitToPlayer = sqrtf(addf(addf(
                sqrf(subf(intersection[0], traceRayVec[0])),
                sqrf(subf(intersection[1], traceRayVec[1]))),
                sqrf(subf(intersection[2], traceRayVec[2]))));
        };

        // Calculate the distance to the camera
        var int distHitToCam; distHitToCam = addf(distHitToPlayer, distCamToPlayer);

        // Debug visualization
        if (LineVisible(GFA_DebugTRTrj)) {
            // Trace ray intersection
            var int f5; f5 = mkf(5); // Margin
            UpdateBBox3(GFA_DebugTRBBox,
                        subf(intersection[0], f5),
                        subf(intersection[1], f5),
                        subf(intersection[2], f5),
                        addf(intersection[0], f5),
                        addf(intersection[1], f5),
                        addf(intersection[2], f5));

            // Trace ray trajectory
            UpdateLine3(GFA_DebugTRTrj,
                        traceRayVec[0],
                        traceRayVec[1],
                        traceRayVec[2],
                        addf(traceRayVec[0], traceRayVec[3]),
                        addf(traceRayVec[1], traceRayVec[4]),
                        addf(traceRayVec[2], traceRayVec[5]));

            // Focus vob bounding box
            if (foundVob) {
                UpdateBBoxAddr(GFA_DebugTRBBoxVob, foundVob+zCVob_bbox3D_offset);
            } else {
                const int QUARTER_BBOX_SIZE = sizeof_zTBBox3D/4;
                var int empty[QUARTER_BBOX_SIZE];
                UpdateBBoxAddr(GFA_DebugTRBBoxVob, _@(empty));
            };
        };
    };

    // Update focus and enemy
    GFA_SetFocusAndTarget(foundFocus);

    // Whether or not the trace ray was recomputed, write all call-by-reference variables
    if (vobPtr) {
        MEM_WriteInt(vobPtr, foundVob);
    };
    if (posPtr) {
        MEM_CopyBytes(_@(intersection), posPtr, sizeof_zVEC3);
    };
    if (distPtr) {
        MEM_WriteInt(distPtr, distHitToPlayer);
    };
    if (trueDistPtr) {
        MEM_WriteInt(trueDistPtr, distHitToCam);
    };

    // Return whether there was a hit. By Gothic's pseudo-locals, it will stay with the previous result until recomputed
    var int hit;
    return hit;
};
