/*
 * This file contains all configurations for free aiming in spell combat (spells). See config\reticle.d for reticle
 * configurations.
 *
 * Requires the feature GFA_SPELLS (see config\settings.d).
 *
 * List of included functions:
 *  func int GFA_ShiftAimVob(int spellID)
 *
 * Related functions that can be used:
 *  func void GFA_AimVobAttachFX(string effectInst)
 *  func void GFA_AimVobDetachFX()
 */


/*
 * This function is called continuously while aiming with spells to correct the aim vob position. The return value is
 * interpreted as the amount of centimeters, the aim vob should be shifted along the camera out vector (viewing angle).
 * This function should never be of use and should be adjusted for individual spells only. Usually, no spell requires
 * the aim vob to be shifted. Exceptions are spells that utilize the aim vob as target to spawn VFX on it with the
 * functions GFA_AimVobAttachFX() and GFA_AimVobDetachFX().
 */
func int GFA_ShiftAimVob(var int spellID, var int posPtr) {
    // if (spellID == ...) { return -100; }; // Push the aim vob 100 cm away from any wall towards the player

    // Usually none
    return 0;
};
