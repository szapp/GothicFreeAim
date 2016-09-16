/*
 * Free aim framework
 *
 * Written by mud-freak (2016)
 *
 * Requirements:
 *  - Ikarus >= 1.2 (floats)
 *  - LeGo >= 2.3.2 (LeGo_FrameFunctions | LeGo_HookEngine)
 *
 * Customizability:
 *  - Collectible projectiles (yes/no):    FREEAIM_PROJECTILE_COLLECTABLE
 *  - Draw force (drop-off) calculation:   freeAimGetDrawForce()
 *  - Accuracy calculation:                freeAimGetAccuracy()
 *  - Headshot damage multiplier:          freeAimGetHeadshotMultiplier()
 *  - Headshot event:                      freeAimHeadshotEvent()
 * Advanced (modification not recommended):
 *  - Scatter radius for accuracy:         FREEAIM_SCATTER_DEG
 *  - Camera view (shoulder view):         FREEAIM_CAMERA, FREEAIM_CAMERA_X_SHIFT
 *  - Time before projectile drop-off:     FREEAIM_TRAJECTORY_ARC_MAX
 */

/* Free aim settings, only modify those listed above */
const int    FREEAIM_CAMERA_X_SHIFT               = 0;      // Set to 1, if camera is in shoulder view (not recommended)
const int    FREEAIM_MAX_DIST                     = 5000;   // 50 meters. For shooting and crosshair adjustments
const int    FREEAIM_DRAWTIME_MIN                 = 1110;   // Minimum draw time (ms). Do not change - tied to animation
const int    FREEAIM_DRAWTIME_MAX                 = 2500;   // Maximum draw time (ms) for best trajectory
const int    FREEAIM_TRAJECTORY_ARC_MAX           = 400;    // Maximum time (ms) at which the trajectory drops off
const int    FREEAIM_TREMOR                       = 12;     // Camera tremor when exceeding FREEAIM_DRAWTIME_MAX
const float  FREEAIM_ROTATION_SCALE               = 0.16;   // Turn rate. Non weapon mode is 0.2 (zMouseRotationScale)
const float  FREEAIM_PROJECTILE_GRAVITY           = 0.1;    // The gravity decides how fast the projectile drops
const int    FREEAIM_PROJECTILE_COLLECTABLE       = 1;      // Make use of the projectile collectible script
const float  FREEAIM_SCATTER_DEG                  = 2.2;    // Maximum scatter radius in degrees
const int    FREEAIM_ACTIVE_PREVFRAME             = 0;      // Internal. Do not change
const int    CROSSHAIR_MIN_SIZE                   = 16;     // Smallest crosshair size in pixels (longest range)
const int    CROSSHAIR_MED_SIZE                   = 20;     // Medium crosshair size in pixels (for disabled focus)
const int    CROSSHAIR_MAX_SIZE                   = 32;     // Biggest crosshair size in pixels (closest range)
const int    ARROWAI_REDIRECT                     = 0;      // Used to redirect call-by-reference argument
const string FREEAIM_CAMERA               = "CamModRngeFA"; // CCamSys_Def script instance
const string FREEAIM_TRAIL_FX            = "freeAim_TRAIL"; // Trailstrip FX. Should not be changed
var   int    crosshairHndl;                                 // Holds the crosshair handle
var   int    bowDrawOnset;                                  // Time onset of drawing the bow

/* These are all addresses used. Of course for gothic 2 as LeGo only supports gothic 2 */
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
const int alternativeHitchanceAdr                 = 6953494; //0x6A1A10
const int oCNpc__GetModel                         = 7571232; //0x738720
const int zCModel__SearchNode                     = 5758960; //0x57DFF0
const int zCModel__GetBBox3DNodeWorld             = 5738736; //0x5790F0
const int zTBBox3D__GetSphere3D                   = 5528768; //0x545CC0
const int zTBBox3D__Scale                         = 5528560; //0x545BF0
const int zTBBox3D__IsIntersecting                = 6115184; //0x5D4F70
const int mouseEnabled                            = 9248108; //0x8D1D6C
const int mouseSensX                              = 9019720; //0x89A148
const int mouseDeltaX                             = 9246300; //0x8D165C
const int oCAniCtrl_Human__InterpolateCombineAni  = 7037296; //0x6B6170 // Hook
const int oCAIArrow__SetupAIVob                   = 6951136; //0x6A10E0 // Hook
const int oCAIHuman__BowMode                      = 6905600; //0x695F00 // Hook
const int oCAIArrowBase__DoAI                     = 6948416; //0x6A0640 // Hook
const int onArrowHitNpcPtr                        = 6949832; //0x6A0BC8 // Hook
const int onArrowHitVobPtr                        = 6949929; //0x6A0C29 // Hook
const int onArrowHitStatPtr                       = 6949460; //0x6A0A54 // Hook
const int onArrowDamagePtr                        = 6953621; //0x6A1A95 // Hook
const int oCNpcFocus__SetFocusMode                = 7072800; //0x6BEC20 // Hook
const int oCAIHuman__MagicMode                    = 4665296; //0x472FD0 // Hook
const int mouseUpdate                             = 5062907; //0x4D40FB // Hook

