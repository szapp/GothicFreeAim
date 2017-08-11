/*
 * This file contains all configurations for collision behaviors and hit registration of projectiles.
 *
 * Requires the feature GFA_CUSTOM_COLLISIONS (see config\settings.d).
 */


/*
 * This function is called every time an NPC is hit by a projectile (arrows and bolts). It can be used to define the
 * collision behavior (or disabling hit registration) on NPCs based on different criteria.
 * The argument 'material' holds the material of the armor (of the target), -1 for no armor equipped. For armors of NPCs
 * the materials are defined as in Constants.d (MAT_METAL, MAT_WOOD, ...).
 * Note: Unlike most other config functions, this function is also called for NPC shooters!
 *
 * Ideas: 'ineffective' ranged weapons, armor materials immune to arrows, disable friendly-fire, maximum range, ...
 * Examples  are written below and commented out and serve as inspiration of what is possible.
 */
func int GFA_GetCollisionWithNpc(var C_Npc shooter, var C_Npc target, var C_Item weapon, var int material) {
    // Valid return values are:
    const int DESTROY = 0; // No hit registration (no damage), projectile vanishes
    const int DAMAGE  = 1; // Positive hit registration, projectile is put into inventory if GFA_REUSE_PROJECTILES == 1
    const int DEFLECT = 2; // No hit registration (no damage), projectile bounces off

    // Disable friendly-fire for the player
    if (Npc_IsPlayer(shooter))
    && (target.aivar[AIV_PARTYMEMBER])
    && (target.aivar[AIV_LASTTARGET] != Hlp_GetInstanceID(hero)) {
        return DESTROY;
    };

    /*
    // Metal armors may be more durable
    if (material == MAT_METAL) && (Hlp_Random(100) < 20) {
        return DEFLECT;
    }; */

    // Fix AI reaction
    if (Npc_IsPlayer(shooter)) && (Npc_GetDistToPlayer(target) > FIGHT_DIST_CANCEL) {
        // If player is too far away, do nothing. This is important, because of a limitation in the AI. NPCs do not
        // react to damage if they are shot from outside of the ranged combat distance. This check fixes the problem
        return DESTROY;
    };

    /*
    // Ineffective weapons
    if (Hlp_IsValidItem(weapon)) {
        // Caution: Weapon may have been unequipped already at this time (unlikely)! Use Hlp_IsValidItem(weapon)

        if (weapon.ineffective) {
            // Special case for weapon property
            return DEFLECT;
        };
    }; */

    // Usually all shots on NPCs should be registered. For defining the hit chances see GFA_GetAccuracy()
    return DAMAGE;
};


/*
 * This function is called every time an NPC is hit by a projectile (arrows and bolts). It can be used to define the
 * damage behavior on NPCs based on different criteria. Damage behavior defines how much damage is finally applied to
 * the victim. This allows, e.g. preventing a victim to die, and instead knock it out with one shot (see examples).
 *
 * The argument 'isCriticalHit' states whether the active shot was a critical hit.
 *
 * Ideas: special knockout munition, NPCs that cannot be killed by ranged weapons, instant kill on critical hit, ...
 * Examples are written below and commented out and serve as inspiration of what is possible.
 */
func int GFA_GetDamageBehavior(var C_Npc target, var C_Item weapon, var int talent, var int isCritialHit) {
    // Valid return values are:
    const int DO_NOT_KNOCKOUT  = 0; // Gothic default: Normal damage, projectiles kill and never knockout (HP != 1)
    const int DO_NOT_KILL      = 1; // Normal damage, projectiles knockout and never kill (HP > 0)
    const int INSTANT_KNOCKOUT = 2; // One shot knockout (1 HP)
    const int INSTANT_KILL     = 3; // One shot kill (0 HP)

    /*
    // Create knockout arrows
    if (Hlp_IsValidItem(weapon)) {
        // Caution: Weapon may have been unequipped already at this time (unlikely)! Use Hlp_IsValidItem(weapon)

        if (weapon.munition == Hlp_GetInstanceID(ItRw_KnockOutArrow)) // Special arrow
        && (isCritialHit) {                                           // Only if it was a critical hit
            return INSTANT_KNOCKOUT;
        };
    }; */

    /*
    // Enemies that cannot be killed (at most knocked out) with ranged weapons
    if (target.guild == SOME_MONSTER_GUILD) {
        return DO_NOT_KILL;
    }; */

    /*
    // Instant kill on critical hit (by itself complete nonsense)
    if (isCriticalHit) {
        return INSTANT_KILL;
    }; */

    // Gothic default
    return DO_NOT_KNOCKOUT;
};


