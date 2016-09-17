/*
 * Gothic 2 Free Aiming
 *
 * Written by mud-freak (2016)
 *
 * Forum thread:
 *  - Release thread:
 *  - Development thread:
 *
 * Github:
 *  -
 *
 * Requirements:
 *  - Ikarus >= 1.2 (with floats)
 *  - LeGo >= 2.3.2 (LeGo_FrameFunctions | LeGo_HookEngine)
 *
 * Customizability:
 *  - Collect and re-use shot projectiles (yes/no):   FREEAIM_REUSE_PROJECTILES
 *  - Draw force (drop-off) calculation:              freeAimGetDrawForce()
 *  - Accuracy calculation:                           freeAimGetAccuracy()
 *  - Reticle style and size:                         freeAimGetReticle(), FREEAIM_RETICLE_BOW, FREEAIM_RETICLE_CROSSBOW
 *  - Headshot damage calculation:                    freeAimGetHeadshotDamage(var int damage, var C_NPC target)
 *  - Headshot event (print, sound, xp, ...):         freeAimHeadshotEvent(var C_NPC target)
 *  - Head sizes for headshot detection on monsters:  freeAimGetHeadSize(var C_NPC monster)
 * Advanced (modification not recommended):
 *  - Scatter radius for accuracy:                    FREEAIM_SCATTER_DEG
 *  - Camera view (shoulder view):                    FREEAIM_CAMERA and FREEAIM_CAMERA_X_SHIFT
 *  - Max time before projectile drop-off:            FREEAIM_TRAJECTORY_ARC_MAX
 *
 * Usage:
 *  - Initialize after Ikarus and LeGo (LeGo_FrameFunctions | LeGo_HookEngine) in INIT_GLOBAL() with freeAim_Init();
 */

/* Free aim settings, only modify those listed above */
const int    FREEAIM_REUSE_PROJECTILES    = 1;               // Enable collection and re-using of shot projectiles
const int    FREEAIM_CAMERA_X_SHIFT       = 0;               // One, if camera is set to shoulderview (not recommended)
const int    FREEAIM_DRAWTIME_MIN         = 1110;            // Min draw time (ms): Do not change - tied to animation
const int    FREEAIM_DRAWTIME_MAX         = 2500;            // Max draw time (ms): When is bow/crossbow fully drawn
const int    FREEAIM_TRAJECTORY_ARC_MAX   = 400;             // Max time (ms) after which the trajectory drops off
const float  FREEAIM_ROTATION_SCALE       = 0.16;            // Turn rate. Non-weapon mode is 0.2 (zMouseRotationScale)
const float  FREEAIM_SCATTER_DEG          = 2.2;             // Maximum scatter radius in degrees
const int    FREEAIM_RETICLE_MIN_SIZE     = 16;              // Smallest reticle size in pixels (longest range)
const int    FREEAIM_RETICLE_MED_SIZE     = 20;              // Medium reticle size in pixels (for disabled focus)
const int    FREEAIM_RETICLE_MAX_SIZE     = 32;              // Biggest reticle size in pixels (closest range)
const int    FREEAIM_RETICLE_BOW          = POINTY_RETICLE;  // Reticle texture definitions are in Constants.d
const int    FREEAIM_RETICLE_CROSSBOW     = POINTY_RETICLE;  // Reticle texture definitions are in Constants.d
const string FREEAIM_CAMERA               = "CamModRngeFA";  // CCamSys_Def script instance for free aim
const string FREEAIM_TRAIL_FX             = "freeAim_TRAIL"; // Trailstrip FX. Should not be changed
const float  FREEAIM_PROJECTILE_GRAVITY   = 0.1;             // The gravity decides how fast the projectile drops
const int    FREEAIM_MAX_DIST             = 5000;            // 50m. Shooting/reticle adjustments. Do not change
const int    FREEAIM_ACTIVE_PREVFRAME     = 0;               // Internal. Do not change
const int    FREEAIM_ARROWAI_REDIRECT     = 0;               // Used to redirect call-by-reference argument
const int    FLOAT1K                      = 1148846080;      // 1000 as float
var   int    freeAimReticleHndl;                             // Holds the handle of the reticle
var   int    freeAimBowDrawOnset;                            // Time onset of drawing the bow

