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
 *  - Projectile instance for re-using                freeAimGetUsedProjectileInstance(instance, targetNpc)
 *  - Draw force (gravity/drop-off) calculation:      freeAimGetDrawForce(weapon, talent)
 *  - Accuracy calculation:                           freeAimGetAccuracy(weapon, talent)
 *  - Reticle style:                                  freeAimGetReticleStyle(weapon, talent)
 *  - Reticle size:                                   freeAimGetReticleSize(size, weapon, talent)
 *  - Critical hit calculation (position, damage):    freeAimCriticalHitDef(target, weapon, damage)
 *  - Critical hit event (print, sound, xp, ...):     freeAimCriticalHitEvent(target, weapon)
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
const string FREEAIM_CAMERA               = "CamModRngeFA";  // CCamSys_Def script instance for free aim
const string FREEAIM_TRAIL_FX             = "freeAim_TRAIL"; // Trailstrip FX. Should not be changed
const int    FREEAIM_DEBUG_WEAKSPOT       = 0;               // Visualize weakspot bbox and trajectory
const int    FREEAIM_DEBUG_CONSOLE        = 1;               // Console command for debugging. Turn off in final mod
const float  FREEAIM_PROJECTILE_GRAVITY   = 0.1;             // The gravity decides how fast the projectile drops
const int    FREEAIM_MAX_DIST             = 5000;            // 50m. Shooting/reticle adjustments. Do not change
const int    FREEAIM_ACTIVE_PREVFRAME     = 0;               // Internal. Do not change
const int    FREEAIM_ARROWAI_REDIRECT     = 0;               // Used to redirect call-by-reference argument
const int    FLOAT1K                      = 1148846080;      // 1000 as float
var   int    freeAimDebugBBox[6];                            // Boundingbox for debug visualization
var   int    freeAimDebugTrj[6];                             // Projectile trajectory for debug visualization
var   int    freeAimReticleHndl;                             // Holds the handle of the reticle
var   int    freeAimBowDrawOnset;                            // Time onset of drawing the bow
class Weakspot { var string node; var int dimX; var int dimY; var int bDmg; }; // For readability

/* Enter onset/offset frame numbers of drawing animations of weapons here (start and end of pulling the string) */
func int freeAimGetAniDrawFrame(var string aniName, var int onset) { // Onset: onset = 1, offset: onset = 0
    // These numbers need to be present for every animation that is used. The standard animations are already added
    // When adding a new animation, keep in mind that the frame numbers must be greater than or equal to one
    if (Hlp_StrCmp(aniName, "S_BOWAIM")) { if (onset) { return 1; }; return 2; }; // All frames
    if (Hlp_StrCmp(aniName, "T_BOWRUN_2_BOWAIM")) { if (onset) { return 1; }; return 9; }; // Frames 1 to 9
    if (Hlp_StrCmp(aniName, "T_BOWWALK_2_BOWAIM")) { if (onset) { return 1; }; return 9; }; // Frames 1 to 9
    if (Hlp_StrCmp(aniName, "T_BOWRELOAD")) { if (onset) { return 20; }; return 36; }; // Frames 20 to 36
    // Add any other possible draw animation here
    return -1; // Reaching this line will yield an error. Add ALL possible drawing animations above!
};

/* Modify this function to alter the draw force calculation. Scaled between 0 and 100 (percent) */
func int freeAimGetDrawForce(var C_Item weapon, var int talent) {
    MEM_CallByString(STR_Upper("freeAimGetDrawPercent")); // Ignore these two lines
    var int drawPercent; drawPercent = MEM_PopIntResult(); // Get the draw animation progress in percent [0, 100]
    // Possibly incorporate factors like e.g. a quick-draw talent, weapon-specific stats, ...
    // Check if bow or crossbow with (weapon.flags & ITEM_BOW) or (weapon.flags & ITEM_CROSSBOW)
    var int drawForce; drawForce = drawPercent; // For now just set the draw force to the progress of the draw animation
    // In the end make sure the return value is in the range of [0, 100]
    if (drawForce < 0) { drawForce = 0; } else if (drawForce > 100) { drawForce = 100; }; // Respect the ranges
    return drawForce;
};

/* Modify this function to alter accuracy calculation. Scaled between 0 and 100 (percent) */
func int freeAimGetAccuracy(var C_Item weapon, var int talent) {
    // Add any other factors here e.g. weapon-specific accuracy stats, weapon spread, accuracy talent, ...
    // Check if bow or crossbow with (weapon.flags & ITEM_BOW) or (weapon.flags & ITEM_CROSSBOW)
    // Here the talent is scaled by draw force: draw force=100% => accuracy=talent; draw force=0% => accuracy=talent/2
    var int drawForce; drawForce = freeAimGetDrawForce(weapon, talent); // Already scaled to [0, 100]
    if (drawForce < talent) { drawForce = talent; }; // Decrease impact of draw force on talent
    var int accuracy; accuracy = (talent * drawForce)/100;
    if (accuracy < 0) { accuracy = 0; } else if (accuracy > 100) { accuracy = 100; }; // Respect the ranges
    return accuracy;
};