/*
 * This function is called every time the world (static or vobs) is hit by a projectile (arrows and bolts). It can be
 * used to define the collision behavior for different materials or surface textures.
 * Note: Unlike most other config functions, this function is also called for NPC shooters!
 *
 * The parameter 'materials' is a bit field for all materials attached to the hit object.
 * The parameter 'textures' is a string containing all texture names, delimiter: |
 *
 * CAUTION: Unfortunately, all vobs in Gothic 1 belong to the UNDEF material group. With descriptive texture names,
 * however, the material can be retrieved, e.g. (STR_IndexOf(textures, "WOOD") != 1). At the end of the function there
 * is an elaborate check for all wooding textures in Gothic 1 to compensate for the lack of material groups.
 *
 * Examples are written below and commented out and serve as inspiration of what is possible.
 */
func int GFA_GetCollisionWithWorld(var C_Npc shooter, var C_Item weapon, var int materials, var string textures) {
    // Valid return values are:
    const int DESTROY = 0; // Projectile is destroyed on impact
    const int STUCK   = 1; // Projectile gets stuck in the surface
    const int DEFLECT = 2; // Projectile is repelled

    // Several materials may be present
    const int UNDEF = 1<<0;
    const int METAL = 1<<1;
    const int STONE = 1<<2;
    const int WOOD  = 1<<3;
    const int EARTH = 1<<4;
    const int WATER = 1<<5;
    const int SNOW  = 1<<6;

    // Projectiles stay stuck in wood (default in Gothic 2)
    if (materials & WOOD) || (STR_IndexOf(textures, "WOOD") != -1) {
        return STUCK;
    };

    // Examples by texture name
    if (STR_IndexOf(textures, "|MOWOBOWMARK01.TGA") != -1) // Bullseye/shooting range texture (mind the delimiter '|')
    || (STR_IndexOf(textures, "|OCODWAWEHRGANGDA.TGA") != -1) { // Ore crate texture
        return STUCK;
    };

    /*
    // Keep in mind that this function is also called for NPC shooters
    if (Npc_IsPlayer(shooter)) {
        // ...
    }; */

    // The projectile might break on impact with stone (20% of the shots)
    if ((materials & STONE) || (STR_IndexOf(textures, "STONE") != -1))
    && (Hlp_Random(100) < 20) {
        return DESTROY;
    };

    // Since Gothic 1 is a bit weak on supplying the material properties of vobs, here is a check on texture name key
    // words, that fixes that deficit. This part can safely be deleted when using Gothic 2
    if (STR_IndexOf(textures, "BAUM") != -1)
    || (STR_IndexOf(textures, "TREE") != -1)
    || (STR_IndexOf(textures, "RANKEN") != -1)
    || (STR_IndexOf(textures, "RINDE") != -1)
    || (STR_IndexOf(textures, "BARK") != -1)
    || (STR_IndexOf(textures, "BUSH") != -1)
    || (STR_IndexOf(textures, "PLANT") != -1)
    || (STR_IndexOf(textures, "ROOT") != -1)
    || (STR_IndexOf(textures, "FOREST") != -1)
    || (STR_IndexOf(textures, "PLANK") != -1)
    || (STR_IndexOf(textures, "BRETT") != -1)
    || (STR_IndexOf(textures, "LATTE") != -1)
    || (STR_IndexOf(textures, "HOLZ") != -1)
    || (STR_IndexOf(textures, "BOOK") != -1)
    || (STR_IndexOf(textures, "SKULL") != -1)
    || (STR_IndexOf(textures, "BEAM") != -1)
    || (STR_IndexOf(textures, "CRATE") != -1)
    || (STR_IndexOf(textures, "CHEST") != -1)
    || (STR_IndexOf(textures, "SHELF") != -1)
    || (STR_IndexOf(textures, "TABLE") != -1)
    || (STR_IndexOf(textures, "LOG") != -1)
    || (STR_IndexOf(textures, "BED") != -1)
    || (STR_IndexOf(textures, "BARREL") != -1)
    || (STR_IndexOf(textures, "FASS") != -1)
    || (STR_IndexOf(textures, "HUETTE") != -1) {
        return STUCK;
    };

    // Projectiles deflect off of all of other surfaces (default behavior of Gothic 2)
    return DEFLECT;
};
