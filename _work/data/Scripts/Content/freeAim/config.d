/*
 * G2 Free Aim v0.1.2 - Free aiming for the video game Gothic 2 by Piranha Bytes
 * Copyright (C) 2016  mud-freak (@szapp)
 *
 * This file is part of G2 Free Aim.
 * <http://github.com/szapp/g2freeAim>
 *
 * G2 Free Aim is free software: you can redistribute it and/or modify
 * it under the terms of the MIT License.
 * On redistribution this notice must remain intact and all copies must
 * identify the original author.
 *
 * G2 Free Aim is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * MIT License for more details.
 *
 * You should have received a copy of the MIT License
 * along with G2 Free Aim.  If not, see <http://opensource.org/licenses/MIT>.
 *
 *
 * Customizability:
 *  - Show weakspot debug visualization by default:   FREEAIM_DEBUG_WEAKSPOT
 *  - Show trace ray debug visualization by default:  FREEAIM_DEBUG_TRACERAY
 *  - Apply trigger collision fix (disable coll.):    FREEAIM_TRIGGER_COLL_FIX
 *  - Allow freeAim console commands (cheats):        FREEAIM_DEBUG_CONSOLE
 *  - Maximum bow draw time (ms):                     FREEAIM_DRAWTIME_MAX
 *  - Disable free aiming for spells (yes/no):        FREEAIM_DISABLE_SPELLS
 *  - Collect and re-use shot projectiles (yes/no):   FREEAIM_REUSE_PROJECTILES
 *  - Projectile instance for re-using:               freeAimGetUsedProjectileInstance(instance, targetNpc)
 *  - Draw force (gravity/drop-off) calculation:      freeAimGetDrawForce(weapon, talent)
 *  - Accuracy calculation:                           freeAimGetAccuracy(weapon, talent)
 *  - Reticle style (texture, color, size):           freeAimGetReticleRanged(target, weapon, talent, distance)
 *  - Reticle style for spells:                       freeAimGetReticleSpell(target, spellID, spellInst, spellLevel, ..)
 *  - Hit registration on npcs (e.g. friendly-fire):  freeAimHitRegNpc(target, weapon, material)
 *  - Hit registration on world:                      freeAimHitRegWld(shooter, weapon, material, texture)
 *  - Change the base damage at time of shooting:     freeAimScaleInitialDamage(basePointDamage, weapon, talent)
 *  - Critical hit calculation (position, damage):    freeAimCriticalHitDef(target, weapon, damage)
 *  - Critical hit event (print, sound, xp, ...):     freeAimCriticalHitEvent(target, weapon)
 * Advanced (modification not recommended):
 *  - Scatter radius for accuracy:                    FREEAIM_SCATTER_DEG
 *  - Camera view (shoulder view):                    FREEAIM_CAMERA and FREEAIM_CAMERA_X_SHIFT
 *  - Max time before projectile drop-off:            FREEAIM_TRAJECTORY_ARC_MAX
 *  - Gravity of projectile after drop-off:           FREEAIM_PROJECTILE_GRAVITY
 *  - Turn speed while aiming:                        FREEAIM_ROTATION_SCALE
 *  - Additional hit detection test (EXPERIMENTAL):   FREEAIM_HITDETECTION_EXP
 *  - Shift the aim vob:                              freeAimShiftAimVob(spellID)
 */

