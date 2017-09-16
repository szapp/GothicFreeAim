/*
 * Debugging visualizations
 *
 * Gothic Free Aim (GFA) v1.0.0-beta - Free aiming for the video games Gothic 1 and Gothic 2 by Piranha Bytes
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
 * Visualize a bounding box in 3D space. Function can generally be used to debug operations in 3D space.
 */
func void GFA_VisualizeBBox(var int bboxPtr, var int color) {
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
func void GFA_VisualizeLine(var int pos1Ptr, var int pos2Ptr, var int color) {
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
 * zCWorld::AdvanceClock(), because it has to happen BEFORE where the frame functions are hooked. Otherwise the drawn
 * lines disappear.
 */
func void GFA_VisualizeTraceRay() {
    if (!GFA_DEBUG_TRACERAY) || (MEM_Game.pause_screen) {
        return;
    };

    // Visualize trace ray intersection as small green bounding box
    if (GFA_DebugTRBBox[0]) {
        GFA_VisualizeBBox(_@(GFA_DebugTRBBox), zCOLOR_GREEN);
    };

    // Visualize trace ray as green line
    if (GFA_DebugTRTrj[0]) {
        GFA_VisualizeLine(_@(GFA_DebugTRTrj), _@(GFA_DebugTRTrj)+sizeof_zVEC3, zCOLOR_GREEN);
    };

    // Visualize validated found vob as green bounding box, if present
    if (GFA_DebugTRPrevVob) {
        GFA_VisualizeBBox(GFA_DebugTRPrevVob, zCOLOR_GREEN);
    };
};


/*
 * Visualize the bounding box of the weak spot (critical hit) and the projectile trajectory for debugging. This function
 * hooks zCWorld::AdvanceClock(), because it has to happen BEFORE where the frame functions are hooked. Otherwise the
 * drawn lines disappear.
 */
func void GFA_VisualizeWeakspot() {
    if (!GFA_DEBUG_WEAKSPOT) || (MEM_Game.pause_screen) {
        return;
    };

    // Visualize critical hit node (weak spot) as red bounding box
    if (GFA_DebugWSBBox[0]) {
        GFA_VisualizeBBox(_@(GFA_DebugWSBBox), zCOLOR_RED);
    };

    // Approximate projectile trajectory as red line
    if (GFA_DebugWSTrj[0]) {
        GFA_VisualizeLine(_@(GFA_DebugWSTrj), _@(GFA_DebugWSTrj)+sizeof_zVEC3, zCOLOR_RED);
    };
};