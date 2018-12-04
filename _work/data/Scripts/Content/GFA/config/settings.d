/*
 * This file contains the basic settings of this script package, based on the different features.
 *
 * Values deviating too far from the default values should either be avoided or tested thoroughly!
 */


// GFA_RANGED
const int   GFA_TRUE_HITCHANCE     = TRUE;  // Enable accuracy scattering (true) or use Gothic default hit chance
const int   GFA_UPDATE_RET_SHOOT   = FALSE; // Also update the reticle while the shooting/reloading animation plays
const int   GFA_TRAJECTORY_ARC_MAX = 200;   // Maximum time (ms) after which projectile trajectory drops off (gravity)
const float GFA_PROJECTILE_GRAVITY = 0.1;   // Gravity to apply to projectile after GFA_TRAJECTORY_ARC_MAX ms
const int   GFA_MAX_RECOIL         = 15;    // Visual angle (degrees) of maximum recoil (recoil = 100%)

// GFA_RANGED and/or GFA_SPELLS
const int   GFA_STRAFING           = TRUE;  // Enable/disable movement while aiming (for both ranged and spell combat)
const float GFA_ROTATION_SCALE     = 0.16;  // Turn rate while aiming (changes Gothic 1 controls only)
const int   GFA_CAMERA_X_SHIFT     = FALSE; // Set to true, if camera is set to shoulderview (not recommended)
const int   GFA_DEBUG_CONSOLE      = TRUE;  // Enable console commands (debugging). Disable in final mod
const int   GFA_DEBUG_PRINT        = FALSE; // Output information to zSpy by default (can be enabled via console)

// GFA_CUSTOM_COLLISIONS
const int   GFA_COLL_PRIOR_NPC     = -1;    // When bouncing off: ignore(-1), destroy(0), coll(1) or deflect(2) off NPC
const int   GFA_TRIGGER_COLL_FIX   = TRUE;  // Trigger collision fix (disable collision), necessary for Gothic 2 only
