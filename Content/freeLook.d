/*
 * Manually rotate the hero
 */

/* Turn hero (incl. camera if attached) by degrees (in float) */
func void turnHero(var int degreesf) {
    var oCNPC her; her = Hlp_GetNpc(hero);
    const int oCAniCtrl_Human__TurnDegrees = 7006992; //0x6AEB10
    CALL_IntParam(0); // 0 = disable turn animation
    CALL_FloatParam(degreesf);
    CALL__thiscall(her.anictrl, oCAniCtrl_Human__TurnDegrees);
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
    // disp += 1;
    // if (disp > 50) {
    //     MEM_Info(ConcatStrings(ConcatStrings(IntToString(MEM_Timer.totalTime - timeM), ". IFI: "), toStringf(MEM_Timer.frameTimeFloat)));
    //     disp = 0;
    // };
    // timeM = MEM_Timer.totalTime;

    var int xChng; xChng = getMouseMove(0); // Change in x position
    if (xChng == FLOATNULL) { return; };
    turnHero(mulf(xChng, mod));
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
