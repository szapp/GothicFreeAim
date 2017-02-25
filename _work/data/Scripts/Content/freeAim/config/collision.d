/*
 * This file contains all configurations for collision and hit registration of projectiles.
 */

/*
 * This function is called every time an npc is hit by a projectile (arrows and bolts). It can be used to define the
 * collision behavior (or disabling hit registration) on npcs based on different criteria.
 * Ideas: 'ineffective' ranged weapons, armor materials immune to arrows, disable friendly-fire, maximum range
 */
func int freeAimHitRegNpc(var C_Npc target, var C_Item weapon, var int material) {
    // Valid return values are:
    const int DESTROY = 0; // No hit reg (no damage), projectile is destroyed
    const int COLLIDE = 1; // Hit reg (damage), projectile is put into inventory
    const int DEFLECT = 2; // No hit reg (no damage), projectile is repelled
    // The argument 'material' holds the material of the armor (of the target), -1 for no armor equipped
    // For armors of npcs the materials are defined as in Constants.d (MAT_METAL, MAT_WOOD, ...)
    if (target.aivar[AIV_PARTYMEMBER]) // Disable friendly-fire
    && (target.aivar[AIV_LASTTARGET] != Hlp_GetInstanceID(hero)) { return DESTROY; };
    //  if (material == MAT_METAL) && (Hlp_Random(100) < 20) { return DEFLECT; }; // Metal armors may be more durable
    if (Npc_GetDistToPlayer(target) > FIGHT_DIST_CANCEL) { return DESTROY; }; // If player is too far away, do nothing
    // The weapon can also be considered (e.g. ineffective weapons). Make use of 'weapon' for that
    // Caution: Weapon may have been unequipped already at this time (unlikely)! Use Hlp_IsValidItem(weapon)
    //  if (Hlp_IsValidItem(weapon)) && (weapon.ineffective) { return DEFLECT; }; // Special case for weapon property
    return COLLIDE; // Usually all shots on npcs should be registered, see freeAimGetAccuracy() above
};

/*
 * This function is called every time the world (static or vobs) is hit by a projectile (arrows ans bolts). It can be
 * used to define the collision behavior for different materials or surface textures.
 * Note: Unlike freeAimHitRegNpc() and all other functions here, this function is also called for npc shooters!
 */
func int freeAimHitRegWld(var C_Npc shooter, var C_Item weapon, var int material, var string texture) {
    // Valid return values are:
    const int DESTROY = 0; // Projectile is destroyed on impact
    const int COLLIDE = 1; // Projectile gets stuck in the surface
    const int DEFLECT = 2; // Projectile is repelled
    // Note: The materials of the world are defined differently (than the familiar item-materials):
    const int METAL = 1;
    const int STONE = 2;
    const int WOOD  = 3;
    const int EARTH = 4;
    const int WATER = 5;
    const int SNOW  = 6;
    const int UNDEF = 0;
    if (material == WOOD) { return COLLIDE; }; // Projectiles stay stuck in wood (default in gothic)
    if (Hlp_StrCmp(texture, "MOWOBOWMARK01.TGA")) { return COLLIDE; }; // Condition by surface texture
    //  if (Npc_IsPlayer(shooter)) ... // Keep in mind that this function is also called for npc shooters
    if (material == STONE) && (Hlp_Random(100) < 20) { return DESTROY; }; // The projectile might break on impact
    // The example in the previous line can also be treated in freeAimGetUsedProjectileInstance() below
    // The weapon can also be considered (e.g. ineffective weapons). Make use of 'weapon' for that
    // Caution: Weapon may have been unequipped already at this time (unlikely)! Use Hlp_IsValidItem(weapon)
    //  if (Hlp_IsValidItem(weapon)) && (weapon.ineffective) { return DEFLECT; }; // Special case for weapon property
    return DEFLECT; // Projectiles deflect off of all other surfaces
};
