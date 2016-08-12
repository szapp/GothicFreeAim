/*
 * Manually rotate the hero
 */

/* Creates or returns the aim vob */
func int getAimVob(var int posPtr) {
    var int vobPtr; vobPtr = MEM_SearchVobByName("AIMVOB");
    if (!vobPtr) {
        vobPtr = MEM_Alloc(sizeof_zCVob);
        const int oCVob__oCVob = 7845536; //0x77B6A0
        CALL__thiscall(vobPtr, oCVob__oCVob);
        MEM_WriteString(vobPtr+16, "AIMVOB"); // _zCObject_objectName
        const int zCWorld__AddVobAsChild = 6440352; //0x6245A0
        CALL_PtrParam(_@(MEM_Vobtree));
        CALL_PtrParam(vobPtr);
        CALL__thiscall(_@(MEM_World), zCWorld__AddVobAsChild);
    };
    // Update aim vob position
    const int zCVob__SetPositionWorld = 6404976; //0x61BB70
    CALL_PtrParam(posPtr);
    CALL__thiscall(vobPtr, zCVob__SetPositionWorld);
    return vobPtr;
};

/* Turn hero (incl. camera if attached) by degrees (in float) */
func void turnHero(var int degreesf) {
    var oCNPC her; her = Hlp_GetNpc(hero);
    const int oCAniCtrl_Human__TurnDegrees = 7006992; //0x6AEB10
    CALL_IntParam(0); // 0 = disable turn animation
    CALL_FloatParam(degreesf);
    CALL__thiscall(her.anictrl, oCAniCtrl_Human__TurnDegrees);
};

/* Turn hero (incl. camera if attached) by degrees (in float) "aim-edition" */
func void aimHero(var int degreesf) {
    turnHero(degreesf); return;



    MEM_InitGlobalInst(); // This is necessary here to find the camera vob, although it was called in init_global. Why?
    var zCVob cam; cam = _^(MEM_Camera.connectedVob);
    var oCNPC her; her = Hlp_GetNpc(hero);
    var int pos[6]; // Combined pos[3] + dir[3]
    pos[0] = her._zCVob_trafoObjToWorld[ 3];  pos[3] = mulf(cam.trafoObjToWorld[ 2], mkf(AIM_MAX_DIST));
    pos[1] = her._zCVob_trafoObjToWorld[ 7];  pos[4] = mulf(cam.trafoObjToWorld[ 6], mkf(AIM_MAX_DIST));
    pos[2] = her._zCVob_trafoObjToWorld[11];  pos[5] = mulf(cam.trafoObjToWorld[10], mkf(AIM_MAX_DIST));
    pos[0] = addf(pos[0], pos[3]);
    pos[1] = addf(pos[1], pos[4]);
    pos[2] = addf(pos[2], pos[5]);

    const int oCAniCtrl_Human__TurnDegrees = 7006992; //0x6AEB10
    CALL_IntParam(0); // 0 = disable turn animation
    CALL_FloatParam(degreesf);
    CALL__thiscall(her.anictrl, oCAniCtrl_Human__TurnDegrees);

    var zCVob vob; vob = _^(getAimVob(_@(pos)));

    //const int oCAniCtrl_Human__SetLookAtTarget = 7037792; //0x6B6360
    //CALL_PtrParam(_@(pos));
    //CALL__thiscall(her.anictrl, oCAniCtrl_Human__SetLookAtTarget);
};

/* Check if mouse moved along the x-/y-axis */
func int getMouseMove(var int xy) { // 0 = x, 1 = y
    const int zCInput_Win32__GetMousePos = 5068592; //0x4D5730
    const int zCInput_zinput = 9246288; //0x8D1650
    var int pos[3];
    CALL_PtrParam(_@(pos)+8); // Not clear
    CALL_PtrParam(_@(pos)+4); // Change in y position
    CALL_PtrParam(_@(pos));   // Change in x position
    CALL__thiscall(MEM_ReadInt(zCInput_zinput), zCInput_Win32__GetMousePos);
    return MEM_ReadStatArr(pos, !!xy);
};

var int timeM; var int disp;
/* Manually update the rotation of the hero including the camera */
func void updateHeroYrot(var int mod) { // Float multiplier (e.g. FLOATEINS)
    var int xChng; xChng = getMouseMove(0); // Change in x position
    if (xChng == FLOATNULL) { return; };
    //turnHero(mulf(xChng, mod));
    aimHero(mulf(xChng, mod));
};