/* Modify this function to alter the draw force calculation. Scaled between 0 and 100 (percent) */
func int freeAimGetDrawForce() {
    var C_Item weapon; // The weapon can also be considered (e.g. weapon specific damage). Make use of 'weapon' for that
    if (Npc_IsInFightMode(hero, FMODE_FAR)) { weapon = Npc_GetReadiedWeapon(hero); }
    else if (Npc_HasEquippedRangedWeapon(hero)) { weapon = Npc_GetEquippedRangedWeapon(hero); }
    else { MEM_Error("freeAimGetDrawForce: No valid weapon equipped/readied!"); return -1; }; // Should never happen
    // Check for how long the bow was drawn
    var int drawForce; drawForce = MEM_Timer.totalTime - freeAimBowDrawOnset;
    // Set drawForce by draw time scaled between min and max times
    drawForce = (100 * (drawForce - FREEAIM_DRAWTIME_MIN))/(FREEAIM_DRAWTIME_MAX - FREEAIM_DRAWTIME_MIN);
    // Possibly incorporate more factors like e.g. a quick-draw talent, weapon-specific stats, ...
    if (drawForce > 100) { drawForce = 100; } else if (drawForce < 0) { drawForce = 0; }; // Must be in [0, 100]
    return drawForce;
};

/* Modify this function to alter accuracy calculation. Scaled between 0 and 100 (percent) */
func int freeAimGetAccuracy() {
    // Right now there is two factors running into accuracy: (1) character talent, (2) draw force
    // Factor 1: Talent (keep in mind that it might be greater than 100)
    var int talent; var C_Item weapon; // Retrieve the weapon first to distinguish between (cross-)bow talent
    if (Npc_IsInFightMode(hero, FMODE_FAR)) { weapon = Npc_GetReadiedWeapon(hero); }
    else if (Npc_HasEquippedRangedWeapon(hero)) { weapon = Npc_GetEquippedRangedWeapon(hero); }
    else { MEM_Error("freeAimGetAccuracy: No valid weapon equipped/readied!"); return -1; };
    if (weapon.flags & ITEM_BOW) { talent = hero.HitChance[NPC_TALENT_BOW]; } // Bow talent
    else if (weapon.flags & ITEM_CROSSBOW) { talent = hero.HitChance[NPC_TALENT_CROSSBOW]; } // Crossbow talent
    else { MEM_Error("freeAimGetAccuracy: No valid weapon equipped/readied!"); return -1; };
    // Factor 2: Draw force
    var int drawForce; drawForce = freeAimGetDrawForce(); // Already scaled between [0, 100], see freeAimGetDrawForce()
    // Factor X: Add any other factors here e.g. weapon-specific accuracy stats, weapon spread, accuracy talent, ...
    // Calculate overall accuracy: From all factors (modify the following lines to change the calculation)
    // Here the talent is scaled by draw force: draw force=100% => accuracy=talent; draw force=0% => accuracy=talent/2
    if (drawForce < talent) { drawForce = talent; }; // Decrease impact of draw force on talent
    var int accuracy; accuracy = (talent * drawForce)/100;
    // Final accuracy needs to be in [0, 100]
    if (accuracy > 100) { accuracy = 100; } else if (accuracy < 0) { accuracy = 0; };
    return accuracy;
};

/* Modify this function to alter the reticle style and size. By draw force, weapon-specific stats, talent, ... */
func int freeAimGetReticle(var int sizePtr) {
    var int reticleStyle; var int reticleSize; reticleSize = MEM_ReadInt(sizePtr);
    if (Npc_IsInFightMode(hero, FMODE_FAR)) {
        var C_Item weapon; weapon = Npc_GetReadiedWeapon(hero); // Get readied ranged weapon
        // Modify these lines to include special cases for certain weapons
        if (weapon.flags & ITEM_BOW) { reticleStyle = FREEAIM_RETICLE_BOW; } // Bow readied
        else if (weapon.flags & ITEM_CROSSBOW) { reticleStyle = FREEAIM_RETICLE_CROSSBOW; } // Crossbow readied
        else { MEM_Error("freeAimGetReticle: No valid weapon readied!"); return -1; };
    } else { MEM_Error("freeAimGetReticle: No valid weapon readied!"); return -1; };
    // The reticle size comes precalculated by aiming distance. It can be changed by overwriting it
    // var int scale; scale = -freeAimGetDrawForce()+100; // E.g. scale with draw force instead
    // var int scale; scale = -freeAimGetAccuracy()+100; // or scale with accuracy
    // reticleSize = (((FREEAIM_RETICLE_MAX_SIZE-FREEAIM_RETICLE_MIN_SIZE)*(scale))/100)+FREEAIM_RETICLE_MIN_SIZE;
    // The size should not exceed the ranges
    if (reticleSize < FREEAIM_RETICLE_MIN_SIZE) { reticleSize = FREEAIM_RETICLE_MIN_SIZE; }
    else if (reticleSize > FREEAIM_RETICLE_MAX_SIZE) { reticleSize = FREEAIM_RETICLE_MAX_SIZE; };
    MEM_WriteInt(sizePtr, reticleSize); // Overwrite reticle size
    return reticleStyle;
};

