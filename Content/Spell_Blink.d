// *********************
// SPL_Blink (mud-freak)
// *********************

const int SPL_COST_BLINK        =   10; // Mana cost. Can be freely adjusted.
const int STEP_BLINK            =    1; // STEP_BLINK * time_per_mana = time before "arming" the spell.
const int SPL_BLINK_MAXDIST     = 1000; // Maximum distance (cm) to traverse. Can be freely adjusted.
const int SPL_BLINK_OBJDIST     =   75; // Set by PFX radius. Do not touch.

/* Do NOT change any of these settings. Some might seem non-sensical but each of them is very important! */
INSTANCE Spell_Blink (C_Spell_Proto) {
    time_per_mana               = 500; // Time (ms): STEP_BLINK * time_per_mana = ramp up time.
    damage_per_level            = 0;
    spelltype                   = SPELL_NEUTRAL;
    targetCollectAlgo           = TARGET_COLLECT_FOCUS_FALLBACK_CASTER; // Do not change
    targetCollectType           = TARGET_TYPE_ITEMS; // Do not change
    canChangeTargetDuringInvest = 0; // Do not change
    //targetCollectRange          = 0;
    //targetCollectAzi            = 0;
    //targetCollectElev           = 0;
};

func int Spell_Logic_Blink(var int manaInvested) {
    // Not enough mana; only hero is allowed to use this spell
    if (self.attribute[ATR_MANA] < STEP_BLINK) || (!Npc_IsPlayer(self)) { return SPL_DONTINVEST; };

    // Two levels: Build up spell, create aim vob/start passive invest loop
    // The first level is purely aesthetic. Without it the aim FX would be started instantly.
    if (manaInvested < STEP_BLINK) {
        self.aivar[AIV_SpellLevel] = 1; // Start with lvl 1
        return SPL_STATUS_CANINVEST_NO_MANADEC;
    } else if (manaInvested >= STEP_BLINK) && (self.aivar[AIV_SpellLevel] < 2) {
        self.aivar[AIV_SpellLevel] = 2;
        return SPL_NEXTLEVEL; // Reach level 2 (meaning from here on the spell is "armed" and the aim FX shows)
    };

    // Aiming does not cost mana
    return SPL_STATUS_CANINVEST_NO_MANADEC;
};

