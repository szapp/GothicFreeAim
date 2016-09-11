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
const int    FREEAIM_FOCUS_ACTIVATED              = 1;      // Enable/Disable focus collection (disable for performance)
const int    FREEAIM_CAMERA_X_SHIFT               = 0;      // Set to 1, if camera is in shoulder view (not recommended)
const int    FREEAIM_MAX_DIST                     = 5000;   // 50 meters. For shooting and crosshair adjustments
const int    FREEAIM_DRAWTIME_MIN                 = 1110;   // Minimum draw time (ms). Do not change - tied to animation
const int    FREEAIM_DRAWTIME_MAX                 = 2500;   // Maximum draw time (ms) for best trajectory
const int    FREEAIM_TRAJECTORY_ARC_MAX           = 400;    // Maximum distance at which the trajectory drops off
const int    FREEAIM_TREMOR                       = 12;     // Camera tremor when exceeding FREEAIM_DRAWTIME_MAX
const float  FREEAIM_ROTATION_SCALE               = 0.16;   // Turn rate. Non weapon mode is 0.2 (zMouseRotationScale)
const float  FREEAIM_PROJECTILE_GRAVITY           = 0.1;    // The gravity decides how fast the projectile drops
const int    FREEAIM_PROJECTILE_COLLECTABLE       = 1;      // Make use of the projectile collectible script
const int    CROSSHAIR_MIN_SIZE                   = 16;     // Smallest crosshair size in pixels (longest range)
const int    CROSSHAIR_MED_SIZE                   = 20;     // Medium crosshair size in pixels (for disabled focus)
const int    CROSSHAIR_MAX_SIZE                   = 32;     // Biggest crosshair size in pixels (closest range)
const int    ARROWAI_REDIRECT                     = 0;      // Used to redirect call-by-reference argument
const string FREEAIM_CAMERA               = "CamModRngeFA"; // CCamSys_Def script instance
const string FREEAIM_TRAIL_FX            = "freeAim_TRAIL"; // Trailstrip FX. Should not be changed
var   int    crosshairHndl;                                 // Holds the crosshair handle
var   int    bowDrawOnset;                                  // Time onset of drawing the bow

/* These are all addresses (a.o.) used. Of course for gothic 2 as LeGo only supports gothic 2 */
const int sizeof_zCVob                            = 288; // Gothic 1: 256
const int oCNpc_anictrl_offset                    = 2432; // Gothic 1: 2488
const int oCNpc_focus_vob_offset                  = 2476; // Gothic 1: 2532
const int zCVob__zCVob                            = 6283744; //0x5FE1E0
const int zCVob__SetPositionWorld                 = 6404976; //0x61BB70
const int zCWorld__AddVobAsChild                  = 6440352; //0x6245A0
const int oCAniCtrl_Human__Turn                   = 7005504; //0x6AE540
const int oCNpc__GetAngles                        = 6820528; //0x6812B0
const int zCWorld__TraceRayNearestHit_Vob         = 6430624; //0x621FA0
const int zCVob__TraceRay                         = 6291008; //0x5FFE40
const int zCArray_zCVob__IsInList                 = 7159168; //0x6D3D80
const int oCNpc__SetFocusVob                      = 7547744; //0x732B60
const int oCNpc__SetEnemy                         = 7556032; //0x734BC0
const int zCVob__GetRigidBody                     = 6285664; //0x5FE960
const int oCItem__InsertEffect                    = 7416896; //0x712C40
const int oCItem__RemoveEffect                    = 7416832; //0x712C00
const int oCGame__s_bUseOldControls               = 9118144; //0x8B21C0
const int zString_CamModRanged                    = 9234704; //0x8CE910
const int mouseEnabled                            = 9248108; //0x8D1D6C
const int mouseSensX                              = 9019720; //0x89A148
const int mouseDeltaX                             = 9246300; //0x8D165C
const int oCAniCtrl_Human__InterpolateCombineAni  = 7037296; //0x6B6170 // Hook
const int oCAIArrow__SetupAIVob                   = 6951136; //0x6A10E0 // Hook
const int oCAIHuman__BowMode                      = 6905600; //0x695F00 // Hook
const int oCAIArrowBase__DoAI                     = 6948416; //0x6A0640 // Hook
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
        HookEngineF(oCAIArrowBase__DoAI, 7, projectileCollectable); // Called for projectile
        HookEngineF(mouseUpdate, 5, manualRotation);
        hookFreeAim = 1;
    };
    MEM_Info("Free aim initialized.");
};

