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
const int FREEAIM_SHOULDER                        = 0;      // 0 = left, 1 = right
const int AIM_MAX_DIST                            = 5000;   // 50 meters. For shooting at the crosshair at all ranges.
const int CROSSHAIR_MIN_SIZE                      = 16;     // Smallest crosshair size in pixels (longest aiming range)
const int CROSSHAIR_MAX_SIZE                      = 32;     // Biggest crosshair size in pixels (closest aiming range)
var int crosshairHndl;                                      // Holds the crosshair handle

/* These are all addresses (a.o.) used. When adjusting these, it should also work for Gothic 1 */
const int sizeof_zCVob                            = 288; // Gothic 2: 288, Gothic 1: 256
const int zCVob__zCVob                            = 6283744; //0x5FE1E0
const int zCVob__SetPositionWorld                 = 6404976; //0x61BB70
const int zCWorld__AddVobAsChild                  = 6440352; //0x6245A0
const int oCAniCtrl_Human__TurnDegrees            = 7006992; //0x6AEB10
const int oCNpc__GetAngles                        = 6820528; //0x6812B0
const int zCWorld__TraceRayNearestHit_Vob         = 6430624; //0x621FA0
const int mouseEnabled                            = 9248108; //0x8D1D6C
const int mouseSensX                              = 9019720; //0x89A148
const int mouseDeltaX                             = 9246300; //0x8D165C
/* Hooks */
const int oCAniCtrl_Human__InterpolateCombineAni  = 7037296; //0x6B6170
const int oCAIArrow__SetupAIVob                   = 6951136; //0x6A10E0
const int oCAIHuman__BowMode                      = 6905600; //0x695F00
const int oCNpcFocus__SetFocusMode                = 7072800; //0x6BEC20
const int oCAIHuman__MagicMode                    = 4665296; //0x472FD0
const int mouseUpdate                             = 5062907; //0x4D40FB

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
    if (!MEM_ReadInt(mouseEnabled)) { return 0; }; // Only when mouse controls are enabled
    var oCNpc her; her = Hlp_GetNpc(hero);
    if (!Npc_IsInFightMode(her, FMODE_FAR)) { return 0; }; // Only while using bow/crossbow
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
            if (size < CROSSHAIR_MIN_SIZE) { size = CROSSHAIR_MIN_SIZE; };
            if (size > CROSSHAIR_MAX_SIZE) { size = CROSSHAIR_MAX_SIZE; };
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
    var oCNpc her; her = Hlp_GetNpc(hero);
    if (Npc_IsInFightMode(her, FMODE_FAR)) { return 1; }; // Only while using bow/crossbow
    return 0;
};

/* Mouse handling for manually turning the player model */
func void manualRotation() {
    if (!isFreeAimActive()) { return; };
    var int deltaX; deltaX = mulf(mkf(MEM_ReadInt(mouseDeltaX)), MEM_ReadInt(mouseSensX)); // Get mouse change in x
    if (deltaX == FLOATNULL) { return; }; // Only rotate if there was movement along x position
    var int frameAdj; frameAdj = mulf(MEM_Timer.frameTimeFloat, fracf(16, 1000)); // Frame lock
    deltaX = mulf(deltaX, frameAdj);
    var oCNpc her; her = Hlp_GetNpc(hero);
    var int hAniCtrl; hAniCtrl = her.anictrl;
    var int null;
    const int call = 0;
    if (CALL_Begin(call)) {
        CALL_IntParam(_@(null)); // 0 = disable turn animation (there is none while aiming anyways)
        CALL_FloatParam(_@(deltaX));
        CALL__thiscall(_@(hAniCtrl), oCAniCtrl_Human__TurnDegrees);
        call = CALL_End();
    };
};

