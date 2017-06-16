/*
 * This file contains all basic settings. Values deviating too far from the default values should either be avoided or
 * tested thoroughly.
 */

const int    FREEAIM_REUSE_PROJECTILES  = 1;               // Enable collection and re-using of shot projectiles
const int    FREEAIM_DISABLE_SPELLS     = 0;               // Disable free aiming for spells (ranged uneffected)
const int    FREEAIM_DRAWTIME_MAX       = 1200;            // Max draw time (ms): When is the bow fully drawn
const int    FREEAIM_DEBUG_CONSOLE      = 1;               // Enable console commands (debugging). Disable in final mod
const int    FREEAIM_DEBUG_WEAKSPOT     = 0;               // Show weakspot debugging visualization by default
const int    FREEAIM_DEBUG_TRACERAY     = 0;               // Show trace ray debugging visualization by default
const int    FREEAIM_TRIGGER_COLL_FIX   = 1;               // Apply trigger collision fix (disable collision)

// Modifying any line below is not recommended!
const float  FREEAIM_SCATTER_DEG        = 2.2;             // Maximum scatter radius in degrees for ranged accuracy
const int    FREEAIM_TRAJECTORY_ARC_MAX = 400;             // Max time (ms) after which the trajectory drops off
const float  FREEAIM_PROJECTILE_GRAVITY = 0.1;             // Gravity of projectile after FREEAIM_TRAJECTORY_ARC_MAX ms
const string FREEAIM_CAMERA             = "CamModFreeAim"; // CCamSys_Def script instance for free aim
const int    FREEAIM_CAMERA_X_SHIFT     = 0;               // Camera is set to shoulderview, s.a. (not recommended)
const float  FREEAIM_ROTATION_SCALE     = 0.05;            // Turn rate while aiming
const int    FREEAIM_HITDETECTION_EXP   = 0;               // Additional hit detection test (EXPERIMENTAL)