/* Modify this function to alter the draw force calculation. Scaled between 0 and 100 (percent) */
func int freeAimGetDrawForce() {
    // Scale draw time between 0 and 100
    var int drawForce; drawForce = MEM_Timer.totalTime - bowDrawOnset; // Check for how long the bow was drawn
    if (drawForce > FREEAIM_DRAWTIME_MAX) { drawForce = 100; } // Fully drawn
    else if (drawForce < FREEAIM_DRAWTIME_MIN) { drawForce = 0; } // No negative numbers
    else { // Calculate the percentage [0, 100]
        var int numerator; numerator = mkf(100 * (drawForce - FREEAIM_DRAWTIME_MIN));
        var int denominator; denominator = mkf(FREEAIM_DRAWTIME_MAX - FREEAIM_DRAWTIME_MIN);
        drawForce = roundf(divf(numerator, denominator));
    };
    // Possibly incorporate more factors like e.g. a quick-draw talent, weapon-specific stats, ...
    // If adding more factors, keep in mind that the final drawForce must be in [0, 100]. This line could ensure that:
    // if (drawForce > 100) { drawForce = 100; } else if (drawForce < 0) { drawForce = 0; };
    return drawForce;
};

/* Modify this function to alter accuracy calculation. Scaled between 0 and 100 (percent) */
func int freeAimGetAccuracy() {
    var int accuracy[3]; // Number of factors playing into the accuracy(+1), here: talent [1] and draw force [2]
    // Factor 1: Talent (keep in mind that it might be greater than 100)
    var C_Item weapon;
    if (Npc_IsInFightMode(hero, FMODE_FAR)) { weapon = Npc_GetReadiedWeapon(hero); }
    else if (Npc_HasEquippedRangedWeapon(hero)) { weapon = Npc_GetEquippedRangedWeapon(hero); }
    else { MEM_Error("freeAimGetAccuracy: No valid weapon equipped/readied!"); return -1; };
    if (weapon.flags & ITEM_BOW) { accuracy[1] = hero.HitChance[NPC_TALENT_BOW]; }
    else if (weapon.flags & ITEM_CROSSBOW) { accuracy[1] = hero.HitChance[NPC_TALENT_CROSSBOW]; }
    else { MEM_Error("freeAimGetAccuracy: No valid weapon equipped/readied!"); return -1; };
    // Factor 2: Draw force
    accuracy[2] = freeAimGetDrawForce(); // Already scaled between [0, 100], see freeAimGetDrawForce()
    // Factor X: Add any other factors here e.g. weapon-specific accuracy stats, weapon spread, accuracy talent, ...
    // Calculate overall accuracy: From all factors (modify the following lines to change the calculation)
    // Here the talent is scaled by draw force: draw force=100% => accuracy=talent; draw force=0% => accuracy=talent/2
    if (accuracy[2] < accuracy[1]) { accuracy[2] = accuracy[1]; }; // Decrease impact of draw force on talent
    accuracy[0] = (accuracy[1] * accuracy[2])/100;
    // Final accuracy needs to be in [0, 100]
    if (accuracy[0] > 100) { accuracy[0] = 100; } else if (accuracy[0] < 0) { accuracy[0] = 0; };
    return accuracy[0];
};

/* Modify this function to set the headshot multiplier. Caution: Return value is a float */
func int freeAimGetHeadshotMultiplier() {
    var int multiplier;
    // Possibly incorporate weapon-specific stats, headshot talent, dependency on accuracy, ...
    multiplier = castToIntf(2.0); // For now it is just a fixed multiplier
    return multiplier; // Caution: This only multiplies the base damage (damage of the weapon), not the final damage!
};

