/*
 * This file contains all configurations for critical hits for bows and crossbows.
 *
 * Requires the feature GFA_CRITICALHITS (see config\settings.d).
 *
 * List of included functions:
 *  func void GFA_GetCriticalHit(C_Npc target, string bone, C_Item weapon, int talent, int dmgMsgPtr)
 *  func void GFA_GetCriticalHitAutoAim(C_Npc target, C_Item weapon, int talent, int dmgMsgPtr)
 */


// Stores the pointer of the hit marker zCView
const int GFA_HITMARKER = 0;


/*
 * This function is called every time (any kind of) NPC is hit by a projectile (arrows and bolts). Originally it was
 * meant to design critical hits based on a specific bone of the model, but it can also be used to change the damage
 * (or to trigger any other kind of special events) based on any bone of the model that was hit. Additionally, it allows
 * to specify a "damage behavior". The damage behavior defines how much damage is eventually applied to the victim. This
 * allows, e.g. to prevent a victim from dying, and instead knock it out with one shot (see examples in function).
 * This function is only called if free aiming is enabled. For critical hits without free aiming see
 * GFA_GetCriticalHitAutoAim() below.
 *
 * The damage value is a float and represents the new base damage (damage of weapon), not the final damage!
 * All possible damage behaviors are defined in _intern/const.d (DMG_*).
 *
 * Note: This function is specific to free aiming. For critical hits without free aiming see GFA_GetCriticalHitAutoAim()
 *       below.
 *
 * Ideas: incorporate weapon-specific stats, head shot talent, special knockout munition, dependency on target, ...
 * Examples are written below and commented out and serve as inspiration of what is possible.
 *
 * Here, preliminary critical hits for almost all Gothic 1 and Gothic 2 monsters are defined (all head shots).
 */