/* Modify this function to alter the reticle style. By draw force, weapon-specific stats, talent, ... */
func int freeAimGetReticleStyle(var C_Item weapon, var int talent) {
    if (weapon.flags & ITEM_BOW) { return POINTY_RETICLE; }; // Bow readied
    if (weapon.flags & ITEM_CROSSBOW) { return POINTY_RETICLE; }; // Crossbow readied
    return NORMAL_RETICLE;
};

/* Modify this function to alter the reticle size. By draw force, weapon-specific stats, talent, ... */
func int freeAimGetReticleSize(var int size, var int weapon, var int talent) {
    // The argument 'size' comes precalculated by aiming distance
    // var int scale; scale = -freeAimGetDrawForce(weapon, talent)+100; // E.g. scale with draw force instead
    // var int scale; scale = -freeAimGetAccuracy(weapon, talent)+100; // or scale with accuracy
    // size = (((FREEAIM_RETICLE_MAX_SIZE-FREEAIM_RETICLE_MIN_SIZE)*(scale))/100)+FREEAIM_RETICLE_MIN_SIZE;
    return size; // For now leave it scaled by distance
};

/* Modify this function to define a critical hit by weak spot (e.g. head node for headshot), its size and the damage */
func void freeAimCriticalHitDef(var C_Npc target, var C_Item weapon, var int damage, var int returnPtr) {
    var Weakspot weakspot; weakspot = _^(returnPtr);
    // This function is dynamic: It is called on every hit and the weakspot and damage can be calculated individually
    // Possibly incorporate weapon-specific stats, headshot talent, dependecy on target, ...
    // The damage may depent on the target npc (e.g. different damage for monsters). Make use of 'target' argument
    // if (target.guild < GIL_SEPERATOR_HUM) { }; // E.g. special case for humans
    // The weapon can also be considered (e.g. weapon specific damage). Make use of 'weapon' for that
    // Caution: Weapon may have been unequipped already at this time! Use Hlp_IsValidItem(weapon) to check
    // if (Hlp_IsValidItem(weapon)) && (weapon.certainProperty > 10) { }; // E.g. special case for weapon property
    // The damage is a float and represents the new base damage (damage of weapon), not the final damage!
    if (target.guild < GIL_SEPERATOR_HUM) { // Humans: head shot
        weakspot.node = "Bip01 Head"; // Upper/lower case is not important, but spelling and spaces are
        weakspot.dimX = -1; // Retrieve from model (works only on humans and only for head node!)
        weakspot.dimY = -1;
        weakspot.bDmg = mulf(damage, castToIntf(2.0)); // Double the base damage. This is a float
    // } else if (target.aivar[AIV_MM_REAL_ID] == ID_TROLL) {
    //    weakspot.node = "Bip01 R Finger0"; // Difficult to hit when the troll attacks
    //    weakspot.dimX = 100; // 100x100cm size
    //    weakspot.dimY = 100;
    //    weakspot.bDmg = mulf(damage, castToIntf(1.75));
    // } else if (target.aivar[AIV_MM_REAL_ID] == ...
    //    ...
    } else { // Default
        weakspot.node = "Bip01 Head";
        weakspot.dimX = 60; // 60x60cm size
        weakspot.dimY = 60;
        weakspot.bDmg = mulf(damage, castToIntf(2.0)); // Double the base damage. This is a float
    };
};

/* Use this function to create an event when getting a critical hit, e.g. print or sound jingle, leave blank for none */
func void freeAimCriticalHitEvent(var C_Npc target, var C_Item weapon) {
    // The event may depent on the target npc (e.g. different sound for monsters). Make use of 'target' argument
    // if (target.guild < GIL_SEPERATOR_HUM) { }; // E.g. special case for humans
    // The critical hits could also be counted here to give an xp reward after 25 headshots
    // The weapon can also be considered (e.g. weapon specific print). Make use of 'weapon' for that
    // Caution: Weapon may have been unequipped already at this time! Use Hlp_IsValidItem(weapon) to check
    // if (Hlp_IsValidItem(weapon)) && (weapon.certainProperty > 10) { }; // E.g. special case for weapon property
    Snd_Play("FORGE_ANVIL_A1");
    PrintS("Kritischer Treffer"); // "Critical hit"
};

/* Modify this function to alter the projectile instance after shooting for re-using, e.g. used arrow */
func int freeAimGetUsedProjectileInstance(var int projectileInst, var C_Npc inventoryNpc) {
    // By returning zero, the projectile is completely removed (e.g. retrieve-projectile-talent not learned yet)
    // The argument inventoryNpc holds the npc in whose inventory it will be put, or is empty if it landed in the world
    // if (projectileInst == Hlp_GetInstanceID(ItRw_Arrow)) { // Exchange the instance for a "used" one
    //     if (!Hlp_IsValidItem(ItRw_UsedArrow)) { Wld_InsertItem(ItRw_UsedArrow, MEM_FARFARAWAY); }; // Initialize!
    //     projectileInst = Hlp_GetInstanceID(ItRw_UsedArrow);
    // };
    if (Hlp_IsValidNpc(inventoryNpc)) { // Projectile hit npc and will be put into their inventory
        if (Npc_IsPlayer(inventoryNpc)) { return 0; }; // Do not put projectiles in player inventory
        // if (inventoryNpc.guild < GIL_SEPERATOR_HUM) { return 0; }; // Remove projectile when it hits humans
        // if (PLAYER_TALENT_TAKEANIMALTROPHY[REUSE_Arrow] == FALSE) { return 0; }; // Retrieve-projectile-talent
        // if (!Npc_HasItems(hero, ItMi_ArrowTool)) { return 0; }; // Player needs tool to remove the projectile
        return projectileInst; // For now it is just preserved (is put in the inventory as is)
    } else { // Projectile did not hit npc and landed in world
        // if (PLAYER_TALENT_REUSE_ARROW == FALSE) { return 0; }; // Reuse-projectile-talent
        return projectileInst; // For now it is just preserved (leave it in the world as is)
    };
};

