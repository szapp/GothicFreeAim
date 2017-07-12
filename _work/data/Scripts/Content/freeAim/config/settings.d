/*
 * This file contains all basic settings. Values deviating too far from the default values should either be avoided or
 * tested thoroughly.
 */


/*
 * Features that can be independently enabled and disabled. It is possible, to not use free aiming at all, but still
 * make use of the other features. Any combination of features is possible, while completely disabling the others.
 *
 * An exception is the custom collision feature: It can be used without free aiming, but if free aiming for ranged
 * combat and scattering (FREEAIM_TRUE_HITCHANCE) are both enabled, custom collision will be enabled automatically.
 */
const int    FREEAIM_RANGED             = TRUE;            // Free aiming for ranged combat (bow and crossbow)
const int    FREEAIM_SPELLS             = TRUE;            // Free aiming for magic combat (spells)
const int    FREEAIM_REUSE_PROJECTILES  = TRUE;            // Enable collection and re-using of shot projectiles
const int    FREEAIM_CUSTOM_COLLISIONS  = TRUE;            // Elaborate, custom collision and hit registration config
const int    FREEAIM_CRITICALHITS       = TRUE;            // Critical hits (like head shots)


/*
 * Adjustable settings (depending on the above features)
 */
// Only take effect with FREEAIM_RANGED
const int    FREEAIM_TRUE_HITCHANCE     = TRUE;            // Enable scattering (true) or use Gothic default hit chance
const int    FREEAIM_DRAWTIME_MAX       = 1200;            // Max draw time (ms): When is the bow fully drawn
const int    FREEAIM_TRAJECTORY_ARC_MAX = 200;             // Max time (ms) after which the trajectory drops off
const float  FREEAIM_PROJECTILE_GRAVITY = 0.1;             // Gravity of projectile after FREEAIM_TRAJECTORY_ARC_MAX ms
const int    FREEAIM_MAX_RECOIL         = 16;              // Amount of maximum vertical mouse movement on recoil
const int    FREEAIM_HORZ_RECOIL        = 2;               // Range [-x, x] of horizontal mouse deviation on recoil

// Only take effect with FREEAIM_RANGED or FREEAIM_SPELLS
const float  FREEAIM_ROTATION_SCALE     = 0.16;            // Turn rate while aiming (changes Gothic 1 controls only)
const string FREEAIM_CAMERA             = "CamModFreeAim"; // CCamSys_Def script instance (change not recommended)
const int    FREEAIM_CAMERA_X_SHIFT     = FALSE;           // Camera is set to shoulderview, s.a. (not recommended)
const int    FREEAIM_DEBUG_CONSOLE      = TRUE;            // Enable console commands (debugging). Disable in final mod
const int    FREEAIM_DEBUG_WEAKSPOT     = FALSE;           // Show weakspot debugging visualization by default
const int    FREEAIM_DEBUG_TRACERAY     = FALSE;           // Show trace ray debugging visualization by default

// Only take effect with FREEAIM_CUSTOM_COLLISIONS
const int    FREEAIM_COLL_PRIOR_NPC     = -1;              // After coll: ignre(-1), dstry(0), coll(1), dflct(2) off NPC
const int    FREEAIM_TRIGGER_COLL_FIX   = TRUE;            // Apply trigger collision fix (disable collision)
