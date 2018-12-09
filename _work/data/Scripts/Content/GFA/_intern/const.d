/*
 * Internal constants of GFA
 *
 * Gothic Free Aim (GFA) v1.1.0 - Free aiming for the video games Gothic 1 and Gothic 2 by Piranha Bytes
 * Copyright (C) 2016-2018  mud-freak (@szapp)
 *
 * This file is part of Gothic Free Aim.
 * <http://github.com/szapp/GothicFreeAim>
 *
 * Gothic Free Aim is free software: you can redistribute it and/or
 * modify it under the terms of the MIT License.
 * On redistribution this notice must remain intact and all copies must
 * identify the original author.
 *
 * Gothic Free Aim is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * MIT License for more details.
 *
 * You should have received a copy of the MIT License along with
 * Gothic Free Aim.  If not, see <http://opensource.org/licenses/MIT>.
 */


/*
 * Gothic Free Aim internal constants. Do not modify! Change the settings in config\settings.d
 */


/* Initialization */

const string GFA_VERSION            = "Gothic Free Aim v1.1.0";
const int    GFA_LEGO_FLAGS         = LeGo_HookEngine       // For initializing all hooks
                                    | LeGo_ConsoleCommands  // For console commands and debugging
                                    | LeGo_Random;          // For scattering and other uses of random numbers

var   int    GFA_Flags;                                     // Flags for initialization of GFA
const int    GFA_RANGED             = 1<<0;                 // Free aiming for ranged combat (bow and crossbow)
const int    GFA_SPELLS             = 1<<1;                 // Free aiming for spell combat (spells)
const int    GFA_REUSE_PROJECTILES  = 1<<2;                 // Enable collection and re-using of shot projectiles
const int    GFA_CUSTOM_COLLISIONS  = 1<<3;                 // Custom collision/damage behaviors and hit registration
const int    GFA_CRITICALHITS       = 1<<4;                 // Critical hits for ranged combat (e.g. head shots)
const int    GFA_ALL                = (1<<5) - 1;           // Initialize all features

const int    GFA_INITIALIZED        = 0;                    // Indicator whether GFA was initialized


/* Free aiming and free movement */

const int    GFA_ACTIVE             = 0;                    // Status indicator of free aiming/free movement
const int    GFA_ACT_FREEAIM        = 1<<1;                 // Free aiming status (for spells only)
const int    GFA_ACT_MOVEMENT       = 1<<2;                 // Free movement status
const int    GFA_SPL_FREEAIM        = (FMODE_MAGIC          // Free aiming modifier for spells
                                       & ~GFA_ACT_MOVEMENT);

const int    GFA_ACTIVE_CTRL_SCHEME = 1;                    // Control scheme of active FMODE (for Gothic 1 always 1)
const int    GFA_CTRL_SCHEME_RANGED = 0;                    // Control scheme ranged
const int    GFA_CTRL_SCHEME_SPELLS = 0;                    // Control scheme spells
const int    GFA_SPELLS_G1_CTRL     = 1;                    // Internal reference for engine
const float  GFA_MAX_TURN_RATE_G1   = 2.0;                  // Gothic 1 has a maximum turn rate (engine default: 2.0)

const int    GFA_MIN_AIM_DIST       = 140;                  // Minimum targeting distance. Fixes vertical shooting bug
const int    GFA_MAX_DIST           = 5000;                 // Distance for shooting/reticle. Do not change
var   int    GFA_NO_AIM_NO_FOCUS;                           // Remove focus when not aiming (change in ini-file)
var   int    GFA_RAY_INTERVAL;                              // Perform trace ray every x ms (change in ini-file)
var   int    GFA_AimRayPrevCalcTime;                        // Time of last trace ray calculation

const int    GFA_RETICLE_MIN_SIZE   = 32;                   // Reticle size in pixels (at its smallest)
const int    GFA_RETICLE_MAX_SIZE   = 64;                   // Reticle size in pixels (at its biggest)
const int    GFA_RETICLE_PTR        = 0;                    // Reticle zCView
var   int    GFA_AimVobHasFX;                               // For performance: check whether FX needs to be removed

const string GFA_CAMERA             = "CamModGFA";          // CCamSys_Def script instance

const float  GFA_FOCUS_FAR_NPC      = 15.0;                 // NPC azimuth for ranged focus for free aiming
const float  GFA_FOCUS_SPL_NPC      = 15.0;                 // NPC azimuth for spell focus for free aiming
const int    GFA_FOCUS_SPL_ITM      = 0;                    // Item priority for spell focus for free aiming

const int    GFA_FOCUS_FAR_NPC_DFT  = FLOATNULL;            // Backup NPC azimuth from ranged focus instance
const int    GFA_FOCUS_SPL_NPC_DFT  = FLOATNULL;            // Backup NPC azimuth from spell focus instance
const int    GFA_FOCUS_SPL_ITM_DFT  = 0;                    // Backup item priority from spell focus instance


/* Aim movement */

var   int    GFA_IsStrafing;                                // State of strafing (movement ID)
const int    GFA_STRAFE_POSTCAST    = 500;                  // Time (ms) to remain in aim movement after casting a spell
var   int    GFA_SpellPostCastDelay;                        // Keep record of post cast delay

