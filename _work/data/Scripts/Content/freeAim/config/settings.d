/*
 * This file contains all basic settings. Values deviating too far from the default values should either be avoided or
 * tested thoroughly.
 */


/*
 * Adjustable settings
 */
const int    FREEAIM_REUSE_PROJECTILES  = TRUE;            // Enable collection and re-using of shot projectiles
const int    FREEAIM_DISABLE_SPELLS     = FALSE;           // Disable free aiming for spells (ranged uneffected)
const int    FREEAIM_DRAWTIME_MAX       = 1200;            // Max draw time (ms): When is the bow fully drawn
const int    FREEAIM_TRUE_HITCHANCE     = TRUE;            // Enable scattering (true) or use Gothic default hit chance
const int    FREEAIM_TRIGGER_COLL_FIX   = TRUE;            // Apply trigger collision fix (disable collision)
const int    FREEAIM_DEBUG_CONSOLE      = TRUE;            // Enable console commands (debugging). Disable in final mod
const int    FREEAIM_DEBUG_WEAKSPOT     = FALSE;           // Show weakspot debugging visualization by default
const int    FREEAIM_DEBUG_TRACERAY     = FALSE;           // Show trace ray debugging visualization by default


/*
 * Modifying any line below is not recommended!
 */
const int    FREEAIM_TRAJECTORY_ARC_MAX = 400;             // Max time (ms) after which the trajectory drops off
const float  FREEAIM_PROJECTILE_GRAVITY = 0.1;             // Gravity of projectile after FREEAIM_TRAJECTORY_ARC_MAX ms
const string FREEAIM_CAMERA             = "CamModFreeAim"; // CCamSys_Def script instance (change not recommended)
const int    FREEAIM_CAMERA_X_SHIFT     = FALSE;           // Camera is set to shoulderview, s.a. (not recommended)
const float  FREEAIM_ROTATION_SCALE     = 0.16;            // Turn rate while aiming (changes Gothic 1 controls only)
