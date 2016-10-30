/*
 * G2 Free Aim - Free aiming for the video game Gothic 2 by Piranha Bytes
 * Copyright (C) 2016  mud-freak (@szapp)
 *
 * This file is part of G2 Free Aim.
 * http://github.com/szapp/g2freeAim
 *
 * G2 Free Aim is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * On redistribution this notice must remain intact and all copies must
 * identify the original author.
 *
 * G2 Free Aim is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with G2 Free Aim.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Customizability:
 *  - Show weakspot debug visualization by default    FREEAIM_DEBUG_WEAKSPOT
 *  - Allow freeAim console commands (cheats)         FREEAIM_DEBUG_CONSOLE
 *  - Maximum bow draw time (ms):                     FREEAIM_DRAWTIME_MAX
 *  - Disable free aiming for spells (yes/no):        FREEAIM_DISABLE_SPELLS
 *  - Collect and re-use shot projectiles (yes/no):   FREEAIM_REUSE_PROJECTILES
 *  - Projectile instance for re-using                freeAimGetUsedProjectileInstance(instance, targetNpc)
 *  - Draw force (gravity/drop-off) calculation:      freeAimGetDrawForce(weapon, talent)
 *  - Accuracy calculation:                           freeAimGetAccuracy(weapon, talent)
 *  - Reticle style (texture, color, size):           freeAimGetReticle(target, weapon, talent, distance)
 *  - Disable hit registration (e.g. friendly-fire):  freeAimHitRegistration(target, weapon, material)
 *  - Critical hit calculation (position, damage):    freeAimCriticalHitDef(target, weapon, damage)
 *  - Critical hit event (print, sound, xp, ...):     freeAimCriticalHitEvent(target, weapon)
 * Advanced (modification not recommended):
 *  - Scatter radius for accuracy:                    FREEAIM_SCATTER_DEG
 *  - Camera view (shoulder view):                    FREEAIM_CAMERA and FREEAIM_CAMERA_X_SHIFT
 *  - Max time before projectile drop-off:            FREEAIM_TRAJECTORY_ARC_MAX
 *  - Gravity of projectile after drop-off:           FREEAIM_PROJECTILE_GRAVITY
 *  - Turn speed while aiming:                        FREEAIM_ROTATION_SCALE
 *  - Shift the aim vob:                              freeAimShiftAimVob
 */

/* Initialize fixed settings. This function is called once at the beginning of each session. Set the constants here */
func void freeAimInitConstants() {
    // If you want to change a setting, uncomment the respective line. These are the default values.
    // FREEAIM_REUSE_PROJECTILES    = 1;               // Enable collection and re-using of shot projectiles
    // FREEAIM_DISABLE_SPELLS       = 0;               // If true, free aiming is disabled for spells (not for ranged)
    // FREEAIM_DRAWTIME_MAX         = 1200;            // Max draw time (ms): When is the bow fully drawn
    // FREEAIM_DEBUG_CONSOLE        = 1;               // Console commands for debugging. Set to zero in final mod
    // FREEAIM_DEBUG_WEAKSPOT       = 0;               // Visualize weakspot bbox and trajectory by default
    // Modifing anything below is not recommended!
    // FREEAIM_SCATTER_DEG          = 2.2;             // Maximum scatter radius in degrees
    // FREEAIM_TRAJECTORY_ARC_MAX   = 400;             // Max time (ms) after which the trajectory drops off
    // FREEAIM_PROJECTILE_GRAVITY   = 0.1;             // The gravity decides how fast the projectile drops
    // FREEAIM_CAMERA               = "CamModFreeAim"; // CCamSys_Def script instance for free aim
    // FREEAIM_CAMERA_X_SHIFT       = 0;               // One, if camera is set to shoulderview, s.a. (not recommended)
    // FREEAIM_ROTATION_SCALE       = 0.16;            // Turn rate. Non-weapon mode is 0.2 (zMouseRotationScale)
};