/********************************************** DO NO CROSS THIS LINE **************************************************

  WARNING: All necessary adjustments can be performed above. You should not need to edited anything below.
  Proceed at your own risk: On modifying the functions below free aiming will most certainly become unstable.

*********************************************** DO NO CROSS THIS LINE *************************************************/

/* All addresses used (gothic2). In case of a gothic1 port: There are a lot of hardcoded address offsets in the code! */
const int zCVob___CreateNewInstance               = 6281536; //0x5FD940
const int zCVob__SetPositionWorld                 = 6404976; //0x61BB70
const int zCVob__GetRigidBody                     = 6285664; //0x5FE960
const int zCVob__TraceRay                         = 6291008; //0x5FFE40
const int zCArray_zCVob__IsInList                 = 7159168; //0x6D3D80
const int zCWorld__TraceRayNearestHit_Vob         = 6430624; //0x621FA0
const int zCWorld__AddVobAsChild                  = 6440352; //0x6245A0
const int zString_CamModRanged                    = 9234704; //0x8CE910
const int oCAniCtrl_Human__Turn                   = 7005504; //0x6AE540
const int oCAniCtrl_Human__GetLayerAni            = 7011712; //0x6AFD80
const int oCNpc__GetAngles                        = 6820528; //0x6812B0
const int oCNpc__SetFocusVob                      = 7547744; //0x732B60
const int oCNpc__SetEnemy                         = 7556032; //0x734BC0
const int oCNpc__GetModel                         = 7571232; //0x738720
const int oCItem__InitByScript                    = 7412688; //0x711BD0
const int oCItem__InsertEffect                    = 7416896; //0x712C40
const int oCItem__RemoveEffect                    = 7416832; //0x712C00
const int zCModel__SearchNode                     = 5758960; //0x57DFF0
const int zCModel__GetBBox3DNodeWorld             = 5738736; //0x5790F0
const int zCModel__GetNodePositionWorld           = 5738816; //0x579140
const int zTBBox3D__Draw                          = 5529312; //0x545EE0
const int zCLineCache__Line3D                     = 5289040; //0x50B450
const int zlineCache                              = 9257720; //0x8D42F8
const int oCGame__s_bUseOldControls               = 9118144; //0x8B21C0
const int mouseEnabled                            = 9248108; //0x8D1D6C
const int mouseSensX                              = 9019720; //0x89A148
const int mouseDeltaX                             = 9246300; //0x8D165C
const int zCWorld__AdvanceClock                   = 6447328; //0x6260E0 // Hook length 10
const int oCAniCtrl_Human__InterpolateCombineAni  = 7037296; //0x6B6170 // Hook length 5
const int oCAIArrow__SetupAIVob                   = 6951136; //0x6A10E0 // Hook length 6
const int oCAIHuman__BowMode                      = 6905600; //0x695F00 // Hook length 6
const int oCAIArrowBase__DoAI                     = 6948416; //0x6A0640 // Hook length 7
const int onArrowHitNpcAddr                       = 6949832; //0x6A0BC8 // Hook length 5
const int onArrowHitVobAddr                       = 6949929; //0x6A0C29 // Hook length 5
const int onArrowHitStatAddr                      = 6949460; //0x6A0A54 // Hook length 5
const int onArrowHitChanceAddr                    = 6953483; //0x6A1A0B // Hook length 5
const int onArrowDamageAddr                       = 6953621; //0x6A1A95 // Hook length 7
const int onDmgAnimationAddr                      = 6774593; //0x675F41 // Hook length 9
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
        HookEngineF(onArrowDamageAddr, 7, freeAimDetectCriticalHit); // Critical hit detection
        HookEngineF(onArrowHitChanceAddr, 5, freeAimDoNpcHit); // Decide whether a projectile hits or not
        HookEngineF(onDmgAnimationAddr , 9, freeAimDmgAnimation); // Disable damage animation while aming
        if (FREEAIM_DEBUG_CONSOLE) { // Enable console command for debugging
            CC_Register(freeAimDebugWeakspot, "debug weakspot", "turn debug visualization on/off");
        };
        if (FREEAIM_DEBUG_CONSOLE) || (FREEAIM_DEBUG_WEAKSPOT) { // Visualization of weakspot for debugging
            HookEngineF(zCWorld__AdvanceClock, 10, freeAimVisualizeWeakspot); // FrameFunctions hook too early
        };
        if (FREEAIM_REUSE_PROJECTILES) { // Because of balancing issues, this is a constant and not a variable
            HookEngineF(onArrowHitNpcAddr, 5, freeAimOnArrowHitNpc); // Put projectile into inventory
            HookEngineF(onArrowHitVobAddr, 5, freeAimOnArrowGetStuck); // Keep projectile alive when stuck in vob
            HookEngineF(onArrowHitStatAddr, 5, freeAimOnArrowGetStuck); // Keep projectile alive when stuck in world
        };
        r_DefaultInit(); // Start rng for aiming accuracy
        hookFreeAim = 1;
    };
    MEM_Info("Free aim initialized.");
};

