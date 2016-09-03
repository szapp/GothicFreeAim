/*
 * Free aim framework
 *
 * Written by mud-freak
 * With help from Lehona
 *
 * Requirements:
 *  - Ikarus (>= 1.2 +floats)
 *  - LeGo (>= 2.3.2 HookEngine)
 */

/* Free aim settings */
const int   FREEAIM_ACTIVATED                     = 1;      // Enable/Disable free aiming
const int   FREEAIM_FOCUS_ACTIVATED               = 1;      // Enable/Disable focus collection (disable for performance)
const int   FREEAIM_SHOULDER                      = 0;      // 0 = left, 1 = right
const int   FREEAIM_MAX_DIST                      = 5000;   // 50 meters. For shooting and crosshair adjustments.
const float FREEAIM_ROTATION_SCALE                = 0.16;   // Turn rate. Non weapon mode is 0.2 (zMouseRotationScale)
const int   CROSSHAIR_MIN_SIZE                    = 16;     // Smallest crosshair size in pixels (longest range)
const int   CROSSHAIR_MED_SIZE                    = 20;     // Medium crosshair size in pixels (for disabled focus)
const int   CROSSHAIR_MAX_SIZE                    = 32;     // Biggest crosshair size in pixels (closest range)
var int crosshairHndl;                                      // Holds the crosshair handle

/* These are all addresses (a.o.) used. When adjusting these, it should also work for Gothic 1 */
const int sizeof_zCVob                            = 288; // Gothic 2: 288, Gothic 1: 256
const int zCVob__zCVob                            = 6283744; //0x5FE1E0
const int zCVob__SetPositionWorld                 = 6404976; //0x61BB70
const int zCWorld__AddVobAsChild                  = 6440352; //0x6245A0
const int oCAniCtrl_Human__Turn                   = 7005504; //0x6AE540
const int oCNpc__GetAngles                        = 6820528; //0x6812B0
const int zCWorld__TraceRayNearestHit_Vob         = 6430624; //0x621FA0
const int zCVob__TraceRay                         = 6291008; //0x5FFE40
const int oCNpc__SetFocusVob                      = 7547744; //0x732B60
const int mouseEnabled                            = 9248108; //0x8D1D6C
const int mouseSensX                              = 9019720; //0x89A148
const int mouseDeltaX                             = 9246300; //0x8D165C
const int oCAniCtrl_Human__InterpolateCombineAni  = 7037296; //0x6B6170 // Hook
const int oCAIArrow__SetupAIVob                   = 6951136; //0x6A10E0 // Hook
const int oCAIHuman__BowMode                      = 6905600; //0x695F00 // Hook
const int oCNpcFocus__SetFocusMode                = 7072800; //0x6BEC20 // Hook
const int oCAIHuman__MagicMode                    = 4665296; //0x472FD0 // Hook
const int mouseUpdate                             = 5062907; //0x4D40FB // Hook

/* Initialize free aim framework */
func void Init_FreeAim() {
    const int hookFreeAim = 0;
    if (!hookFreeAim) {
        HookEngineF(oCAniCtrl_Human__InterpolateCombineAni, 5, catchICAni);
        HookEngineF(oCAIArrow__SetupAIVob, 6, shootTarget);
        HookEngineF(oCAIHuman__BowMode, 6, manageCrosshair); // Called continuously
        HookEngineF(oCNpcFocus__SetFocusMode, 7, manageCrosshair); // Called when changing focus mode (several times)
        HookEngineF(oCAIHuman__MagicMode, 7, manageCrosshair); // Called continuously
        HookEngineF(mouseUpdate, 5, manualRotation);
        hookFreeAim = 1;
    };
    //Focus_Ranged.npc_prio = -1; // Disable focus collection
    MEM_Info("Free aim initialized.");
};

/* Check whether free aim should be activated */
func int isFreeAimActive() {
    if (!FREEAIM_ACTIVATED) { return 0; }; // Only free aiming is enabled
    if (!MEM_ReadInt(mouseEnabled)) { return 0; }; // Only when mouse controls are enabled
    if (!Npc_IsInFightMode(hero, FMODE_FAR)) { return 0; }; // Only while using bow/crossbow
    if (!MEM_KeyPressed(MEM_GetKey("keyAction"))) && (!MEM_KeyPressed(MEM_GetSecondaryKey("keyAction"))) { return 0; };
    return 1;
};