func void GFA_GetCriticalHit(var C_Npc target, var string bone, var C_Item weapon, var int talent, var int dmgMsgPtr) {
    var DmgMsg damage; damage = _^(dmgMsgPtr);

    // In case this helps with differentiating between NPC types: Exact instance name, e.g. "ORCWARRIOR_LOBART1"
    var string instName; instName = MEM_ReadString(MEM_GetSymbolByIndex(Hlp_GetInstanceID(target)));

    /*
    // The damage may depend on the target NPC (e.g. different damage for monsters). Make use of 'target' for that
    if (target.guild < GIL_SEPERATOR_HUM) {
        // ...
    }; */

    /*
    // Create knockout arrows: Retrieve munition item from weapon. Make use of 'weapon' for that
    // Caution: Weapon may have been unequipped already at this time (unlikely)! Use Hlp_IsValidItem(weapon)
    if (Hlp_IsValidItem(weapon)) {
        if (weapon.munition == ItRw_KnockOutArrow) { // Special arrow
            if (Hlp_StrCmp(bone, "BIP01 HEAD")) {    // Only if it was a head shot
                // Knockout on critical hit
                damage.behavior = INSTANT_KNOCKOUT;
                return;
            } else {
                // Normal damage otherwise (but prevent killing the victim)
                damage.behavior = DO_NOT_KILL;
                return;
            };
        };
    }; */

    /*
    // Instant kill on head shot
    if (Hlp_StrCmp(bone, "BIP01 HEAD")) {
        damage.behavior = DMG_INSTANT_KILL;
        return;
    };*/

    /*
    // Shots may destroy animal trophies if the arrow hits certain body parts
    if (Hlp_StrCmp(bone, "BIP01 SPINE")) // Add more bones if necessary
    && (Hlp_StrCmp(instName, "WOLF") {
        // When hitting a wolf in the torso, it is not possible to get its fur
        target.aivar[AIV_Fur] = FALSE; // Check this AI variable in B_GiveDeathInv()
        damage.info = "Torso hit: Fur is damaged and cannot be retrieved";
        return;
    };
    */

    // Increase damage for head shots (or other weak spots)
    if (Hlp_StrCmp(bone, "BIP01 HEAD")) {
        // Differentiate between Gothic 1 and Gothic 2
        if (GOTHIC_BASE_VERSION == 1) {

            // Gothic 1: Only allow critical hit, if the total damage would still not cause damage:
            // (damage * 2 < protection of target)
            if (roundf(damage.value)*2 < damage.protection) {
                damage.info = "Critical hit would not exceed protection"; // Debugging info for zSpy
                return;
            };

            // Incorporate the critical hit chance (talent value) for Gothic 1. By aiming and targeting, the talent
            // value in Gothic 1 (which is responsible for the critical hit chance) becomes obsolete. To still have an
            // incentive to learn the higher stages of ranged weapons, an additional probability for critical hits can
            // be imposed here. Keep in mind that critical hits are still determined by aiming, but hits are not
            // considered critical 100% of the time
            if (GOTHIC_BASE_VERSION == 1) {
                if (!talent) {
                    // With no learned skill level, there are no critical hits (just like in the original Gothic 1)
                    damage.info = "Critical hits not yet learned, critical hit chance = 0% (see character menu)";
                    return;
                } else if (talent < 25) {
                    // Stage 1: Only 50% of the positive hits are in fact critical
                    damage.info = "First level critical hit chance (character menu), adjusted to 50-50 chance";
                    if (Hlp_Random(100) < 50) { // Approx. 50-50 chance
                        return;
                    };
                }; // Else stage 2: All positive hits on the weak spot are critical hits (no change)
            };

            // In Gothic 1, critical hits receive weapon damage x2 (this is the default)
            damage.value = mulf(damage.value, castToIntf(2.0)); // This is a float

        } else if (GOTHIC_BASE_VERSION == 2) {

            // Gothic 2: Only allow critical hits, if non-critical shots would cause damage
            // (damage + dexterity > point protection of target), Gothic 2 always takes point damage for projectiles!
            if (roundf(damage.value)+hero.attribute[ATR_DEXTERITY] < damage.protection)
            || (damage.protection == /*IMMUNE*/ -1) {
                damage.info = "Damage does not exceed protection";
                return;
            };

            // Extra exception for metal armors (paladin armor). Gothic 2 only: There are no helmets in Gothic 1
            if (Npc_HasEquippedArmor(target)) {
                var C_Item armor; armor = Npc_GetEquippedArmor(target);
                if (armor.material == MAT_METAL)    // Armor is made out of metal
                && (!Npc_CanSeeNpc(target, hero)) { // Target is not facing the player (helmets do not cover the face)
                    damage.info = "Target NPC protected by helmet";
                    return;
                };
            };

            // In Gothic 2, there are no critical hits for ranged combat by default. Here, x1.3 seems more reasonable,
            // because in Gothic 2, the dexterity is added to weapon damage.
            damage.value = mulf(damage.value, castToIntf(1.3)); // This is a float
        };


        // Show some event to the user about the critical hit

        /*
        // Simple screen notification
        PrintS("Critical hit"); */

        // Shooter-like hit marker
        if (!GFA_HITMARKER) {
            // Create it (if it does not exist) in the center of the screen
            Print_GetScreenSize(); // Necessary for Print_Screen
            GFA_HITMARKER = ViewPtr_CreateCenterPxl(Print_Screen[PS_X]/2, Print_Screen[PS_Y]/2,  // Coordinates
                                                    GFA_RETICLE_MAX_SIZE, GFA_RETICLE_MAX_SIZE); // Size

            // Get 7th frame of animated texture as static texture
            ViewPtr_SetTexture(GFA_HITMARKER, GFA_AnimateReticleByPercent(RETICLE_TRI_IN, 100, 7));
        };
        ViewPtr_Open(GFA_HITMARKER);

        // Hide the hit marker after 300 ms (formerly a timed framefunction, see below)
        HookEngineF(oCGame__Render, 7, GFA_RemoveHitMarker);

        // Sound notification
        Snd_Play3D(target, "GFA_CRITICALHIT_SFX");
    };

    return;
};


/*
 * A little helper function to avoid using handles (View and FrameFunction) for removing the hit marker. This way,
 * neither the hit marker, nor the framefunction to remove it will be stored in the game save. Furthermore, the number
 * of available handles will not be depleted by creating a new framefunction every time the hit marker is displayed.
 */