const int    GFA_MOVE_FORWARD       = 1<<0;                 // ID (first bit) for moving forward while aiming
const int    GFA_MOVE_BACKWARD      = 1<<1;                 // ID (second bit) for moving backward while aiming
const int    GFA_MOVE_LEFT          = 1<<2;                 // ID (third bit) for moving left while aiming
const int    GFA_MOVE_RIGHT         = 1<<3;                 // ID (fourth bit) for moving right while aiming
const int    GFA_MOVE_TRANS         = 11;                   // Transition ID
const int    GFA_HURT_ANI           = 12;                   // Hurt animation ID

const string GFA_AIM_ANIS[13]       = {                     // Names of aiming movement animations (upper case!)
    "_AIM_STAND",                                           //  0        Transition to standing (ranged combat only)
    "_AIM_MOVEF",                                           //  1  0001  GFA_MOVE_FORWARD
    "_AIM_MOVEB",                                           //  2  0010  GFA_MOVE_BACKWARD
    "",                                                     //  3
    "_AIM_MOVEL",                                           //  4  0100  GFA_MOVE_LEFT
    "_AIM_MOVELF",                                          //  5  0101  GFA_MOVE_LEFT | GFA_MOVE_FORWARD
    "_AIM_MOVELB",                                          //  6  0110  GFA_MOVE_LEFT | GFA_MOVE_BACKWARD
    "",                                                     //  7
    "_AIM_MOVER",                                           //  8  1000  GFA_MOVE_RIGHT
    "_AIM_MOVERF",                                          //  9  1001  GFA_MOVE_RIGHT | GFA_MOVE_FORWARD
    "_AIM_MOVERB",                                          // 10  1010  GFA_MOVE_RIGHT | GFA_MOVE_BACKWARD
    "_AIM_MOVE_2",                                          // 11        Transition prefix
    "_AIM_HURT"                                             // 12        Hurting animation: Caution, different layer
};

const int    GFA_MOVE_ANI_LAYER     = 2;                    // Layer of aiming movement animations (see Humans.mds)


/* Ranged combat */

const string GFA_TRAIL_FX           = "GFA_TRAIL_VFX";      // Trail strip FX. Should not be changed
const string GFA_TRAIL_FX_SIMPLE    = "GFA_TRAIL_INST_VFX"; // Simplified trail strip FX for use in Gothic 1
const string GFA_BREAK_FX           = "GFA_DESTROY_VFX";    // FX of projectile breaking on impact with world

const int    GFA_DRAWTIME_READY     = 475;                  // Time (ms) for readying the weapon. Fixed by animation
const int    GFA_DRAWTIME_RELOAD    = 1250;                 // Time (ms) for reloading the weapon. Fixed by animation
var   int    GFA_BowDrawOnset;                              // Time onset of drawing the bow
var   int    GFA_MouseMovedLast;                            // Time of last mouse movement

const float  GFA_SCATTER_HIT        = 1.5;                  // (Visual angle)/2 within which everything is a hit
const float  GFA_SCATTER_MISS       = 4.2;                  // (Visual angle)/2 outside which everything is a miss
const float  GFA_SCATTER_MAX        = 6.0;                  // (Visual angle)/2 of maximum scatter (all in degrees)

var   int    GFA_CollTrj[6];                                // Projectile trajectory of last collision candidate
var   string GFA_HitModelNode;                              // Name of model node that was hit

const int    DMG_NO_CHANGE          = 0;                    // Do not adjust the damage
const int    DMG_DO_NOT_KNOCKOUT    = 1;                    // Normal damage, shot may kill but never knockout (HP != 1)
const int    DMG_DO_NOT_KILL        = 2;                    // Normal damage, shot may knockout but never kill (HP > 0)
const int    DMG_INSTANT_KNOCKOUT   = 3;                    // One shot knockout (HP = 1)
const int    DMG_INSTANT_KILL       = 4;                    // One shot kill (HP = 0)

const int    DMG_BEHAVIOR_MAX       = 4;


/* Debugging */

var   int    GFA_StatsShots;                                // Shooting statistics: Count total number of shots taken
var   int    GFA_StatsHits;                                 // Shooting statistics: Count positive hits on target

var   int    GFA_DebugTRTrj;                                // Handle of trace ray trajectory
var   int    GFA_DebugTRBBox;                               // Handle of trace ray intersection
var   int    GFA_DebugTRBBoxVob;                            // Handle of trace ray detected vob bounding box
var   int    GFA_DebugCollTrj;                              // Handle of projectile trajectory
var   int    GFA_DebugBoneBBox;                             // Handle of bone bounding box
var   int    GFA_DebugBoneOBBox;                            // Handle of bone oriented bounding box


/* Numerical constants */

const int    FLOATONE_NEG           = -1082130432;          // -1 as float
const int    FLOAT1C                = 1120403456;           // 100 as float
const int    FLOAT3C                = 1133903872;           // 300 as float
const int    FLOAT1K                = 1148846080;           // 1000 as float
