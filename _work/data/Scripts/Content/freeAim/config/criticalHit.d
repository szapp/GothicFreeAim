/*
 * This file contains all configurations for critical hits for bows and crossbows.
 */

/*
 * This function is called every time (any kind of) npc is hit by a projectile (arrows and bolts) to determine, whether
 * a critical hit occured. This function returns a defintion of the critical hit area (weakspot) based on the npc that
 * it hit or the weapon used. A weakspot is defined by its bone, size and modified damage.
 * Here, preliminary weakspots for almost all Gothic 2 monsters are defined (all headshots).
 */
func void freeAimCriticalHitDef(var C_Npc target, var C_Item weapon, var int damage, var int rtrnPtr) {
    var Weakspot weakspot; weakspot = _^(rtrnPtr);
    // This function is dynamic: It is called on every hit and the weakspot and damage can be calculated individually
    // Possibly incorporate weapon-specific stats, headshot talent, dependency on target, ...
    // The damage may depend on the target npc (e.g. different damage for monsters). Make use of 'target' argument
    //  if (target.guild < GIL_SEPERATOR_HUM) { }; // E.g. special case for humans
    // The weapon can also be considered (e.g. weapon specific damage). Make use of 'weapon' for that
    // Caution: Weapon may have been unequipped already at this time (unlikely)! Use Hlp_IsValidItem(weapon) to check
    //  if (Hlp_IsValidItem(weapon)) && (weapon.certainProperty > 10) { }; // E.g. special case for weapon property
    // The damage is a float and represents the new base damage (damage of weapon), not the final damage!
    weakspot.node = "Bip01 Head"; // Upper/lower case is not important, but spelling and spaces are
    weakspot.bDmg = mulf(damage, castToIntf(1.5)); // Increase the base damage. This is a float
    if (target.guild < GIL_SEPERATOR_HUM)
    || ((target.guild > GIL_SEPERATOR_ORC) && (target.guild < GIL_DRACONIAN))
    || (target.guild == GIL_ZOMBIE)
    || (target.guild == GIL_SUMMONEDZOMBIE) {
        // Here is also room for story-dependent exceptions (e.g. a specific npc may have a different weak spot)
        weakspot.dimX = -1; // Retrieve from model (works only on humanoids and only for head node!)
        weakspot.dimY = -1;
    } else if (target.guild == GIL_BLOODFLY) // Bloodflys and meatbugs don't have a head node
    || (target.guild == GIL_MEATBUG)
    || (target.guild == GIL_STONEGUARDIAN) // Stoneguardians have too large heads (head node is not centered)
    || (target.guild == GIL_SUMMONEDGUARDIAN)
    || (target.guild == GIL_STONEGOLEM) // Same for golems
    || (target.guild == GIL_FIREGOLEM)
    || (target.guild == GIL_ICEGOLEM)
    || (target.guild == GIL_SUMMONED_GOLEM)
    || (target.guild == GIL_SWAMPGOLEM)
    || (target.guild == GIL_SKELETON) // Skeletons are only bones, there is no critical hit
    || (target.guild == GIL_SUMMONED_SKELETON)
    || (target.guild == GIL_SKELETON_MAGE)
    || (target.guild == GIL_GOBBO_SKELETON)
    || (target.guild == GIL_SUMMONED_GOBBO_SKELETON)
    || (target.guild == GIL_SHADOWBEAST_SKELETON) {
        weakspot.node = ""; // Disable critical hits this way
    } else if (target.aivar[AIV_MM_REAL_ID] == ID_BLATTCRAWLER) {
        weakspot.node = "ZM_Fuehler_01"; // Blattcrawler has a tiny head that is not centered. ZM_Fuehler_01 is, though
        weakspot.dimX = 45;
        weakspot.dimY = 35;
    } else if (target.aivar[AIV_MM_REAL_ID] == ID_BLOODHOUND) {
        weakspot.dimX = 55;
        weakspot.dimY = 50;
    } else if (target.aivar[AIV_MM_REAL_ID] == ID_ORCBITER) {
        weakspot.dimX = 45;
        weakspot.dimY = 40;
    } else if (target.aivar[AIV_MM_REAL_ID] == ID_RAZOR) || (target.aivar[AIV_MM_REAL_ID] == ID_DRAGONSNAPPER) {
        weakspot.dimX = 40;
        weakspot.dimY = 40;
    } else if (target.aivar[AIV_MM_REAL_ID] == ID_GARGOYLE) { // Both panther and fire beast
        weakspot.dimX = 65;
        weakspot.dimY = 60;
    } else if (target.aivar[AIV_MM_REAL_ID] == ID_SNAPPER) {
        weakspot.dimX = 40;
        weakspot.dimY = 35;
    } else if (target.aivar[AIV_MM_REAL_ID] == ID_TROLL) {
        weakspot.dimX = 90;
        weakspot.dimY = 100;
    } else if (target.aivar[AIV_MM_REAL_ID] == ID_TROLL_BLACK) {
        weakspot.dimX = 70;
        weakspot.dimY = 80;
    } else if (target.aivar[AIV_MM_REAL_ID] == ID_KEILER) {
        weakspot.dimX = 60;
        weakspot.dimY = 65;
    } else if (target.aivar[AIV_MM_REAL_ID] == ID_WARG) || (target.aivar[AIV_MM_REAL_ID] == ID_ICEWOLF) {
        weakspot.dimX = 40;
        weakspot.dimY = 45;
    } else if (target.guild == GIL_SWAMPSHARK) {
        weakspot.node = "ZS_MOUTH"; // Hard to hit
        weakspot.dimX = 30;
        weakspot.dimY = 30;
    } else if (target.guild == GIL_ALLIGATOR) {
        weakspot.dimX = 80;
        weakspot.dimY = 60;
    } else if (target.guild == GIL_GIANT_RAT) { // All rats (desert, swamp, normal)
        weakspot.dimX = 40;
        weakspot.dimY = 35;
    } else if (target.guild == GIL_GOBBO) {
        weakspot.dimX = 25;
        weakspot.dimY = 25;
    } else if (target.guild == GIL_DEMON) || (target.guild == GIL_SUMMONED_DEMON) { // Both demon and demon lord
        weakspot.dimX = 35;
        weakspot.dimY = 40;
    } else if (target.guild == GIL_DRACONIAN) {
        weakspot.dimX = 40;
        weakspot.dimY = 40;
    } else if (target.guild == GIL_DRAGON) {
        weakspot.dimX = 60;
        weakspot.dimY = 70;
    } else if (target.guild == GIL_WARAN) {
        weakspot.dimX = 50;
        weakspot.dimY = 50;
    } else if (target.guild == GIL_GIANT_BUG) {
        weakspot.dimX = 30;
        weakspot.dimY = 40;
    } else if (target.guild == GIL_HARPY) {
        weakspot.dimX = 25;
        weakspot.dimY = 25;
    } else if (target.guild == GIL_LURKER) {
        weakspot.dimX = 30;
        weakspot.dimY = 30;
    } else if (target.guild == GIL_MINECRAWLER) {
        weakspot.dimX = 50;
        weakspot.dimY = 50;
    } else if (target.guild == GIL_MOLERAT) {
        weakspot.dimX = 35;
        weakspot.dimY = 30;
    } else if (target.guild == GIL_SCAVENGER) {
        weakspot.dimX = 35;
        weakspot.dimY = 40;
    } else if (target.guild == GIL_SHADOWBEAST) {
        weakspot.dimX = 60;
        weakspot.dimY = 60;
    } else if (target.guild == GIL_SHEEP) {
        weakspot.dimX = 20;
        weakspot.dimY = 25;
    } else if (target.guild == GIL_WOLF) || (target.guild == GIL_SUMMONED_WOLF) {
        weakspot.dimX = 25;
        weakspot.dimY = 40;
    } else { // Default size for any non-listed monster
        weakspot.dimX = 50; // 50x50cm size
        weakspot.dimY = 50;
    };
};