/* Initialize fixed settings. This function is called once at the beginning of each session. Set the constants here */
func void freeAimInitConstants() {
    // If you want to change a setting, uncomment the respective line. These are the default values.
    // FREEAIM_REUSE_PROJECTILES  = 1;                 // Enable collection and re-using of shot projectiles
    // FREEAIM_DISABLE_SPELLS     = 0;                 // If true, free aiming is disabled for spells (not for ranged)
    // FREEAIM_DRAWTIME_MAX       = 1200;              // Max draw time (ms): When is the bow fully drawn
    // FREEAIM_DEBUG_CONSOLE      = 1;                 // Console commands for debugging. Set to zero in final mod
    // FREEAIM_DEBUG_WEAKSPOT     = 0;                 // Visualize weakspot bbox and trajectory by default
    // FREEAIM_DEBUG_TRACERAY     = 0;                 // Visualize trace ray bboxes and trajectory by default
    // FREEAIM_TRIGGER_COLL_FIX   = 1;                 // Apply trigger collision fix (disable collision)
    // Modifying any line below is not recommended!
    // FREEAIM_SCATTER_DEG        = 2.2;               // Maximum scatter radius in degrees
    // FREEAIM_TRAJECTORY_ARC_MAX = 400;               // Max time (ms) after which the trajectory drops off
    // FREEAIM_PROJECTILE_GRAVITY = 0.1;               // The gravity decides how fast the projectile drops
    // FREEAIM_CAMERA             = "CamModFreeAim";   // CCamSys_Def script instance for free aim
    // FREEAIM_CAMERA_X_SHIFT     = 0;                 // One, if camera is set to shoulderview, s.a. (not recommended)
    // FREEAIM_ROTATION_SCALE     = 0.16;              // Turn rate. Non-weapon mode is 0.2 (zMouseRotationScale)
    // FREEAIM_HITDETECTION_EXP   = 0;                 // Additional hit detection (EXPERIMENTAL)
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
    // Add any other factors here e.g. weapon-specific accuracy stats, weapon spread, accuracy talent, ...
    // Check if bow or crossbow with (weapon.flags & ITEM_BOW) or (weapon.flags & ITEM_CROSSBOW)
    // Here the talent is scaled by draw force: draw force=100% => accuracy=talent; draw force=0% => accuracy=talent/2
    var int drawForce; drawForce = freeAimGetDrawForce(weapon, talent); // Already scaled to [0, 100]
    var int accuracy; accuracy = (talent-talent/2)*drawForce/100+talent/2;
    if (accuracy < 0) { accuracy = 0; } else if (accuracy > 100) { accuracy = 100; }; // Respect the ranges
    return accuracy;
};

// This a list of available reticle textures. Some of them are animated as indicated. Animated textures can be passed to
// the following functions:
//  reticle.texture = freeAimAnimateReticleByTime(textureFileName, framesPerSecond, numberOfFrames)
//  reticle.texture = freeAimAnimateReticleByPercent(textureFileName, 100, numberOfFrames) // Where 100 is a percentage
const string RETICLE_DOT           = "RETICLEDOT.TGA";
const string RETICLE_CROSSTWO      = "RETICLECROSSTWO.TGA";
const string RETICLE_CROSSTHREE    = "RETICLECROSSTHREE.TGA";
const string RETICLE_CROSSFOUR     = "RETICLECROSSFOUR.TGA";
const string RETICLE_X             = "RETICLEX.TGA";
const string RETICLE_CIRCLE        = "RETICLECIRCLE.TGA";
const string RETICLE_CIRCLECROSS   = "RETICLECIRCLECROSS.TGA";
const string RETICLE_DOUBLECIRCLE  = "RETICLEDOUBLECIRCLE.TGA";       // Can be animated (rotation)  10 Frames [00..09]
const string RETICLE_PEAK          = "RETICLEPEAK.TGA";
const string RETICLE_NOTCH         = "RETICLENOTCH.TGA";              // Can be animated (expanding) 17 Frames [00..16]
const string RETICLE_TRI_IN        = "RETICLETRIIN.TGA";              // Can be animated (expanding) 17 Frames [00..16]
const string RETICLE_TRI_IN_DOT    = "RETICLETRIINDOT.TGA";           // Can be animated (expanding) 17 Frames [00..16]
const string RETICLE_TRI_OUT_DOT   = "RETICLETRIOUTDOT.TGA";          // Can be animated (expanding) 17 Frames [00..16]
const string RETICLE_DROP          = "RETICLEDROP.TGA";               // Can be animated (expanding)  8 Frames [00..07]
const string RETICLE_FRAME         = "RETICLEFRAME.TGA";
const string RETICLE_EDGES         = "RETICLEEDGES.TGA";
const string RETICLE_BOWL          = "RETICLEBOWL.TGA";
const string RETICLE_HORNS         = "RETICLEHORNS.TGA";
const string RETICLE_BOLTS         = "RETICLEBOLTS.TGA";
const string RETICLE_BLAZE         = "RETICLEBLAZE.TGA";              // Can be animated (flames)    10 Frames [00..09]
const string RETICLE_WHIRL         = "RETICLEWHIRL.TGA";              // Can be animated (rotation)  10 Frames [00..09]
const string RETICLE_BRUSH         = "RETICLEBRUSH.TGA";
const string RETICLE_SPADES        = "RETICLESPADES.TGA";
const string RETICLE_SQUIGGLE      = "RETICLESQUIGGLE.TGA";