/* Delete crosshair (hiding it is not sufficient, since it might change texture later) */
func void removeCrosshair() {
    if (Hlp_IsValidHandle(crosshairHndl)) { View_Delete(crosshairHndl); };
};

/* Draw crosshair */
func void insertCrosshair(var int crosshairStyle, var int size) {
    if (crosshairStyle > 1) {
        var string crosshairTex;
        if (!Hlp_IsValidHandle(crosshairHndl)) {
            Print_GetScreenSize();
            crosshairHndl = View_CreateCenterPxl(Print_Screen[PS_X]/2, Print_Screen[PS_Y]/2, size, size);
            crosshairTex = MEM_ReadStatStringArr(crosshair, crosshairStyle);
            View_SetTexture(crosshairHndl, crosshairTex);
            View_Open(crosshairHndl);
        } else {
            var zCView crsHr; crsHr = _^(getPtr(crosshairHndl));
            if (!crsHr.isOpen) { View_Open(crosshairHndl); };
            crosshairTex = MEM_ReadStatStringArr(crosshair, crosshairStyle);
            if (!Hlp_StrCmp(View_GetTexture(crosshairHndl), crosshairTex)) {
                View_SetTexture(crosshairHndl, crosshairTex);
            };
            if (size < CROSSHAIR_MIN_SIZE) { size = CROSSHAIR_MIN_SIZE; }
            else if (size > CROSSHAIR_MAX_SIZE) { size = CROSSHAIR_MAX_SIZE; };
            if (crsHr.psizex != size) {
                View_ResizePxl(crosshairHndl, size, size);
                View_MoveToPxl(crosshairHndl, Print_Screen[PS_X]/2-(size/2), Print_Screen[PS_Y]/2-(size/2));
            };
        };
    } else { removeCrosshair(); };
};

/* Decide when to draw crosshair (otherwise make sure it's deleted) */
func void manageCrosshair() {
    if (!isFreeAimActive()) { removeCrosshair(); };
};

/* Check whether free aim should collect focus */
func int getFreeAimFocus() {
    if (!FREEAIM_FOCUS_ACTIVATED) { return 0; }; // More performance friendly
    var oCNpc her; her = Hlp_GetNpc(hero);
    if (Npc_IsInFightMode(her, FMODE_FAR)) { return 1; }; // Only while using bow/crossbow
    return 0;
};

/* Mouse handling for manually turning the player model */
func void manualRotation() {
    if (!isFreeAimActive()) { return; };
    var int deltaX; deltaX = mulf(mkf(MEM_ReadInt(mouseDeltaX)), MEM_ReadInt(mouseSensX)); // Get mouse change in x
    if (deltaX == FLOATNULL) { return; }; // Only rotate if there was movement along x position
    deltaX = mulf(deltaX, castToIntf(FREEAIM_ROTATION_SCALE)); // Turn rate
    var int hAniCtrl; hAniCtrl = MEM_ReadInt(_@(hero)+2432); // oCNpc->anictrl
    var int null;
    const int call = 0;
    if (CALL_Begin(call)) {
        CALL_IntParam(_@(null)); // 0 = disable turn animation (there is none while aiming anyways)
        CALL_FloatParam(_@(deltaX));
        CALL__thiscall(_@(hAniCtrl), oCAniCtrl_Human__Turn);
        call = CALL_End();
    };
};