const int oCNpcFocus__focuslist = 11208440; //0xAB06F8
const int oCNpcFocus__focus = 11208504; //0xAB0738
const int Focus_RangedFA = 0; // Focus class ptr

/* Check whether free aim should be activated */
func int isFreeAimActive() {
    if (!STR_ToInt(MEM_GetGothOpt("FREEAIM", "enabled"))) // Free aiming is disabled in the menu
    || (!MEM_ReadInt(mouseEnabled)) // Mouse controls are disabled
    || (!MEM_ReadInt(oCGame__s_bUseOldControls)) { // Classic gothic 1 controls are disabled
/*        if (MEM_ReadInt(oCNpcFocus__focuslist+8) != _@(Focus_Ranged)) { // Reset ranged focus collection to standard
            MEM_WriteInt(oCNpcFocus__focuslist+8, _@(Focus_Ranged));
        };*/
        Focus_Ranged.npc_azi =  45.0; // Reset ranged focus collection to standard
        Focus_Ranged.npc_elevup =  90.0;
        Focus_Ranged.npc_elevdo =  -85.0;
        if (!Hlp_StrCmp(MEM_ReadString(zString_CamModRanged), "CamModRanged")) { // Reset camera mode to standard
            MEM_WriteString(zString_CamModRanged, "CAMMODRANGED"); // Upper case here is very important
        };
        return 0;
    };
    // Everything below is only reached if free aiming is enabled (but not necessarily active)
    if (MEM_Game.pause_screen) { return 0; }; // Only when playing
    if (!InfoManager_HasFinished()) { return 0; }; // Not in dialogs
    if (!Npc_IsInFightMode(hero, FMODE_FAR)) { return 0; }; // Only while using bow/crossbow
    // Everything below is only reached if free aiming is enabled and active (player is in respective fight mode)
/*    if (!Focus_RangedFA) { // DANGEROUS: pointer changes
        Focus_RangedFA = MEM_Alloc(80);
        MEM_CopyWords(oCNpcFocus__focuslist+8, Focus_RangedFA, 80);
        MEM_WriteInt(Focus_RangedFA+12, castToIntf(15.0));
        MEM_WriteInt(Focus_RangedFA+16, castToIntf(15.0));
        MEM_WriteInt(Focus_RangedFA+20, castToIntf(-10.0));
    };
    if (MEM_ReadInt(oCNpcFocus__focuslist+8) != _@(Focus_RangedFA)) { // Set stricter focus collection
        MEM_WriteInt(oCNpcFocus__focuslist+8, _@(Focus_RangedFA));
    };*/
    Focus_Ranged.npc_azi = 15.0; // Set stricter focus collection
    Focus_Ranged.npc_elevup = 15.0;
    Focus_Ranged.npc_elevdo = -10.0;
    if (!Hlp_StrCmp(MEM_ReadString(zString_CamModRanged), FREEAIM_CAMERA)) { // Correct the camera mode
        MEM_WriteString(zString_CamModRanged, STR_Upper(FREEAIM_CAMERA)); // Upper case here is very important
    };
    var int keyStateAction1; keyStateAction1 = MEM_KeyState(MEM_GetKey("keyAction")); // A bit much, but needed later
    var int keyStateAction2; keyStateAction2 = MEM_KeyState(MEM_GetSecondaryKey("keyAction"));
    if (keyStateAction1 != KEY_PRESSED) && (keyStateAction1 != KEY_HOLD) // Only while pressing the action button
    && (keyStateAction2 != KEY_PRESSED) && (keyStateAction2 != KEY_HOLD) { return 0; };
    // Get onset for drawing the bow when just pressing down the action key
    if (keyStateAction1 == KEY_PRESSED) || (keyStateAction2 == KEY_PRESSED) { bowDrawOnset = MEM_Timer.totalTime; };
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
    if (Npc_IsInFightMode(hero, FMODE_FAR)) { return 1; }; // Only while using bow/crossbow
    return 0;
};