/* Modify this function to alter the reticle texture, color and size (scaled between 0 and 100) for ranged combat. */
func void freeAimGetReticleRanged(var C_Npc target, var C_Item weapon, var int talent, var int dist, var int rtrnPtr) {
    var Reticle reticle; reticle = _^(rtrnPtr);
    // Color (do not set the color to preserve the original texture color)
    if (Hlp_IsValidNpc(target)) { // The argument 'target' might be empty!
        var int att; att = Npc_GetAttitude(target, hero);
        if (att == ATT_FRIENDLY) { reticle.color = Focusnames_Color_Friendly(); }
        else if (att == ATT_HOSTILE) { reticle.color = Focusnames_Color_Hostile(); };
    };
    // Size (scale between [0, 100]: 0 is smallest, 100 is biggest)
    reticle.size = -dist + 100; // Inverse aim distance: bigger for closer range: 100 for closest, 0 for most distance
    //  reticle.size = -freeAimGetDrawForce(weapon, talent) + 100; // Or inverse draw force: bigger for less draw force
    //  reticle.size = -freeAimGetAccuracy(weapon, talent) + 100; // Or inverse accuracy: bigger with lower accuracy
    // More sophisticated customization is also possible: change the texture by draw force, the size by accuracy, ...
    if (weapon.flags & ITEM_BOW) { // Change reticle texture by drawforce (irrespective of the reticle size set above)
        var int drawForce; drawForce = freeAimGetDrawForce(weapon, talent); // Already scaled between [0, 100]
        reticle.texture = freeAimAnimateReticleByPercent(RETICLE_NOTCH, drawForce, 17); // Animate reticle by draw force
    } else if (weapon.flags & ITEM_CROSSBOW) { // Change reticle texture by distance
        reticle.size = 75; // Keep the size fixed here
        reticle.texture = freeAimAnimateReticleByPercent(RETICLE_DROP, dist, 8); // Animate reticle by distance
    };
};