/* Shoot aim-tailored trace ray. Do no use for other things. This function is customized for aiming. */
func int aimRay(var int distance, var int vobPtr, var int posPtr, var int distPtr) {
    var int flags; flags = (1<<0) | (1<<14) | (1<<9);
    // (zTRACERAY_VOB_IGNORE_NO_CD_DYN | zTRACERAY_VOB_IGNORE_PROJECTILES | zTRACERAY_POLY_TEST_WATER)
    MEM_InitGlobalInst(); var int camPos[6];
    camPos[0] = MEM_ReadInt(MEM_Camera.connectedVob+72);
    camPos[1] = MEM_ReadInt(MEM_Camera.connectedVob+88);
    camPos[2] = MEM_ReadInt(MEM_Camera.connectedVob+104);
    // Calculate point-line distance, to shift the start point of the trace ray to the level of the player model
    // Necessary, because if zooming out, (1) there might be something between camera and hero, (2) max distance is off
    var int herPtr; herPtr = _@(hero);
    var int shoulder; shoulder = mkf((FREEAIM_SHOULDER*2)-1); // Now left is -1, right is +1
    var int helpPos[3]; // Help point along the right vector of the camera vob for point-line distance
    helpPos[0] = addf(MEM_ReadInt(herPtr+72), mulf(MEM_ReadInt(MEM_Camera.connectedVob+60), mulf(shoulder, mkf(1000))));
    helpPos[1] = addf(MEM_ReadInt(herPtr+88), mulf(MEM_ReadInt(MEM_Camera.connectedVob+76), mulf(shoulder, mkf(1000))));
    helpPos[2] = addf(MEM_ReadInt(herPtr+104),mulf(MEM_ReadInt(MEM_Camera.connectedVob+92), mulf(shoulder, mkf(1000))));
    var int u[3]; var int v[3];
    u[0] = subf(camPos[0], MEM_ReadInt(herPtr+72));  v[0] = subf(camPos[0], helpPos[0]);
    u[1] = subf(camPos[1], MEM_ReadInt(herPtr+88));  v[1] = subf(camPos[1], helpPos[1]);
    u[2] = subf(camPos[2], MEM_ReadInt(herPtr+104)); v[2] = subf(camPos[2], helpPos[2]);
    var int crossProd[3]; // Cross-product
    crossProd[0] = subf(mulf(u[1], v[2]), mulf(u[2], v[1]));
    crossProd[1] = subf(mulf(u[2], v[0]), mulf(u[0], v[2]));
    crossProd[2] = subf(mulf(u[0], v[1]), mulf(u[1], v[0]));
    var int dist; dist = sqrtf(addf(addf(sqrf(crossProd[0]), sqrf(crossProd[1])), sqrf(crossProd[2])));
    dist = divf(dist, mkf(1000)); // Devide area of triangle by length between herPos and helpPos
    // Trace ray vectors
    camPos[0] = addf(camPos[0], mulf(MEM_ReadInt(MEM_Camera.connectedVob+68), dist)); // Start ray from here
    camPos[1] = addf(camPos[1], mulf(MEM_ReadInt(MEM_Camera.connectedVob+84), dist));
    camPos[2] = addf(camPos[2], mulf(MEM_ReadInt(MEM_Camera.connectedVob+100), dist));
    camPos[3] = mulf(MEM_ReadInt(MEM_Camera.connectedVob+68), mkf(distance)); // Direction-/to-vector of ray
    camPos[4] = mulf(MEM_ReadInt(MEM_Camera.connectedVob+84), mkf(distance));
    camPos[5] = mulf(MEM_ReadInt(MEM_Camera.connectedVob+100), mkf(distance));
    var int fromPosPtr; fromPosPtr = _@(camPos);
    var int dirPosPtr; dirPosPtr = _@(camPos)+12;
    var int worldPtr; worldPtr = _@(MEM_World);
    const int call = 0;
    if (CALL_Begin(call)) {
        CALL_IntParam(_@(flags)); // Trace ray flags
        CALL_PtrParam(_@(herPtr)); // Ignore player model
        CALL_PtrParam(_@(dirPosPtr)); // Trace ray direction
        CALL__fastcall(_@(worldPtr), _@(fromPosPtr), zCWorld__TraceRayNearestHit_Vob);
        call = CALL_End();
    };
    var int found; found = CALL_RetValAsInt();
    // The is a hack to allow detection of npcs. Trace rays ignore npcs unless zTRACERAY_VOB_BBOX is specified = bad!
    var int offset; offset = 0; // Index to iterate over vob list
    var int foundFocus; foundFocus = 0; // Is the focus vob in the vob list
    var int trRep; trRep = MEM_Alloc(40); // sizeof_zTTraceRayReport
    var int nearestNpcDist; nearestNpcDist = mkf(distance); // Select nearest npc
    var C_NPC target;
    flags = (1<<0) | (1<<2); // (zTRACERAY_VOB_IGNORE_NO_CD_DYN | zTRACERAY_VOB_BBOX) // Important!
    // This is essentially taken/modified from 0x621B80 zCWorld::TraceRayNearestHit (specifically at 0x621D82)
    while(MEM_World.traceRayVobList_numInArray > offset); // Iterate over vob list
        var int curVob; curVob = MEM_ReadIntArray(MEM_World.traceRayVobList_array, offset); // Current vob
        offset += 1; // Advance in array
        if (Hlp_Is_oCNpc(curVob)) && (curVob != herPtr) { // If vob is npc and not hero
            target = _^(curVob); // Do not allow focussing npcs that are down
            if (Npc_IsInState(target, ZS_Unconscious))
            || (Npc_IsInState(target, ZS_MagicSleep))
            || (Npc_IsDead(target)) { continue; };
            const int call2 = 0;
            if (CALL_Begin(call2)) {
                CALL_PtrParam(_@(trRep)); // zTTraceRayReport
                CALL_IntParam(_@(flags)); // Trace ray flags
                CALL_PtrParam(_@(dirPosPtr)); // Trace ray direction
                CALL_PtrParam(_@(fromPosPtr)); // Start vector
                CALL__thiscall(_@(curVob), zCVob__TraceRay);
                call2 = CALL_End();
            };
            if (CALL_RetValAsInt()) { // Got a hit: Update trace ray report
                distance = sqrtf(addf(addf(
                    sqrf(subf(MEM_ReadInt(trRep+12), camPos[0])),
                    sqrf(subf(MEM_ReadInt(trRep+16), camPos[1]))),
                    sqrf(subf(MEM_ReadInt(trRep+20), camPos[2]))));
                if (lf(distance, nearestNpcDist)) { // Prefer the closest npc
                    nearestNpcDist = distance;
                    MEM_World.foundVob = curVob;
                    MEM_CopyWords(trRep+12, _@(MEM_World.foundIntersection), 3); // 0x0C zVEC3
                    foundFocus = curVob; // Found focus vob (do not leave loop yet, there might be a nearer npc)
                };
            };
        };
    end;
    MEM_Free(trRep); // Free the report
    const int call3 = 0; // Set the focus vob properly: reference counter
    if (CALL_Begin(call3)) {
        CALL_PtrParam(_@(foundFocus)); // If no npc was found, this will remove the focus
        CALL__thiscall(_@(herPtr), oCNpc__SetFocusVob);
        call3 = CALL_End();
    };
    // Write return/call-by-reference variables
    if (vobPtr) { MEM_WriteInt(vobPtr, MEM_World.foundVob); };
    if (posPtr) { MEM_CopyWords(_@(MEM_World.foundIntersection), posPtr, 3); };
    if (distPtr) {
        distance = sqrtf(addf(addf(
            sqrf(subf(MEM_World.foundIntersection[0], camPos[0])),
            sqrf(subf(MEM_World.foundIntersection[1], camPos[1]))),
            sqrf(subf(MEM_World.foundIntersection[2], camPos[2]))));
        MEM_WriteInt(distPtr, distance);
    };
    return found;
};

