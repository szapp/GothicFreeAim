/*
 * This file contains all configurations for collision and hit registration of projectiles.
 *
 * Supported: Gothic 2 only
 */


/*
 * This function is called every time an NPC is hit by a projectile (arrows and bolts). It can be used to define the
 * collision behavior (or disabling hit registration) on NPCs based on different criteria.
 * The argument 'material' holds the material of the armor (of the target), -1 for no armor equipped. For armors of NPCs
 * the materials are defined as in Constants.d (MAT_METAL, MAT_WOOD, ...).
 *
 * Ideas: 'ineffective' ranged weapons, armor materials immune to arrows, disable friendly-fire, maximum range. Examples
 * are written below and commented out and serve as inspiration of what is possible
 */
func int freeAimHitRegNpc(var C_Npc target, var C_Item weapon, var int material) {
    // Valid return values are:
    const int DESTROY = 0; // No hit registration (no damage), projectile is destroyed
    const int COLLIDE = 1; // Hit registration (damage), projectile is put into inventory
    const int DEFLECT = 2; // No hit registration (no damage), projectile is repelled

    if (target.aivar[AIV_PARTYMEMBER]) && (target.aivar[AIV_LASTTARGET] != Hlp_GetInstanceID(hero)) {
        // Disable friendly-fire
        return DESTROY;
    };

    /*
    if (material == MAT_METAL) && (Hlp_Random(100) < 20) {
        // Metal armors may be more durable
        return DEFLECT;
    }; */

    if (Npc_GetDistToPlayer(target) > FIGHT_DIST_CANCEL) {
        // If player is too far away, do nothing. This is important, because of a limitation in the AI. NPCs do not
        // react to damage if they are shot from outside of the ranged combat distance. This check fixes the problem
        return DESTROY;
    };

    /*
    if (Hlp_IsValidItem(weapon)) {
        // The weapon can also be considered (e.g. ineffective weapons). Make use of 'weapon' for that
        // Caution: Weapon may have been unequipped already at this time (unlikely)! Use Hlp_IsValidItem(weapon)

        if (weapon.ineffective) {
            // Special case for weapon property
            return DEFLECT;
        };
    }; */

    // Usually all shots on NPCs should be registered. For defining the hit chances see freeAimGetAccuracy()
    return COLLIDE;
};


/*
 * This function is called every time the world (static or vobs) is hit by a projectile (arrows ans bolts). It can be
 * used to define the collision behavior for different materials or surface textures.
 * Note: Unlike freeAimHitRegNpc() and all other config functions, this function is also called for NPC shooters!
 *
 * Examples are written below and commented out and serve as inspiration of what is possible.
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

    if (material == WOOD) {
        // Projectiles stay stuck in wood (default in Gothic)
        return COLLIDE;
    };

    if (Hlp_StrCmp(texture, "MOWOBOWMARK01.TGA")) { // Bullseye/shooting range texture
        // Condition by surface texture
        return COLLIDE;
    };

    /*
    if (Npc_IsPlayer(shooter)) {
        // Keep in mind that this function is also called for NPC shooters
        // ...
    }; */

    if (material == STONE) && (Hlp_Random(100) < 20) {
        // The projectile might break on impact with stone (20% of the shots)
        return DESTROY;
    };

    /*
    if (Hlp_IsValidItem(weapon)) {
        // The weapon can also be considered (e.g. ineffective weapons). Make use of 'weapon' for that
        // Caution: Weapon may have been unequipped already at this time (unlikely)! Use Hlp_IsValidItem(weapon)

        if (weapon.ineffective) {
            // Special case for weapon property
            return DEFLECT;
        };
    }; */

    // Projectiles deflect off of all other surfaces (default behavior)
    return DEFLECT;
};