/* Use this function to create an event when getting a headshot, e.g. a print or a sound jingle, leave blank for none */
func void freeAimHeadshotEvent() {
    Snd_Play("FORGE_ANVIL_A1");
    PrintS("Kritischer Treffer"); // "Critical hit"
};

/********************************************** DO NO CROSS THIS LINE **************************************************

  WARNING: All necessary adjustments can be performed above. You should not need to edited anything below.
  Proceed at your own risk: On modifying the functions below free aiming will most certainly become unstable.

*********************************************** DO NO CROSS THIS LINE *************************************************/

/* Initialize free aim framework */
func void Init_FreeAim() {
    const int hookFreeAim = 0;
    if (!hookFreeAim) {
        HookEngineF(oCAniCtrl_Human__InterpolateCombineAni, 5, catchICAni); // Updates aiming animation
        HookEngineF(oCAIArrow__SetupAIVob, 6, shootTarget); // Sets projectile direction and trajectory
        HookEngineF(oCAIHuman__BowMode, 6, manageCrosshair); // Manages the crosshair (style, on/off)
        HookEngineF(oCNpcFocus__SetFocusMode, 7, manageCrosshair); // Called when changing focus mode (several times)
        HookEngineF(oCAIHuman__MagicMode, 7, manageCrosshair); // Manages the crosshair (style, on/off)
        HookEngineF(mouseUpdate, 5, manualRotation); // Updates the player model rotation by mouse input
        HookEngineF(oCAIArrowBase__DoAI, 7, projectileCollectable); // AI loop for each projectile
        HookEngineF(onArrowDamagePtr, 7, headshotDetection); // Headshot detection
        if (FREEAIM_PROJECTILE_COLLECTABLE) { // Because of balancing issues, this is a constant and not a variable
            HookEngineF(onArrowHitNpcPtr, 5, onArrowHitNpc); // Puts projectile into inventory
            HookEngineF(onArrowHitVobPtr, 5, onArrowGetStuck); // Keeps projectile alive when stuck in world
            HookEngineF(onArrowHitStatPtr, 5, onArrowGetStuck); // Keeps projectile alive when stuck in world
        };
        MemoryProtectionOverride(alternativeHitchanceAdr, 10); // Enable overwriting hit chance
        r_DefaultInit(); // Start rng for aiming accuracy
        hookFreeAim = 1;
    };
    MEM_Info("Free aim initialized.");
};

/* Hit chance of 100%. Taken from http://forum.worldofplayers.de/forum/threads/1475456?p=25080651#post25080651 */
func void alternativeHitchance() {
    MEM_WriteByte(alternativeHitchanceAdr, ASMINT_OP_nop);
    MEM_WriteByte(alternativeHitchanceAdr+1, ASMINT_OP_nop);
    MEM_WriteByte(alternativeHitchanceAdr+2, ASMINT_OP_nop);
    MEM_WriteByte(alternativeHitchanceAdr+3, ASMINT_OP_nop);
    MEM_WriteByte(alternativeHitchanceAdr+4, ASMINT_OP_nop);
    MEM_WriteByte(alternativeHitchanceAdr+5, ASMINT_OP_nop);
};

/* Restore default hit chance calculation (by talent) */
func void resetHitchance() {
    MEM_WriteByte(alternativeHitchanceAdr, 15);
    MEM_WriteByte(alternativeHitchanceAdr+1, 141);
    MEM_WriteByte(alternativeHitchanceAdr+2, 157);
    MEM_WriteByte(alternativeHitchanceAdr+3, 1);
    MEM_WriteByte(alternativeHitchanceAdr+4, 0);
    MEM_WriteByte(alternativeHitchanceAdr+5, 0);
};

/* Update internal settings when turning free aim on/off in the options */
func void updateFreeAimSetting(var int on) {
    MEM_Info("Updating internal free aiming settings");
    if (on) {
        Focus_Ranged.npc_azi = 15.0; // Set stricter focus collection
        Focus_Ranged.npc_elevup = 15.0;
        Focus_Ranged.npc_elevdo = -10.0;
        MEM_WriteString(zString_CamModRanged, STR_Upper(FREEAIM_CAMERA)); // New camera mode, upper case is important
        alternativeHitchance(); // 100% hit chance (calculated else where for free aiming)
        FREEAIM_ACTIVE_PREVFRAME = 1;
    } else {
        Focus_Ranged.npc_azi =  45.0; // Reset ranged focus collection to standard
        Focus_Ranged.npc_elevup =  90.0;
        Focus_Ranged.npc_elevdo =  -85.0;
        MEM_WriteString(zString_CamModRanged, "CAMMODRANGED"); // Restore camera mode, upper case is important
        resetHitchance(); // Restore default hit chance
        FREEAIM_ACTIVE_PREVFRAME = -1;
    };
};