/* Hook oCAniCtrl_Human::InterpolateCombineAni. Set target position to update aim animation */
func void catchICAni() {
    if (!isFreeAimActive()) { return; };
    var int herPtr; herPtr = _@(hero);



    // Strafing
    var int keyState_strafeL1; keyState_strafeL1 = MEM_KeyState(MEM_GetKey("keyStrafeLeft"));
    var int keyState_strafeL2; keyState_strafeL2 = MEM_KeyState(MEM_GetSecondaryKey("keyStrafeLeft"));
    var int keyState_strafeR1; keyState_strafeR1 = MEM_KeyState(MEM_GetKey("keyStrafeRight"));
    var int keyState_strafeR2; keyState_strafeR2 = MEM_KeyState(MEM_GetSecondaryKey("keyStrafeRight"));
    var int keyState_back1; keyState_back1 = MEM_KeyState(MEM_GetKey("keyDown"));
    var int keyState_back2; keyState_back2 = MEM_KeyState(MEM_GetSecondaryKey("keyDown"));
    if (keyState_strafeL1 > KEY_UP) || (keyState_strafeL2 > KEY_UP)
    || (keyState_strafeR1 > KEY_UP) || (keyState_strafeR2 > KEY_UP)
    || (keyState_back1 > KEY_UP) || (keyState_back2 > KEY_UP) {
        const int oCNpc__GetModel = 7571232; //0x738720
        const int zCModel__IsAnimationActive = 5727888; //0x576690
        const int zCModel__StartAni = 5746544; //0x57AF70
        const int zCModel__StopAnimation = 5727728; //0x5765F0
        CALL__thiscall(herPtr, oCNpc__GetModel);
        var int model; model = CALL_RetValAsInt();
        if (keyState_strafeL1 == KEY_PRESSED || keyState_strafeL1 == KEY_HOLD)
        || (keyState_strafeL2 == KEY_PRESSED || keyState_strafeL2 == KEY_HOLD) {
            CALL_zStringPtrParam("T_FREEAIMSTRAFEL");
            CALL__thiscall(model, zCModel__IsAnimationActive);
            if (!CALL_RetValAsInt()) {
                CALL_IntParam(0);
                CALL_zStringPtrParam("T_FREEAIMSTRAFEL");
                CALL__thiscall(model, zCModel__StartAni);
            };
        } else if (keyState_strafeL1 == KEY_RELEASED) || (keyState_strafeL2 == KEY_RELEASED) {
            CALL_zStringPtrParam("T_FREEAIMSTRAFEL");
            CALL__thiscall(model, zCModel__StopAnimation);
        };
        if (keyState_strafeR1 == KEY_PRESSED || keyState_strafeR1 == KEY_HOLD)
        || (keyState_strafeR2 == KEY_PRESSED || keyState_strafeR2 == KEY_HOLD) {
            CALL_zStringPtrParam("T_FREEAIMSTRAFER");
            CALL__thiscall(model, zCModel__IsAnimationActive);
            if (!CALL_RetValAsInt()) {
                CALL_IntParam(0);
                CALL_zStringPtrParam("T_FREEAIMSTRAFER");
                CALL__thiscall(model, zCModel__StartAni);
            };
        } else if (keyState_strafeR1 == KEY_RELEASED) || (keyState_strafeR2 == KEY_RELEASED) {
            CALL_zStringPtrParam("T_FREEAIMSTRAFER");
            CALL__thiscall(model, zCModel__StopAnimation);
        };
        if (keyState_back1 == KEY_PRESSED || keyState_back1 == KEY_HOLD)
        || (keyState_back2 == KEY_PRESSED || keyState_back2 == KEY_HOLD) {
            CALL_zStringPtrParam("T_FREEAIMBACK");
            CALL__thiscall(model, zCModel__IsAnimationActive);
            if (!CALL_RetValAsInt()) {
                CALL_IntParam(0);
                CALL_zStringPtrParam("T_FREEAIMBACK");
                CALL__thiscall(model, zCModel__StartAni);
            };
        } else if (keyState_back1 == KEY_RELEASED) || (keyState_back2 == KEY_RELEASED) {
            CALL_zStringPtrParam("T_FREEAIMBACK");
            CALL__thiscall(model, zCModel__StopAnimation);
        };
    };


    var int size; size = CROSSHAIR_MAX_SIZE; // Start out with the maximum size of crosshair (adjust below)
    if (getFreeAimFocus()) { // Set focus npc if there is a valid one under the crosshair
       var int distance; aimRay(FREEAIM_MAX_DIST, 0, 0, _@(distance)); // Shoot trace ray and retrieve aim distance
       size -= roundf(mulf(divf(distance, mkf(FREEAIM_MAX_DIST)), mkf(size))); // Adjust crosshair size
    } else { // More performance friendly. Here, there will be NO focus, otherwise it gets stuck on npcs.
        size = CROSSHAIR_MED_SIZE; // Set default crosshair size. Here, it is not dynamic
        const int call2 = 0; // Set the focus vob properly (here it will be set to zero): reference counter
        var int null;
        if (CALL_Begin(call2)) {
            CALL_PtrParam(_@(null)); // This will remove the focus
            CALL__thiscall(_@(herPtr), oCNpc__SetFocusVob);
            call2 = CALL_End();
        };
    };
    insertCrosshair(POINTY_CROSSHAIR, size); // Draw/update crosshair
    MEM_InitGlobalInst(); // This is necessary here to find the camera vob, although it was called in init_global. Why?
    var zCVob cam; cam = _^(MEM_Camera.connectedVob);
    var int pos[3]; // The position is calculated from the camera, not the player model.
    pos[0] = addf(cam.trafoObjToWorld[ 3], mulf(cam.trafoObjToWorld[ 2], mkf(FREEAIM_MAX_DIST)));
    pos[1] = addf(cam.trafoObjToWorld[ 7], mulf(cam.trafoObjToWorld[ 6], mkf(FREEAIM_MAX_DIST)));
    pos[2] = addf(cam.trafoObjToWorld[11], mulf(cam.trafoObjToWorld[10], mkf(FREEAIM_MAX_DIST)));
    // Get aiming angles
    var int angleX; var int angXptr; angXptr = _@(angleX);
    var int angleY; var int angYptr; angYptr = _@(angleY);
    var int posPtr; posPtr = _@(pos); // So many pointer because it is a recyclable call
    const int call3 = 0;
    if (CALL_Begin(call3)) {
        CALL_PtrParam(_@(angYptr));
        CALL_PtrParam(_@(angXptr)); // X angle not needed
        CALL_PtrParam(_@(posPtr));
        CALL__thiscall(_@(herPtr), oCNpc__GetAngles);
        call3 = CALL_End();
    };
    if (lf(absf(angleY), fracf(1, 4))) { // Prevent multiplication with too small numbers. Would result in aim twitching
        angleY = fracf(1, 4);
        if (lf(angleY, FLOATNULL)) { angleY =  negf(angleY); };
    };
    // This following paragraph is essentially "copied" from oCAIHuman::BowMode (0x695F00)
    var int deg90To05; deg90To05 = mulf(1010174817, FLOATHALF); // 0.0111111*0.5 (from 0x8306EC in g2)
    angleY = mulf(angleY, deg90To05); // Scale Y +-90 degrees to +-0.5
    angleY = addf(angleY, FLOATHALF); // Shift Y +-0.5 to +-1
    angleY = subf(FLOATONE, angleY);  // Flip  Y +-1 to -+1
    if (lef(angleY, FLOATNULL)) {
        angleY = FLOATNULL; // Maximum aim height (straight up)
    } else if (gef(angleY, 1065353216)) {
        angleY = 1065353216; //3F800000 // Minimum aim height (down)
    };
    // New aiming coordinates. Overwrite the arguments passed to oCAniCtrl_Human::InterpolateCombineAni
    MEM_WriteInt(ESP+4, FLOATHALF); // Always at the x center
    MEM_WriteInt(ESP+8, angleY);
};

