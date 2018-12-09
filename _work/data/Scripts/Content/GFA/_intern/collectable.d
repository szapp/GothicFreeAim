/*
 * Collectable projectiles feature
 *
 * Gothic Free Aim (GFA) v1.1.0 - Free aiming for the video games Gothic 1 and Gothic 2 by Piranha Bytes
 * Copyright (C) 2016-2018  mud-freak (@szapp)
 *
 * This file is part of Gothic Free Aim.
 * <http://github.com/szapp/GothicFreeAim>
 *
 * Gothic Free Aim is free software: you can redistribute it and/or
 * modify it under the terms of the MIT License.
 * On redistribution this notice must remain intact and all copies must
 * identify the original author.
 *
 * Gothic Free Aim is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * MIT License for more details.
 *
 * You should have received a copy of the MIT License along with
 * Gothic Free Aim.  If not, see <http://opensource.org/licenses/MIT>.
 */


/*
 * This function keeps the projectiles in the world. It hooks the end of the oCAIArrow::DoAI() loop and checks whether
 * the projectile stopped moving. Once it has, the AI is detached from the projectile. The default behavior of removing
 * the projectile from the world is circumvented by clamping the AI life time to maximum until it is removed.
 */
func void GFA_RP_KeepProjectileInWorld() {
    // Check if AI was already removed. Happens if NPC is hit, see GFA_RP_PutProjectileIntoInventory()
    var int destroyed; destroyed = MEM_ReadInt(EDI);
    if (destroyed) {
        return;
    };

    // Check validity of projectile and its rigid body
    var int arrowAI; arrowAI = ESI; // oCAIArrow* is the AI of the projectile
    var int projectilePtr; projectilePtr = EBX; // oCItem*
    if (!projectilePtr) {
        return;
    };
    var oCItem projectile; projectile = _^(projectilePtr);
    if (!projectile._zCVob_rigidBody) {
        return;
    };

    // Always keep the projectile alive, set infinite life time
    if (gef(MEM_ReadInt(arrowAI+oCAIArrowBase_lifeTime_offset), FLOATNULL)) {
        MEM_WriteInt(arrowAI+oCAIArrowBase_lifeTime_offset, FLOATONE_NEG);
        projectile._zCVob_visualAlpha = FLOATONE; // Fully visible
    };

    // Check if the projectile stopped moving
    if (!(projectile._zCVob_bitfield[0] & zCVob_bitfield0_physicsEnabled)) {

        // Remove the trail strip FX; only if the projectile does not have a different effect (like magic arrows)
        if (GOTHIC_BASE_VERSION == 2) {
            if (Hlp_StrCmp(MEM_ReadString(projectilePtr+oCItem_effect_offset), GFA_TRAIL_FX)) {
                const int call = 0;
                if (CALL_Begin(call)) {
                    CALL__thiscall(_@(projectilePtr), oCItem__RemoveEffect);
                    call = CALL_End();
                };
                MEM_WriteString(projectilePtr+oCItem_effect_offset, "");
            };
        };

        // Replace the projectile if desired, retrieve new projectile instance from config
        var C_Npc emptyNpc; emptyNpc = MEM_NullToInst(); // No NPC was hit, so pass an empty instance as argument
        var C_Npc shooter; shooter = _^(MEM_ReadInt(arrowAI+oCAIArrow_origin_offset));
        var int projInst; projInst = GFA_GetUsedProjectileInstance(projectile.instanz, shooter, emptyNpc);

        // Check if the new projectile instance is valid, -1 for invalid instance, 0 for empty
        if (projInst > 0) {

            // Update projectile instance
            if (projInst != projectile.instanz) {
                const int call2 = 0; const int one = 1;
                if (CALL_Begin(call2)) {
                    CALL_IntParam(_@(one));      // Amount
                    CALL_PtrParam(_@(projInst)); // Instance ID
                    CALL__thiscall(_@(projectilePtr), oCItem__InitByScript);
                    call2 = CALL_End();
                };
            };

            // Make the projectile focusable, i.e. collectable
            projectile.flags = projectile.flags & ~ITEM_NFOCUS;
            projectile._zCVob_bitfield[4] = projectile._zCVob_bitfield[4] & ~zCVob_bitfield4_dontWriteIntoArchive;

            // Detach arrow AI from projectile (projectile will have no AI)
            const int call3 = 0; var int zero;
            if (CALL_Begin(call3)) {
                CALL_IntParam(_@(zero));
                CALL__thiscall(_@(projectilePtr), zCVob__SetAI);
                call3 = CALL_End();
            };

        } else {
            // New projectile instance is empty or invalid. Let oCAIArrow::DoAI() remove the projectile
            GFA_CC_ProjectileDestroy(arrowAI);
        };
    };
};


