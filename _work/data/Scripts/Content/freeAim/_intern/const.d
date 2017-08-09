/*
 * Constants
 *
 * Gothic Free Aim (GFA) v1.0.0-alpha - Free aiming for the video games Gothic 1 and Gothic 2 by Piranha Bytes
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
const string GFA_VERSION            = "Gothic Free Aim v1.0.0-alpha";
const int    GFA_LEGO_FLAGS         = LeGo_HookEngine       // For initializing all hooks
                                    | LeGo_FrameFunctions   // For projectile gravity
                                    | LeGo_ConsoleCommands  // For console commands and debugging
                                    | LeGo_Random           // For scattering and other uses of random numbers
                                    | LeGo_PrintS;          // To be safe (in case it is used in critical hit event)

const int    GFA_DRAWTIME_READY     = 650;                  // Time (ms) for readying the bow. Fixed by animation
const int    GFA_DRAWTIME_RELOAD    = 1110;                 // Time (ms) for reloading the bow. Fixed by animation
var   int    GFA_BowDrawOnset;                              // Time onset of drawing the bow

const int    GFA_RETICLE_MIN_SIZE   = 32;                   // Smallest reticle size in pixels
const int    GFA_RETICLE_MAX_SIZE   = 64;                   // Biggest reticle size in pixels
var   int    GFA_ReticleHndl;                               // Handle of the reticle
var   int    GFA_AimVobHasFX;                               // Performance: check whether FX needs to be removed

const string GFA_TRAIL_FX           = "GFA_TRAIL_VFX";      // Trailstrip FX. Should not be changed
const string GFA_TRAIL_FX_SIMPLE    = "GFA_TRAIL_INST_VFX"; // Simplified trailstrip FX for use in Gothic 1
const string GFA_BREAK_FX           = "GFA_DESTROY_VFX";    // FX of projectile breaking on impact with world
const string GFA_CAMERA             = "CamModGFA";          // CCamSys_Def script instance

const int    GFA_MIN_AIM_DIST       = 140;                  // Minimum targeting distance. Fixes vertical shooting bug
const int    GFA_MAX_DIST           = 5000;                 // Distance for shooting/reticle. Do not change
var   int    GFA_AimRayInterval;                            // Perform trace ray every x ms (change in ini-file)
var   int    GFA_AimRayPrevCalcTime;                        // Time of last trace ray calculation


const float  GFA_SCATTER_HIT        = 2.6;                  // (Visual angle)/2 within which everything is a hit
const float  GFA_SCATTER_MISS       = 3.3;                  // (Visual angle)/2 outside which everything is a miss
const float  GFA_SCATTER_MAX        = 5.0;                  // (Visual angle)/2 of maximum scatter (all in degrees)

const float  GFA_MAX_TURN_RATE_G1   = 2.0;                  // Gothic 1 has a maximum turn rate (engine default: 2.0)

var   int    GFA_Recoil;                                    // Amount of vertical mouse movement on recoil

const int    FLOAT1C                = 1120403456;           // 100 as float
const int    FLOAT3C                = 1133903872;           // 300 as float
const int    FLOAT1K                = 1148846080;           // 1000 as float

const int    GFA_ACTIVE             = 0;                    // Status indicator of free aiming
const int    GFA_INIT_HITREG        = 0;                    // Check if hit registration hook was initialized

var   int    GFA_LastHitCritical;                           // Was the last hit critical (will be reset immediately)

var   int    GFA_DebugWSBBox[6];                            // Weakspot bounding box for debug visualization
var   int    GFA_DebugWSTrj[6];                             // Projectile trajectory for debug visualization
var   int    GFA_DebugTRBBox[6];                            // Trace ray intersection for debug visualization
var   int    GFA_DebugTRTrj[6];                             // Trace ray trajectory for debug visualization
var   int    GFA_DebugTRPrevVob;                            // Trace ray detected vob bbox pointer for debugging