/* Update internal settings when turning free aim on/off in the options */
func void freeAimUpdateSettings(var int on) {
    MEM_Info("Updating internal free aiming settings");
    if (on) {
        Focus_Ranged.npc_azi = 15.0; // Set stricter focus collection
        Focus_Ranged.npc_elevup = 15.0;
        Focus_Ranged.npc_elevdo = -10.0;
        MEM_WriteString(zString_CamModRanged, STR_Upper(FREEAIM_CAMERA)); // New camera mode, upper case is important
        FREEAIM_ACTIVE_PREVFRAME = 1;
    } else {
        Focus_Ranged.npc_azi =  45.0; // Reset ranged focus collection to standard
        Focus_Ranged.npc_elevup =  90.0;
        Focus_Ranged.npc_elevdo =  -85.0;
        MEM_WriteString(zString_CamModRanged, "CAMMODRANGED"); // Restore camera mode, upper case is important
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
        var C_Npc target; target = _^(potentialVob);  // Do not allow focussing npcs that are down
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

/* Internal helper function for freeAimGetReticleSize() and freeAimGetReticleStyle() */
func int freeAimGetReticle(var int sizePtr) {
    var int reticleStyle; var int reticleSize; reticleSize = MEM_ReadInt(sizePtr);
    var int talent; var C_Item weapon; // Retrieve the weapon first to distinguish between (cross-)bow talent
    if (Npc_IsInFightMode(hero, FMODE_FAR)) { weapon = Npc_GetReadiedWeapon(hero); }
    else if (Npc_HasEquippedRangedWeapon(hero)) { weapon = Npc_GetEquippedRangedWeapon(hero); }
    else { MEM_Error("freeAimGetReticle: No valid weapon equipped/readied!"); return -1; }; // Should never happen
    if (weapon.flags & ITEM_BOW) { talent = hero.HitChance[NPC_TALENT_BOW]; } // Bow talent
    else if (weapon.flags & ITEM_CROSSBOW) { talent = hero.HitChance[NPC_TALENT_CROSSBOW]; } // Crossbow talent
    else { MEM_Error("freeAimGetReticle: No valid weapon equipped/readied!"); return -1; };
    reticleStyle = freeAimGetReticleStyle(weapon, talent);
    reticleSize = freeAimGetReticleSize(reticleSize, weapon, talent);
    if (reticleSize < FREEAIM_RETICLE_MIN_SIZE) { reticleSize = FREEAIM_RETICLE_MIN_SIZE; }
    else if (reticleSize > FREEAIM_RETICLE_MAX_SIZE) { reticleSize = FREEAIM_RETICLE_MAX_SIZE; };
    if (reticleStyle < 0) || (reticleStyle >= MAX_RETICLE) {
        MEM_Error("freeAimGetReticle: Invalid reticleStyle!"); reticleStyle = NO_RETICLE; };
    MEM_WriteInt(sizePtr, reticleSize); // Overwrite reticle size
    return reticleStyle;
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

/* Retrieve the percentage of drawing the weapon by animation */
func int freeAimGetDrawPercent() {
    var int hAniCtrl; hAniCtrl = MEM_ReadInt(_@(hero)+2432); // oCNpc.anictrl
    var int one; one = 1; const int call = 0;
    if (CALL_Begin(call)) {
        CALL_IntParam(_@(one)); // Layer one
        CALL__thiscall(_@(hAniCtrl), oCAniCtrl_Human__GetLayerAni);
        call = CALL_End();
    };
    var int ani; ani = CALL_RetValAsInt(); // zCModelAniActive*
    if (!ani) { MEM_Error("freeAimGetDrawPercent: No active animation found!"); return 0; };
    if (!MEM_ReadInt(ani)) { MEM_Error("freeAimGetDrawPercent: No active animation found!"); return 0; }; // Separate if
    var string aniName; aniName = STR_Upper(MEM_ReadString(MEM_ReadInt(ani)+36)); // zCModelAni*->name
    var int currentFrame; currentFrame = roundf(MEM_ReadInt(ani+12)); // zCModelAniActive*->actFrame
    var int onsetFrame; onsetFrame = freeAimGetAniDrawFrame(aniName, 1); // Drawing starts
    var int offsetFrame; offsetFrame = freeAimGetAniDrawFrame(aniName, 0); // Drawing ends
    if (onsetFrame == -1) || (offsetFrame == -1) {
        MEM_Error("freeAimGetDrawPercent: Animation not found!"); return 0; };
    if (onsetFrame <= 0) || (offsetFrame <= 0) || (onsetFrame == offsetFrame) {
        MEM_Error("freeAimGetDrawPercent: Animation onset/offset invalid!"); return 0; };
    var int drawPercent; drawPercent = (100*(currentFrame - onsetFrame))/(offsetFrame - onsetFrame); // Draw progress
    if (drawPercent < 0) { drawPercent = 0; } else if (drawPercent > 100) { drawPercent = 100; }; // Respect the ranges
    return drawPercent;
};

/* Internal helper function for freeAimGetDrawForce() */
func int freeAimGetDrawForce_() {
    var int talent; var C_Item weapon; // Retrieve the weapon first to distinguish between (cross-)bow talent
    if (Npc_IsInFightMode(hero, FMODE_FAR)) { weapon = Npc_GetReadiedWeapon(hero); }
    else if (Npc_HasEquippedRangedWeapon(hero)) { weapon = Npc_GetEquippedRangedWeapon(hero); }
    else { MEM_Error("freeAimGetDrawForce_: No valid weapon equipped/readied!"); return -1; }; // Should never happen
    if (weapon.flags & ITEM_BOW) { talent = hero.HitChance[NPC_TALENT_BOW]; } // Bow talent
    else if (weapon.flags & ITEM_CROSSBOW) { talent = hero.HitChance[NPC_TALENT_CROSSBOW]; } // Crossbow talent
    else { MEM_Error("freeAimGetDrawForce_: No valid weapon equipped/readied!"); return -1; };
    var int drawForce; drawForce = freeAimGetDrawForce(weapon, talent);
    if (drawForce > 100) { drawForce = 100; } else if (drawForce < 0) { drawForce = 0; }; // Must be in [0, 100]
    return drawForce;
};

/* Internal helper function for freeAimGetAccuracy() */
func int freeAimGetAccuracy_() {
    var int talent; var C_Item weapon; // Retrieve the weapon first to distinguish between (cross-)bow talent
    if (Npc_IsInFightMode(hero, FMODE_FAR)) { weapon = Npc_GetReadiedWeapon(hero); }
    else if (Npc_HasEquippedRangedWeapon(hero)) { weapon = Npc_GetEquippedRangedWeapon(hero); }
    else { MEM_Error("freeAimGetAccuracy_: No valid weapon equipped/readied!"); return -1; }; // Should never happen
    if (weapon.flags & ITEM_BOW) { talent = hero.HitChance[NPC_TALENT_BOW]; } // Bow talent
    else if (weapon.flags & ITEM_CROSSBOW) { talent = hero.HitChance[NPC_TALENT_CROSSBOW]; } // Crossbow talent
    else { MEM_Error("freeAimGetAccuracy_: No valid weapon equipped/readied!"); return -1; };
    var int accuracy; accuracy = freeAimGetAccuracy(weapon, talent);
    if (accuracy < 1) { accuracy = 1; } else if (accuracy > 100) { accuracy = 100; }; // Limit to [1, 100] // Div by 0!
    return accuracy;
};

/* Set the projectile direction and trajectory. Hook oCAIArrow::SetupAIVob */
func void freeAimSetupProjectile() {
    var int projectile; projectile = MEM_ReadInt(ESP+4);  // First argument is the projectile
    var C_Npc shooter; shooter = _^(MEM_ReadInt(ESP+8)); // Second argument is shooter
    if (FREEAIM_ACTIVE_PREVFRAME != 1) || (!Npc_IsPlayer(shooter)) { return; }; // Only for player and when fa active
    // 1st: Set projectile drop-off (by draw force)
    const int call2 = 0;
    if (CALL_Begin(call2)) {
        CALL__thiscall(_@(projectile), zCVob__GetRigidBody); // Get ridigBody this way, it will be properly created
        call2 = CALL_End();
    };
    var int rBody; rBody = CALL_RetValAsInt(); // zCRigidBody*
    var int drawForce; drawForce = freeAimGetDrawForce_(); // Modify the draw force in that function, not here!
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
    // 2nd: Manipulate aiming accuracy (scatter): Rotate target position (azimuth, elevation)
    var int distance; freeAimRay(FREEAIM_MAX_DIST, 0, 0, 0, _@(distance)); // Trace ray intersection
    var int accuracy; accuracy = freeAimGetAccuracy_(); // Change the accuracy calculation in that function, not here!
    if (accuracy > 100) { accuracy = 100; } else if (accuracy < 1) { accuracy = 1; }; // Prevent devision by zero
    var int angleMax; angleMax = roundf(mulf(mulf(fracf(1, accuracy), castToIntf(FREEAIM_SCATTER_DEG)), FLOAT1K));
    var int angleY; angleY = fracf(r_MinMax(-angleMax, angleMax), 1000); // Degrees azimuth
    angleMax = roundf(sqrtf(subf(sqrf(mkf(angleMax)), sqrf(mulf(angleY, FLOAT1K))))); // sqrt(angleMax^2-angleY^2)
    var int angleX; angleX = fracf(r_MinMax(-angleMax, angleMax), 1000); // Degrees elevation (restrict to circle)
    var zMAT4 camPos; camPos = _^(MEM_ReadInt(MEM_ReadInt(MEMINT_oGame_Pointer_Address)+20)+60); //0=right, 2=out, 3=pos
    var int pos[3]; pos[0] = FLOATNULL; pos[1] = FLOATNULL; pos[2] = distance;
    SinCosApprox(Print_ToRadian(angleX)); // Rotate around x-axis (elevation scatter)
    pos[1] = mulf(negf(pos[2]), sinApprox); // y*cos - z*sin = y'
    pos[2] = mulf(pos[2], cosApprox);       // y*sin + z*cos = z'
    SinCosApprox(Print_ToRadian(angleY)); // Rotate around y-axis (azimuth scatter)
    pos[0] = mulf(pos[2], sinApprox); //  x*cos + z*sin = x'
    pos[2] = mulf(pos[2], cosApprox); // -x*sin + z*cos = z'
    var int newPos[3]; // Rotation (translation into local coordinate system of camera)
    newPos[0] = addf(addf(mulf(camPos.v0[0], pos[0]), mulf(camPos.v0[1], pos[1])), mulf(camPos.v0[2], pos[2]));
    newPos[1] = addf(addf(mulf(camPos.v1[0], pos[0]), mulf(camPos.v1[1], pos[1])), mulf(camPos.v1[2], pos[2]));
    newPos[2] = addf(addf(mulf(camPos.v2[0], pos[0]), mulf(camPos.v2[1], pos[1])), mulf(camPos.v2[2], pos[2]));
    pos[0] = addf(camPos.v0[3], newPos[0]);
    pos[1] = addf(camPos.v1[3], newPos[1]);
    pos[2] = addf(camPos.v2[3], newPos[2]);
    // 3rd: Setup the aim vob
    var int vobPtr; vobPtr = MEM_SearchVobByName("AIMVOB"); // Arrow needs target vob
    if (!vobPtr) { // Does not exist
        MEM_Info("freeAimSetupProjectile: Creating aim vob."); // Should be printed only once ever
        CALL__cdecl(zCVob___CreateNewInstance); // This actually allocates the memory, so no need to care about freeing
        vobPtr = CALL_RetValAsPtr();
        MEM_WriteString(vobPtr+16, "AIMVOB"); // zCVob._zCObject_objectName
        CALL_PtrParam(_@(MEM_Vobtree));
        CALL_PtrParam(vobPtr);
        CALL__thiscall(_@(MEM_World), zCWorld__AddVobAsChild);
    };
    var int posPtr; posPtr = _@(pos);
    const int call4 = 0; // Set position to aim vob
    if (CALL_Begin(call4)) {
        CALL_PtrParam(_@(posPtr)); // Update aim vob position
        CALL__thiscall(_@(vobPtr), zCVob__SetPositionWorld);
        call4 = CALL_End();
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

/* Determine the hit chance. For the player it's always 100%. True hit chance is calcualted in freeAimGetAccuracy() */
func void freeAimDoNpcHit() {
    var int hitChance; hitChance = MEM_ReadInt(ESP+24); // esp+1ACh+194h
    var C_Npc shooter; shooter = _^(MEM_ReadInt(EBP+92)); // ebp+5Ch // oCNpc*
    if (FREEAIM_ACTIVE_PREVFRAME) && (Npc_IsPlayer(shooter)) { MEM_WriteInt(ESP+24, 100); }; // Player always hits
};

/* Arrow gets stuck in npc: put projectile instance into inventory and let ai die */
func void freeAimOnArrowHitNpc() {
    var oCItem projectile; projectile = _^(MEM_ReadInt(ESI+88));
    var C_Npc victim; victim = _^(EDI);
    var int projInst; projInst = freeAimGetUsedProjectileInstance(projectile.instanz, victim); // Get "used" instance
    if (projInst > 0) { CreateInvItem(victim, projInst); }; // Put respective instance in inventory
    if (FF_ActiveData(freeAimDropProjectile, _@(projectile._zCVob_rigidBody))) {
        FF_RemoveData(freeAimDropProjectile, _@(projectile._zCVob_rigidBody)); };
    MEM_WriteInt(ESI+56, -1073741824); // oCAIArrow.lifeTime // Mark this AI for freeAimWatchProjectile()
};

/* Arrow gets stuck in static or dynamic world (non-npc): keep ai alive */
func void freeAimOnArrowGetStuck() {
    var int projectilePtr; projectilePtr = MEM_ReadInt(ESI+88);
    var oCItem projectile; projectile = _^(projectilePtr);
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
        var C_Npc emptyNpc;
        var int projInst; projInst = freeAimGetUsedProjectileInstance(projectile.instanz, emptyNpc); // "Used" instance
        if (projInst > 0) { // Will be -1 on invalid item
            if (projInst != projectile.instanz) { // Only change the instance if different
                const int call3 = 0; const int one = 1;
                if (CALL_Begin(call3)) {
                    CALL_IntParam(_@(one)); // Amount
                    CALL_PtrParam(_@(projInst)); // Instance ID
                    CALL__thiscall(_@(projectilePtr), oCItem__InitByScript);
                    call3 = CALL_End();
                };
            };
            projectile._zCVob_callback_ai = 0; // Release vob from AI
            projectile.flags = projectile.flags &~ ITEM_NFOCUS; // Focusable
            MEM_WriteInt(arrowAI+56, FLOATONE); // oCAIArrow.lifeTime // Set high lifetime to ensure item visibility
            MEM_WriteInt(removePtr, 0); // Do not remove vob on AI destruction
            MEM_WriteInt(ESP+8, _@(FREEAIM_ARROWAI_REDIRECT)); // Divert the actual "return" value
        };
    } else if (MEM_ReadInt(arrowAI+56) == -1073741824) { // Marked as positive hit on npc: do not keep alive
        MEM_WriteInt(arrowAI+56, FLOATNULL); // oCAIArrow.lifeTime
    };
};

/* Disable damage animation. Taken from http://forum.worldofplayers.de/forum/threads/1474431?p=25057480#post25057480 */
func void freeAimDmgAnimation() {
    var C_Npc victim; victim = _^(ECX);
    if (Npc_IsPlayer(victim)) && (freeAimIsActive()) { EAX = 0; }; // Disable damage animation while aiming
};

/* Visualize the bounding box of the weakspot and the projectile trajectory for debugging */
func void freeAimVisualizeWeakspot() {
    if (!FREEAIM_DEBUG_WEAKSPOT) { return; };
    if (freeAimDebugBBox[0]) { // Visualize weak spot bounding box
        var int cGreenPtr; cGreenPtr = _@(zCOLOR_GREEN);
        var int bboxPtr; bboxPtr = _@(freeAimDebugBBox);
        const int call = 0;
        if (CALL_Begin(call)) {
            CALL_PtrParam(_@(cGreenPtr));
            CALL__thiscall(_@(bboxPtr), zTBBox3D__Draw);
            call = CALL_End();
        };
    };
    if (freeAimDebugTrj[0]) { // Visualize projectile trajectory
        var int cRedPtr; cRedPtr = _@(zCOLOR_RED);
        var int pos1Ptr; pos1Ptr = _@(freeAimDebugTrj);
        var int pos2Ptr; pos2Ptr = _@(freeAimDebugTrj)+12;
        const int call2 = 0; var int null;
        if (CALL_Begin(call2)) {
            CALL_IntParam(_@(null));
            CALL_PtrParam(_@(cRedPtr));
            CALL_PtrParam(_@(pos2Ptr));
            CALL_PtrParam(_@(pos1Ptr));
            CALL__thiscall(_@(zlineCache), zCLineCache__Line3D);
            call2 = CALL_End();
        };
    };
};

/* Internal helper function for freeAimCriticalHitEvent() */
func void freeAimCriticalHitEvent_(var C_Npc target) {
    var C_Item weapon; // Caution: Weapon may have been unequipped already at this time
    if (Npc_IsInFightMode(hero, FMODE_FAR)) { weapon = Npc_GetReadiedWeapon(hero); }
    else if (Npc_HasEquippedRangedWeapon(hero)) { weapon = Npc_GetEquippedRangedWeapon(hero); };
    freeAimCriticalHitEvent(target, weapon);
};

/* Internal helper function for freeAimCriticalHitDef() */
func void freeAimCriticalHitDef_(var C_Npc target, var int damagePtr, var int returnPtr) {
    var C_Item weapon; // Caution: Weapon may have been unequipped already at this time
    if (Npc_IsInFightMode(hero, FMODE_FAR)) { weapon = Npc_GetReadiedWeapon(hero); }
    else if (Npc_HasEquippedRangedWeapon(hero)) { weapon = Npc_GetEquippedRangedWeapon(hero); };
    freeAimCriticalHitDef(target, weapon, MEM_ReadInt(damagePtr), returnPtr);
    MEM_WriteString(returnPtr, STR_Upper(MEM_ReadString(returnPtr))); // Nodes are always upper case
    if (lf(MEM_ReadInt(returnPtr+28), FLOATNULL)) { MEM_WriteInt(returnPtr+28, FLOATNULL); }; // Correct negative damage
};

/* Console function to enable/disable weak spot debug output */
func string freeAimDebugWeakspot(var string command) {
    FREEAIM_DEBUG_WEAKSPOT = !FREEAIM_DEBUG_WEAKSPOT;
    if (FREEAIM_DEBUG_WEAKSPOT) { return "Debug weak spot on."; } else { return "Debug weak spot off."; };
};

/* Detect critical hits and increase base damage. Modify the weak spot in freeAimCriticalHitDef() */
func void freeAimDetectCriticalHit() {
    var int damagePtr; damagePtr = ESP+228; // esp+1ACh+C8h // int*
    var int target; target = MEM_ReadInt(ESP+28); // esp+1ACh+190h // oCNpc*
    var int projectile; projectile = MEM_ReadInt(EBP+88); // ebp+58h // oCItem*
    var C_Npc shooter; shooter = _^(MEM_ReadInt(EBP+92)); // ebp+5Ch // oCNpc*
    if (FREEAIM_ACTIVE_PREVFRAME != 1) || (!Npc_IsPlayer(shooter)) { return; }; // Only for player and when fa active
    var C_Npc targetNpc; targetNpc = _^(target);
    // Get model from target npc
    const int call = 0;
    if (CALL_Begin(call)) {
        CALL__thiscall(_@(target), oCNpc__GetModel);
        call = CALL_End();
    };
    var int model; model = CALL_RetValAsPtr();
    // Get weak spot node from target model
    var int autoAlloc[8]; var Weakspot weakspot; weakspot = _^(_@(autoAlloc)); // Gothic takes care of freeing this ptr
    freeAimCriticalHitDef_(targetNpc, damagePtr, _@(weakspot)); // Retrieve weakspot specs
    var int nodeStrPtr; nodeStrPtr = _@(weakspot);
    const int call2 = 0;
    if (CALL_Begin(call2)) {
        CALL_PtrParam(_@(nodeStrPtr));
        CALL__thiscall(_@(model), zCModel__SearchNode);
        call2 = CALL_End();
    };
    var int node; node = CALL_RetValAsPtr();
    if (!node) { MEM_Error("freeAimDetectCriticalHit: Node not found!"); return; };
    if (weakspot.dimX == -1) && (weakspot.dimY == -1) { // Retrieve the bbox by model
        if (MEM_ReadInt(node+8)) { // node->nodeVisual // If the node has a dedicated visual, retrieve bbox
            // Get the bbox of the node (although zCModelNodeInst has a zTBBox3D property, it is empty the first time)
            CALL_PtrParam(node); CALL_RetValIsStruct(24); // sizeof_zTBBox3D // No recyclable call possible
            CALL__thiscall(model, zCModel__GetBBox3DNodeWorld);
            var int nodeBBoxPtr; nodeBBoxPtr = CALL_RetValAsPtr();
            MEM_CopyWords(nodeBBoxPtr, _@(freeAimDebugBBox), 6); // zTBBox3D
            MEM_Free(nodeBBoxPtr); // Free memory
        } else {
            MEM_Error("freeAimDetectCriticalHit: Node has no boundingbox!");
            return;
        };
    } else if (weakspot.dimX < 0) && (weakspot.dimY < 0) { // Bbox dimensions must be positive
        MEM_Error("freeAimDetectCriticalHit: Boundingbox dimensions illegal!");
        return;
    } else { // Create bbox by dimensions
        weakspot.dimX /= 2; weakspot.dimY /= 2;
        // Get the position of the node (although zCModelNodeInst has a position property, it is empty the first time)
        CALL_PtrParam(node); CALL_RetValIsStruct(12); // sizeof_zVEC3 // No recyclable call possible bc of structure
        CALL__thiscall(model, zCModel__GetNodePositionWorld);
        var int nodPosPtr; nodPosPtr = CALL_RetValAsInt();
        var int nodePos[3]; MEM_CopyWords(nodPosPtr, _@(nodePos), 3);
        MEM_Free(nodPosPtr); // Free memory
        freeAimDebugBBox[0] = subf(nodePos[0], mkf(weakspot.dimX)); // Build an own bbox by the passed node dimensions
        freeAimDebugBBox[1] = subf(nodePos[1], mkf(weakspot.dimY));
        freeAimDebugBBox[2] = subf(nodePos[2], mkf(weakspot.dimX));
        freeAimDebugBBox[3] = addf(nodePos[0], mkf(weakspot.dimX));
        freeAimDebugBBox[4] = addf(nodePos[1], mkf(weakspot.dimY));
        freeAimDebugBBox[5] = addf(nodePos[2], mkf(weakspot.dimX));
    };
    // The internal engine functions are not accurate enough for detecting a shot through a bbox
    // Instead check here if "any" point along the line of projectile direction lies inside the bbox of the node
    var int dir[3]; // Direction of collision line along the right-vector of the projectile (projectile flies sideways)
    dir[0] = MEM_ReadInt(projectile+60); dir[1] = MEM_ReadInt(projectile+76); dir[2] = MEM_ReadInt(projectile+92);
    freeAimDebugTrj[0] = addf(MEM_ReadInt(projectile+ 72), mulf(dir[0], mkf(100))); // Start 1m behind the projectile
    freeAimDebugTrj[1] = addf(MEM_ReadInt(projectile+ 88), mulf(dir[1], mkf(100)));
    freeAimDebugTrj[2] = addf(MEM_ReadInt(projectile+104), mulf(dir[2], mkf(100)));
    var int intersection; intersection = 0; // Critical hit detected
    var int i; i=0; var int iter; iter = 700/5; // 7meters: Max distance from model bbox edge to node bbox (e.g. troll)
    while(i <= iter); i += 1; // Walk along the line in steps of 5cm
        freeAimDebugTrj[3] = subf(freeAimDebugTrj[0], mulf(dir[0], mkf(i*5))); // Next point along the collision line
        freeAimDebugTrj[4] = subf(freeAimDebugTrj[1], mulf(dir[1], mkf(i*5)));
        freeAimDebugTrj[5] = subf(freeAimDebugTrj[2], mulf(dir[2], mkf(i*5)));
        if (lef(freeAimDebugBBox[0], freeAimDebugTrj[3])) && (lef(freeAimDebugBBox[1], freeAimDebugTrj[4]))
        && (lef(freeAimDebugBBox[2], freeAimDebugTrj[5])) && (gef(freeAimDebugBBox[3], freeAimDebugTrj[3]))
        && (gef(freeAimDebugBBox[4], freeAimDebugTrj[4])) && (gef(freeAimDebugBBox[5], freeAimDebugTrj[5])) {
            intersection = 1; }; // Current point is inside the node bbox, but stay in loop for debugging the line
    end;
    if (intersection) { // Critical hit detected
        freeAimCriticalHitEvent_(targetNpc); // Use this function to add an event, e.g. a print or a sound
        MEM_WriteInt(damagePtr, weakspot.bDmg); // Base damage not final damage
    };
};
