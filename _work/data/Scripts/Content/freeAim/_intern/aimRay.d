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

/* Shoot aim-tailored trace ray. Do no use for other purposes. This function is customized for aiming. */
func int freeAimRay(var int distance, var int focusType, var int vobPtr, var int posPtr, var int distPtr,
        var int trueDistPtr) {
    // Only run full trace ray machinery every so often (see freeAimRayInterval)
    var int curTime; curTime = MEM_Timer.totalTime;
    if (curTime-prevCalculationTime >= freeAimRayInterval) {
        var int prevCalculationTime; prevCalculationTime = curTime;
        // Flags: VOB_IGNORE_NO_CD_DYN | POLY_IGNORE_TRANSP | POLY_TEST_WATER | VOB_IGNORE_PROJECTILES
        var int flags; flags = (1<<0) | (1<<8) | (1<<9) | (1<<14); // Do not change (will make trace ray unstable)
        var zMAT4 camPos; camPos = _^(MEM_ReadInt(MEM_ReadInt(MEMINT_oGame_Pointer_Address)+20)+60);
        var int herPtr; herPtr = _@(hero);
        // Shift the start point for the trace ray beyond the player model. Necessary, because if zooming out,
        // (1) there might be something between camera and hero and (2) the maximum aiming distance is off.
        var int distCamToPlayer; distCamToPlayer = sqrtf(addf(addf( // Does not care about camera offset (camera shift)
            sqrf(subf(MEM_ReadInt(herPtr+72), camPos.v0[3])),
            sqrf(subf(MEM_ReadInt(herPtr+88), camPos.v1[3]))),
            sqrf(subf(MEM_ReadInt(herPtr+104), camPos.v2[3]))));
        if (FREEAIM_CAMERA_X_SHIFT) { // Shifting camera (shoulderview) is not recommended. Aiming is harder + less fps?
            // This makes the distance mentioned above more complex and requires calculation of a point-line distance
            // For illustration: http://mathworld.wolfram.com/Point-LineDistance3-Dimensional.html
            var int line[6]; // Line with two points along the camera right vector at the level of the player model
            line[0] = subf(MEM_ReadInt(herPtr+72),  mulf(camPos.v0[0], FLOAT1K)); // Left of player model
            line[1] = subf(MEM_ReadInt(herPtr+88),  mulf(camPos.v1[0], FLOAT1K));
            line[2] = subf(MEM_ReadInt(herPtr+104), mulf(camPos.v2[0], FLOAT1K));
            line[3] = addf(MEM_ReadInt(herPtr+72),  mulf(camPos.v0[0], FLOAT1K)); // Right of player model
            line[4] = addf(MEM_ReadInt(herPtr+88),  mulf(camPos.v1[0], FLOAT1K));
            line[5] = addf(MEM_ReadInt(herPtr+104), mulf(camPos.v2[0], FLOAT1K));
            var int u[3]; var int v[3]; // Subtract both points of the line from the camera position
            u[0] = subf(camPos.v0[3], line[0]); v[0] = subf(camPos.v0[3], line[3]);
            u[1] = subf(camPos.v1[3], line[1]); v[1] = subf(camPos.v1[3], line[4]);
            u[2] = subf(camPos.v2[3], line[2]); v[2] = subf(camPos.v2[3], line[5]);
            var int crossProd[3]; // Cross-product
            crossProd[0] = subf(mulf(u[1], v[2]), mulf(u[2], v[1]));
            crossProd[1] = subf(mulf(u[2], v[0]), mulf(u[0], v[2]));
            crossProd[2] = subf(mulf(u[0], v[1]), mulf(u[1], v[0]));
            distCamToPlayer = sqrtf(addf(addf(sqrf(crossProd[0]), sqrf(crossProd[1])), sqrf(crossProd[2])));
            distCamToPlayer = divf(distCamToPlayer, mkf(2000)); // Divide area of triangle by length between points
        };
        distance = mkf(distance);
        var int traceRayVec[6];
        traceRayVec[0] = addf(camPos.v0[3], mulf(camPos.v0[2], distCamToPlayer)); // Start ray from here
        traceRayVec[1] = addf(camPos.v1[3], mulf(camPos.v1[2], distCamToPlayer));
        traceRayVec[2] = addf(camPos.v2[3], mulf(camPos.v2[2], distCamToPlayer));
        traceRayVec[3] = mulf(camPos.v0[2], distance); // Direction-/to-vector of ray
        traceRayVec[4] = mulf(camPos.v1[2], distance);
        traceRayVec[5] = mulf(camPos.v2[2], distance);
        var int fromPosPtr; fromPosPtr = _@(traceRayVec);
        var int dirPosPtr; dirPosPtr = _@(traceRayVec)+12;
        var int worldPtr; worldPtr = _@(MEM_World);
        const int call = 0;
        if (CALL_Begin(call)) {
            CALL_IntParam(_@(flags)); // Trace ray flags
            CALL_PtrParam(_@(herPtr)); // Ignore player model
            CALL_PtrParam(_@(dirPosPtr)); // Trace ray direction
            CALL__fastcall(_@(worldPtr), _@(fromPosPtr), zCWorld__TraceRayNearestHit_Vob);
            call = CALL_End();
        };
        var int hit; hit = CALL_RetValAsInt(); // Did the trace ray hit
        var int foundVob; foundVob = MEM_World.foundVob;
        var int intersection[3]; MEM_CopyWords(_@(MEM_World.foundIntersection), _@(intersection), 3);
        var int distHitToPlayer;
        if (!hit) && (!foundVob) { // Fix the intersection if there was no hit (trace ray is inconsistent)
            intersection[0] = addf(traceRayVec[0], traceRayVec[3]);
            intersection[1] = addf(traceRayVec[1], traceRayVec[4]);
            intersection[2] = addf(traceRayVec[2], traceRayVec[5]);
            distHitToPlayer = distance; // Maximum distance of trace ray
        } else {
            distHitToPlayer = sqrtf(addf(addf(
                sqrf(subf(intersection[0], traceRayVec[0])),
                sqrf(subf(intersection[1], traceRayVec[1]))),
                sqrf(subf(intersection[2], traceRayVec[2]))));
        };
        var int distHitToCam; distHitToCam = addf(distHitToPlayer, distCamToPlayer);
        var int foundFocus; foundFocus = 0; // Is the focus vob in the trace ray vob list
        var int potentialVob; potentialVob = MEM_ReadInt(herPtr+2476); // oCNpc.focus_vob // Focus vob by f-collection
        if (potentialVob) { // Check if collected focus matches the desired focus type
            var int runDetailedTraceRay; runDetailedTraceRay = 0; // Second trace ray only if focus vob is reasonable
            if (!focusType) { // No focus vob (still a trace ray though)
                foundFocus = 0;
            } else if (focusType != TARGET_TYPE_ITEMS) && (Hlp_Is_oCNpc(potentialVob)) { // Validate focus vob, if npc
                var C_Npc target; target = _^(potentialVob);
                MEM_PushInstParam(target); // Function is not defined yet at time of parsing:
                MEM_Call(C_NpcIsUndead); // C_NpcIsUndead(target);
                var int npcIsUndead; npcIsUndead = MEM_PopIntResult();
                MEM_PushInstParam(target); // Function is not defined yet at time of parsing:
                MEM_Call(C_NpcIsDown); // C_NpcIsDown(target);
                var int npcIsDown; npcIsUndead = MEM_PopIntResult();
                if ((focusType == TARGET_TYPE_NPCS) // Any npc
                || ((focusType == TARGET_TYPE_ORCS) && target.guild > GIL_SEPERATOR_ORC) // Only focus orcs
                || ((focusType == TARGET_TYPE_HUMANS) && target.guild < GIL_SEPERATOR_HUM) // Only focus humans
                || ((focusType == TARGET_TYPE_UNDEAD) && npcIsUndead)) // Only focus undead npcs
                && (!npcIsDown) {
                    var int potVobPtr; potVobPtr = _@(potentialVob);
                    var int voblist; voblist = _@(MEM_World.traceRayVobList_array);
                    const int call2 = 0;
                    if (CALL_Begin(call2)) { // More complicated for npcs: Check if npc is in trace ray vob list
                        CALL_PtrParam(_@(potVobPtr)); // Explanation: Npcs are never HIT by a trace ray (only collected)
                        CALL__thiscall(_@(voblist), zCArray_zCVob__IsInList);
                        call2 = CALL_End();
                    };
                    runDetailedTraceRay = CALL_RetValAsInt(); // Will perform detailed trace ray if npc was in vob list
                };
            } else if (focusType <= TARGET_TYPE_ITEMS) && (Hlp_Is_oCItem(potentialVob)) {
                runDetailedTraceRay = 1; // Will perform detailed trace ray
            };
            if (runDetailedTraceRay) { // If focus collection is reasonable, run a more detailed examination
                // zCWorld::TraceRayNearestHit (0x621D82 in g2)
                flags = (1<<0) | (1<<2); // (zTRACERAY_VOB_IGNORE_NO_CD_DYN | zTRACERAY_VOB_BBOX) // Important!
                var int trRep; trRep = MEM_Alloc(40); // sizeof_zTTraceRayReport
                const int call3 = 0;
                if (CALL_Begin(call3)) {
                    CALL_PtrParam(_@(trRep)); // zTTraceRayReport
                    CALL_IntParam(_@(flags)); // Trace ray flags
                    CALL_PtrParam(_@(dirPosPtr)); // Trace ray direction
                    CALL_PtrParam(_@(fromPosPtr)); // Start vector
                    CALL__thiscall(_@(potentialVob), zCVob__TraceRay); // This is a vob specific trace ray
                    call3 = CALL_End();
                };
                if (CALL_RetValAsInt()) { // Got a hit: Update trace ray report
                    foundVob = potentialVob;
                    MEM_CopyWords(trRep+12, _@(intersection), 3); // 0x0C zVEC3
                    foundFocus = potentialVob; // Confirmed focus vob
                };
                MEM_Free(trRep); // Free the report
            };
        };
        if (foundFocus != potentialVob) { // If focus vob changed by the validation above
            const int call4 = 0; // Set the focus vob properly: reference counter
            if (CALL_Begin(call4)) {
                CALL_PtrParam(_@(foundFocus)); // If no valid focus found, this will remove the focus (foundFocus == 0)
                CALL__thiscall(_@(herPtr), oCNpc__SetFocusVob);
                call4 = CALL_End();
            };
        };
        if (foundFocus != MEM_ReadInt(herPtr+1176)) { //0x0498 oCNpc.enemy
            const int call5 = 0; // Set the enemy properly: reference counter
            if (CALL_Begin(call5)) {
                CALL_PtrParam(_@(foundFocus));
                CALL__thiscall(_@(herPtr), oCNpc__SetEnemy);
                call5 = CALL_End();
            };
        };
        // Debug visualization
        if (FREEAIM_DEBUG_TRACERAY) {
            freeAimDebugTRBBox[0] = subf(intersection[0], mkf(5));
            freeAimDebugTRBBox[1] = subf(intersection[1], mkf(5));
            freeAimDebugTRBBox[2] = subf(intersection[2], mkf(5));
            freeAimDebugTRBBox[3] = addf(freeAimDebugTRBBox[0], mkf(10));
            freeAimDebugTRBBox[4] = addf(freeAimDebugTRBBox[1], mkf(10));
            freeAimDebugTRBBox[5] = addf(freeAimDebugTRBBox[2], mkf(10));
            MEM_CopyWords(_@(traceRayVec), _@(freeAimDebugTRTrj), 3);
            freeAimDebugTRTrj[3] = addf(traceRayVec[0], traceRayVec[3]);
            freeAimDebugTRTrj[4] = addf(traceRayVec[1], traceRayVec[4]);
            freeAimDebugTRTrj[5] = addf(traceRayVec[2], traceRayVec[5]);
            if (foundVob) { freeAimDebugTRPrevVob = foundVob+124; } else { freeAimDebugTRPrevVob = 0; };
        };
    };
    // Write call-by-reference variables
    if (vobPtr) { MEM_WriteInt(vobPtr, foundVob); };
    if (posPtr) { MEM_CopyWords(_@(intersection), posPtr, 3); };
    if (distPtr) { MEM_WriteInt(distPtr, distHitToPlayer); };
    if (trueDistPtr) { MEM_WriteInt(trueDistPtr, distHitToCam); };
    return hit;
};