/* Mouse handling for manually turning the player model */
func void manualRotation() {
    if (!isFreeAimActive()) { return; };
    var int deltaX; deltaX = mulf(mkf(MEM_ReadInt(mouseDeltaX)), MEM_ReadInt(mouseSensX)); // Get mouse change in x
    if (deltaX == FLOATNULL) { return; }; // Only rotate if there was movement along x position
    deltaX = mulf(deltaX, castToIntf(FREEAIM_ROTATION_SCALE)); // Turn rate
    var int hAniCtrl; hAniCtrl = MEM_ReadInt(_@(hero)+oCNpc_anictrl_offset); // oCNpc.anictrl
    const int call = 0; var int null;
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
    var zMAT4 camPos; camPos = _^(MEM_ReadInt(MEM_ReadInt(MEMINT_oGame_Pointer_Address)+20)+60); //0=right, 2=out, 3=pos
    var int herPtr; herPtr = _@(hero);
    // Shift the start point for the trace ray beyond the player model. Necessary, because if zooming out,
    // (1) there might be something between camera and hero and (2) the maximum aiming distance is off.
    var int dist; dist = sqrtf(addf(addf( // Distance between camera and player model (does not care about cam offset)
        sqrf(subf(MEM_ReadInt(herPtr+72), camPos.v0[3])),
        sqrf(subf(MEM_ReadInt(herPtr+88), camPos.v1[3]))),
        sqrf(subf(MEM_ReadInt(herPtr+104), camPos.v2[3]))));
    if (FREEAIM_CAMERA_X_SHIFT) { // Shifting the camera (shoulderview) is not recommended. Aiming is harder + less fps?
        // This makes the distance mentioned above more complex and requires the calculation of a point-line distance
        // For illustration: http://mathworld.wolfram.com/Point-LineDistance3-Dimensional.html
        var int line[6]; // Line with two points along the camera right vector at the level of the player model
        line[0] = subf(MEM_ReadInt(herPtr+72),  mulf(camPos.v0[0], mkf(1000))); // Left of player model
        line[1] = subf(MEM_ReadInt(herPtr+88),  mulf(camPos.v1[0], mkf(1000)));
        line[2] = subf(MEM_ReadInt(herPtr+104), mulf(camPos.v2[0], mkf(1000)));
        line[3] = addf(MEM_ReadInt(herPtr+72),  mulf(camPos.v0[0], mkf(1000))); // Right of player model
        line[4] = addf(MEM_ReadInt(herPtr+88),  mulf(camPos.v1[0], mkf(1000)));
        line[5] = addf(MEM_ReadInt(herPtr+104), mulf(camPos.v2[0], mkf(1000)));
        var int u[3]; var int v[3]; // Substract both points of the line from the camera position
        u[0] = subf(camPos.v0[3], line[0]); v[0] = subf(camPos.v0[3], line[3]);
        u[1] = subf(camPos.v1[3], line[1]); v[1] = subf(camPos.v1[3], line[4]);
        u[2] = subf(camPos.v2[3], line[2]); v[2] = subf(camPos.v2[3], line[5]);
        var int crossProd[3]; // Cross-product
        crossProd[0] = subf(mulf(u[1], v[2]), mulf(u[2], v[1]));
        crossProd[1] = subf(mulf(u[2], v[0]), mulf(u[0], v[2]));
        crossProd[2] = subf(mulf(u[0], v[1]), mulf(u[1], v[0]));
        dist = sqrtf(addf(addf(sqrf(crossProd[0]), sqrf(crossProd[1])), sqrf(crossProd[2])));
        dist = divf(dist, mkf(2000)); // Devide area of triangle by length between the points on the line
    };
    var int traceRayVec[6];
    traceRayVec[0] = addf(camPos.v0[3], mulf(camPos.v0[2], dist)); // Start ray from here
    traceRayVec[1] = addf(camPos.v1[3], mulf(camPos.v1[2], dist));
    traceRayVec[2] = addf(camPos.v2[3], mulf(camPos.v2[2], dist));
    traceRayVec[3] = mulf(camPos.v0[2], mkf(distance)); // Direction-/to-vector of ray
    traceRayVec[4] = mulf(camPos.v1[2], mkf(distance));
    traceRayVec[5] = mulf(camPos.v2[2], mkf(distance));
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
    var int found; found = CALL_RetValAsInt(); // Did the trace ray hit
    var int foundFocus; foundFocus = 0; // Is the focus vob in the trace ray vob list
    var int potentialVob; potentialVob = MEM_ReadInt(herPtr+oCNpc_focus_vob_offset); // Focus vob by focus collection
    if (potentialVob) && (Hlp_Is_oCNpc(potentialVob)) { // Now check if the collected focus was hit by the trace ray
        var C_NPC target; target = _^(potentialVob);  // Do not allow focussing npcs that are down
        if (!Npc_IsInState(target, ZS_Unconscious)) && (!Npc_IsInState(target, ZS_MagicSleep)) && (!Npc_IsDead(target)){
            var int potVobPtr; potVobPtr = _@(potentialVob);
            var int voblist; voblist = _@(MEM_World.traceRayVobList_array);
            const int call2 = 0;
            if (CALL_Begin(call2)) { // Check if focus vob is in trace ray vob list
                CALL_PtrParam(_@(potVobPtr));
                CALL__thiscall(_@(voblist), zCArray_zCVob__IsInList);
                call2 = CALL_End();
            };
            if (CALL_RetValAsInt()) { // If it is in the vob list, run a more detailed examination
                // This is essentially taken/modified from zCWorld::TraceRayNearestHit (specifically at 0x621D82 in g2)
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
                    MEM_World.foundVob = potentialVob;
                    MEM_CopyWords(trRep+12, _@(MEM_World.foundIntersection), 3); // 0x0C zVEC3
                    foundFocus = potentialVob; // Confirmed focus vob
                };
                MEM_Free(trRep); // Free the report
            };
        };
    };
    if (foundFocus != potentialVob) { // If focus vob changed
        const int call4 = 0; // Set the focus vob properly: reference counter
        if (CALL_Begin(call4)) {
            CALL_PtrParam(_@(foundFocus)); // If no npc was found, this will remove the focus
            CALL__thiscall(_@(herPtr), oCNpc__SetFocusVob);
            call4 = CALL_End();
        };
        const int call5 = 0; var int null; // Remove the enemy properly: reference counter
        if (CALL_Begin(call5)) {
            CALL_PtrParam(_@(null)); // Always remove oCNpc.enemy. Target will be set to aimvob when shooting
            CALL__thiscall(_@(herPtr), oCNpc__SetEnemy);
            call5 = CALL_End();
        };
    };
    // Write call-by-reference variables
    if (vobPtr) { MEM_WriteInt(vobPtr, MEM_World.foundVob); };
    if (posPtr) { MEM_CopyWords(_@(MEM_World.foundIntersection), posPtr, 3); };
    if (distPtr) {
        distance = sqrtf(addf(addf(
            sqrf(subf(MEM_World.foundIntersection[0], traceRayVec[0])),
            sqrf(subf(MEM_World.foundIntersection[1], traceRayVec[1]))),
            sqrf(subf(MEM_World.foundIntersection[2], traceRayVec[2]))));
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
        const int call4 = 0; var int null; // Set the focus vob properly: reference counter
        if (CALL_Begin(call4)) {
            CALL_PtrParam(_@(null)); // This will remove the focus
            CALL__thiscall(_@(herPtr), oCNpc__SetFocusVob);
            call4 = CALL_End();
        };
        const int call5 = 0; // Remove the enemy properly: reference counter
        if (CALL_Begin(call5)) {
            CALL_PtrParam(_@(null)); // Always remove oCNpc.enemy. Target will be set to aimvob when shooting
            CALL__thiscall(_@(herPtr), oCNpc__SetEnemy);
            call5 = CALL_End();
        };
    };
    insertCrosshair(POINTY_CROSSHAIR, size); // Draw/update crosshair
    var zMAT4 camPos; camPos = _^(MEM_ReadInt(MEM_ReadInt(MEMINT_oGame_Pointer_Address)+20)+60); //0=right, 2=out, 3=pos
    var int pos[3]; // The position is calculated from the camera, not the player model.
    pos[0] = addf(camPos.v0[3], mulf(camPos.v0[2], mkf(FREEAIM_MAX_DIST)));
    pos[1] = addf(camPos.v1[3], mulf(camPos.v1[2], mkf(FREEAIM_MAX_DIST)));
    pos[2] = addf(camPos.v2[3], mulf(camPos.v2[2], mkf(FREEAIM_MAX_DIST)));
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
    if (lf(absf(angleX), 1048576000)) { // Prevent multiplication with too small numbers. Would result in aim twitching
        if (lf(angleX, FLOATNULL)) { angleX =  -1098907648; } // -0.25
        else { angleX = 1048576000; }; // 0.25
    };
    if (lf(absf(angleY), 1048576000)) { // Prevent multiplication with too small numbers. Would result in aim twitching
        if (lf(angleY, FLOATNULL)) { angleY =  -1098907648; } // -0.25
        else { angleY = 1048576000; }; // 0.25
    };
    // This following paragraph is essentially "copied" from oCAIHuman::BowMode (0x695F00 in g2)
    angleX = addf(mulf(angleX, 1001786197), FLOATHALF); // Scale and X [-90° +90°] to [0 +1]
    angleY = negf(subf(mulf(angleY, 1001786197), FLOATHALF)); // Scale and flip Y [-90° +90°] to [+1 0]
    if (lef(angleX, FLOATNULL)) { angleX = FLOATNULL; } // Maximum turning
    else if (gef(angleX, 1065353216)) { angleX = 1065353216; };
    if (lef(angleY, FLOATNULL)) { angleY = FLOATNULL; } // Maximum aim height (straight up)
    else if (gef(angleY, 1065353216)) { angleY = 1065353216; }; // Minimum aim height (down)
    // New aiming coordinates. Overwrite the arguments passed to oCAniCtrl_Human::InterpolateCombineAni
    MEM_WriteInt(ESP+4, angleX); // Also overwrite x. Important for strafing
    MEM_WriteInt(ESP+8, angleY);
};