/* Modify this function to alter the reticle texture, color and size (scaled between 0 and 100) for magic combat. */
func void freeAimGetReticleSpell(var C_Npc target, var int spellID, var C_Spell spellInst, var int spellLevel,
        var int isScroll, var int manaInvested, var int dist, var int rtrnPtr) {
    var Reticle reticle; reticle = _^(rtrnPtr);
    // 1. Texture (needs to be set, otherwise reticle will not be displayed)
    //  if (spellInst.spellType == SPELL_GOOD) { reticle.texture = RETICLE_CIRCLECROSS; }
    //  else if (spellInst.spellType == SPELL_NEUTRAL) { reticle.texture = RETICLE_CIRCLECROSS; }
    //  else if (spellInst.spellType == SPELL_BAD) { reticle.texture = RETICLE_CIRCLECROSS; };
    // 2. Color (do not set the color to preserve the original texture color)
    if (Hlp_IsValidNpc(target)) { // The argument 'target' might be empty!
        var int att; att = Npc_GetAttitude(target, hero);
        if (att == ATT_FRIENDLY) { reticle.color = Focusnames_Color_Friendly(); }
        else if (att == ATT_HOSTILE) { reticle.color = Focusnames_Color_Hostile(); };
    };
    // 3. Size (scale between [0, 100]: 0 is smallest, 100 is biggest)
    reticle.size = -dist + 100; // Inverse aim distance: bigger for closer range: 100 for closest, 0 for most distance
    // More sophisticated customization is also possible: change the texture by spellID, the size by spellLevel, ...
    // Size by spell level for invest spells (e.g. increase size by invest level)
    //  if (spellLevel < 2) { reticle.size = 75; }
    //  else if (spellLevel >= 2) { reticle.size = 100; };
    // Different reticle for scrolls
    //  if (isScroll) { reticle.color = RGBA(125, 200, 250, 255); }; // Light blue
    // Scale size by the amount of mana invested
    //  reticle.size = manaInvested; // This should be scaled between [0, 100]
    // One possibility is to set the reticle texture by grouping the spells, as it is done below
    // Ice spells
    if (spellID == SPL_Icebolt)
    || (spellID == SPL_IceCube)
    || (spellID == SPL_IceLance) {
        reticle.texture = RETICLE_SPADES;
    } // Water spells
    else if (spellID == SPL_WaterFist)
    || (spellID == SPL_Inflate)
    || (spellID == SPL_Geyser)
    || (spellID == SPL_Waterwall) {
        reticle.texture = freeAimAnimateReticleByTime(RETICLE_WHIRL, 30, 10); // Animate reticle with 30 FPS (10 Frames)
    } // Fire spells
    else if (spellID == SPL_Firebolt)
    || (spellID == SPL_InstantFireball)
    || (spellID == SPL_ChargeFireball)
    || (spellID == SPL_Pyrokinesis)
    || (spellID == SPL_Firestorm) {
        reticle.texture = RETICLE_HORNS;
    } // Electric spells
    else if (spellID == SPL_Zap)
    || (spellID == SPL_LightningFlash)
    || (spellID == SPL_ChargeZap) {
        reticle.texture = freeAimAnimateReticleByTime(RETICLE_BLAZE, 15, 10); // Animate reticle with 15 FPS (10 Frames)
    } // Paladin spells
    else if (spellID == SPL_PalHolyBolt)
    || (spellID == SPL_PalRepelEvil)
    || (spellID == SPL_PalDestroyEvil) {
        reticle.texture = RETICLE_FRAME;
    } // Evil spells
    else if (spellID == SPL_BreathOfDeath)
    || (spellID == SPL_MasterOfDisaster)
    || (spellID == SPL_Energyball)
    || (spellID == SPL_Skull) {
        reticle.texture = RETICLE_BOWL;
    } else {
        reticle.texture = RETICLE_EDGES; // Set this as "default" texture here (if none of the conditions above is met)
    };
};

/* Modify this function to disable hit registration on npcs, e.g. 'ineffective' ranged weapons, no friendly-fire, ... */
func int freeAimHitRegNpc(var C_Npc target, var C_Item weapon, var int material) {
    // Valid return values are:
    const int DESTROY = 0; // No hit reg (no damage), projectile is destroyed
    const int COLLIDE = 1; // Hit reg (damage), projectile is put into inventory
    const int DEFLECT = 2; // No hit reg (no damage), projectile is repelled
    // The argument 'material' holds the material of the armor (of the target), -1 for no armor equipped
    // For armors of npcs the materials are defined as in Constants.d (MAT_METAL, MAT_WOOD, ...)
    if (target.aivar[AIV_PARTYMEMBER]) // Disable friendly-fire
    && (target.aivar[AIV_LASTTARGET] != Hlp_GetInstanceID(hero)) { return DESTROY; };
    //  if (material == MAT_METAL) && (Hlp_Random(100) < 20) { return DEFLECT; }; // Metal armors may be more durable
    // The weapon can also be considered (e.g. ineffective weapons). Make use of 'weapon' for that
    // Caution: Weapon may have been unequipped already at this time (unlikely)! Use Hlp_IsValidItem(weapon)
    //  if (Hlp_IsValidItem(weapon)) && (weapon.ineffective) { return DEFLECT; }; // Special case for weapon property
    return COLLIDE; // Usually all shots on npcs should be registered, see freeAimGetAccuracy() above
};