/* Modify this function to set the headshot damage. Caution: damage is a float and should be returned as such */
func int freeAimGetHeadshotDamage(var int damage, var C_NPC target) {
    // Possibly incorporate weapon-specific stats, headshot talent, dependecy on target, ...
    // The damage may depent on the target npc (e.g. different damage for monsters). Make use of 'target' argument
    // if (target.guild < GIL_SEPERATOR_HUM) { }; // E.g. special case for humans
    var C_Item weapon; // The weapon can also be considered (e.g. weapon specific damage). Make use of 'weapon' for that
    if (Npc_IsInFightMode(hero, FMODE_FAR)) { weapon = Npc_GetReadiedWeapon(hero); }
    else if (Npc_HasEquippedRangedWeapon(hero)) { weapon = Npc_GetEquippedRangedWeapon(hero); };
    // Caution: Weapon may have been unequipped already at this time!
    // if (Hlp_IsValidItem(weapon)) && (weapon.certainProperty > 10) { }; // E.g. special case for weapon property
    damage = mulf(damage, castToIntf(2.0)); // For now, just double the base damage
    return damage; // This sets a new base damage (damage of weapon), not the final damage!
};

/* Use this function to create an event when getting a headshot, e.g. a print or a sound jingle, leave blank for none */
func void freeAimHeadshotEvent(var C_NPC target) {
    // The event may depent on the target npc (e.g. different sound for monsters). Make use of 'target' argument
    // if (target.guild < GIL_SEPERATOR_HUM) { }; // E.g. special case for humans
    var C_Item weapon; // The weapon can also be considered (e.g. weapon specific print). Make use of 'weapon' for that
    if (Npc_IsInFightMode(hero, FMODE_FAR)) { weapon = Npc_GetReadiedWeapon(hero); }
    else if (Npc_HasEquippedRangedWeapon(hero)) { weapon = Npc_GetEquippedRangedWeapon(hero); };
    // Caution: Weapon may have been unequipped already at this time!
    // if (Hlp_IsValidItem(weapon)) && (weapon.certainProperty > 10) { }; // E.g. special case for weapon property
    Snd_Play("FORGE_ANVIL_A1");
    PrintS("Kritischer Treffer"); // "Critical hit"
};

/* Modify this function to assign more appropriate head sizes for headshot detection: Only called for non-human npcs */
func int freeAimGetHeadSize(var C_NPC monster) {
    // if (monster.aivar[AIV_MM_REAL_ID] == ID_TROLL) { // Head size for trolls
    //    return 120; // 120x120cm
    // } else if (monster.aivar[AIV_MM_REAL_ID] == ...
    //     ...
    // } else {
    //     return 60; // Default head size is 60x60cm
    // };
    return 60; // Default is 60x60cm
};

/********************************************** DO NO CROSS THIS LINE **************************************************

  WARNING: All necessary adjustments can be performed above. You should not need to edited anything below.
  Proceed at your own risk: On modifying the functions below free aiming will most certainly become unstable.

*********************************************** DO NO CROSS THIS LINE *************************************************/

/* All addresses used (gothic2). In case of a gothic1 port: There are a lot of hardcoded address offsets in the code! */
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
const int alternativeHitchanceAddr                = 6953494; //0x6A1A10
const int oCNpc__GetModel                         = 7571232; //0x738720
const int zCModel__SearchNode                     = 5758960; //0x57DFF0
const int zCModel__GetBBox3DNodeWorld             = 5738736; //0x5790F0
const int zCModel__GetNodePositionWorld           = 5738816; //0x579140
const int mouseEnabled                            = 9248108; //0x8D1D6C
const int mouseSensX                              = 9019720; //0x89A148
const int mouseDeltaX                             = 9246300; //0x8D165C
const int oCAniCtrl_Human__InterpolateCombineAni  = 7037296; //0x6B6170 // Hook length 5
const int oCAIArrow__SetupAIVob                   = 6951136; //0x6A10E0 // Hook length 6
const int oCAIHuman__BowMode                      = 6905600; //0x695F00 // Hook length 6
const int oCAIArrowBase__DoAI                     = 6948416; //0x6A0640 // Hook length 7
const int onArrowHitNpcAddr                       = 6949832; //0x6A0BC8 // Hook length 5
const int onArrowHitVobAddr                       = 6949929; //0x6A0C29 // Hook length 5
const int onArrowHitStatAddr                      = 6949460; //0x6A0A54 // Hook length 5
const int onArrowDamageAddr                       = 6953621; //0x6A1A95 // Hook length 7
const int oCNpcFocus__SetFocusMode                = 7072800; //0x6BEC20 // Hook length 7
const int oCAIHuman__MagicMode                    = 4665296; //0x472FD0 // Hook length 7
const int mouseUpdate                             = 5062907; //0x4D40FB // Hook length 5