/*
 * This function is called when a critical hit occurred and can be used to print something to the screen, play a sound
 * jingle or, as done here by default, show a hitmarker. Leave this function blank for no event.
 */
func void freeAimCriticalHitEvent(var C_Npc target, var C_Item weapon) {
    // The event may depend on the target npc (e.g. different sound for monsters). Make use of 'target' argument
    //  if (target.guild < GIL_SEPERATOR_HUM) { }; // E.g. special case for humans
    // The critical hits could also be counted here to give an xp reward after 25 headshots
    // The weapon can also be considered (e.g. weapon specific print). Make use of 'weapon' for that
    // Caution: Weapon may have been unequipped already at this time (unlikely)! Use Hlp_IsValidItem(weapon) to check
    //  if (Hlp_IsValidItem(weapon)) && (weapon.certainProperty > 10) { }; // E.g. special case for weapon property
    // Simple screen notification
    //  PrintS("Critical hit");
    // Shooter-like hit marker
    var int hitmark;
    if (!Hlp_IsValidHandle(hitmark)) { // Create hitmark if it does not exist
        var zCView screen; screen = _^(MEM_Game._zCSession_viewport);
        hitmark = View_CreateCenterPxl(screen.psizex/2, screen.psizey/2, 64, 64);
        View_SetTexture(hitmark, freeAimAnimateReticleByPercent(RETICLE_TRI_IN, 100, 7)); // Retrieve 7th frame of ani
    };
    View_Open(hitmark);
    FF_ApplyExtData(View_Close, 300, 1, hitmark);
    // Sound notification
    Snd_Play3D(target, "FREEAIM_CRITICALHIT");
};
