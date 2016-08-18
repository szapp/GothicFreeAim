/*
 * Free aim framework
 *
 * Written by mud-freak
 * With help from Lehona
 *
 * Requirements:
 *  - Ikarus (>= 1.2 +floats)
 *  - LeGo (>= 2.3.2) with initialized packages:
 *     - LeGo_HookEngine
 *     - LeGo_Cursor
  */

const int AIM_MAX_DIST                            = 5000; // 50 meters. For shooting at the crosshair at all ranges.
const int sizeof_zCVob                            = 288;
/* These are all addresses used. When adjusting these, it should also work for Gothic 1 */
const int zCVob__zCVob                            = 7845536; //0x5FE1E0
const int zCVob__SetPositionWorld                 = 6404976; //0x61BB70
const int zCWorld__AddVobAsChild                  = 6440352; //0x6245A0
const int oCAniCtrl_Human__TurnDegrees            = 7006992; //0x6AEB10
const int oCNpc__GetAngles                        = 6820528; //0x6812B0
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
};

/* Check whether free aim should be activated */
func int isFreeAimActive() {
    if (!MEM_ReadInt(mouseEnabled)) { return 0; }; // Only when mouse controls are enabled
    var oCNpc her; her = Hlp_GetNpc(hero);
    if (!Npc_IsInFightMode(her, FMODE_FAR)) { return 0; }; // Only while using bow/crossbow
    if (!MEM_KeyPressed(MEM_GetKey("keyAction"))) && (!MEM_KeyPressed(MEM_GetSecondaryKey("keyAction"))) { return 0; };
    return 1;
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

/* Hook oCAniCtrl_Human::InterpolateCombineAni. Set target position to update aim animation */
func void catchICAni() {
    if (!isFreeAimActive()) { return; };
    MEM_InitGlobalInst(); // This is necessary here to find the camera vob, although it was called in init_global. Why?
    var zCVob cam; cam = _^(MEM_Camera.connectedVob);
    var int pos[6]; // Combined pos[3] + dir[3]. The position is calculated from the camera, not the player model.
    pos[0] = cam.trafoObjToWorld[ 3];  pos[3] = mulf(cam.trafoObjToWorld[ 2], mkf(AIM_MAX_DIST));
    pos[1] = cam.trafoObjToWorld[ 7];  pos[4] = mulf(cam.trafoObjToWorld[ 6], mkf(AIM_MAX_DIST));
    pos[2] = cam.trafoObjToWorld[11];  pos[5] = mulf(cam.trafoObjToWorld[10], mkf(AIM_MAX_DIST));
    pos[0] = addf(pos[0], pos[3]);
    pos[1] = addf(pos[1], pos[4]);
    pos[2] = addf(pos[2], pos[5]);
    // Get aiming angles
    var oCNpc her; her = Hlp_GetNpc(hero);
    var int angleX; var int angXptr; angXptr = _@(angleX);
    var int angleY; var int angYptr; angYptr = _@(angleY);
    var int posPtr; posPtr = _@(pos);
    var int herPtr; herPtr = _@(her); // So many pointer because it is a recyclable _thiscall
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
    var int deg90To05; deg90To05 = mulf(1010174817, FLOATHALB); // 0.0111111*0.5 (from 0x8306EC in g2)
    angleY = mulf(angleY, deg90To05); // Scale Y +-90 degrees to +-0.5
    angleY = addf(angleY, FLOATHALB); // Shift Y +-0.5 to +-1
    angleY = subf(FLOATEINS, angleY); // Flip  Y +-1 to -+1
    if (lef(angleY, FLOATNULL)) {
        angleY = FLOATNULL; // Maximum aim height (straight up)
    } else if (gef(angleY, 1065353216)) {
        angleY = 1065353216; //3F800000 // Minimum aim height (down)
    };
    // New aiming coordinates. Overwrite the arguments passed to oCAniCtrl_Human::InterpolateCombineAni
    MEM_WriteInt(ESP+4, FLOATHALB); // Always at the x center
    MEM_WriteInt(ESP+8, angleY);
};

/* Hook oCAIArrow::SetupAIVob */
func void shootTarget() {
    var C_NPC shooter; shooter = _^(MEM_ReadInt(ESP+8)); // Second argument is shooter
    if (!Npc_IsPlayer(shooter)) || (!isFreeAimActive()) { return; }; // Only for the player
    MEM_InitGlobalInst(); // This is necessary here to find the camera vob, although it was called in init_global. Why?
    var zCVob cam; cam = _^(MEM_Camera.connectedVob);
    var int pos[6]; // Combined pos[3] + dir[3]
    pos[0] = cam.trafoObjToWorld[ 3]; pos[3] = mulf(cam.trafoObjToWorld[ 2], mkf(AIM_MAX_DIST));
    pos[1] = cam.trafoObjToWorld[ 7]; pos[4] = mulf(cam.trafoObjToWorld[ 6], mkf(AIM_MAX_DIST));
    pos[2] = cam.trafoObjToWorld[11]; pos[5] = mulf(cam.trafoObjToWorld[10], mkf(AIM_MAX_DIST));
    if (TraceRay(_@(pos), _@(pos)+12, // Shoot trace ray from camera(!) to max distance
            (zTRACERAY_POLY_TEST_WATER | zTRACERAY_POLY_IGNORE_TRANSP | zTRACERAY_VOB_IGNORE_PROJECTILES))) {
        pos[0] = MEM_World.foundIntersection[0]; // Set new position to intersection
        pos[1] = MEM_World.foundIntersection[1]; // (First point where the trace ray made contact with a polygon)
        pos[2] = MEM_World.foundIntersection[2];
    } else {
        pos[0] = addf(pos[0], pos[3]); // If nothing is in the way, set new position to max distance
        pos[1] = addf(pos[1], pos[4]);
        pos[2] = addf(pos[2], pos[5]);
    };
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

/*
 * Crosshair framework
 */
var int crosshairHndl; // Hold the crosshair handle

/* Delete crosshair (hiding it is not sufficient, since it might change texture later) */
func void removeCrosshair() {
    if (Hlp_IsValidHandle(crosshairHndl)) { View_Delete(crosshairHndl); };
};

/* Draw crosshair */
func void insertCrosshair(var int crosshairStyle) {
    if (crosshairStyle > 1) {
        var string crosshairTex;
        if (!Hlp_IsValidHandle(crosshairHndl)) {
            Print_GetScreenSize();
            var int posX; posX = Print_Screen[PS_X] / 2;
            var int posY; posY = Print_Screen[PS_Y] / 2;
            crosshairHndl = View_CreatePxl(posX-32, posY-32, posX+32, posY+32);
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
        };
    } else { removeCrosshair(); };
};

/* Decide when to draw crosshair (otherwise make sure it's deleted) */
func void manageCrosshair() {
    if (!MEM_KeyPressed(MEM_GetKey("keyAction")))
    && (!MEM_KeyPressed(MEM_GetSecondaryKey("keyAction"))) {
        removeCrosshair(); // Only apply manual rotation when action button is held
        return;
    };
    if (Npc_IsInFightMode(hero, FMODE_FAR)) {
        Focus_Ranged.npc_prio = -1; // Disable focus collection
        insertCrosshair(PNTSML_CROSSHAIR);
    } else if (Npc_IsInFightMode(hero, FMODE_MAGIC)) {
        var int activeSpell; activeSpell = Npc_GetActiveSpell(hero);
        insertCrosshair(MEM_ReadStatArr(spellTurnable, activeSpell));
    } else { removeCrosshair(); };
};