/* Initialize free aim framework */
func void freeAim_Init() {
    const int hookFreeAim = 0;
    if (!hookFreeAim) {
        HookEngineF(oCAniCtrl_Human__InterpolateCombineAni, 5, freeAimAnimation); // Update aiming animation
        HookEngineF(oCAIArrow__SetupAIVob, 6, freeAimSetupProjectile); // Set projectile direction and trajectory
        HookEngineF(oCAIHuman__BowMode, 6, freeAimManageReticle); // Manage the reticle (style, on/off)
        HookEngineF(oCNpcFocus__SetFocusMode, 7, freeAimManageReticle); // Manage the reticle (style, on/off)
        HookEngineF(oCAIHuman__MagicMode, 7, freeAimManageReticle); // Manage the reticle (style, on/off)
        HookEngineF(mouseUpdate, 5, freeAimManualRotation); // Update the player model rotation by mouse input
        HookEngineF(oCAIArrowBase__DoAI, 7, freeAimWatchProjectile); // AI loop for each projectile
        HookEngineF(onArrowDamageAddr, 7, freeAimDetectHeadshot); // Headshot detection
        if (FREEAIM_REUSE_PROJECTILES) { // Because of balancing issues, this is a constant and not a variable
            HookEngineF(onArrowHitNpcAddr, 5, freeAimOnArrowHitNpc); // Put projectile into inventory
            HookEngineF(onArrowHitVobAddr, 5, freeAimOnArrowGetStuck); // Keep projectile alive when stuck in vob
            HookEngineF(onArrowHitStatAddr, 5, freeAimOnArrowGetStuck); // Keep projectile alive when stuck in world
        };
        MemoryProtectionOverride(alternativeHitchanceAddr, 10); // Enable overwriting hit chance
        r_DefaultInit(); // Start rng for aiming accuracy
        hookFreeAim = 1;
    };
    MEM_Info("Free aim initialized.");
};

/* Hit chance of 100%. Taken from http://forum.worldofplayers.de/forum/threads/1475456?p=25080651#post25080651 */
func void freeAimAltHitchance() {
    MEM_WriteByte(alternativeHitchanceAddr, ASMINT_OP_nop);
    MEM_WriteByte(alternativeHitchanceAddr+1, ASMINT_OP_nop);
    MEM_WriteByte(alternativeHitchanceAddr+2, ASMINT_OP_nop);
    MEM_WriteByte(alternativeHitchanceAddr+3, ASMINT_OP_nop);
    MEM_WriteByte(alternativeHitchanceAddr+4, ASMINT_OP_nop);
    MEM_WriteByte(alternativeHitchanceAddr+5, ASMINT_OP_nop);
};

/* Restore default hit chance calculation (by talent) */
func void freeAimResetHitchance() {
    MEM_WriteByte(alternativeHitchanceAddr, 15);
    MEM_WriteByte(alternativeHitchanceAddr+1, 141);
    MEM_WriteByte(alternativeHitchanceAddr+2, 157);
    MEM_WriteByte(alternativeHitchanceAddr+3, 1);
    MEM_WriteByte(alternativeHitchanceAddr+4, 0);
    MEM_WriteByte(alternativeHitchanceAddr+5, 0);
};

/* Update internal settings when turning free aim on/off in the options */
func void freeAimUpdateSettings(var int on) {
    MEM_Info("Updating internal free aiming settings");
    if (on) {
        Focus_Ranged.npc_azi = 15.0; // Set stricter focus collection
        Focus_Ranged.npc_elevup = 15.0;
        Focus_Ranged.npc_elevdo = -10.0;
        MEM_WriteString(zString_CamModRanged, STR_Upper(FREEAIM_CAMERA)); // New camera mode, upper case is important
        freeAimAltHitchance(); // Always hit; Hit-chance/accuracy will be calculated in freeAimGetAccuracy()
        FREEAIM_ACTIVE_PREVFRAME = 1;
    } else {
        Focus_Ranged.npc_azi =  45.0; // Reset ranged focus collection to standard
        Focus_Ranged.npc_elevup =  90.0;
        Focus_Ranged.npc_elevdo =  -85.0;
        MEM_WriteString(zString_CamModRanged, "CAMMODRANGED"); // Restore camera mode, upper case is important
        freeAimResetHitchance(); // Restore default hit chance
        FREEAIM_ACTIVE_PREVFRAME = -1;
    };
};

/* Check whether free aiming should be activated */
func int freeAimIsActive() {
    if (!STR_ToInt(MEM_GetGothOpt("FREEAIM", "enabled"))) // Free aiming is disabled in the menu
    || (!MEM_ReadInt(mouseEnabled)) // Mouse controls are disabled
    || (!MEM_ReadInt(oCGame__s_bUseOldControls)) { // Classic gothic 1 controls are disabled
        if (FREEAIM_ACTIVE_PREVFRAME != -1) { freeAimUpdateSettings(0); }; // Update internal settings (turn off)
        return 0;
    };
    if (FREEAIM_ACTIVE_PREVFRAME != 1) { freeAimUpdateSettings(1); }; // Update internal settings (turn on)
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
    if (keyStateAction1 == KEY_PRESSED) || (keyStateAction2 == KEY_PRESSED) {
        freeAimBowDrawOnset = MEM_Timer.totalTime; };
    return 1;
};

