/*
 * Internal constants of GFA
 *
 * Gothic Free Aim (GFA) v1.0.0-beta - Free aiming for the video games Gothic 1 and Gothic 2 by Piranha Bytes
 * Copyright (C) 2016-2017  mud-freak (@szapp)
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
const string GFA_VERSION            = "Gothic Free Aim v1.0.0-beta";
const int    GFA_LEGO_FLAGS         = LeGo_HookEngine       // For initializing all hooks
                                    | LeGo_FrameFunctions   // For projectile gravity
                                    | LeGo_ConsoleCommands  // For console commands and debugging
                                    | LeGo_Random           // For scattering and other uses of random numbers
                                    | LeGo_PrintS;          // To be safe (in case it is used in critical hit event)

var   int    GFA_Flags;                                     // Flags for initialization of GFA
const int    GFA_BUGFIXES           = 0<<0;                 // Misc Gothic bug fixes, applied always (pseudo flag)
const int    GFA_RANGED             = 1<<0;                 // Free aiming for ranged combat (bow and crossbow)
const int    GFA_SPELLS             = 1<<1;                 // Free aiming for spell combat (spells)
const int    GFA_REUSE_PROJECTILES  = 1<<2;                 // Enable collection and re-using of shot projectiles
const int    GFA_CUSTOM_COLLISIONS  = 1<<3;                 // Custom collision/damage behaviors and hit registration
const int    GFA_CRITICALHITS       = 1<<4;                 // Critical hits for ranged combat (e.g. head shots)
const int    GFA_ALL                = (1<<5) - 1;           // Initialize all features

const int    GFA_DRAWTIME_READY     = 475;                  // Time (ms) for readying the weapon. Fixed by animation
const int    GFA_DRAWTIME_RELOAD    = 1250;                 // Time (ms) for reloading the weapon. Fixed by animation
var   int    GFA_BowDrawOnset;                              // Time onset of drawing the bow
var   int    GFA_MouseMovedLast;                            // Time of last mouse movement

const int    GFA_RETICLE_MIN_SIZE   = 32;                   // Smallest reticle size in pixels
const int    GFA_RETICLE_MAX_SIZE   = 64;                   // Biggest reticle size in pixels
var   int    GFA_ReticleHndl;                               // Handle of the reticle
var   int    GFA_AimVobHasFX;                               // For performance: check whether FX needs to be removed

const string GFA_TRAIL_FX           = "GFA_TRAIL_VFX";      // Trail strip FX. Should not be changed
const string GFA_TRAIL_FX_SIMPLE    = "GFA_TRAIL_INST_VFX"; // Simplified trail strip FX for use in Gothic 1
const string GFA_BREAK_FX           = "GFA_DESTROY_VFX";    // FX of projectile breaking on impact with world
const string GFA_CAMERA             = "CamModGFA";          // CCamSys_Def script instance

const int    GFA_MIN_AIM_DIST       = 140;                  // Minimum targeting distance. Fixes vertical shooting bug
const int    GFA_MAX_DIST           = 5000;                 // Distance for shooting/reticle. Do not change
var   int    GFA_AimRayInterval;                            // Perform trace ray every x ms (change in ini-file)
var   int    GFA_AimRayPrevCalcTime;                        // Time of last trace ray calculation

const float  GFA_SCATTER_HIT        = 2.6;                  // (Visual angle)/2 within which everything is a hit
const float  GFA_SCATTER_MISS       = 3.3;                  // (Visual angle)/2 outside which everything is a miss
const float  GFA_SCATTER_MAX        = 5.0;                  // (Visual angle)/2 of maximum scatter (all in degrees)

var   int    GFA_LastHitCritical;                           // Was the last hit critical (will be reset immediately)

var   int    GFA_StatsShots;                                // Shooting statistics: Count total number of shots taken
var   int    GFA_StatsHits;                                 // Shooting statistics: Count positive hits on target
var   int    GFA_StatsCriticalHits;                         // Shooting statistics: Count number of critical hits

const float  GFA_MAX_TURN_RATE_G1   = 2.0;                  // Gothic 1 has a maximum turn rate (engine default: 2.0)

const int    GFA_ACTIVE             = 0;                    // Status indicator of free aiming
const int    GOTHIC_CONTROL_SCHEME  = 1;                    // Active control scheme (for Gothic 1 always 1)

const float  GFA_FOCUS_FAR_NPC      = 15.0;                 // NPC azimuth for ranged focus for free aiming
const float  GFA_FOCUS_SPL_NPC      = 15.0;                 // NPC azimuth for spell focus for free aiming
const int    GFA_FOCUS_SPL_ITM      = 0;                    // Item priority for spell focus for free aiming

const int    GFA_FOCUS_FAR_NPC_DFT  = FLOATNULL;            // Backup NPC azimuth from ranged focus instance
const int    GFA_FOCUS_SPL_NPC_DFT  = FLOATNULL;            // Backup NPC azimuth from spell focus instance
const int    GFA_FOCUS_SPL_ITM_DFT  = 0;                    // Backup item priority from spell focus instance

const int    FLOAT1C                = 1120403456;           // 100 as float
const int    FLOAT3C                = 1133903872;           // 300 as float
const int    FLOAT1K                = 1148846080;           // 1000 as float

var   int    GFA_DebugWSBBox[6];                            // Weak spot bounding box for debug visualization
var   int    GFA_DebugWSTrj[6];                             // Projectile trajectory for debug visualization
var   int    GFA_DebugTRBBox[6];                            // Trace ray intersection for debug visualization
var   int    GFA_DebugTRTrj[6];                             // Trace ray trajectory for debug visualization
var   int    GFA_DebugTRPrevVob;                            // Trace ray detected vob bounding box pointer for debugging

var   int    GFA_IsStrafing;                                // State of strafing

const int    GFA_MOVE_FORWARD       = 1<<0;                 // ID (first bit) for moving forward while aiming
const int    GFA_MOVE_BACKWARD      = 1<<1;                 // ID (second bit) for moving backward while aiming
const int    GFA_MOVE_LEFT          = 1<<2;                 // ID (third bit) for moving left while aiming
const int    GFA_MOVE_RIGHT         = 1<<3;                 // ID (fourth bit) for moving right while aiming
const int    GFA_MOVE_TRANS         = 11;                   // Transistion ID

const string GFA_AIM_ANIS[12]       = {                     // Names of aiming movement animations (upper case!)
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
    "_AIM_MOVE_2"                                           // 11        Transistion prefix
};

const int    GFA_MOVE_ANI_LAYER     = 2;                    // Layer of aiming movement animations (see Humans.mds)