/* Check whether free aiming should be activated */
func int isFreeAimActive() {
    if (!STR_ToInt(MEM_GetGothOpt("FREEAIM", "enabled"))) // Free aiming is disabled in the menu
    || (!MEM_ReadInt(mouseEnabled)) // Mouse controls are disabled
    || (!MEM_ReadInt(oCGame__s_bUseOldControls)) { // Classic gothic 1 controls are disabled
        if (FREEAIM_ACTIVE_PREVFRAME != -1) { updateFreeAimSetting(0); }; // Update internal settings (turn off)
        return 0;
    };
    if (FREEAIM_ACTIVE_PREVFRAME != 1) { updateFreeAimSetting(1); }; // Update internal settings (turn on)
    // Everything below is only reached if free aiming is enabled (but not necessarily active)
    if (MEM_Game.pause_screen) { return 0; }; // Only when playing
    if (!InfoManager_HasFinished()) { return 0; }; // Not in dialogs
    if (!Npc_IsInFightMode(hero, FMODE_FAR)) { return 0; }; // Only while using bow/crossbow
    // Everything below is only reached if free aiming is enabled and active (player is in respective fight mode)
    var int keyStateAction1; keyStateAction1 = MEM_KeyState(MEM_GetKey("keyAction")); // A bit much, but needed below
    var int keyStateAction2; keyStateAction2 = MEM_KeyState(MEM_GetSecondaryKey("keyAction"));
    if (keyStateAction1 != KEY_PRESSED) && (keyStateAction1 != KEY_HOLD) // Only while pressing the action button
    && (keyStateAction2 != KEY_PRESSED) && (keyStateAction2 != KEY_HOLD) { return 0; };
    // Get onset for drawing the bow - right when pressing down the action key
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
        if (size < CROSSHAIR_MIN_SIZE) { size = CROSSHAIR_MIN_SIZE; }
        else if (size > CROSSHAIR_MAX_SIZE) { size = CROSSHAIR_MAX_SIZE; };
        if (!Hlp_IsValidHandle(crosshairHndl)) { // Create crosshair if it does not exist
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
            if (crsHr.psizex != size) { // Update its size
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
    if (!STR_ToInt(MEM_GetGothOpt("FREEAIM", "focusEnabled"))) { // No focus collection (performance) not recommended
        if (!MEM_GothOptExists("FREEAIM", "focusEnabled")) {
            MEM_SetGothOpt("FREEAIM", "focusEnabled", "1"); // Turn on by default
        } else { return 0; };
    };
    if (Npc_IsInFightMode(hero, FMODE_FAR)) { return 1; }; // Only while using bow/crossbow
    return 0;
};

/* Mouse handling for manually turning the player model */
func void manualRotation() {
    if (!isFreeAimActive()) { return; };
    var int deltaX; deltaX = mulf(mkf(MEM_ReadInt(mouseDeltaX)), MEM_ReadInt(mouseSensX)); // Get mouse change in x
    if (deltaX == FLOATNULL) { return; }; // Only rotate if there was movement along x position
    deltaX = mulf(deltaX, castToIntf(FREEAIM_ROTATION_SCALE)); // Turn rate
    var int hAniCtrl; hAniCtrl = MEM_ReadInt(_@(hero)+2432); // oCNpc.anictrl
    const int call = 0; var int null;
    if (CALL_Begin(call)) {
        CALL_IntParam(_@(null)); // 0 = disable turn animation (there is none while aiming anyways)
        CALL_FloatParam(_@(deltaX));
        CALL__thiscall(_@(hAniCtrl), oCAniCtrl_Human__Turn);
        call = CALL_End();
    };
};

/* Shoot aim-tailored trace ray. Do no use for other purposes. This function is customized for aiming. */
func int aimRay(var int distance, var int vobPtr, var int posPtr, var int distPtr, var int trueDistPtr) {
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
    var int potentialVob; potentialVob = MEM_ReadInt(herPtr+2476); // oCNpc.focus_vob // Focus vob by focus collection
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
    if (distPtr) { // Distance between intersection and player model
        distance = sqrtf(addf(addf(
            sqrf(subf(MEM_World.foundIntersection[0], traceRayVec[0])),
            sqrf(subf(MEM_World.foundIntersection[1], traceRayVec[1]))),
            sqrf(subf(MEM_World.foundIntersection[2], traceRayVec[2]))));
        MEM_WriteInt(distPtr, distance);
    };
    if (trueDistPtr) { // Distance between intersection and camera
        distance = sqrtf(addf(addf(
            sqrf(subf(MEM_World.foundIntersection[0], camPos.v0[3])),
            sqrf(subf(MEM_World.foundIntersection[1], camPos.v1[3]))),
            sqrf(subf(MEM_World.foundIntersection[2], camPos.v2[3]))));
        MEM_WriteInt(trueDistPtr, distance);
    };
    return found;
};

/* Set target position to update aim animation. Hook oCAniCtrl_Human::InterpolateCombineAni */
func void catchICAni() {
    if (!isFreeAimActive()) { return; };
    var int herPtr; herPtr = _@(hero);

/*    // Strafing
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
    };*/

    var int size; size = CROSSHAIR_MAX_SIZE; // Start out with the maximum size of crosshair (adjust below)
    if (getFreeAimFocus()) { // Set focus npc if there is a valid one under the crosshair
       var int distance; aimRay(FREEAIM_MAX_DIST, 0, 0, _@(distance), 0); // Shoot trace ray and retrieve aim distance
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
    var int pos[3]; // The position is calculated from the camera, not the player model
    pos[0] = addf(camPos.v0[3], mulf(camPos.v0[2], mkf(FREEAIM_MAX_DIST)));
    pos[1] = addf(camPos.v1[3], mulf(camPos.v1[2], mkf(FREEAIM_MAX_DIST)));
    pos[2] = addf(camPos.v2[3], mulf(camPos.v2[2], mkf(FREEAIM_MAX_DIST)));
    // Get aiming angles
    var int angleX; var int angXptr; angXptr = _@(angleX);
    var int angleY; var int angYptr; angYptr = _@(angleY);
    var int posPtr; posPtr = _@(pos); // So many pointers because it is a recyclable call
    const int call3 = 0;
    if (CALL_Begin(call3)) {
        CALL_PtrParam(_@(angYptr));
        CALL_PtrParam(_@(angXptr)); // X angle not needed so far (later for strafing)
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
    angleX = addf(mulf(angleX, 1001786197), FLOATHALF); // Scale X [-90° +90°] to [0 +1]
    angleY = negf(subf(mulf(angleY, 1001786197), FLOATHALF)); // Scale and flip Y [-90° +90°] to [+1 0]
    if (lef(angleX, FLOATNULL)) { angleX = FLOATNULL; } // Maximum turning
    else if (gef(angleX, 1065353216)) { angleX = 1065353216; };
    if (lef(angleY, FLOATNULL)) { angleY = FLOATNULL; } // Maximum aim height (straight up)
    else if (gef(angleY, 1065353216)) { angleY = 1065353216; }; // Minimum aim height (down)
    // New aiming coordinates. Overwrite the arguments passed to oCAniCtrl_Human::InterpolateCombineAni
    MEM_WriteInt(ESP+4, angleX); // Also overwrite x. Important for strafing
    MEM_WriteInt(ESP+8, angleY);
};

/* Set the projectile direction and trajectory. Hook oCAIArrow::SetupAIVob */
func void shootTarget() {
    var int projectile; projectile = MEM_ReadInt(ESP+4);  // First argument is the projectile
    var C_NPC shooter; shooter = _^(MEM_ReadInt(ESP+8)); // Second argument is shooter
    if (!Npc_IsPlayer(shooter)) || (!isFreeAimActive()) { return; }; // Only for the player
    var int distance; aimRay(FREEAIM_MAX_DIST, 0, 0, 0, _@(distance)); // Trace ray intersection
    var int vobPtr; vobPtr = MEM_SearchVobByName("AIMVOB"); // Arrow needs target vob
    if (!vobPtr) {
        vobPtr = MEM_Alloc(288); // sizeof_zCVob // Will never delete this vob (it will be re-used on the next shot)
        CALL__thiscall(vobPtr, zCVob__zCVob);
        MEM_WriteString(vobPtr+16, "AIMVOB"); // zCVob._zCObject_objectName
        CALL_PtrParam(_@(MEM_Vobtree));
        CALL_PtrParam(vobPtr);
        CALL__thiscall(_@(MEM_World), zCWorld__AddVobAsChild);
    };
    // Manipulate aiming position (scatter/accuracy): Rotate position around y and x axes (left/right, up/down)
    var int accuracy; accuracy = freeAimGetAccuracy(); // Change the accuracy calculation in that function, not here!
    if (accuracy > 100) { accuracy = 100; } else if (accuracy < 1) { accuracy = 1; }; // Prevent devision by zero
    var int angleMax; angleMax = roundf(mulf(mulf(fracf(1, accuracy), castToIntf(FREEAIM_SCATTER_DEG)), mkf(1000)));
    var int angleY; angleY = fracf(r_MinMax(-angleMax, angleMax), 1000); // Degrees around y-axis
    angleMax = roundf(sqrtf(subf(sqrf(mkf(angleMax)), sqrf(mulf(angleY, mkf(1000)))))); // sqrt(angleMax^2-angleY^2)
    var int angleX; angleX = fracf(r_MinMax(-angleMax, angleMax), 1000); // Degrees around x-axis (restrict to circle)
    var zMAT4 camPos; camPos = _^(MEM_ReadInt(MEM_ReadInt(MEMINT_oGame_Pointer_Address)+20)+60); //0=right, 2=out, 3=pos
    var int pos[3]; pos[0] = FLOATNULL; pos[1] = FLOATNULL; pos[2] = distance;
    SinCosApprox(Print_ToRadian(angleX)); // Rotate around x-axis (up-down scatter)
    pos[1] = mulf(negf(pos[2]), sinApprox); // y*cosθ − z*sinθ = y'
    pos[2] = mulf(pos[2], cosApprox);       // y*sinθ + z*cosθ = z'
    SinCosApprox(Print_ToRadian(angleY)); // Rotate around y-axis (left-right scatter)
    pos[0] = mulf(pos[2], sinApprox); //  x*cosθ + z*sinθ = x'
    pos[2] = mulf(pos[2], cosApprox); // −x*sinθ + z*cosθ = z'
    var int newPos[3]; // Rotation (translation into local coordinate system of camera)
    newPos[0] = addf(addf(mulf(camPos.v0[0], pos[0]), mulf(camPos.v0[1], pos[1])), mulf(camPos.v0[2], pos[2]));
    newPos[1] = addf(addf(mulf(camPos.v1[0], pos[0]), mulf(camPos.v1[1], pos[1])), mulf(camPos.v1[2], pos[2]));
    newPos[2] = addf(addf(mulf(camPos.v2[0], pos[0]), mulf(camPos.v2[1], pos[1])), mulf(camPos.v2[2], pos[2]));
    pos[0] = addf(camPos.v0[3], newPos[0]);
    pos[1] = addf(camPos.v1[3], newPos[1]);
    pos[2] = addf(camPos.v2[3], newPos[2]);
    // Set position to aim vob
    var int posPtr; posPtr = _@(pos);
    const int call = 0;
    if (CALL_Begin(call)) {
        CALL_PtrParam(_@(posPtr)); // Update aim vob position
        CALL__thiscall(_@(vobPtr), zCVob__SetPositionWorld);
        call = CALL_End();
    };
    // Set projectile drop-off (by draw force)
    const int call2 = 0;
    if (CALL_Begin(call2)) {
        CALL__thiscall(_@(projectile), zCVob__GetRigidBody); // Get ridigBody this way, it will be properly created
        call2 = CALL_End();
    };
    var int rBody; rBody = CALL_RetValAsInt(); // zCRigidBody*
    var int drawForce; drawForce = freeAimGetDrawForce(); // Modify the draw force in that function, not here!
    var int gravityMod; gravityMod = FLOATONE; // Gravity only modified on short draw time
    if (drawForce < 25) { gravityMod = mkf(3); }; // Very short draw time increases gravity
    drawForce = mulf(fracf(drawForce, 100), mkf(FREEAIM_TRAJECTORY_ARC_MAX));
    FF_ApplyOnceExtData(dropProjectile, roundf(drawForce), 1, rBody); // When to hit the projectile with gravity
    bowDrawOnset = MEM_Timer.totalTime; // Reset draw timer
    MEM_WriteInt(rBody+236, mulf(castToIntf(FREEAIM_PROJECTILE_GRAVITY), gravityMod)); // Set gravity (but not enabled)
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

/* This function is timed by draw force and is responsible for applying gravity to a projectile */
func void dropProjectile(var int rigidBody) {
    if (!rigidBody) || (!MEM_ReadInt(rigidBody)) { return; };
    if (MEM_ReadInt(rigidBody+188) == FLOATNULL) // zCRigidBody.velocity[3]
    && (MEM_ReadInt(rigidBody+192) == FLOATNULL)
    && (MEM_ReadInt(rigidBody+196) == FLOATNULL) { return; }; // Do not add gravity if projectile already stopped moving
    MEM_WriteByte(rigidBody+256, 1); // Turn on gravity (zCRigidBody.bitfield)
};

/* Arrow gets stuck in npc: put projectile instance into inventory and let ai die */
func void onArrowHitNpc() {
    var oCItem projectile; projectile = _^(MEM_ReadInt(ESI+88));
    var C_NPC victim; victim = _^(EDI);
    var int munitionInst; munitionInst = projectile.instanz; // May change munitionInst here, e.g. into "used arrow"
    CreateInvItems(victim, munitionInst, 1); // Put respective munition instance into the inventory
    if (FF_ActiveData(dropProjectile, _@(projectile._zCVob_rigidBody))) {
        FF_RemoveData(dropProjectile, _@(projectile._zCVob_rigidBody)); };
    MEM_WriteInt(ESI+56, -1073741824); // oCAIArrow.lifeTime (mark this AI for projectileCollectable)
};

/* Arrow gets stuck in static or dynamic world (non-npc): keep ai alive */
func void onArrowGetStuck() {
    var int projectilePtr; projectilePtr = MEM_ReadInt(ESI+88);
    var oCItem projectile; projectile = _^(projectilePtr);
    if (Hlp_StrCmp(projectile.effect, FREEAIM_TRAIL_FX)) { // Remove trail strip fx
        const int call = 0;
        if (CALL_Begin(call)) {
            CALL__thiscall(_@(projectilePtr), oCItem__RemoveEffect);
            call = CALL_End();
        };
    };
    projectile.flags = projectile.flags &~ ITEM_NFOCUS; // Focusable (collectable)
    projectile._zCVob_callback_ai = 0; // Release vob from AI
    if (FF_ActiveData(dropProjectile, _@(projectile._zCVob_rigidBody))) {
        FF_RemoveData(dropProjectile, _@(projectile._zCVob_rigidBody)); };
    // Have projectile not go to deep in. Might not make sense but trust me. (RightVec will be multiplied later)
    projectile._zCVob_trafoObjToWorld[0] = mulf(projectile._zCVob_trafoObjToWorld[0], -1096111445);
    projectile._zCVob_trafoObjToWorld[4] = mulf(projectile._zCVob_trafoObjToWorld[4], -1096111445);
    projectile._zCVob_trafoObjToWorld[8] = mulf(projectile._zCVob_trafoObjToWorld[8], -1096111445);
};

/* Once a projectile stopped moving keep it alive */
func void projectileCollectable() {
    var int arrowAI; arrowAI = ECX; // AI of the projectile
    var int projectilePtr; projectilePtr = MEM_ReadInt(ESP+4); // Projectile (item). Taken from arguments
    var int removePtr; removePtr = MEM_ReadInt(ESP+8); // Boolean pointer (call-by-reference argument)
    if (!projectilePtr) { return; }; // oCItem. In case it does not exist
    var oCItem projectile; projectile = _^(projectilePtr);
    if (!projectile._zCVob_rigidBody) { return; }; // zCRigidBody. Might not exist the first time
    // Reset projectile gravity (zCRigidBody.gravity) after collision (oCAIArrow.collision)
    if (MEM_ReadInt(arrowAI+52)) { MEM_WriteInt(projectile._zCVob_rigidBody+236, FLOATONE); }; // Set gravity to default
    if (!FREEAIM_PROJECTILE_COLLECTABLE) { return; }; // Normal projectile handling
    // If the projectile stopped moving (and did not hit npc), release its AI
    if (MEM_ReadInt(arrowAI+56) != -1073741824) && !(projectile._zCVob_bitfield[0] & zCVob_bitfield0_physicsEnabled) {
        if (FF_ActiveData(dropProjectile, _@(projectile._zCVob_rigidBody))) {
            FF_RemoveData(dropProjectile, _@(projectile._zCVob_rigidBody)); };
        if (Hlp_StrCmp(projectile.effect, FREEAIM_TRAIL_FX)) { // Remove trail strip fx
            const int call2 = 0;
            if (CALL_Begin(call2)) {
                CALL__thiscall(_@(projectilePtr), oCItem__RemoveEffect);
                call2 = CALL_End();
            };
        };
        projectile.flags = projectile.flags &~ ITEM_NFOCUS; // Focusable (collectable)
        projectile._zCVob_callback_ai = 0; // Release vob from AI
        MEM_WriteInt(arrowAI+56, FLOATONE); // oCAIArrow.lifeTime // Set high lifetime to ensure item visibility
        MEM_WriteInt(removePtr, 0); // Do not remove vob on AI destruction
        MEM_WriteInt(ESP+8, _@(ARROWAI_REDIRECT)); // Divert the actual "return" value
    } else if (MEM_ReadInt(arrowAI+56) == -1073741824) { // Marked as positive hit on npc: do not keep alive
        MEM_WriteInt(arrowAI+56, FLOATNULL); // oCAIArrow.lifeTime
    };
};

/* Detect headshot and increase initial damage. Modify the damage in freeAimGetHeadshotMultiplier() */
func void headshotDetection() {
    var int damagePtr; damagePtr = ESP+428-200; // esp+1ACh+C8h
    var int target; target = MEM_ReadInt(ESP+428-400); // esp+1ACh+190h
    var int projectile; projectile = MEM_ReadInt(EBP+88); // ebp+58h
    // Get model from target npc
    const int call = 0;
    if (CALL_Begin(call)) {
        CALL__thiscall(_@(target), oCNpc__GetModel);
        call = CALL_End();
    };
    var int model; model = CALL_RetValAsPtr();
    // Get head node from target model
    var int node; node = _@s("BIP01 HEAD");
    const int call2 = 0;
    if (CALL_Begin(call2)) {
        CALL_PtrParam(_@(node));
        CALL__thiscall(_@(model), zCModel__SearchNode);
        call2 = CALL_End();
    };
    var int head; head = CALL_RetValAsPtr();
    if (!head) { return; }; // I think some monsters don't have a head node!
    // Get the bbox of the head (although the zCModelNodeInst class has a zTBBox3D property, it is necessary this way)
    CALL_PtrParam(head);
    CALL_RetValIsStruct(24); // sizeof_zTBBox3D // No recyclable call possible
    CALL__thiscall(model, zCModel__GetBBox3DNodeWorld);
    var int headBBox; headBBox = CALL_RetValAsPtr();
    // Get the 3dsphere of the head (necessary, since the bbox of the head is too small, working with spheres is easier)
    CALL_RetValIsStruct(16); // sizeof_zTBSphere3D // No recyclable call possible
    CALL__thiscall(headBBox, zTBBox3D__GetSphere3D);
    var int headSphere; headSphere = CALL_RetValAsPtr();
    MEM_WriteInt(headSphere+12, mulf(MEM_ReadInt(headSphere+12), castToIntf(1.75))); // Scale it up
    //CALL_PtrParam(_@(zCOLOR_RED)); CALL__thiscall(headSphere, /*0x5441F0 zTBSphere3D__Draw*/5521904); // Visualization
    // Copy and enlarge the projectile bbox as well
    var int projectileBBox; projectileBBox = MEM_Alloc(24); // sizeof_zTBBox3D
    MEM_CopyWords(projectile+124, projectileBBox, 6);
    var int bboxScale; bboxScale = castToIntf(1.5); // The projectile bbox is only detected if it is also enlarged a bit
    const int call5 = 0;
    if (CALL_Begin(call5)) {
        CALL_FloatParam(_@(bboxScale));
        CALL__thiscall(_@(projectileBBox), zTBBox3D__Scale);
        call5 = CALL_End();
    };
    // Check intersection between projectile bbox and head 3dsphere (most reliable method)
    const int call4 = 0;
    if (CALL_Begin(call4)) {
        CALL_PtrParam(_@(headSphere));
        CALL__thiscall(_@(projectileBBox), zTBBox3D__IsIntersecting);
        call4 = CALL_End();
    };
    var int intersection; intersection = CALL_RetValAsInt();
    MEM_Free(projectileBBox); MEM_Free(headBBox); MEM_Free(headSphere); // Free the memory
    if (intersection) {
        freeAimHeadshotEvent(); // Use this function to add an event when getting a headshot, e.g. a print or a sound
        MEM_WriteInt(damagePtr, mulf(MEM_ReadInt(damagePtr), freeAimGetHeadshotMultiplier())); // BASE damage!
    };
};