/* Hide reticle */
func void freeAimRemoveReticle() {
    if (Hlp_IsValidHandle(freeAimReticleHndl)) { View_Close(freeAimReticleHndl); };
};

/* Draw reticle */
func void freeAimInsertReticle(var int reticleStyle, var int size) {
    if (reticleStyle > 1) {
        var string reticleTex;
        if (size < FREEAIM_RETICLE_MIN_SIZE) { size = FREEAIM_RETICLE_MIN_SIZE; }
        else if (size > FREEAIM_RETICLE_MAX_SIZE) { size = FREEAIM_RETICLE_MAX_SIZE; };
        if (!Hlp_IsValidHandle(freeAimReticleHndl)) { // Create reticle if it does not exist
            Print_GetScreenSize();
            freeAimReticleHndl = View_CreateCenterPxl(Print_Screen[PS_X]/2, Print_Screen[PS_Y]/2, size, size);
            reticleTex = MEM_ReadStatStringArr(reticle, reticleStyle);
            View_SetTexture(freeAimReticleHndl, reticleTex);
            View_Open(freeAimReticleHndl);
        } else {
            var zCView crsHr; crsHr = _^(getPtr(freeAimReticleHndl));
            if (!crsHr.isOpen) { View_Open(freeAimReticleHndl); };
            reticleTex = MEM_ReadStatStringArr(reticle, reticleStyle);
            if (!Hlp_StrCmp(View_GetTexture(freeAimReticleHndl), reticleTex)) {
                View_SetTexture(freeAimReticleHndl, reticleTex);
            };
            if (crsHr.psizex != size) { // Update its size
                View_ResizePxl(freeAimReticleHndl, size, size);
                View_MoveToPxl(freeAimReticleHndl, Print_Screen[PS_X]/2-(size/2), Print_Screen[PS_Y]/2-(size/2));
            };
        };
    } else { freeAimRemoveReticle(); };
};

/* Decide when to draw reticle or when to hide it */
func void freeAimManageReticle() {
    if (!freeAimIsActive()) { freeAimRemoveReticle(); };
};

/* Check whether free aiming should collect focus */
func int freeAimGetCollectFocus() {
    if (!STR_ToInt(MEM_GetGothOpt("FREEAIM", "focusEnabled"))) { // No focus collection (performance) not recommended
        if (!MEM_GothOptExists("FREEAIM", "focusEnabled")) {
            MEM_SetGothOpt("FREEAIM", "focusEnabled", "1"); // Turn on by default
        } else { return 0; };
    };
    if (Npc_IsInFightMode(hero, FMODE_FAR)) { return 1; }; // Only while using bow/crossbow
    return 0;
};