/* Hook oCAIArrow::SetupAIVob */
func void shootTarget() {
    var C_NPC shooter; shooter = _^(MEM_ReadInt(ESP+8)); // Second argument is shooter
    if (!Npc_IsPlayer(shooter)) || (!isFreeAimActive()) { return; }; // Only for the player
    var int pos[3]; aimRay(FREEAIM_MAX_DIST, 0, _@(pos), 0); // Shoot trace ray and retrieve intersection
    var int vobPtr; vobPtr = MEM_SearchVobByName("AIMVOB"); // Arrow needs target vob
    if (!vobPtr) {
        vobPtr = MEM_Alloc(sizeof_zCVob); // Will never delete this vob (it will be re-used on the next shot)
        CALL__thiscall(vobPtr, zCVob__zCVob);
        MEM_WriteString(vobPtr+16, "AIMVOB"); // _zCObject_objectName
        CALL_PtrParam(_@(MEM_Vobtree));
        CALL_PtrParam(vobPtr);
        CALL__thiscall(_@(MEM_World), zCWorld__AddVobAsChild);
    };
    var int posPtr; posPtr = _@(pos);
    const int call = 0;
    if (CALL_Begin(call)) {
        CALL_PtrParam(_@(posPtr)); // Update aim vob position
        CALL__thiscall(_@(vobPtr), zCVob__SetPositionWorld);
        call = CALL_End();
    };
    MEM_WriteInt(ESP+12, vobPtr); // Overwrite the third argument (target vob) passed to oCAIArrow::SetupAIVob
};
