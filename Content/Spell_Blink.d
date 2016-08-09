// *********************
// SPL_Blink (mud-freak)
// *********************

const int SPL_COST_BLINK     =   10; // Mana cost. Can be freely adjusted.
const int STEP_BLINK         =   10; // "Time" before creating aim vob. Kepp in synch with the invest ani duration.
const int SPL_BLINK_MAXDIST  = 1000; // Maximum distance (cm) to blink. Can be freely adjusted.
const int SPL_BLINK_OBJDIST  =   75; // Set by PFX radius. Do not touch.

INSTANCE Spell_Blink (C_Spell_Proto) {
    time_per_mana            = 20; // STEP_BLINK * time_per_mana + time_per_mana = ramp up time.
    damage_per_level         = 0;
    spelltype                = SPELL_NEUTRAL;
    canTurnDuringInvest      = 1; // Not working. For a hack see updateHeroYrot()
    targetCollectAlgo        = TARGET_COLLECT_NONE;
    targetCollectRange       = 0;
    targetCollectAzi         = 0;
    targetCollectElev        = 0;
};

func int Spell_Logic_Blink(var int manaInvested) {
    // Not enough mana
    if (self.attribute[ATR_MANA] < STEP_BLINK) {
        return SPL_DONTINVEST;
    };

    // Aim vob variables
    var int vobPtr; var zCVob vob;
    vobPtr = MEM_SearchVobByName(ConCatStrings("BlinkObj_", IntToString(self.id)));

    // Manually enable rotation around y-axis
    if (!aimModifier) { aimModifier = FLOATEINS; };
    updateHeroYrot(aimModifier); // Outsourced to hook since it might be useful for other spells/weapons as well

    if (manaInvested <= STEP_BLINK*1) {

        // Ramp up (waiting for invest ani): Nothing happens. The caster "builds up" the spell (called several times)
        self.aivar[AIV_SpellLevel] = 1; // Start with lvl 1

        // Small fix in case a vob is caught in focus (happens rarely when switching between spells very fast)
        if Npc_IsPlayer(self) {
            var oCNPC slf; slf = Hlp_GetNpc(self);
            slf.focus_vob = 0;
        };

        return SPL_STATUS_CANINVEST_NO_MANADEC;
    } else if (manaInvested > (STEP_BLINK*1)) && (self.aivar[AIV_SpellLevel] <= 1) {
        // After ramp up time: Create aim vob (called exactly once)

        if (!vobPtr) {
            // Create aim vob
            vobPtr = MEM_Alloc(sizeof_zCVob);
            const int zCVob__zCVob = 6283744; //0x5FE1E0
            CALL__thiscall(vobPtr, zCVob__zCVob);
            vob = _^(vobPtr); vob._zCObject_objectName = ConCatStrings("BlinkObj_", IntToString(self.id));
            // Insert into world
            const int zCWorld__AddVobAsChild = 6440352; //0x6245A0
            CALL_PtrParam(_@(MEM_Vobtree));
            CALL_PtrParam(vobPtr);
            CALL__thiscall(_@(MEM_World), zCWorld__AddVobAsChild);
        };
        vob = _^(vobPtr);

        Wld_StopEffect("SPELLFX_BLINK_DESTINATION"); // Remove effect if exists first
        Wld_PlayEffect("SPELLFX_BLINK_DESTINATION", vob, vob, 0, 0, 0, FALSE); // FX stays attached to moving aim vob

        // Moved: I was teleported to the origin (0, 0, 0) of the map once. Set spell lvl AFTER position is set.
        //self.aivar[AIV_SpellLevel] = 2;
        //return SPL_NEXTLEVEL; // Reach lvl 2
    };

    // Spell ramp up is over. The following is called every iteration (after creation of aim vob).
    MEM_InitGlobalInst(); // This is necessary here to find the camera vob, although it was called in init_global. Why?

    // Get caster and camera vob
    var zCVob caster; caster = Hlp_GetNpc(self);
    var zCVob cam; cam = _^(MEM_Camera.connectedVob);

    // Set trace ray (start from caster and go along the outvector of the camera vob)
    var int pos[6]; // Combined pos[3] + dir[3]
    pos[0] = caster.trafoObjToWorld[ 3];  pos[3] = mulf(cam.trafoObjToWorld[ 2], mkf(SPL_BLINK_MAXDIST));
    pos[1] = caster.trafoObjToWorld[ 7];  pos[4] = mulf(cam.trafoObjToWorld[ 6], mkf(SPL_BLINK_MAXDIST));
    pos[2] = caster.trafoObjToWorld[11];  pos[5] = mulf(cam.trafoObjToWorld[10], mkf(SPL_BLINK_MAXDIST));

    // Shoot trace ray
    if (TraceRay(_@(pos), _@(pos)+12, // From caster to max distance
            (zTRACERAY_VOB_IGNORE_NO_CD_DYN         // Ignore dynamic vobs (like NPCs)
                | zTRACERAY_POLY_TEST_WATER         // Hit water
                | zTRACERAY_POLY_NORMAL             // Calculate normal vector (actually not needed here)
                | zTRACERAY_POLY_IGNORE_TRANSP))) { // Ignore alpha objects (invisible objects)
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
    // POS = POS - (DIR * OBJDIS)
    pos[0] = subf(pos[0], mulf(cam.trafoObjToWorld[ 2], mkf(SPL_BLINK_OBJDIST)));
    pos[1] = subf(pos[1], mulf(cam.trafoObjToWorld[ 6], mkf(SPL_BLINK_OBJDIST)));
    pos[2] = subf(pos[2], mulf(cam.trafoObjToWorld[10], mkf(SPL_BLINK_OBJDIST)));

    // Update aim vob position (FX will tag along)
    const int zCVob__SetPositionWorld = 6404976; //0x61BB70
    CALL_PtrParam(_@(pos));
    CALL__thiscall(vobPtr, zCVob__SetPositionWorld);

    // Get distance for aim multiplier. For smoother aiming: slower in distance, faster in proximity
    var int dx; dx = subf(pos[0], caster.trafoObjToWorld[ 3]);
    var int dy; dy = subf(pos[1], caster.trafoObjToWorld[ 7]);
    var int dz; dz = subf(pos[2], caster.trafoObjToWorld[11]);
    var int dist3d; dist3d = sqrtf(addf(addf(sqrf(dx), sqrf(dy)), sqrf(dz)));
    aimModifier = subf(FLOATEINS, divf(dist3d, mkf(SPL_BLINK_MAXDIST*2)));

    // First time after aim vob creation
    if (self.aivar[AIV_SpellLevel] <= 1) {
        self.aivar[AIV_SpellLevel] = 2;
        return SPL_NEXTLEVEL; // Reach lvl 2
    };

    // Aiming does not cost mana
    return SPL_STATUS_CANINVEST_NO_MANADEC;
};

func void Spell_Cast_Blink(var int spellLevel) {
    // Remove aim FX
    Wld_StopEffect("SPELLFX_BLINK_DESTINATION");

    // Spell was aborted by caster before it started (ramp up not finished)
    if (spellLevel < 2) { return; };

    // Retrieve position from aim vob
    var int vobPtr; vobPtr = MEM_SearchVobByName(ConCatStrings("BlinkObj_", IntToString(self.id)));
    if (!vobPtr) {
        // MEM_Error("Blink: Failed to retrieve destination (aim vob)"); // Don't break immersion
        AI_PlayAni(self, "T_CASTFAIL");
        Wld_PlayEffect("SPELLFX_BLINK_FAIL", self, self, 0, 0, 0, FALSE);
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
    const int zCWorld__RemoveVob = 6441840; //0x624B70
    CALL_PtrParam(vobPtr);
    CALL__thiscall(_@(MEM_World), zCWorld__RemoveVob);
    vobPtr = 0; // Don't free vobPtr. Seems to be done in zCWorld::RemoveVob

    // Check for wp
    const int zCWayNet__GetWaypoint = 8061744; //0x7B0330
    CALL__fastcall(_@(MEM_Waynet), _@s(ConCatStrings("WP_BLINKOBJ_", IntToString(self.id))), zCWayNet__GetWaypoint);
    var int wpPtr; wpPtr = CALL_RetValAsInt();
    if (wpPtr) { // Delete old wp
        const int zCWayNet__DeleteWaypoint = 8049328; //0x7AD2B0
        CALL_PtrParam(wpPtr);
        CALL__thiscall(_@(MEM_Waynet), zCWayNet__DeleteWaypoint);
    };

    // Create wp
    wpPtr = MEM_Alloc(124); // sizeof_zCWaypoint
    const int zCWaypoint__zCWaypoint = 8058736; //0x7AF770
    CALL__thiscall(wpPtr, zCWaypoint__zCWaypoint);
    // Set position
    MEM_CopyWords(_@(pos), wpPtr+68, 6);
    // Name wp
    const int zCWaypoint__SetName = 8059824; //0x7AFBB0
    CALL_zStringPtrParam(ConCatStrings("WP_BLINKOBJ_", IntToString(self.id)));
    CALL__thiscall(wpPtr, zCWaypoint__SetName);
    // Insert into waynet
    const int zCWayNet__InsertWaypoint = 8048896; //0x7AD100
    CALL_PtrParam(wpPtr);
    CALL__thiscall(_@(MEM_Waynet), zCWayNet__InsertWaypoint);

    // Decrease mana (the usual)
    self.attribute[ATR_MANA] -= SPL_COST_BLINK;
    if (self.attribute[ATR_MANA] < 0) {
        self.attribute[ATR_MANA] = 0;
    };
    self.aivar[AIV_SelectSpell] += 1;

    // Teleport to wp
    AI_Teleport(self, ConCatStrings("WP_BLINKOBJ_", IntToString(self.id)));
    // AI_PlayAni(self, "T_HEASHOOT_2_STAND"); // Not working here. AI_Teleport clears EM (AI queue)
};
