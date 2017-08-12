/*
 * This file contains all configurations for collectable projectiles.
 *
 * Requires the feature GFA_REUSE_PROJECTILES (see config\settings.d).
 *
 * List of included functions:
 *  func int GFA_GetUsedProjectileInstance(int projectileInst, C_Npc inventoryNpc)
 */


/*
 * When collecting projectiles is enabled (GFA_REUSE_PROJECTILES == 1), this function is called whenever a projectile
 * (arrows and bolts) hits an NPC or stops in the world. It is useful to replace the projectile or to remove it.
 * Return value is an item instance. When returning zero, the projectile is destroyed.
 * The parameter 'inventoryNpc' holds the NPC in whose inventory it will be put, or is empty if it landed in the world.
 *
 * Ideas: exchange projectile for a 'used' or 'broken' one, retrieval talent or tool, ...
 * There are a lot of examples given below, they are all commented out and serve as inspiration of what is possible.
 */
func int GFA_GetUsedProjectileInstance(var int projectileInst, var C_Npc inventoryNpc) {
    /*
    // Exchange the projectile with a 'used' one (e.g. arrow, that needs to be repaired)
    if (projectileInst == Hlp_GetInstanceID(ItRw_Arrow)) {
        if (!Hlp_IsValidItem(ItRw_UsedArrow)) {
            // Initialize! It is important, that the item instance is valid (must have been created before), otherwise
            // its value is -1. To ensure this, create the item once at way point 'TOT'.
            Wld_InsertItem(ItRw_UsedArrow, MEM_FARFARAWAY);
        };
        projectileInst = Hlp_GetInstanceID(ItRw_UsedArrow);
    }; */

    if (Hlp_IsValidNpc(inventoryNpc)) {
        // Projectile hit an NPC and will be put into their inventory

        // Do not put projectiles into the inventory of the player
        if (Npc_IsPlayer(inventoryNpc)) {
            return 0;
        };

        /*
        // Remove projectile when it hits humans
        if (inventoryNpc.guild < GIL_SEPERATOR_HUM) {
            return 0;
        }; */

        /*
        // Player needs to learn a talent to remove the projectile
        if (PLAYER_TALENT_TAKEANIMALTROPHY[REUSE_Arrow] == FALSE) {
            return 0;
        }; */

        /*
        // Player needs tool to retrieve the projectile
        if (!Npc_HasItems(hero, ItMi_ArrowTool)) {
            return 0;
        }; */

        /*
        // 50% chance of retrieval
        if (Hlp_Random(100) < 50) {
            return 0;
        }; */

        // For now it is just preserved (is put in the inventory as is)
        return projectileInst;

    } else {
        // Projectile did not hit NPC, but landed in world

        /*
        // Player needs to learn a talent to collect the projectile
        if (PLAYER_TALENT_REUSE_ARROW == FALSE) {
            return 0;
        }; */

        // For now it is just preserved (leave it in the world as is)
        return projectileInst;
    };
};
