/*
 * Debugging visualizations
 *
 * G2 Free Aim v1.0.0-alpha - Free aiming for the video game Gothic 2 by Piranha Bytes
 * Copyright (C) 2016-2017  mud-freak (@szapp)
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
 * Visualize a bounding box in 3D space. Function can generally be used to debug operations in 3D space.
 */
func void freeAimVisualizeBBox(var int bboxPtr, var int color) {
    var int cPtr; cPtr = _@(color);
    const int call = 0;
    if (CALL_Begin(call)) {
        CALL_PtrParam(_@(cPtr)); // zCOLOR*
        CALL__thiscall(_@(bboxPtr), zTBBox3D__Draw);
        call = CALL_End();
    };
};


/*
 * Visualize a line in 3D space. Function can generally be used to debug operations in 3D space.
 */
func void freeAimVisualizeLine(var int pos1Ptr, var int pos2Ptr, var int color) {
    const int call = 0; var int zero;
    if (CALL_Begin(call)) {
        CALL_IntParam(_@(zero));
        CALL_IntParam(_@(color));   // zCOLOR
        CALL_PtrParam(_@(pos2Ptr)); // zVEC3*
        CALL_PtrParam(_@(pos1Ptr)); // zVEC3*
        CALL__thiscall(_@(zlineCache), zCLineCache__Line3D);
        call = CALL_End();
    };
};


/*
 * Visualize the bounding boxes of the trace ray and its trajectory for debugging. This function hooks
 * zCWorld::AdvanceClock, because it has to happen BEFORE where the frame functions are hooked. Otherwise the drawn
 * lines disappear.
 */
func void freeAimVisualizeTraceRay() {
    if (!FREEAIM_DEBUG_TRACERAY) || (MEM_Game.pause_screen) {
        return;
    };

    // Visualize trace ray intersection as small green bounding box
    if (freeAimDebugTRBBox[0]) {
        freeAimVisualizeBBox(_@(freeAimDebugTRBBox), zCOLOR_GREEN);
    };

    // Visualize trace ray as green line
    if (freeAimDebugTRTrj[0]) {
        freeAimVisualizeLine(_@(freeAimDebugTRTrj), _@(freeAimDebugTRTrj)+sizeof_zVEC3, zCOLOR_GREEN);
    };

    // Visualize validated found vob as green bounding box, if present
    if (freeAimDebugTRPrevVob) {
        freeAimVisualizeBBox(freeAimDebugTRPrevVob, zCOLOR_GREEN);
    };
};


/*
 * Visualize the bounding box of the weak spot (critical hit) and the projectile trajectory for debugging. This function
 * hooks zCWorld::AdvanceClock, because it has to happen BEFORE where the frame functions are hooked. Otherwise the
 * drawn lines disappear.
 */
func void freeAimVisualizeWeakspot() {
    if (!FREEAIM_DEBUG_WEAKSPOT) || (MEM_Game.pause_screen) {
        return;
    };

    // Visualize critical hit node (weak spot) as red bounding box
    if (freeAimDebugWSBBox[0]) {
        freeAimVisualizeBBox(_@(freeAimDebugWSBBox), zCOLOR_RED);
    };

    // Approximate projectile trajectory as red line
    if (freeAimDebugWSTrj[0]) {
        freeAimVisualizeLine(_@(freeAimDebugWSTrj), _@(freeAimDebugWSTrj)+sizeof_zVEC3, zCOLOR_RED);
    };
};
