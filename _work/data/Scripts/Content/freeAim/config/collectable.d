/*
 * This file contains all configurations for collectable projectiles.
 *
 * Requires the feature GFA_REUSE_PROJECTILES (see config\settings.d).
 */


/*
 * When collecting projectiles is enabled (GFA_REUSE_PROJECTILES == 1), this function is called whenever a projectile
 * (arrows and bolts) hits an NPC or stops in the world. It is useful to replace the projectile or to remove it.
 * Return value is a item instance. When returning zero, the projectile is destroyed.
 * The argument 'inventoryNpc' holds the NPC in whose inventory it will be put, or is empty if it landed in the world.
 *
 * There are a lot of examples given below, they are all commented out and serve as inspiration of what is possible.
 */
func int GFA_GetUsedProjectileInstance(var int projectileInst, var C_Npc inventoryNpc) {
    // When returning zero, the projectile is completely removed (e.g. retrieve-projectile-talent not learned yet)

    /*
    // Exchange the projectile with a "used" one (e.g. arrow, that needs to be repaired)
    if (projectileInst == Hlp_GetInstanceID(ItRw_Arrow)) {
        if (!Hlp_IsValidItem(ItRw_UsedArrow)) {
            // Initialize! It is important, that the item instance is valid (must have been created before), otherwise
            // its value is -1. To ensure this, create the item once at waypoint 'TOT'.
            Wld_InsertItem(ItRw_UsedArrow, MEM_FARFARAWAY);
        };
        projectileInst = Hlp_GetInstanceID(ItRw_UsedArrow);
    }; */

    if (Hlp_IsValidNpc(inventoryNpc)) {
        // Projectile hit an NPC and will be put into their inventory

        if (Npc_IsPlayer(inventoryNpc)) {
            // Do not put projectiles in the player's inventory
            return 0;
        };

        /*
        if (inventoryNpc.guild < GIL_SEPERATOR_HUM) {
            // Remove projectile when it hits humans
            return 0;
        }; */

        /*
        if (PLAYER_TALENT_TAKEANIMALTROPHY[REUSE_Arrow] == FALSE) {
            // Player needs to learn a talent to remove the projectile
            return 0;
        }; */

        /*
        if (!Npc_HasItems(hero, ItMi_ArrowTool)) {
            // Player needs tool to remove the projectile
            return 0;
        }; */

        /*
        if (Hlp_Random(100) < 50) {
            // 50% chance of retrieval
            return 0;
        }; */

        // For now it is just preserved (is put in the inventory as is)
        return projectileInst;

    } else {
        // Projectile did not hit npc and landed in world

        /*
        if (PLAYER_TALENT_REUSE_ARROW == FALSE) {
            // Player needs to learn a talent to remove the projectile
            return 0;
        }; */

        // For now it is just preserved (leave it in the world as is)
        return projectileInst;
    };
};