func void GFA_RemoveHitMarker() {
    const int TIME = 0; TIME += MEM_Timer.frameTime;
    // After 300 ms hide the hit marker
    if (TIME >= 300) {
        TIME = 0;
        ViewPtr_Close(GFA_HITMARKER);
        RemoveHookF(oCGame__Render, 0, GFA_RemoveHitMarker);
    };
};


/*
 * This function is analogous to GFA_GetCriticalHit() above, but is called when free aiming for ranged weapons is not
 * active.
 *
 * Note: This function would not be necessary for Gothic 1, as it already has critical hits for auto aiming by default.
 *       Nevertheless, the original critical hit calculation of Gothic 1 is disabled and replaced by this function. This
 *       way, the critical hit chance can be manipulated if desired. The lines of code below for Gothic 1 are the same
 *       as default by Gothic.
 *
 * Ideas: scale critical hit chance with player skill and distance, ...
 * Some examples are written below (section of Gothic 2) and commented out and serve as inspiration of what is possible.
 */
func void GFA_GetCriticalHitAutoAim(var C_Npc target, var C_Item weapon, var int talent, var int dmgMsgPtr) {
    var DmgMsg damage; damage = _^(dmgMsgPtr);

    // In case this helps with differentiating between NPC types: Exact instance name, e.g. "ORCWARRIOR_LOBART1"
    var string instName; instName = MEM_ReadString(MEM_GetSymbolByIndex(Hlp_GetInstanceID(target)));

    // Define critical hit probability
    var int rand; rand = Hlp_Random(100);

    // Differentiate between Gothic 1 and Gothic 2
    if (GOTHIC_BASE_VERSION == 1) {
        // Gothic 1 already has a critical hit chance by default. Here, the default is just preserved:
        if (rand < talent) {
            // Increase damage by x2 (like it is default in Gothic 1)
            damage.value = mulf(damage.value, castToIntf(2.0)); // This is a float

            // Sound notification on critical hit
            Snd_Play3D(target, "GFA_CRITICALHIT_SFX");
        };
        return;

    } else {
        // For Gothic 2 the critical hit chance for auto aim can be introduced here

        // Here, scale the critical hit chance between MIN (0% skill) and MAX (100% skill)
        var int min; // With   0% skill, min% of the hits are critical hits
        var int max; // With 100% skill, max% of the hits are critical hits

        // Also take the distance into account
        var int distance; distance = Npc_GetDistToPlayer(target);
        if (distance <= FloatToInt(RANGED_CHANCE_MINDIST)/2) {
            // Close range
            min = 3;
            max = 30;
        } else if (distance <= FloatToInt(RANGED_CHANCE_MINDIST)) {
            // Medium range
            min = 2;
            max = 20;
        } else if (distance < FloatToInt(RANGED_CHANCE_MAXDIST)) {
            // Far range
            min = 1;
            max = 10;
        } else {
            // To far away for critical hits
            min = 0;
            max = 0;
        };

        // Scale the critical hit chance between min and max
        var int critChance; critChance = GFA_ScaleRanges(talent, 0, 100, min, max);

        /*
        // The critical hit chance may depend on the target NPC. Make use of 'target' for that
        if (target.guild < GIL_SEPERATOR_HUM) {
            // ...
        }; */

        /*
        // The weapon can also be considered (e.g. weapon specific print). Make use of 'weapon' for that
        // Caution: Weapon may have been unequipped already at this time (unlikely)! Use Hlp_IsValidItem(weapon)
        if (Hlp_IsValidItem(weapon)) {
            if (weapon.certainProperty > 10) { // E.g. special case for weapon property
                // ...
            };
        }; */

        // Respect the percentage ranges
        if (critChance < 0) {
            critChance = 0;
        } else if (critChance > 100) {
            critChance = 100;
        };

        // Increase the damage
        if (rand < critChance) {
            // Increase damage by x1.3 (because the dexterity is also added to ranged weapons)
            damage.value = mulf(damage.value, castToIntf(1.3)); // This is a float

            // Sound notification on critical hit
            Snd_Play3D(target, "GFA_CRITICALHIT_SFX");
        };

        return;
    };
};