/* Modify this function to alter the draw force calculation. Scaled between 0 and 100 (percent) */
func int freeAimGetDrawForce(var C_Item weapon, var int talent) {
    var int drawTime; drawTime = MEM_Timer.totalTime - freeAimBowDrawOnset;
    // Possibly incorporate more factors like e.g. a quick-draw talent, weapon-specific stats, ...
    if (weapon.flags & ITEM_CROSSBOW) { return 100; }; // Always full draw force on crossbows
    // For now the draw time is scaled by a maximum. Replace FREEAIM_DRAWTIME_MAX by a variable for a quick-draw talent
    var int drawForce; drawForce = (100 * drawTime) / FREEAIM_DRAWTIME_MAX;
    if (drawForce < 0) { drawForce = 0; } else if (drawForce > 100) { drawForce = 100; }; // Respect the ranges
    return drawForce;
};

/* Modify this function to alter accuracy calculation. Scaled between 0 and 100 (percent) */
func int freeAimGetAccuracy(var C_Item weapon, var int talent) {
    // Add any other factors here e.g. weafpon-specific accuracy stats, weapon spread, accuracy talent, ...
    // Check if bow or crossbow with (weapon.flags & ITEM_BOW) or (weapon.flags & ITEM_CROSSBOW)
    // Here the talent is scaled by draw force: draw force=100% => accuracy=talent; draw force=0% => accuracy=talent/2
    var int drawForce; drawForce = freeAimGetDrawForce(weapon, talent); // Already scaled to [0, 100]
    if (drawForce < talent) { drawForce = talent; }; // Decrease impact of draw force on talent
    var int accuracy; accuracy = (talent * drawForce)/100;
    if (accuracy < 0) { accuracy = 0; } else if (accuracy > 100) { accuracy = 100; }; // Respect the ranges
    return accuracy;
};

const string RETICLE_SIMPLE = "RETICLESIMPLE.TGA";
const string RETICLE_NORMAL = "RETICLENORMAL.TGA";
const string RETICLE_NOTCH  = "RETICLENOTCH.TGA";

/* Modify this function to alter the reticle texture, color and size (scaled between 0 and 100) for ranged combat. */
func void freeAimGetReticleRanged(var C_Npc target, var C_Item weapon, var int talent, var int dist, var int rtrnPtr) {
    var Reticle reticle; reticle = _^(rtrnPtr);
    // Texture (needs to be set, otherwise reticle will not be displayed)
    if (weapon.flags & ITEM_BOW) { reticle.texture = RETICLE_NOTCH; } // Bow readied (this is actually replaced below)
    else if (weapon.flags & ITEM_CROSSBOW) { reticle.texture = RETICLE_NOTCH; }; // Crossbow readied
    // Color (do not set the color to preserve the original texture color)
    if (Hlp_IsValidNpc(target)) { // The argument 'target' might be empty!
        var int att; att = Npc_GetAttitude(target, hero);
        if (att == ATT_FRIENDLY) { reticle.color = Focusnames_Color_Friendly(); }
        else if (att == ATT_HOSTILE) { reticle.color = Focusnames_Color_Hostile(); };
    };
    // Size (scale between [0, 100]: 0 is smallest, 100 is biggest)
    reticle.size = -dist+100; // Inverse aim distance: bigger for closer range: 100 for closest, 0 for most distance
    // reticle.size = -freeAimGetDrawForce(weapon, talent)+100; // Or inverse draw force: bigger for less draw force
    // reticle.size = -freeAimGetAccuracy(weapon, talent)+100; // Or inverse accuracy: bigger with lower accuracy
    // More sophisticated customization is also possible: change the texture by draw force, the size by accuracy, ...
    if (weapon.flags & ITEM_BOW) { // Change reticle texture by drawforce (irrespective of the reticle size set above)
        var int drawForce; drawForce = freeAimGetDrawForce(weapon, talent);
        if (drawForce < 5) { reticle.texture = "RETICLENOTCH00.TGA"; } // Simulate draw force by animating the reticle
        else if (drawForce < 11) { reticle.texture = "RETICLENOTCH01.TGA"; }
        else if (drawForce < 17) { reticle.texture = "RETICLENOTCH02.TGA"; }
        else if (drawForce < 23) { reticle.texture = "RETICLENOTCH03.TGA"; }
        else if (drawForce < 29) { reticle.texture = "RETICLENOTCH04.TGA"; }
        else if (drawForce < 35) { reticle.texture = "RETICLENOTCH05.TGA"; }
        else if (drawForce < 41) { reticle.texture = "RETICLENOTCH06.TGA"; }
        else if (drawForce < 47) { reticle.texture = "RETICLENOTCH07.TGA"; }
        else if (drawForce < 53) { reticle.texture = "RETICLENOTCH08.TGA"; }
        else if (drawForce < 59) { reticle.texture = "RETICLENOTCH09.TGA"; }
        else if (drawForce < 65) { reticle.texture = "RETICLENOTCH10.TGA"; }
        else if (drawForce < 73) { reticle.texture = "RETICLENOTCH11.TGA"; }
        else if (drawForce < 81) { reticle.texture = "RETICLENOTCH12.TGA"; }
        else if (drawForce < 88) { reticle.texture = "RETICLENOTCH13.TGA"; }
        else if (drawForce < 94) { reticle.texture = "RETICLENOTCH14.TGA"; }
        else if (drawForce < 100) { reticle.texture = "RETICLENOTCH15.TGA"; }
        else { reticle.texture = RETICLE_NOTCH; };
    };
};

