// ***********************************************************************************************************
// Spell_ProcessInvest
// -------------------
// is called when the Spell is being cast. For instant spells this function is called once, for invest spells
// it is called every frame (so multiple times) for the duration of investing the spell. This function does
// the same as the Spell_Logic_* function, with the small difference that it can be called (reliably) every
// frame (the Spell_Logic_* functions are very unstable for time_per_mana below 30). Additionally the effect
// or targets can be manupulated here because this function is hooked infront of the creation of the FX.
// Utilize this distributor function like it is done in Spell_ProcessMana and Spell_ProcessMana_Release.
// Place any spells in here that benefit from this additional control. Spells that don't. should not be
// listed here. The consecutive functions will have access to:
// self     = caster
// other    = target (if target is NPC)
// item     = target (if target is item)
// ***********************************************************************************************************

const int oCAniCtrl_Human__IsInCastAni = 7047264; //0x6B8860

func void Spell_ProcessInvest() {

    // Get self and other (or item)
    self = _^(MEM_ReadInt(ESP+4)); // Self is a global instance (Classes.d) and will stay set in the functions below
    var int targetPtr; targetPtr = MEM_ReadInt(ESP+8);
    if (Hlp_Is_oCNpc(targetPtr)) { other = _^(targetPtr); } // Other will stay set in the functions below
    else if (Hlp_Is_oCItem(targetPtr)) { item = _^(targetPtr); }; // Same for item
    // Figure out if spell is actually being invested (or just opened for example)
    CALL__thiscall(MEM_ReadInt(_@(self)+2432), oCAniCtrl_Human__IsInCastAni); // 0x0980 oCNpc.anictrl
    if (!CALL_RetValAsInt()) { return; };
    // From here on it's the usual (like in Spell_ProcessMana and Spell_ProcessManaRelease)


    var int activeSpell; activeSpell = Npc_GetActiveSpell(self);

    // ------ Spells, that cast after letting go of the key ------
    if (activeSpell == SPL_Blink            )   {   Spell_Invest_Blink_new(); return;   };
    // ...



    // ------ All other spells don't need to hook the function and should not be listed here ------
};