/*
 * This function is called when a projectile hits an NPC. It is hooked by the collision detection function of
 * projectiles. It puts the projectile instance into inventory (if desired) and lets the AI die.
 */
func void GFA_RP_PutProjectileIntoInventory() {
    var int arrowAI; arrowAI = ESI;

    // Since deflection of projectiles (collision feature) does not exist in Gothic 1 by default, it is not inherently
    // clear at this point, whether the projectile is deflecting off of this NPC, like it is clear here for Gothic 2.
    // To help out, the projectile AI is prior marked as deflecting (-1) by GFA_CC_ProjectileCollisionWithNpc().
    if (MEM_ReadInt(arrowAI+oCAIArrow_destroyProjectile_offset) == -1) {
        // Reset to zero, otherwise the projectile is removed by oCAIArrow::DoAI()
        MEM_WriteInt(arrowAI+oCAIArrow_destroyProjectile_offset, 0);
        return;
    };

    var oCItem projectile; projectile = _^(MEM_ReadInt(arrowAI+oCAIArrowBase_hostVob_offset));

    // Differentiate between positive hit and collision without damage (in case of auto aim hit registration)
    var int positiveHit; positiveHit = MEMINT_SwitchG1G2(
        (ECX != 100),                                      // Gothic 1: ECX is 100 if the hit did not register
        MEM_ReadInt(arrowAI+oCAIArrowBase_hasHit_offset)); // Gothic 2: dedicated property (does not exist in Gothic 1)

    if (positiveHit) {
        var C_Npc victim; victim = _^(MEMINT_SwitchG1G2(EBX, EDI));
        var C_Npc shooter; shooter = _^(MEM_ReadInt(arrowAI+oCAIArrow_origin_offset));

        // Replace the projectile if desired, retrieve new projectile instance from config
        var int projInst; projInst = GFA_GetUsedProjectileInstance(projectile.instanz, shooter, victim);
        if (projInst > 0) {
            CreateInvItem(victim, projInst); // Put respective instance in inventory
        };
    };

    GFA_CC_ProjectileDestroy(arrowAI);
};


/*
 * This function is called when a projectile gets 'stuck' in the world (static and dynamic). It is hooked by the
 * collision detection function of projectiles. Here, the projectile is properly repositioned to be collectable. This
 * function is only necessary for Gothic 2.
 */
func void GFA_RP_RepositionProjectileInSurface() {
    var int arrowAI; arrowAI = ESI;
    var oCItem projectile; projectile = _^(MEM_ReadInt(arrowAI+oCAIArrowBase_hostVob_offset));

    // Have the projectile not go in too deep. RightVec will be multiplied later
    projectile._zCVob_trafoObjToWorld[0] = mulf(projectile._zCVob_trafoObjToWorld[0], -1096111445); // -33.3 cm
    projectile._zCVob_trafoObjToWorld[4] = mulf(projectile._zCVob_trafoObjToWorld[4], -1096111445);
    projectile._zCVob_trafoObjToWorld[8] = mulf(projectile._zCVob_trafoObjToWorld[8], -1096111445);
};