/* Modify this function to alter the reticle texture, color and size (scaled between 0 and 100) for magic combat. */
func void freeAimGetReticleSpell(var C_Npc target, var int spellID, var C_Spell spellInst, var int spellLevel,
        var int dist, var int rtrnPtr) {
    var Reticle reticle; reticle = _^(rtrnPtr);
    // Texture (needs to be set, otherwise reticle will not be displayed)
    if (spellInst.spellType == SPELL_GOOD) { reticle.texture = RETICLE_NORMAL; }
    else if (spellInst.spellType == SPELL_NEUTRAL) { reticle.texture = RETICLE_NORMAL; }
    else if (spellInst.spellType == SPELL_BAD) { reticle.texture = RETICLE_NORMAL; };
    // Color (do not set the color to preserve the original texture color)
    if (Hlp_IsValidNpc(target)) { // The argument 'target' might be empty!
        var int att; att = Npc_GetAttitude(target, hero);
        if (att == ATT_FRIENDLY) { reticle.color = Focusnames_Color_Friendly(); }
        else if (att == ATT_HOSTILE) { reticle.color = Focusnames_Color_Hostile(); };
    };
    // Size (scale between [0, 100]: 0 is smallest, 100 is biggest)
    reticle.size = -dist+100; // Inverse aim distance: bigger for closer range: 100 for closest, 0 for most distance
    // More sophisticated customization is also possible: change the texture by spellID, the size by spellLevel, ...
    // if (spellID == SPL_Firebolt) { reticle.texture = RETICLE_SIMPLE; }
    // else if (spellID == SPL_InstantFireball) { reticle.texture = RETICLE_NORMAL; }
    // else if ...
    // Size by spell level for invest spells (e.g. increase size by invest level)
    // if (spellLevel < 2) { reticle.size = 75; }
    // else if (spellLevel >= 2) { reticle.size = 100; };
    if (spellID == SPL_Blink) { reticle.texture = ""; }; // No reticle for blink
};