func void Spell_Invest_Blink_new() {
    if (!Npc_IsPlayer(self)) { return; }; // Only player is allowed to use this spell
    MEM_InitGlobalInst(); // This is necessary here to find the camera vob, although it was called in init_global. Why?
    var zCVob cam; cam = _^(MEM_Camera.connectedVob);
    var zCVob slf; slf = Hlp_GetNpc(self);
    // Prepare vob variables
    var String vobname; vobname = ConCatStrings("BlinkObj_", IntToString(MEM_ReadInt(_@(slf)+MEM_NpcID_Offset)));
    var int vobPtr; vobPtr = MEM_SearchVobByName(vobname);
    const int zCVob__SetPositionWorld = 6404976; //0x61BB70
    if (!vobPtr) { // Aim vob should not exist at this point
        // Create and name aim vob (NEEDS to be an item, because of focus)
        vobPtr = MEM_Alloc(840); // sizeof_oCItem
        const int oCItem__oCItem = 7410320; //0x711290
        CALL__thiscall(vobPtr, oCItem__oCItem);
/*        const int oCItem__oCItem = 7410800;
        CALL_IntParam(1);
        CALL_zStringPtrParam("ITMI_STOMPER");
        CALL__thiscall(vobPtr, oCItem__oCItem);*/

/*        vobPtr = MEM_Alloc(sizeof_zCVob);
        const int oCVob__oCVob = 7845536; //0x77B6A0
        CALL__thiscall(vobPtr, oCVob__oCVob);*/

/*        const int zCVob__SetVisual = 6301312; //0x602680
        CALL_zStringPtrParam("NW_NATURE_BAUMSTUMPF_02_115P.3DS");
        CALL__thiscall(vobPtr, zCVob__SetVisual);*/

        MEM_WriteString(vobPtr+16, vobname); // _zCObject_objectName
        // Set temporary position (on hero)
        var int posN[6];
        posN[0] = slf.trafoObjToWorld[ 3];
        posN[1] = slf.trafoObjToWorld[ 7];
        posN[2] = slf.trafoObjToWorld[11];
        CALL_PtrParam(_@(posN));
        CALL__thiscall(vobPtr, zCVob__SetPositionWorld);
        // Insert aim vob into world
        const int oCWorld__AddVobAsChild = 7863856; //0x77FE30
        CALL_PtrParam(_@(MEM_Vobtree));
        CALL_PtrParam(vobPtr);
        CALL__thiscall(_@(MEM_World), oCWorld__AddVobAsChild);
    };

    // Manually enable rotation around y-axis
    //if (!aimModifier) { aimModifier = FLOATEINS; };
    var int frameAdj; frameAdj = divf(MEM_Timer.frameTimeFloat, mkf(10)); // It adjusts speed to fps (~= frame lock)
    //updateHeroYrot(mulf(aimModifier, frameAdj));

    // Set trace ray (start from caster and go along the outvector of the camera vob)
    var int pos[6]; // Combined pos[3] + dir[3]
    pos[0] = slf.trafoObjToWorld[ 3];  pos[3] = mulf(cam.trafoObjToWorld[ 2], mkf(SPL_BLINK_MAXDIST));
    pos[1] = slf.trafoObjToWorld[ 7];  pos[4] = mulf(cam.trafoObjToWorld[ 6], mkf(SPL_BLINK_MAXDIST));
    pos[2] = slf.trafoObjToWorld[11];  pos[5] = mulf(cam.trafoObjToWorld[10], mkf(SPL_BLINK_MAXDIST));

    // Shoot trace ray
    if (TraceRay(_@(pos), _@(pos)+12, // From caster to max distance
            (zTRACERAY_VOB_IGNORE_NO_CD_DYN | zTRACERAY_POLY_TEST_WATER | zTRACERAY_POLY_IGNORE_TRANSP))) {
        // Set new position to intersection (point where the trace ray made contact with a polygon)
        pos[0] = MEM_World.foundIntersection[0];
        pos[1] = MEM_World.foundIntersection[1];
        pos[2] = MEM_World.foundIntersection[2];
    } else {
        // If nothing is in the way, set new position to max distance
        pos[0] = addf(pos[0], pos[3]);
        pos[1] = addf(pos[1], pos[4]);
        pos[2] = addf(pos[2], pos[5]);
    };
    // Substract OBJDIST to get away from intersection (do it also if there was no intersection, to make it smoother)
    pos[0] = subf(pos[0], mulf(cam.trafoObjToWorld[ 2], mkf(SPL_BLINK_OBJDIST))); // Pos = pos - (dir * OBJDIS)
    pos[1] = subf(pos[1], mulf(cam.trafoObjToWorld[ 6], mkf(SPL_BLINK_OBJDIST)));
    pos[2] = subf(pos[2], mulf(cam.trafoObjToWorld[10], mkf(SPL_BLINK_OBJDIST)));

    // Update aim vob position (FX will tag along)
    CALL_PtrParam(_@(pos));
    CALL__thiscall(vobPtr, zCVob__SetPositionWorld);

    // Get distance for aim multiplier. For smoother aiming: slower in distance, faster in proximity
    var int dx; dx = subf(pos[0], slf.trafoObjToWorld[ 3]);
    var int dy; dy = subf(pos[1], slf.trafoObjToWorld[ 7]);
    var int dz; dz = subf(pos[2], slf.trafoObjToWorld[11]);
    var int dist3d; dist3d = sqrtf(addf(addf(sqrf(dx), sqrf(dy)), sqrf(dz))); // Simply the euclidean distance
    //aimModifier = subf(FLOATEINS, divf(dist3d, mkf(SPL_BLINK_MAXDIST*2))); // 1 - (dist * (maxdist * 2))

    const int oCNpc__GetSpellBook = 7596544; //0x73EA00
    CALL__thiscall(_@(slf), oCNpc__GetSpellBook);
    var int mbok; mbok = CALL_RetValAsPtr();

    const int oCMag_Book__GetSelectedSpell = 4683648; //0x477780
    CALL__thiscall(mbok, oCMag_Book__GetSelectedSpell);
    var int spellPtr; spellPtr = CALL_RetValAsPtr();

    var oCSpell curSpell; curSpell = _^(spellPtr);
    curSpell.spellTargetNpc = vobPtr;
    curSpell.spellTarget = vobPtr;

/*    const int oCNpc__SetFocusVob = 7547744; //0x732B60
    CALL_PtrParam(vobPtr);
    CALL__thiscall(_@(slf), oCNpc__SetFocusVob);*/

/*    // Set focus vob (core of this function)
    const int oCNpc__SetFocusVob = 7547744; //0x732B60
    CALL_PtrParam(vobPtr);
    CALL__thiscall(_@(slf), oCNpc__SetFocusVob);*/


/*    const int oCSpell__IsValidTarget = 4743632; //0x4861D0
    CALL_PtrParam(vobPtr);
    CALL__thiscall(spellPtr, oCSpell__IsValidTarget);
    var int valVob; valVob = CALL_RetValAsInt();
    MEM_Info(ConCatStrings("### is valid vob: ", IntToString(valVob)));*/

    // Set target vob
    MEM_WriteInt(ESP+12, vobPtr);
};

