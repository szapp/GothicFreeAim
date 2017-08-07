/*
 * This file contains all basic settings. Values deviating too far from the default values should either be avoided or
 * tested thoroughly.
 */


/*
 * Features that can be independently enabled and disabled. It is possible, to not use free aiming at all, but still
 * make use of the other features. Any combination of features is possible, while completely disabling the others.
 *
 * If GFA_RANGED and GFA_SPELLS are both set to false, the free aiming feature is completely disabled, not affecting
 * the other features, however.
 *
 * A list to the config files that correspond to each feature and offer more indepth customization:
 *  ranged.d        GFA_RANGED
 *  spell.d         GFA_SPELLS
 *  reticle.d       GFA_RANGED and GFA_SPELLS
 *  collectable.d   GFA_REUSE_PROJECTILES
 *  collision.d     GFA_CUSTOM_COLLISIONS
 *  criticalHit.d   GFA_CRITICALHITS
 */
const int   GFA_RANGED             = TRUE;  // Free aiming for ranged combat (bow and crossbow)
const int   GFA_SPELLS             = TRUE;  // Free aiming for magic combat (spells)
const int   GFA_REUSE_PROJECTILES  = TRUE;  // Enable collection & re-using of shot projectiles
const int   GFA_CUSTOM_COLLISIONS  = TRUE;  // Custom collision behaviors and hit registration
const int   GFA_CRITICALHITS       = TRUE;  // Critical hits for ranged combat (e.g. head shots)


/*
 * Adjustable settings (depending on the above features)
 */
// GFA_RANGED
const int   GFA_TRUE_HITCHANCE     = TRUE;  // Enable accuracy scattering (true) or use Gothic default hit chance
const int   GFA_DRAWTIME_MAX       = 1200;  // Max draw time (ms): When is the bow fully drawn
const int   GFA_TRAJECTORY_ARC_MAX = 200;   // Max time (ms) after which the projectile trajectory drops off
const float GFA_PROJECTILE_GRAVITY = 0.1;   // Gravity of projectile after GFA_TRAJECTORY_ARC_MAX ms
const int   GFA_MAX_RECOIL         = 16;    // Amount of maximum vertical mouse movement on recoil
const int   GFA_HORZ_RECOIL        = 2;     // Range [-x, x] of horizontal mouse deviation on recoil

// GFA_RANGED and GFA_SPELLS
const float GFA_ROTATION_SCALE     = 0.16;  // Turn rate while aiming (changes Gothic 1 controls only)
const int   GFA_CAMERA_X_SHIFT     = FALSE; // Set to TRUE if camera is set to shoulderview, s.a. (not recommended)
const int   GFA_DEBUG_CONSOLE      = TRUE;  // Enable console commands (debugging). Disable in final mod
const int   GFA_DEBUG_WEAKSPOT     = FALSE; // Show weakspot (critical hits) debugging visualization by default
const int   GFA_DEBUG_TRACERAY     = FALSE; // Show trace ray debugging visualization by default

// GFA_CUSTOM_COLLISIONS
const int   GFA_COLL_PRIOR_NPC     = -1;    // After wld collision: ignore(-1), destory(0), coll(1) or deflct(2) off NPC
const int   GFA_TRIGGER_COLL_FIX   = TRUE;  // Trigger collision fix (disable collision), necessary for Gothic 2 only