/* Mouse handling for manually turning the player model by mouse input */
func void freeAimManualRotation() {
    if (!freeAimIsActive()) { return; };
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
func int freeAimRay(var int distance, var int vobPtr, var int posPtr, var int distPtr, var int trueDistPtr) {
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
        line[0] = subf(MEM_ReadInt(herPtr+72),  mulf(camPos.v0[0], FLOAT1K)); // Left of player model
        line[1] = subf(MEM_ReadInt(herPtr+88),  mulf(camPos.v1[0], FLOAT1K));
        line[2] = subf(MEM_ReadInt(herPtr+104), mulf(camPos.v2[0], FLOAT1K));
        line[3] = addf(MEM_ReadInt(herPtr+72),  mulf(camPos.v0[0], FLOAT1K)); // Right of player model
        line[4] = addf(MEM_ReadInt(herPtr+88),  mulf(camPos.v1[0], FLOAT1K));
        line[5] = addf(MEM_ReadInt(herPtr+104), mulf(camPos.v2[0], FLOAT1K));
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

/* Update aiming animation. Hook oCAniCtrl_Human::InterpolateCombineAni */
func void freeAimAnimation() {
    if (!freeAimIsActive()) { return; };
    var int herPtr; herPtr = _@(hero);
    var int size; size = FREEAIM_RETICLE_MAX_SIZE; // Start out with the maximum size of reticle (adjust below)
    if (freeAimGetCollectFocus()) { // Set focus npc if there is a valid one under the reticle
       var int distance; freeAimRay(FREEAIM_MAX_DIST, 0, 0, _@(distance), 0); // Shoot ray and retrieve aim distance
       size -= roundf(mulf(divf(distance, mkf(FREEAIM_MAX_DIST)), mkf(size))); // Adjust reticle size
    } else { // More performance friendly. Here, there will be NO focus, otherwise it gets stuck on npcs.
        size = FREEAIM_RETICLE_MED_SIZE; // Set default reticle size. Here, it is not dynamic
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
    freeAimInsertReticle(freeAimGetReticle(_@(size)), size); // Draw/update reticle
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
        CALL_PtrParam(_@(angXptr)); // X angle not needed
        CALL_PtrParam(_@(posPtr));
        CALL__thiscall(_@(herPtr), oCNpc__GetAngles);
        call3 = CALL_End();
    };
    if (lf(absf(angleY), 1048576000)) { // Prevent multiplication with too small numbers. Would result in aim twitching
        if (lf(angleY, FLOATNULL)) { angleY =  -1098907648; } // -0.25
        else { angleY = 1048576000; }; // 0.25
    };
    // This following paragraph is essentially "copied" from oCAIHuman::BowMode (0x695F00 in g2)
    angleY = negf(subf(mulf(angleY, 1001786197), FLOATHALF)); // Scale and flip Y [-90° +90°] to [+1 0]
    if (lef(angleY, FLOATNULL)) { angleY = FLOATNULL; } // Maximum aim height (straight up)
    else if (gef(angleY, 1065353216)) { angleY = 1065353216; }; // Minimum aim height (down)
    // New aiming coordinates. Overwrite the arguments passed to oCAniCtrl_Human::InterpolateCombineAni
    MEM_WriteInt(ESP+4, FLOATHALF); // Always aim at center (x angle)
    MEM_WriteInt(ESP+8, angleY);
};

/* Set the projectile direction and trajectory. Hook oCAIArrow::SetupAIVob */
func void freeAimSetupProjectile() {
    var int projectile; projectile = MEM_ReadInt(ESP+4);  // First argument is the projectile
    var C_NPC shooter; shooter = _^(MEM_ReadInt(ESP+8)); // Second argument is shooter
    if (!Npc_IsPlayer(shooter)) || (!freeAimIsActive()) { return; }; // Only for the player
    var int distance; freeAimRay(FREEAIM_MAX_DIST, 0, 0, 0, _@(distance)); // Trace ray intersection
    var int vobPtr; vobPtr = MEM_SearchVobByName("AIMVOB"); // Arrow needs target vob
    if (!vobPtr) {
        vobPtr = MEM_Alloc(288); // sizeof_zCVob // Will never delete this vob (it will be re-used on the next shot)
        CALL__thiscall(vobPtr, zCVob__zCVob);
        MEM_WriteString(vobPtr+16, "AIMVOB"); // zCVob._zCObject_objectName
        CALL_PtrParam(_@(MEM_Vobtree));
        CALL_PtrParam(vobPtr);
        CALL__thiscall(_@(MEM_World), zCWorld__AddVobAsChild);
    };
    // Manipulate aiming position (scatter/accuracy): Rotate target position around y and x axes (left/right, up/down)
    var int accuracy; accuracy = freeAimGetAccuracy(); // Change the accuracy calculation in that function, not here!
    if (accuracy > 100) { accuracy = 100; } else if (accuracy < 1) { accuracy = 1; }; // Prevent devision by zero
    var int angleMax; angleMax = roundf(mulf(mulf(fracf(1, accuracy), castToIntf(FREEAIM_SCATTER_DEG)), FLOAT1K));
    var int angleY; angleY = fracf(r_MinMax(-angleMax, angleMax), 1000); // Degrees around y-axis
    angleMax = roundf(sqrtf(subf(sqrf(mkf(angleMax)), sqrf(mulf(angleY, FLOAT1K))))); // sqrt(angleMax^2-angleY^2)
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
    FF_ApplyOnceExtData(freeAimDropProjectile, roundf(drawForce), 1, rBody); // When to hit the projectile with gravity
    freeAimBowDrawOnset = MEM_Timer.totalTime; // Reset draw timer
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
func void freeAimDropProjectile(var int rigidBody) {
    if (!rigidBody) || (!MEM_ReadInt(rigidBody)) { return; };
    if (MEM_ReadInt(rigidBody+188) == FLOATNULL) // zCRigidBody.velocity[3]
    && (MEM_ReadInt(rigidBody+192) == FLOATNULL)
    && (MEM_ReadInt(rigidBody+196) == FLOATNULL) { return; }; // Do not add gravity if projectile already stopped moving
    MEM_WriteByte(rigidBody+256, 1); // Turn on gravity (zCRigidBody.bitfield)
};

/* Arrow gets stuck in npc: put projectile instance into inventory and let ai die */
func void freeAimOnArrowHitNpc() {
    var oCItem projectile; projectile = _^(MEM_ReadInt(ESI+88));
    var C_NPC victim; victim = _^(EDI);
    CreateInvItems(victim, projectile.instanz, 1); // Put respective munition instance into the inventory
    if (FF_ActiveData(freeAimDropProjectile, _@(projectile._zCVob_rigidBody))) {
        FF_RemoveData(freeAimDropProjectile, _@(projectile._zCVob_rigidBody)); };
    MEM_WriteInt(ESI+56, -1073741824); // oCAIArrow.lifeTime // Mark this AI for freeAimWatchProjectile()
};

/* Arrow gets stuck in static or dynamic world (non-npc): keep ai alive */
func void freeAimOnArrowGetStuck() {
    var int projectilePtr; projectilePtr = MEM_ReadInt(ESI+88);
    var oCItem projectile; projectile = _^(projectilePtr);
    if (Hlp_StrCmp(projectile.effect, FREEAIM_TRAIL_FX)) { // Remove trail strip fx
        const int call = 0;
        if (CALL_Begin(call)) {
            CALL__thiscall(_@(projectilePtr), oCItem__RemoveEffect);
            call = CALL_End();
        };
    };
    projectile.flags = projectile.flags &~ ITEM_NFOCUS; // Focusable
    projectile._zCVob_callback_ai = 0; // Release vob from AI
    if (FF_ActiveData(freeAimDropProjectile, _@(projectile._zCVob_rigidBody))) {
        FF_RemoveData(freeAimDropProjectile, _@(projectile._zCVob_rigidBody)); };
    // Have projectile not go to deep in. Might not make sense but trust me. (RightVec will be multiplied later)
    projectile._zCVob_trafoObjToWorld[0] = mulf(projectile._zCVob_trafoObjToWorld[0], -1096111445);
    projectile._zCVob_trafoObjToWorld[4] = mulf(projectile._zCVob_trafoObjToWorld[4], -1096111445);
    projectile._zCVob_trafoObjToWorld[8] = mulf(projectile._zCVob_trafoObjToWorld[8], -1096111445);
};

/* Once a projectile stopped moving keep it alive */
func void freeAimWatchProjectile() {
    var int arrowAI; arrowAI = ECX; // oCAIArrow*
    var int projectilePtr; projectilePtr = MEM_ReadInt(ESP+4); // oCItem*
    var int removePtr; removePtr = MEM_ReadInt(ESP+8); // int* (call-by-reference argument)
    if (!projectilePtr) { return; }; // oCItem* might not exist
    var oCItem projectile; projectile = _^(projectilePtr);
    if (!projectile._zCVob_rigidBody) { return; }; // zCRigidBody* might not exist the first time
    // Reset projectile gravity (zCRigidBody.gravity) after collision (oCAIArrow.collision)
    if (MEM_ReadInt(arrowAI+52)) { MEM_WriteInt(projectile._zCVob_rigidBody+236, FLOATONE); }; // Set gravity to default
    if (!FREEAIM_REUSE_PROJECTILES) { return; }; // Normal projectile handling
    // If the projectile stopped moving (and did not hit npc), release its AI
    if (MEM_ReadInt(arrowAI+56) != -1073741824) && !(projectile._zCVob_bitfield[0] & zCVob_bitfield0_physicsEnabled) {
        if (FF_ActiveData(freeAimDropProjectile, _@(projectile._zCVob_rigidBody))) {
            FF_RemoveData(freeAimDropProjectile, _@(projectile._zCVob_rigidBody)); };
        if (Hlp_StrCmp(projectile.effect, FREEAIM_TRAIL_FX)) { // Remove trail strip fx
            const int call2 = 0;
            if (CALL_Begin(call2)) {
                CALL__thiscall(_@(projectilePtr), oCItem__RemoveEffect);
                call2 = CALL_End();
            };
        };
        projectile.flags = projectile.flags &~ ITEM_NFOCUS; // Focusable
        projectile._zCVob_callback_ai = 0; // Release vob from AI
        MEM_WriteInt(arrowAI+56, FLOATONE); // oCAIArrow.lifeTime // Set high lifetime to ensure item visibility
        MEM_WriteInt(removePtr, 0); // Do not remove vob on AI destruction
        MEM_WriteInt(ESP+8, _@(FREEAIM_ARROWAI_REDIRECT)); // Divert the actual "return" value
    } else if (MEM_ReadInt(arrowAI+56) == -1073741824) { // Marked as positive hit on npc: do not keep alive
        MEM_WriteInt(arrowAI+56, FLOATNULL); // oCAIArrow.lifeTime
    };
};

/* Detect headshot and increase initial damage. Modify the damage in freeAimGetHeadshotDamage() */
func void freeAimDetectHeadshot() {
    var int damagePtr; damagePtr = ESP+228; // esp+1ACh+C8h // int*
    var int target; target = MEM_ReadInt(ESP+28); // esp+1ACh+190h // oCNpc*
    var int projectile; projectile = MEM_ReadInt(EBP+88); // ebp+58h // oCItem*
    var C_NPC targetNpc; targetNpc = _^(target);
    // Get model from target npc
    const int call = 0;
    if (CALL_Begin(call)) {
        CALL__thiscall(_@(target), oCNpc__GetModel);
        call = CALL_End();
    };
    var int model; model = CALL_RetValAsPtr();
    // Get head node from target model
    var int node; node = _@s("BIP01 HEAD"); // Needs to be upper case
    const int call2 = 0;
    if (CALL_Begin(call2)) {
        CALL_PtrParam(_@(node));
        CALL__thiscall(_@(model), zCModel__SearchNode);
        call2 = CALL_End();
    };
    var int head; head = CALL_RetValAsPtr();
    if (!head) { return; }; // There should be no npc without head node. But just in case
    var int headBBox[6]; // zTBBox3D
    if (MEM_ReadInt(head+8)) { // head->nodeVisual // If the head has a dedicated visual (humans only), retrieve bbox
        // Get the bbox of the head (although zCModelNodeInst has a zTBBox3D property, it is empty the first time)
        CALL_PtrParam(head); CALL_RetValIsStruct(24); // sizeof_zTBBox3D // No recyclable call possible bc of structure
        CALL__thiscall(model, zCModel__GetBBox3DNodeWorld);
        var int headBBoxPtr; headBBoxPtr = CALL_RetValAsPtr();
        MEM_CopyWords(headBBoxPtr, _@(headBBox), 6);
        MEM_Free(headBBoxPtr); // Free memory
    } else { // Monsters don't have a dedicated head visual: Headshot detection less accurate
        var int headSize; headSize = mkf(freeAimGetHeadSize(targetNpc)/2); // Need to guess the head size
        MEM_Info(ConcatStrings("freeAimDetectHeadshot: No head visual. Set head size to 2*", toStringf(headSize)));
        // Get the position of the head (although zCModelNodeInst has a position property, it is empty the first time)
        CALL_PtrParam(head); CALL_RetValIsStruct(12); // sizeof_zVEC3 // No recyclable call possible bc of structure
        CALL__thiscall(model, zCModel__GetNodePositionWorld);
        var int headPosPtr; headPosPtr = CALL_RetValAsInt();
        var int headPos[3]; MEM_CopyWords(headPosPtr, _@(headPos), 3);
        MEM_Free(headPosPtr); // Free memory
        headBBox[0] = subf(headPos[0], headSize); // Build an own bbox by the guessed head size
        headBBox[1] = subf(headPos[1], headSize);
        headBBox[2] = subf(headPos[2], headSize);
        headBBox[3] = addf(headPos[0], headSize);
        headBBox[4] = addf(headPos[1], headSize);
        headBBox[5] = addf(headPos[2], headSize);
    };
    // The internal engine functions are not accurate enough for detecting a headshot
    // Instead check here if "any" point along the line of projectile direction lies inside the bbox of the head.
    var int pos[3]; var int dir[3]; // Startposition and direction of collision line
    dir[0] = MEM_ReadInt(projectile+60); // This is the right-vector of the projectile (projectile flies sideways)
    dir[1] = MEM_ReadInt(projectile+76);
    dir[2] = MEM_ReadInt(projectile+92);
    pos[0] = addf(MEM_ReadInt(projectile+ 72), mulf(dir[0], mkf(100))); // Start the line 1meter behind the projectile
    pos[1] = addf(MEM_ReadInt(projectile+ 88), mulf(dir[1], mkf(100)));
    pos[2] = addf(MEM_ReadInt(projectile+104), mulf(dir[2], mkf(100)));
    var int intersection; intersection = 0; // Head shot detected
    var int i; i=0; var int iter; iter = 700/5; // 7meters: Max distance from model bbox edge to head bbox (e.g. troll)
    while(i <= iter); // Walk along the line in steps of 5cm
        var int line[3]; i += 1;
        line[0] = subf(pos[0], mulf(dir[0], mkf(i*5))); // Next point a long the collision line
        line[1] = subf(pos[1], mulf(dir[1], mkf(i*5)));
        line[2] = subf(pos[2], mulf(dir[2], mkf(i*5)));
        if (lef(headBBox[0], line[0])) // Is the current point along the collision line inside the head bbox
        && (lef(headBBox[1], line[1]))
        && (lef(headBBox[2], line[2]))
        && (gef(headBBox[3], line[0]))
        && (gef(headBBox[4], line[1]))
        && (gef(headBBox[5], line[2])) {
            intersection = 1;
            break;
        };
    end;
    if (intersection) { // Headshot detected
        freeAimHeadshotEvent(targetNpc); // Use this function to add an event on headshot, e.g. a print or a sound
        MEM_WriteInt(damagePtr, freeAimGetHeadshotDamage(MEM_ReadInt(damagePtr), targetNpc)); // Base damage not final
    };
};
