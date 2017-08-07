/*
 * This file contains all configurations for magic combat (spells).
 */


/*
 * This function is called continuously while aiming with spells to correct the aim vob position. The return value is
 * interpreted as the amount of centimeters, the aim vob should be shifted along the camera out vector (viewing angle).
 * This function should never be of use and should be adjusted for individual spells only. Usually, no spell requires
 * the aim vob to be shifted. Exceptions are spells that utilize the aim vob as target to spawn FX on it with the
 * functions freeAimAttachFX() and freeAimDetachFX().
 */
func int freeAimShiftAimVob(var int spellID) {
    // if (spellID == ...) { return -100; }; // Push the aim vob 100 cm away from any wall towards the player

    // Usually none
    return 0;
};