const int AIM_MAX_DIST    = 10000; // 100 meters. Enough?
const int AIM_OBJ_OFFSET  = 150;   // Cm to shift behind intersection
func void ShootTarget() {
    // Set trace ray (start from shooter and go along the outvector of the camera vob)
    MEM_InitGlobalInst(); // This is necessary here to find the camera vob, although it was called in init_global. Why?
    var zCVob cam; cam = _^(MEM_Camera.connectedVob);
    var zCVob her; her = Hlp_GetNpc(hero);
    var int pos[6]; // Combined pos[3] + dir[3]
    pos[0] = her.trafoObjToWorld[ 3];  pos[3] = mulf(cam.trafoObjToWorld[ 2], mkf(AIM_MAX_DIST));
    pos[1] = her.trafoObjToWorld[ 7];  pos[4] = mulf(cam.trafoObjToWorld[ 6], mkf(AIM_MAX_DIST));
    pos[2] = her.trafoObjToWorld[11];  pos[5] = mulf(cam.trafoObjToWorld[10], mkf(AIM_MAX_DIST));
    // Shoot trace ray
    if (TraceRay(_@(pos), _@(pos)+12, // From shooter to max distance
            (zTRACERAY_VOB_IGNORE_NO_CD_DYN
                | zTRACERAY_POLY_TEST_WATER
                | zTRACERAY_POLY_IGNORE_TRANSP
                | zTRACERAY_VOB_IGNORE_PROJECTILES))) {
        // Set new position to intersection (point where the trace ray made contact with a polygon)
        pos[0] = addf(MEM_World.foundIntersection[0], mulf(cam.trafoObjToWorld[ 2], mkf(AIM_OBJ_OFFSET)));
        pos[1] = addf(MEM_World.foundIntersection[1], mulf(cam.trafoObjToWorld[ 6], mkf(AIM_OBJ_OFFSET)));
        pos[2] = addf(MEM_World.foundIntersection[2], mulf(cam.trafoObjToWorld[10], mkf(AIM_OBJ_OFFSET)));
    } else {
        // If nothing is in the way, set new position to max distance
        pos[0] = addf(pos[0], pos[3]);
        pos[1] = addf(pos[1], pos[4]);
        pos[2] = addf(pos[2], pos[5]);
    };
    var int vobPtr; vobPtr = getAimVob(_@(pos));
    var int ptr; ptr = ESP+12;
    MEM_WriteInt(ptr, vobPtr);
};

/*
 * Free "look" (hook framework).
 * This is not free aiming: Nothing regarding Y-Axis aiming is done here!
 * E.g. arrows will be shot according to the rotation, but still parallel to the ground irrespective of the up angle.
 */
var int crosshairHndl; // Hold the crosshair handle
var int aimModifier; // Modifies the mouse movement speed

/* Delete crosshair (hiding it is not sufficient, since it might change texture later) */
func void removeCrosshair_() {
    if (Hlp_IsValidHandle(crosshairHndl)) { View_Delete(crosshairHndl); };
};

/* "Light" version of removeCrosshair_ (hook into oCNpcFocus::SetFocusMode) */
func void removeCrosshair() {
    if (Npc_IsInFightMode(hero, FMODE_FAR)) || (Npc_IsInFightMode(hero, FMODE_MAGIC)) { return; };
    aimModifier = FLOATEINS; // Reset multiplier
    removeCrosshair_();
};

/* Function maintaining free look and crosshair  */
func void hookFreeLook(var int crosshairStyle) {
    // Only apply manual rotation when action button is held
    if (!MEM_KeyPressed(MEM_GetKey("keyAction")))
    && (!MEM_KeyPressed(MEM_GetSecondaryKey("keyAction"))) {
        removeCrosshair_();
        return;
    };
    // Set fancy crosshair
    if (crosshairStyle > 1) {
        if (!Hlp_IsValidHandle(crosshairHndl)) {
            Print_GetScreenSize();
            var int posX; posX = Print_Screen[PS_X] / 2;
            var int posY; posY = Print_Screen[PS_Y] / 2;
            crosshairHndl = View_CreatePxl(posX-32, posY-32, posX+32, posY+32);
            var String crosshairTex; crosshairTex = MEM_ReadStatStringArr(crosshair, crosshairStyle);
            View_SetTexture(crosshairHndl, crosshairTex);
            View_Open(crosshairHndl);
        } else {
            var zCView crsHr; crsHr = _^(getPtr(crosshairHndl));
            if (!crsHr.isOpen) { View_Open(crosshairHndl); };
        };
    } else { removeCrosshair_(); };
    // Manually enable rotation around y-axis
    if (!aimModifier) { aimModifier = FLOATEINS; };
    var int frameAdj; frameAdj = divf(MEM_Timer.frameTimeFloat, mkf(10)); // It adjusts speed to fps (~= frame lock)
    updateHeroYrot(aimModifier);
};

/* Hook function when ranged weapon is drawn (hook into oCAIHuman::BowMode) */
func void hookFreeLook_ranged() {
    Focus_Ranged.npc_prio = -1; // Disable focus collection
    aimModifier = FLOATEINS; // TODO: Adjust aimModifier like in Spell_Blink.d: slower in distance, faster in proximity
    hookFreeLook(NORMAL_CROSSHAIR);
};

/* Hook function when spell is drawn (hook into oCAIHuman::MagicMode) */
func void hookFreeLook_magic() {
    // Get spell-specific crosshair (Constants.d)
    var int activeSpell; activeSpell = Npc_GetActiveSpell(hero);
    if (!MEM_ReadStatArr(spellTurnable, activeSpell)) {
        removeCrosshair_();
        return;
    };
    hookFreeLook(MEM_ReadStatArr(spellTurnable, activeSpell));
};