func void Spell_Invest_Blink_new_IVT() {
    if (!Npc_IsPlayer(self)) { return; }; // Only player is allowed to use this spell
    var zCVob slf; slf = Hlp_GetNpc(self);
    var String vobname; vobname = ConCatStrings("BlinkObj_", IntToString(MEM_ReadInt(_@(slf)+MEM_NpcID_Offset)));
    var int vobPtr; vobPtr = MEM_SearchVobByName(vobname);

    const int oCNpc__GetSpellBook = 7596544; //0x73EA00
    CALL__thiscall(_@(slf), oCNpc__GetSpellBook);
    var int mbok; mbok = CALL_RetValAsPtr();

    const int oCMag_Book__GetSelectedSpell = 4683648; //0x477780
    CALL__thiscall(mbok, oCMag_Book__GetSelectedSpell);
    var int spellPtr; spellPtr = CALL_RetValAsPtr();

    var oCSpell curSpell; curSpell = _^(spellPtr);
    curSpell.spellTargetNpc = vobPtr;
    curSpell.spellTarget = vobPtr;

/*    if (!vobPtr) {
        const int oCNpc__ClearFocusVob = 7547840; //0x732BC0
        CALL__thiscall(_@(slf), oCNpc__ClearFocusVob);
    } else {
        const int oCNpc__SetFocusVob = 7547744; //0x732B60
        CALL_PtrParam(vobPtr);
        CALL__thiscall(_@(slf), oCNpc__SetFocusVob);
    };*/

    MEM_WriteInt(ESP+4, vobPtr);
};

func void Spell_Cast_Blink(var int spellLevel) {
    // Retrieve position from aim vob
    var int vobPtr; vobPtr = MEM_SearchVobByName(ConCatStrings("BlinkObj_", IntToString(self.id)));
    if (!vobPtr) {
        // MEM_Error("Blink: Failed to retrieve destination (aim vob)"); // Don't break immersion
        AI_PlayAni(self, "T_CASTFAIL"); // Much nicer
        Wld_PlayEffect("SPELLFX_FEAR_GROUND", self, self, 0, 0, 0, FALSE);
        MEM_Warn("Blink: Failed to retrieve destination (aim vob)");
        return;
    };
    var zCVob vob; vob = _^(vobPtr);
    var zCVob caster; caster = Hlp_GetNpc(self);
    var int pos[6]; // Combined pos[3] and dir[3]
    pos[0] = vob.trafoObjToWorld[ 3];   pos[3] = caster.trafoObjToWorld[ 2];
    pos[1] = vob.trafoObjToWorld[ 7];   pos[4] = caster.trafoObjToWorld[ 6];
    pos[2] = vob.trafoObjToWorld[11];   pos[5] = caster.trafoObjToWorld[10];

    // Delete aim vob from world
    const int oCWorld__RemoveVob = 7864512; //0x7800C0
    CALL_PtrParam(vobPtr);
    CALL__thiscall(_@(MEM_World), oCWorld__RemoveVob);
    vobPtr = 0; // Don't free vobPtr. Seems to be done in zCWorld::RemoveVob

    // Spell was aborted by caster before it started (ramp up not finished)
    if (spellLevel < 2) { return; };

    // Check if destination wp already exists (from last cast)
    const int zCWayNet__GetWaypoint = 8061744; //0x7B0330
    CALL__fastcall(_@(MEM_Waynet), _@s(ConCatStrings("WP_BLINKOBJ_", IntToString(self.id))), zCWayNet__GetWaypoint);
    var int wpPtr; wpPtr = CALL_RetValAsInt();
    if (wpPtr) { // Delete old wp first
        const int zCWayNet__DeleteWaypoint = 8049328; //0x7AD2B0
        CALL_PtrParam(wpPtr);
        CALL__thiscall(_@(MEM_Waynet), zCWayNet__DeleteWaypoint);
    };

    // Create wp (wp cannot be deleted afterwards, because AI_Teleport won't find it)
    wpPtr = MEM_Alloc(124); // sizeof_zCWaypoint
    const int zCWaypoint__zCWaypoint = 8058736; //0x7AF770
    CALL__thiscall(wpPtr, zCWaypoint__zCWaypoint);
    // Set position and name wp (position needs to be added before adding it to the waynet)
    MEM_CopyWords(_@(pos), wpPtr+68, 6);
    const int zCWaypoint__SetName = 8059824; //0x7AFBB0
    CALL_zStringPtrParam(ConCatStrings("WP_BLINKOBJ_", IntToString(self.id)));
    CALL__thiscall(wpPtr, zCWaypoint__SetName);
    // Insert wp into waynet (won't be connect to any other wp)
    const int zCWayNet__InsertWaypoint = 8048896; //0x7AD100
    CALL_PtrParam(wpPtr);
    CALL__thiscall(_@(MEM_Waynet), zCWayNet__InsertWaypoint);

    // Decrease mana (the usual)
    if (Npc_GetActiveSpellIsScroll(self)) {
        self.attribute[ATR_MANA] -= SPL_Cost_Scroll;
    } else {
        self.attribute[ATR_MANA] -= SPL_COST_BLINK;
    };
    if (self.attribute[ATR_MANA] < 0) { self.attribute[ATR_MANA] = 0; };
    self.aivar[AIV_SelectSpell] += 1; // Since NPCs can't use this spell, this is just for completeness

    // Teleport to wp
    AI_Teleport(self, ConCatStrings("WP_BLINKOBJ_", IntToString(self.id)));
    // AI_PlayAni(self, "T_HEASHOOT_2_STAND"); // Not working here. AI_Teleport clears EM (AI queue)
};