/* Modify this function to disable hit registration. E.g. 'ineffective' ranged weapons, disable friendly-fire, ... */
func int freeAimHitRegistration(var C_Npc target, var C_Item weapon, var int material) {
    // Valid return values are:
    const int DESTROY = 0; // No hit reg (no damage), projectile is destroyed
    const int COLLIDE = 1; // Hit reg, projectile is put into inventory (npc), or is stuck in the surface (world)
    const int DEFLECT = 2; // No hit reg (no damage), projectile is repelled
    // The argument 'material' holds the material of the target surface
    // If the target surface is an npc, the material will be that of the armor, -1 for no armor equipped
    // To check if it is an npc that is hit, use Hlp_IsValidNpc(target). In other cases target will be empty!
    if (Hlp_IsValidNpc(target)) { // Target is an npc
        // For armors of npcs the materials are defined as in Constants.d (MAT_METAL, MAT_WOOD, ...)
        // Disable friendly-fire
        if (target.aivar[AIV_PARTYMEMBER]) && (target.aivar[AIV_LASTTARGET] != Hlp_GetInstanceID(hero)) {
            return DESTROY; };
        //if (material == MAT_METAL) && (Hlp_Random(100) < 20) { return DEFLECT; }; // Metal armors may be more durable
        // The weapon can also be considered (e.g. ineffective weapons). Make use of 'weapon' for that
        // Caution: Weapon may have been unequipped already at this time (unlikely)! Use Hlp_IsValidItem(weapon)
        // if (Hlp_IsValidItem(weapon)) && (weapon.ineffective) { return DEFLECT; }; // Special case for weapon property
        return COLLIDE; // Usually all shots on npcs should be registered, see freeAimGetAccuracy() above
    } else { // Target is not an npc (might be a vob or a surface in the static world)
        // The materials of the world are defined differently (than that of armors):
        const int METAL = 1;
        const int STONE = 2;
        const int WOOD  = 3;
        const int EARTH = 4;
        const int WATER = 5;
        const int SNOW  = 6;
        const int UNDEF = 0;
        if (material == WOOD) { return COLLIDE; }; // Projectiles stay stuck in wood (default in gothic)
        // if (material == STONE) && (Hlp_Random(100) < 5) { return DESTROY; }; // The projectile might break on impact
        // The example in the previous line can also be treated in freeAimGetUsedProjectileInstance() below
        return DEFLECT; // Projectiles deflect off of all other surfaces
    };
};

/* Modify this function to define a critical hit by weak spot (e.g. head node for headshot), its size and the damage */
func void freeAimCriticalHitDef(var C_Npc target, var C_Item weapon, var int damage, var int rtrnPtr) {
    var Weakspot weakspot; weakspot = _^(rtrnPtr);
    // This function is dynamic: It is called on every hit and the weakspot and damage can be calculated individually
    // Possibly incorporate weapon-specific stats, headshot talent, dependecy on target, ...
    // The damage may depent on the target npc (e.g. different damage for monsters). Make use of 'target' argument
    // if (target.guild < GIL_SEPERATOR_HUM) { }; // E.g. special case for humans
    // The weapon can also be considered (e.g. weapon specific damage). Make use of 'weapon' for that
    // Caution: Weapon may have been unequipped already at this time (unlikely)! Use Hlp_IsValidItem(weapon) to check
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
    // Caution: Weapon may have been unequipped already at this time (unlikely)! Use Hlp_IsValidItem(weapon) to check
    // if (Hlp_IsValidItem(weapon)) && (weapon.certainProperty > 10) { }; // E.g. special case for weapon property
    Snd_Play("FORGE_ANVIL_A1");
    PrintS("Kritischer Treffer"); // "Critical hit"
};

/* Modify this function to exchange (or remove) the projectile after shooting for re-using, e.g. used arrow */
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
        // if (Hlp_Random(100) < 50) { return 0; }; // Chance of retrieval
        return projectileInst; // For now it is just preserved (is put in the inventory as is)
    } else { // Projectile did not hit npc and landed in world
        // if (PLAYER_TALENT_REUSE_ARROW == FALSE) { return 0; }; // Reuse-projectile-talent
        return projectileInst; // For now it is just preserved (leave it in the world as is)
    };
};

/* Shift the aimvob along the camera out vector for spells (if you don't know what this is, you don't need it) */
func int freeAimShiftAimVob(var int spellID) {
    if (spellID == SPL_Blink) { return -100; }; // SPL_Blink visualizes the aim vob: push it away from any wall
    return 0;
};