/* Modify this function to disable hit registration on the world, e.g. deflection of metal, stuck in wood, ... */
func int freeAimHitRegWld(var C_Npc shooter, var C_Item weapon, var int material, var string texture) {
    // This function, unlike freeAimHitRegNpc() and all other functions here, is also called for npc shooters!
    // Valid return values are:
    const int DESTROY = 0; // Projectile is destroyed on impact
    const int COLLIDE = 1; // Projectile gets stuck in the surface
    const int DEFLECT = 2; // Projectile is repelled
    // Note: The materials of the world are defined differently (than the familiar item-materials):
    const int METAL = 1;
    const int STONE = 2;
    const int WOOD  = 3;
    const int EARTH = 4;
    const int WATER = 5;
    const int SNOW  = 6;
    const int UNDEF = 0;
    if (material == WOOD) { return COLLIDE; }; // Projectiles stay stuck in wood (default in gothic)
    if (Hlp_StrCmp(texture, "MOWOBOWMARK01.TGA")) { return COLLIDE; }; // Condition by surface texture
    //  if (Npc_IsPlayer(shooter)) ... // Keep in mind that this function is also called for npc shooters
    if (material == STONE) && (Hlp_Random(100) < 20) { return DESTROY; }; // The projectile might break on impact
    // The example in the previous line can also be treated in freeAimGetUsedProjectileInstance() below
    // The weapon can also be considered (e.g. ineffective weapons). Make use of 'weapon' for that
    // Caution: Weapon may have been unequipped already at this time (unlikely)! Use Hlp_IsValidItem(weapon)
    //  if (Hlp_IsValidItem(weapon)) && (weapon.ineffective) { return DEFLECT; }; // Special case for weapon property
    return DEFLECT; // Projectiles deflect off of all other surfaces
};

/* Modify this function to alter the base damage of projectiles at time of shooting (only DAM_POINT) */
func int freeAimScaleInitialDamage(var int basePointDamage, var C_Item weapon, var int talent) {
    // This function should not be necessary, all damage specifications should be set in the item scripts. However,
    // here the initial damage (DAM_POINT) may be scaled by draw force, accuracy, ...
    // Check if bow or crossbow with (weapon.flags & ITEM_BOW) or (weapon.flags & ITEM_CROSSBOW)
    // Here the damage is scaled by draw force: draw force=100% => baseDamage; draw force=0% => baseDamage/2
    var int drawForce; drawForce = freeAimGetDrawForce(weapon, talent); // Already scaled to [0, 100]
    drawForce = 50 * drawForce / 100 + 50; // Re-scale the drawforce to [50, 100]
    return (basePointDamage * drawForce) / 100; // Scale initial point damage by draw force
};

/* Modify this function to define a critical hit by weak spot (e.g. head node for headshot), its size and the damage */
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
    } else if (target.guild == GIL_BLOODFLY) || (target.guild == GIL_MEATBUG) { // Models that don't have a head node
        weakspot.node = ""; // Disable critical hits this way
    } else { // Default
        weakspot.node = "Bip01 Head";
        weakspot.dimX = 50; // 50x50cm size
        weakspot.dimY = 50;
        weakspot.bDmg = mulf(damage, castToIntf(2.0)); // Double the base damage. This is a float
    };
};

/* Use this function to create an event when getting a critical hit, e.g. print or sound jingle, leave blank for none */
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

/* Modify this function to exchange (or remove) the projectile after shooting for re-using, e.g. used arrow */
func int freeAimGetUsedProjectileInstance(var int projectileInst, var C_Npc inventoryNpc) {
    // By returning zero, the projectile is completely removed (e.g. retrieve-projectile-talent not learned yet)
    // The argument inventoryNpc holds the npc in whose inventory it will be put, or is empty if it landed in the world
    //  if (projectileInst == Hlp_GetInstanceID(ItRw_Arrow)) { // Exchange the instance for a "used" one
    //      if (!Hlp_IsValidItem(ItRw_UsedArrow)) { Wld_InsertItem(ItRw_UsedArrow, MEM_FARFARAWAY); }; // Initialize!
    //      projectileInst = Hlp_GetInstanceID(ItRw_UsedArrow);
    //  };
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
    // if (spellID == ...) { return -100; }; // Push the aim vob 100 cm away from any wall
    return 0;
};