/* Hook oCAIArrow::SetupAIVob */
func void shootTarget() {
    var int projectile; projectile = MEM_ReadInt(ESP+4);  // First argument is the projectile
    var C_NPC shooter; shooter = _^(MEM_ReadInt(ESP+8)); // Second argument is shooter
    if (!Npc_IsPlayer(shooter)) || (!isFreeAimActive()) { return; }; // Only for the player
    var int pos[3]; aimRay(FREEAIM_MAX_DIST, 0, _@(pos), 0); // Shoot trace ray and retrieve intersection
    var int vobPtr; vobPtr = MEM_SearchVobByName("AIMVOB"); // Arrow needs target vob
    if (!vobPtr) {
        vobPtr = MEM_Alloc(sizeof_zCVob); // Will never delete this vob (it will be re-used on the next shot)
        CALL__thiscall(vobPtr, zCVob__zCVob);
        MEM_WriteString(vobPtr+16, "AIMVOB"); // zCVob._zCObject_objectName
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
    // Set projectile drop-off
    const int call2 = 0;
    if (CALL_Begin(call2)) {
        CALL__thiscall(_@(projectile), zCVob__GetRigidBody); // Get ridigBody this way, it will be properly created
        call2 = CALL_End();
    };
    var int rBody; rBody = CALL_RetValAsInt(); // zCRigidBody*
    MEM_Info(ConcatStrings("^ End time: ", IntToString(MEM_Timer.totalTime)));
    bowDrawOnset = MEM_Timer.totalTime - bowDrawOnset; // Check for how long the bow was drawn
    MEM_Info(ConcatStrings("| Duration: ", IntToString(bowDrawOnset)));
    if (bowDrawOnset > FREEAIM_DRAWTIME_MAX) { bowDrawOnset = FREEAIM_TRAJECTORY_ARC_MAX; } // Force drop-off
    else if (bowDrawOnset < FREEAIM_DRAWTIME_MIN) { bowDrawOnset = 0; } // No negative numbers
    else { // Calculate the drop-off time within the range of [0, FREEAIM_TRAJECTORY_ARC_MAX]
        var int numerator; numerator = mkf(FREEAIM_TRAJECTORY_ARC_MAX * (bowDrawOnset - FREEAIM_DRAWTIME_MIN));
        var int denominator; denominator = mkf(FREEAIM_DRAWTIME_MAX - FREEAIM_DRAWTIME_MIN);
        bowDrawOnset = roundf(divf(numerator, denominator));
    };
    MEM_Info(ConcatStrings("### Drop-off time: ", IntToString(bowDrawOnset)));
    FF_ApplyOnceExtData(dropProjectile, bowDrawOnset, 1, rBody); // Safe?
    bowDrawOnset = MEM_Timer.totalTime; // Reset draw timer
    MEM_Info(ConcatStrings("v Start time (rld): ", IntToString(bowDrawOnset)));
    var int gravityMod; gravityMod = FLOATONE;
    if (bowDrawOnset < FREEAIM_TRAJECTORY_ARC_MAX/4) { gravityMod = mkf(2); }; // Very short draw time increases gravity
    // MEM_WriteInt(rBody+236, mulf(castToIntf(FREEAIM_PROJECTILE_GRAVITY), gravityMod)); // Experimental
    MEM_WriteInt(rBody+236, mulf(castToIntf(FREEAIM_PROJECTILE_GRAVITY), gravityMod));
    if (Hlp_Is_oCItem(projectile)) && (Hlp_StrCmp(MEM_ReadString(projectile+564), "")) { // Projectile has no FX
        MEM_WriteString(projectile+564, FREEAIM_TRAIL_FX); // Set trail strip fx for better visibility
        const int call3 = 0;
        if (CALL_Begin(call3)) {
            CALL__thiscall(_@(projectile), oCItem__InsertEffect);
            call3 = CALL_End();
        };
    };
    MEM_WriteInt(ESP+12, vobPtr); // Overwrite the third argument (target vob) passed to oCAIArrow::SetupAIVob
};

func void dropProjectile(var int rigidBody) {
    if (!rigidBody) { return; };
    MEM_WriteByte(rigidBody+256, 1); // Turn on gravity (zCRigidBody.bitfield)
};

/* Once a projectile stopped moving or collided with an npc keep it alive or put it into the inventory. */
func void projectileCollectable() {
    var int arrowAI; arrowAI = ECX; // AI of the projectile
    var int projectilePtr; projectilePtr = MEM_ReadInt(ESP+4); // Projectile (item). Taken from arguments
    var int removePtr; removePtr = MEM_ReadInt(ESP+8); // Boolean pointer (call-by-reference argument)
    if (!projectilePtr) { return; }; // oCItem. In case it does not exist
    var oCItem projectile; projectile = _^(projectilePtr);
    if (!projectile._zCVob_rigidBody) { return; }; // zCRigidBody. Might not exist the first time
    // Reset projectile gravity (zCRigidBody.gravity) after collision (oCAIArrow.collision)
    if (MEM_ReadInt(arrowAI+52)) { MEM_WriteInt(projectile._zCVob_rigidBody+236, FLOATONE); }; // Set gravity to zero
    if (!FREEAIM_PROJECTILE_COLLECTABLE) { return; }; // Normal projectile handling
    // If the projectile gets stuck (instead of bouncing of), check what the projectile collided with
    if (MEM_ReadInt(projectile._zCVob_rigidBody+256) & (1 << 1)) // zCRigidBody.bitfield & collision
    && (MEM_ReadInt(arrowAI+48)) { // oCAIArrow.ignoreVobList
        var zCList voblist; voblist = _^(MEM_ReadInt(arrowAI+48)); // oCAIArrow.ignoreVobList
        while(voblist.next); // Traverse voblist. Don't ask me why the target is in the ignoreVobList
            if (!Hlp_Is_oCNpc(voblist.data)) { voblist = _^(voblist.next); continue; }; // Search for npc
            var C_NPC victim; victim = _^(voblist.data);
            CreateInvItems(victim, projectile.instanz, 1); // Put a respective projectile into the inventory
            MEM_WriteInt(arrowAI+56,  FLOATNULL); // oCAIArrow.lifeTime // Destroy AI and projectile (lifetime = zero)
            return;
        end;
    };
    // If the projectile stopped moving, release its AI
    if (MEM_ReadInt(projectile._zCVob_rigidBody+188) == FLOATNULL) // zCRigidBody.velocity[3]
    && (MEM_ReadInt(projectile._zCVob_rigidBody+192) == FLOATNULL)
    && (MEM_ReadInt(projectile._zCVob_rigidBody+196) == FLOATNULL) {
        MEM_WriteInt(arrowAI+56, FLOATONE); // oCAIArrow.lifeTime // Set high lifetime to ensure item visibility
        projectile.flags = projectile.flags &~ ITEM_NFOCUS; // Focusable (collectable)
        if (Hlp_StrCmp(projectile.effect, FREEAIM_TRAIL_FX)) { // Remove trail strip pfx
            const int call = 0;
            if (CALL_Begin(call)) {
                CALL__thiscall(_@(projectilePtr), oCItem__RemoveEffect);
                call = CALL_End();
            };
        };
        projectile._zCVob_callback_ai = 0; // Release vob from AI
        MEM_WriteInt(removePtr, 0); // Do not remove vob on AI destruction
        MEM_WriteInt(ESP+8, _@(ARROWAI_REDIRECT)); // Divert the actual "return" value
    };
};