/* Shoot aim-tailored trace ray. Do no use for other things. This function is customized for aiming. */
func int aimRay(var int distance, var int vobPtr, var int posPtr, var int distPtr) {
    // (zTRACERAY_VOB_IGNORE_NO_CD_DYN | zTRACERAY_VOB_BBOX | zTRACERAY_VOB_IGNORE_PROJECTILES)
    var int flags; flags = (1<<0) | (1<<2) | (1<<14);
    var int herPtr; herPtr = _@(hero);
    MEM_InitGlobalInst(); var int camPos[6];
    camPos[0] = MEM_ReadInt(MEM_Camera.connectedVob+72);
    camPos[1] = MEM_ReadInt(MEM_Camera.connectedVob+88);
    camPos[2] = MEM_ReadInt(MEM_Camera.connectedVob+104);
    // Calculate point-line distance, to shift the start point of the trace ray beyond the player model
    // Necessary, because if zooming out, (1) there might be something between camera and hero, (2) max distance is off
    var int shoulder; shoulder = mkf((FREEAIM_SHOULDER*2)-1); // Now left is -1, right is +1
    var int helpPos[3]; // Help point along the right vector of the camera vob for point-line distance
    helpPos[0] = addf(MEM_ReadInt(herPtr+72), mulf(MEM_ReadInt(MEM_Camera.connectedVob+60), mulf(shoulder, mkf(1000))));
    helpPos[1] = addf(MEM_ReadInt(herPtr+88), mulf(MEM_ReadInt(MEM_Camera.connectedVob+76), mulf(shoulder, mkf(1000))));
    helpPos[2] = addf(MEM_ReadInt(herPtr+104),mulf(MEM_ReadInt(MEM_Camera.connectedVob+92), mulf(shoulder, mkf(1000))));
    var int u[3]; var int v[3];
    u[0] = subf(camPos[0], MEM_ReadInt(herPtr+72));   v[0] = subf(camPos[0], helpPos[0]);
    u[1] = subf(camPos[1], MEM_ReadInt(herPtr+88));   v[1] = subf(camPos[1], helpPos[1]);
    u[2] = subf(camPos[2], MEM_ReadInt(herPtr+104));  v[2] = subf(camPos[2], helpPos[2]);
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
        CALL_IntParam(_@(flags));
        CALL_PtrParam(_@(herPtr)); // Ignore player model
        CALL_PtrParam(_@(dirPosPtr));
        CALL__fastcall(_@(worldPtr), _@(fromPosPtr), zCWorld__TraceRayNearestHit_Vob);
        call = CALL_End();
    };
    var int found; found = CALL_RetValAsInt();
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
    var oCNpc her; her = Hlp_GetNpc(hero);
    var int size; size = CROSSHAIR_MAX_SIZE; // Size of crosshair
    if (getFreeAimFocus()) { // Set focus npc if there is a valid one under the crosshair
        var int target; var int distance;
        aimRay(AIM_MAX_DIST, _@(target), 0, _@(distance)); // Shoot trace ray and retrieve vob
        if (Hlp_Is_oCNpc(target)) {
            var C_NPC targetNPC; targetNPC = _^(target);
            if (Npc_IsInState(targetNPC, ZS_Unconscious))
            || (Npc_IsInState(targetNPC, ZS_MagicSleep))
            || (Npc_IsDead(targetNPC)) { her.focus_vob = 0; } // If npc is down don't show name or health bar
            else { her.focus_vob = target; }; // Set new focus vob
        } else { her.focus_vob = 0; }; // No npc under crosshair
        size = size - roundf(mulf(divf(distance, mkf(AIM_MAX_DIST)), mkf(size))); // Adjust crosshair size
    };
    insertCrosshair(POINTY_CROSSHAIR, size); // Draw/update crosshair
    MEM_InitGlobalInst(); // This is necessary here to find the camera vob, although it was called in init_global. Why?
    var zCVob cam; cam = _^(MEM_Camera.connectedVob);
    var int pos[3]; // The position is calculated from the camera, not the player model.
    pos[0] = addf(cam.trafoObjToWorld[ 3], mulf(cam.trafoObjToWorld[ 2], mkf(AIM_MAX_DIST)));
    pos[1] = addf(cam.trafoObjToWorld[ 7], mulf(cam.trafoObjToWorld[ 6], mkf(AIM_MAX_DIST)));
    pos[2] = addf(cam.trafoObjToWorld[11], mulf(cam.trafoObjToWorld[10], mkf(AIM_MAX_DIST)));
    // Get aiming angles
    var int angleX; var int angXptr; angXptr = _@(angleX);
    var int angleY; var int angYptr; angYptr = _@(angleY);
    var int posPtr; posPtr = _@(pos);
    var int herPtr; herPtr = _@(her); // So many pointer because it is a recyclable call
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
    angleY = subf(FLOATONE, angleY); // Flip  Y +-1 to -+1
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
    var int pos[3]; aimRay(AIM_MAX_DIST, 0, _@(pos), 0); // Shoot trace ray and retrieve intersection
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