/* Invest loop (hooked BEFORE/DURING invest loop). Manage aim vob and mouse movement
 * This is not included in the normal spell invest loop, because it needs to be called every frame. Otherwise the aiming
 * stutters. When calling a spell invest loop (Spell_Logic_Blink) every frame (time_per_mana = 0) it gets unstable!
 * Always keep that number above 30 at the minimum.
 *
 * The function does the following.
 * 1. Retrieve (or create) aim vob
 * 2. Update mouse movement
 * 3. Shoot trace ray from caster along the camera axis
 * 4. Position aim vob at end (intersection) of trace ray
 * 5. Get distance to aim vob for mouse movement multiplier
 */
var int lastMouseUpdate; // Stores time of last mouse update
func void Spell_Invest_Blink() {
    var zCVob her; her = Hlp_GetNpc(hero);
    // If the spell is not blink
    if (Npc_GetActiveSpell(her) != SPL_Blink) { return; };
    MEM_InitGlobalInst(); // This is necessary here to find the camera vob, although it was called in init_global. Why?
    var zCVob cam; cam = _^(MEM_Camera.connectedVob);
    // Prepare vob variables
    var String vobname; vobname = ConCatStrings("BlinkObj_", IntToString(MEM_ReadInt(_@(her)+MEM_NpcID_Offset)));
    var int vobPtr; vobPtr = MEM_SearchVobByName(vobname);
    const int zCVob__SetPositionWorld = 6404976; //0x61BB70
    if (!vobPtr) { // Aim vob should not exist at this point
        // Create and name aim vob (NEEDS to be an item, because of focus)
        vobPtr = MEM_Alloc(840); // sizeof_oCItem
        const int oCItem__oCItem = 7410320; //0x711290
        CALL__thiscall(vobPtr, oCItem__oCItem);
        MEM_WriteString(vobPtr+16, vobname); // _zCObject_objectName
        // Set temporary position (on hero)
        var int posN[6];
        posN[0] = her.trafoObjToWorld[ 3];
        posN[1] = her.trafoObjToWorld[ 7];
        posN[2] = her.trafoObjToWorld[11];
        CALL_PtrParam(_@(posN));
        CALL__thiscall(vobPtr, zCVob__SetPositionWorld);
        // Insert aim vob into world
        const int oCWorld__AddVobAsChild = 7863856; //0x77FE30
        CALL_PtrParam(_@(MEM_Vobtree));
        CALL_PtrParam(vobPtr);
        CALL__thiscall(_@(MEM_World), oCWorld__AddVobAsChild);
    };

    // Manually enable rotation around y-axis
    //if (!aimModifier) { aimModifier = FLOATEINS; };
    var int frameAdj; frameAdj = divf(MEM_Timer.frameTimeFloat, mkf(10)); // It adjusts speed to fps (~= frame lock)
    // Outsourced since it might be useful for other spells/weapons as well (free aim)
    //updateHeroYrot(mulf(aimModifier, frameAdj));

    // Set trace ray (start from caster and go along the outvector of the camera vob)
    var int pos[6]; // Combined pos[3] + dir[3]
    pos[0] = her.trafoObjToWorld[ 3];  pos[3] = mulf(cam.trafoObjToWorld[ 2], mkf(SPL_BLINK_MAXDIST));
    pos[1] = her.trafoObjToWorld[ 7];  pos[4] = mulf(cam.trafoObjToWorld[ 6], mkf(SPL_BLINK_MAXDIST));
    pos[2] = her.trafoObjToWorld[11];  pos[5] = mulf(cam.trafoObjToWorld[10], mkf(SPL_BLINK_MAXDIST));

    // Shoot trace ray
    if (TraceRay(_@(pos), _@(pos)+12, // From caster to max distance
            (zTRACERAY_VOB_IGNORE_NO_CD_DYN | zTRACERAY_POLY_TEST_WATER | zTRACERAY_POLY_IGNORE_TRANSP))) {
        // Set new position to intersection (point where the trace ray made contact with a polygon)
        pos[0] = MEM_World.foundIntersection[0];
        pos[1] = MEM_World.foundIntersection[1];
        pos[2] = MEM_World.foundIntersection[2];
    } else {
        // If nothing is in the way, set new position to max distance
        pos[0] = addf(pos[0], pos[3]);
        pos[1] = addf(pos[1], pos[4]);
        pos[2] = addf(pos[2], pos[5]);
    };
    // Substract OBJDIST to get away from intersection (do it also if there was no intersection, to make it smoother)
    pos[0] = subf(pos[0], mulf(cam.trafoObjToWorld[ 2], mkf(SPL_BLINK_OBJDIST))); // Pos = pos - (dir * OBJDIS)
    pos[1] = subf(pos[1], mulf(cam.trafoObjToWorld[ 6], mkf(SPL_BLINK_OBJDIST)));
    pos[2] = subf(pos[2], mulf(cam.trafoObjToWorld[10], mkf(SPL_BLINK_OBJDIST)));

    // Update aim vob position (FX will tag along)
    CALL_PtrParam(_@(pos));
    CALL__thiscall(vobPtr, zCVob__SetPositionWorld);

    // Get distance for aim multiplier. For smoother aiming: slower in distance, faster in proximity
    var int dx; dx = subf(pos[0], her.trafoObjToWorld[ 3]);
    var int dy; dy = subf(pos[1], her.trafoObjToWorld[ 7]);
    var int dz; dz = subf(pos[2], her.trafoObjToWorld[11]);
    var int dist3d; dist3d = sqrtf(addf(addf(sqrf(dx), sqrf(dy)), sqrf(dz))); // Simply the euclidean distance
    //aimModifier = subf(FLOATEINS, divf(dist3d, mkf(SPL_BLINK_MAXDIST*2))); // 1 - (dist * (maxdist * 2))

    // Set focus vob (core of this function)
    const int oCNpc__SetFocusVob = 7547744; //0x732B60
    CALL_PtrParam(vobPtr);
    CALL__thiscall(_@(her), oCNpc__SetFocusVob);
};


func void EXTRA() {
    var string infoStr;
    infoStr = "### Spell_Invest_Blink ###";
    if (Hlp_IsValidNpc(self)) {
        infoStr = ConcatStrings(infoStr, " Caster: ");
        infoStr = ConcatStrings(infoStr, self.name);
    };
    if (Hlp_IsValidNpc(other)) {
        infoStr = ConcatStrings(infoStr, " Target(NPC): ");
        infoStr = ConcatStrings(infoStr, other.name);
    };
    if (Hlp_IsValidItem(item)) {
        infoStr = ConcatStrings(infoStr, " Target(item): ");
        infoStr = ConcatStrings(infoStr, item.name);
    };
    MEM_Info(infoStr);
};



// Start effect?
// (*(void (__stdcall **)(zCVob *, int, int))(v16 + 148))(a2, v47, v48);
// Modify effect?
// (*(void (__stdcall **)(zCVob *, zCVob *, _DWORD))(*(_DWORD *)v5->effect + 148))(a2, a2, 0);


