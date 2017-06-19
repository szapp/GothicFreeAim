/*
 * Debugging visualizations
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

/* Visualize a bounding box in 3D space */
func void freeAimVisualizeBBox(var int bboxPtr, var int color) {
    var int cPtr; cPtr = _@(color);
    const int call = 0;
    if (CALL_Begin(call)) {
        CALL_PtrParam(_@(cPtr));
        CALL__thiscall(_@(bboxPtr), zTBBox3D__Draw);
        call = CALL_End();
    };
};

/* Visualize a line in 3D space */
func void freeAimVisualizeLine(var int pos1Ptr, var int pos2Ptr, var int color) {
    const int call = 0; var int zero;
    if (CALL_Begin(call)) {
        CALL_IntParam(_@(zero));
        CALL_IntParam(_@(color));
        CALL_PtrParam(_@(pos2Ptr));
        CALL_PtrParam(_@(pos1Ptr));
        CALL__thiscall(_@(zlineCache), zCLineCache__Line3D);
        call = CALL_End();
    };
};

/* Visualize the bounding boxes of the trace ray its trajectory for debugging */
func void freeAimVisualizeTraceRay() {
    if (!FREEAIM_DEBUG_TRACERAY) { return; };
    if (freeAimDebugTRBBox[0]) { freeAimVisualizeBBox(_@(freeAimDebugTRBBox), zCOLOR_GREEN); };
    if (freeAimDebugTRTrj[0]) { freeAimVisualizeLine(_@(freeAimDebugTRTrj), _@(freeAimDebugTRTrj)+12, zCOLOR_GREEN); };
    if (freeAimDebugTRPrevVob) { freeAimVisualizeBBox(freeAimDebugTRPrevVob, zCOLOR_GREEN); };
};

/* Visualize the bounding box of the weakspot and the projectile trajectory for debugging */
func void freeAimVisualizeWeakspot() {
    if (!FREEAIM_DEBUG_WEAKSPOT) { return; };
    if (freeAimDebugWSBBox[0]) { freeAimVisualizeBBox(_@(freeAimDebugWSBBox), zCOLOR_RED); };
    if (freeAimDebugWSTrj[0]) { freeAimVisualizeLine(_@(freeAimDebugWSTrj), _@(freeAimDebugWSTrj)+12, zCOLOR_RED); };
};
