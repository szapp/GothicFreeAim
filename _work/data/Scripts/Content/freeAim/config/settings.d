/*
 * This file contains all basic settings and allows enabling and disabling the features of this script package.
 * Values deviating too far from the default values should either be avoided or tested thoroughly.
 */


/*
 * These are the features that can be independently enabled and disabled. It is possible to not use free aiming at all,
 * but still make use of the other features. Any combination of features is possible, while completely disabling the
 * others.
 *
 * If GFA_RANGED and GFA_SPELLS are both set to false, the free aiming feature is completely disabled, not affecting
 * the other features, however.
 *
 * Note: The recommended setting is to enable all features, optionally with re-usable projectiles.
 *
 * A list to the config files that correspond to each feature and offer more in-depth customization. It is recommended
 * to read the header comments of the functions in all config files, prior to a decision whether to keep or disable a
 * feature, because there is a lot of information regarding each feature.
 *  ranged.d        GFA_RANGED
 *  spell.d         GFA_SPELLS
 *  reticle.d       GFA_RANGED and GFA_SPELLS
 *  collectable.d   GFA_REUSE_PROJECTILES
 *  collision.d     GFA_CUSTOM_COLLISIONS
 *  criticalHit.d   GFA_CRITICALHITS
 */
const int   GFA_RANGED             = TRUE;  // Free aiming for ranged combat (bow and crossbow)
const int   GFA_SPELLS             = TRUE;  // Free aiming for magic combat (spells)
const int   GFA_REUSE_PROJECTILES  = TRUE;  // Enable collection and re-using of shot projectiles
const int   GFA_CUSTOM_COLLISIONS  = TRUE;  // Custom collision behaviors, hit registration and damage behaviors
const int   GFA_CRITICALHITS       = TRUE;  // Critical hits for ranged combat (e.g. head shots)


/*
 * Adjustable settings (depending on the above features)
 */
// GFA_RANGED
const int   GFA_TRUE_HITCHANCE     = TRUE;  // Enable accuracy scattering (true) or use Gothic default hit chance
const int   GFA_DRAWTIME_MAX       = 1200;  // Maximum draw time (ms): When is the bow fully drawn
const int   GFA_TRAJECTORY_ARC_MAX = 200;   // Maximum time (ms) after which projectile trajectory drops off (gravity)
const float GFA_PROJECTILE_GRAVITY = 0.1;   // Gravity to apply to projectile after GFA_TRAJECTORY_ARC_MAX ms
const int   GFA_MAX_RECOIL         = 16;    // Amount of maximum vertical mouse movement on recoil
const int   GFA_HORZ_RECOIL        = 2;     // Range [-x, x] of horizontal mouse deviation on recoil

// GFA_RANGED and/or GFA_SPELLS
const int   GFA_NO_AIM_NO_FOCUS    = TRUE;  // Remove focus when not aiming: Prevent using bow/spell as enemy detector
const float GFA_ROTATION_SCALE     = 0.16;  // Turn rate while aiming (changes Gothic 1 controls only)
const int   GFA_CAMERA_X_SHIFT     = FALSE; // Set to true, if camera is set to shoulderview (not recommended)
const int   GFA_DEBUG_CONSOLE      = TRUE;  // Enable console commands (debugging). Disable in final mod
const int   GFA_DEBUG_PRINT        = FALSE; // Output information to zSpy by default (can be enabled via console)
const int   GFA_DEBUG_WEAKSPOT     = FALSE; // Show weakspot (critical hits) debugging visualization by default
const int   GFA_DEBUG_TRACERAY     = FALSE; // Show trace ray debugging visualization by default

// GFA_CUSTOM_COLLISIONS
const int   GFA_COLL_PRIOR_NPC     = -1;    // When bouncing off: ignore(-1), destory(0), coll(1) or deflect(2) off NPC
const int   GFA_TRIGGER_COLL_FIX   = TRUE;  // Trigger collision fix (disable collision), necessary for Gothic 2 only
