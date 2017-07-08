/*
 * Aim-specific trace ray and focus collection
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
 * Shoot a trace ray to retrieve the point of intersection with the nearest object in the world, the distance, and to
 * overwrite the focus collection with a desired focus type. This function is customized for aiming and it is not
 * recommended to use for any other matter.
 * This function is very complex, but well tested.
 * To increase performance, increase the value of FREEAIM.focusCollIntvMS in the Gothic INI-file. It determines the
 * interval in milliseconds of how ofter the trace ray is recomputed. The upper bound is 500ms, which already
 * introduces a slight lag in the focus collection and reticle size (if applicable). A recommended value is below 50ms.
 */
func int freeAimRay(var int distance, var int focusType, var int vobPtr, var int posPtr, var int distPtr,
        var int trueDistPtr) {

    // Only run full trace ray machinery every so often (see freeAimRayInterval) to allow weaker machines to run this
    var int curTime; curTime = MEM_Timer.totalTime; // Get current time
    if (curTime-prevCalculationTime >= freeAimRayInterval) { // If the interval is passed, recompute trace ray
        // Update time of previous calculation
        var int prevCalculationTime; prevCalculationTime = curTime;

        // The trace ray is cast along the camera viewing angle from a start point towards a direction/length vector

        // Get camera vob (not camera itself, because it does not offer a reliable position)
        var zCVob camVob; camVob = _^(MEM_Game._zCSession_camVob);
        var zMAT4 camPos; camPos = _^(_@(camVob.trafoObjToWorld[0]));

        var int herPtr; herPtr = _@(hero);
        var oCNpc her; her = _^(herPtr);

        // Shift the start point for the trace ray beyond the player model. This is necessary, because if zooming out
        //  (a) there might be something between camera and hero (unlikely) and
        //  (b) the maximum aiming distance is off and does not correspond to the argument 'distance'
        // To do so, the distance between camera and player is computed:
        var int distCamToPlayer; distCamToPlayer = sqrtf(addf(addf( // Does not care about camera X shift, see below
            sqrf(subf(her._zCVob_trafoObjToWorld[ 3], camPos.v0[zMAT4_position])),
            sqrf(subf(her._zCVob_trafoObjToWorld[ 7], camPos.v1[zMAT4_position]))),
            sqrf(subf(her._zCVob_trafoObjToWorld[11], camPos.v2[zMAT4_position]))));

        // Shifting camera (shoulderview) is NOT RECOMMENDED. Because of the parallax effect, aiming becomes inaccurate
        if (FREEAIM_CAMERA_X_SHIFT) {
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
                             | zTRACERAY_poly_ignore_transp // Do not change (will make trace ray unstable)
                             | zTRACERAY_poly_test_water
                             | zTRACERAY_vob_ignore_projectiles;
        var int fromPosPtr; fromPosPtr = _@(traceRayVec);
        var int dirPosPtr; dirPosPtr = _@(traceRayVec)+sizeof_zVEC3;
        var int worldPtr; worldPtr = _@(MEM_World);
        const int call = 0;
        if (CALL_Begin(call)) {
            CALL_IntParam(_@(flags));     // Trace ray flags
            CALL_PtrParam(_@(herPtr));    // Ignore player model
            CALL_PtrParam(_@(dirPosPtr)); // Trace ray direction
            CALL_PutRetValTo(_@(hit));    // Did the trace ray hit
            CALL__fastcall(_@(worldPtr), _@(fromPosPtr), zCWorld__TraceRayNearestHit_Vob);
            call = CALL_End();
        };

        // Retrieve trace ray report
        var int foundVob; foundVob = MEM_World.foundVob;
        var int intersection[3];
        MEM_CopyBytes(_@(MEM_World.foundIntersection), _@(intersection), sizeof_zVEC3);

        // Correct focus collection. Since the focus collection in Gothic is designed by angles, manipulating the
        // instances in Focus.d, will lead nowhere, when aiming at a distance as angles become wider. Instead if a
        // focus vob was collected by the engine, it will be checked whether it was hit by the trace ray which means
        // the camera is looking directly at it.
        // Unfortunately, NPCs are not registered by normal trace rays like the one above. They are only detected if
        // Boundingbox detection is turned on. This is to be avoided, however, because otherwise all vob bounding boxes
        // would obstruct the trace ray immensely, NEVER allowing the focusing of NPCs.
        // Instead, the trace ray vob list is searched for NPCs. The trace ray vob list holds all vobs that were
        // intersected. If the focus vob (from Gothic's standard focus collection) is present in this vob list, one step
        // remains to confirm, that the NPC is actually in the cross hairs: Running a secondary trace ray with on the
        // NPC with the bounding box trace ray flags.
        var int foundFocus; foundFocus = 0; // Variable to specify whether the focus vob is in the trace ray vob list
        if (her.focus_vob) {
            // Gothic collected a focus vob

            // Second trace ray only if focus vob is reasonable
            var int runDetailedTraceRay; runDetailedTraceRay = 0;

            // Check if collected focus matches the desired focus type (see function parameter focusType)
            if (!focusType) {
                // No focus may be desired for spells that estimate distances but do not want to focus anything
                foundFocus = 0;

            } else if (focusType != TARGET_TYPE_ITEMS) && (Hlp_Is_oCNpc(her.focus_vob)) {
                // If an NPC focus is desired, more detailed checks are necessary

                var C_Npc target; target = _^(her.focus_vob);

                // Check if NPC is undead, function is not defined yet at time of parsing
                MEM_PushInstParam(target);
                MEM_Call(C_NpcIsUndead); // C_NpcIsUndead(target);
                var int npcIsUndead; npcIsUndead = MEM_PopIntResult();

                // Check if NPC is down, function is not defined yet at time of parsing
                MEM_PushInstParam(target);
                MEM_Call(C_NpcIsDown); // C_NpcIsDown(target);
                var int npcIsDown; npcIsDown = MEM_PopIntResult();

                // More detailed focus type tests
                if ((focusType == TARGET_TYPE_NPCS)                                        // Focus any NPC
                || ((focusType == TARGET_TYPE_ORCS) && target.guild > GIL_SEPERATOR_ORC)   // Only focus orcs
                || ((focusType == TARGET_TYPE_HUMANS) && target.guild < GIL_SEPERATOR_HUM) // Only focus humans
                || ((focusType == TARGET_TYPE_UNDEAD) && npcIsUndead))                     // Only focus undead NPCs
                && (!npcIsDown) {
                    // Iterate over trace ray vob list to check if the NPC was collected
                    var int potVobPtr; potVobPtr = _@(her.focus_vob);
                    var int voblist; voblist = _@(MEM_World.traceRayVobList_array);
                    const int call2 = 0;
                    if (CALL_Begin(call2)) { // More complicated for NPCs: Check if NPC is in trace ray vob list
                        CALL_PtrParam(_@(potVobPtr)); // Explanation: NPCs are never HIT by a trace ray (only collected)
                        CALL_PutRetValTo(_@(runDetailedTraceRay)); // Perform detailed trace ray if NPC was in vob list
                        CALL__thiscall(_@(voblist), zCArray_zCVob__IsInList);
                        call2 = CALL_End();
                    };
                };

            } else if (focusType <= TARGET_TYPE_ITEMS) && (Hlp_Is_oCItem(her.focus_vob)) {
                // If an item focus is desired, also perform a detailed trace ray. This ensures a stable focus
                runDetailedTraceRay = 1;
            };

            // If focus collection is reasonable, run a more detailed examination, a vob-specific trace ray
            if (runDetailedTraceRay) {

                // Update the flags and specific trace ray
                flags = zTRACERAY_vob_ignore_no_cd_dyn | zTRACERAY_vob_bbox; // Important!
                var int focusVobPtr; focusVobPtr = her.focus_vob; // Write to variable, otherwise crash on new game
                var int trRep; trRep = MEM_Alloc(sizeof_zTTraceRayReport);
                const int call3 = 0;
                if (CALL_Begin(call3)) {
                    CALL_PtrParam(_@(trRep));      // zTTraceRayReport
                    CALL_IntParam(_@(flags));      // Trace ray flags
                    CALL_PtrParam(_@(dirPosPtr));  // Trace ray direction
                    CALL_PtrParam(_@(fromPosPtr)); // Start vector
                    CALL__thiscall(_@(focusVobPtr), zCVob__TraceRay); // This is a vob specific trace ray
                    call3 = CALL_End();
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


        // If focus vob changed by the validation above, update the focus vob (properly, mind the reference counter)
        if (foundFocus != her.focus_vob) {
            const int call4 = 0;
            if (CALL_Begin(call4)) {
                CALL_PtrParam(_@(foundFocus)); // If no valid focus found, this will remove the focus (foundFocus == 0)
                CALL__thiscall(_@(herPtr), oCNpc__SetFocusVob);
                call4 = CALL_End();
            };
        };

        // If focus vob changed by the validation above, update the enemy NPC (also properly with an engine call)
        if (foundFocus != her.enemy) {
            const int call5 = 0;
            if (CALL_Begin(call5)) {
                CALL_PtrParam(_@(foundFocus));
                CALL__thiscall(_@(herPtr), oCNpc__SetEnemy);
                call5 = CALL_End();
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
        if (FREEAIM_DEBUG_TRACERAY) {
            // Trace ray intersection
            freeAimDebugTRBBox[0] = subf(intersection[0], mkf(5));
            freeAimDebugTRBBox[1] = subf(intersection[1], mkf(5));
            freeAimDebugTRBBox[2] = subf(intersection[2], mkf(5));
            freeAimDebugTRBBox[3] = addf(freeAimDebugTRBBox[0], mkf(10));
            freeAimDebugTRBBox[4] = addf(freeAimDebugTRBBox[1], mkf(10));
            freeAimDebugTRBBox[5] = addf(freeAimDebugTRBBox[2], mkf(10));

            // Trace ray trajectory
            MEM_CopyBytes(_@(traceRayVec), _@(freeAimDebugTRTrj), sizeof_zVEC3);
            freeAimDebugTRTrj[3] = addf(traceRayVec[0], traceRayVec[3]);
            freeAimDebugTRTrj[4] = addf(traceRayVec[1], traceRayVec[4]);
            freeAimDebugTRTrj[5] = addf(traceRayVec[2], traceRayVec[5]);

            // Focus vob bounding box
            if (foundVob) {
                freeAimDebugTRPrevVob = foundVob+zCVob_bbox3D_offset;
            } else {
                freeAimDebugTRPrevVob = 0;
            };
        };
    };


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
