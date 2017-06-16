/*
 * Collectable projectiles
 *
 * G2 Free Aim v0.1.2 - Free aiming for the video game Gothic 2 by Piranha Bytes
 * Copyright (C) 2016  mud-freak (@szapp)
 *
 * This file is part of G2 Free Aim.
 * <http://github.com/szapp/g2freeAim>
 *
 * G2 Free Aim is free software: you can redistribute it and/or modify
 * it under the terms of the MIT License.
 * On redistribution this notice must remain intact and all copies must
 * identify the original author.
 *
 * G2 Free Aim is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * MIT License for more details.
 *
 * You should have received a copy of the MIT License
 * along with G2 Free Aim.  If not, see <http://opensource.org/licenses/MIT>.
 */


/*
 * This function keeps the projectiles in the world. It hooks the end of the oCAIArrow::DoAI loop and checks whether
 * each projectile stopped moving. Once it has, the AI is detached from the projectile and replaced with the default
 * item-AI (oCAIVobMove). The default behavior of removing the projectile from the world is circumvented by clamping the
 * AI life time to maximum.
 */
func void freeAimKeepProjectileInWorld() {
    var int arrowAI; arrowAI = EAX; // oCAIArrow* is the arrow AI of the projectile
    var int projectilePtr; projectilePtr = EBX; // oCItem*
    var int removePtr; removePtr = EDI; // int* determines the removal of the projectile (1 for remove, 0 otherwise)

    // Check validity
    if (MEM_ReadInt(removePtr)) { // AI was already removed. Happens if NPC is hit, see freeAimOnArrowHitNpc()
        return;
    };
    if (!projectilePtr) { // In case oCItem* does not exist (should never happen)
        return;
    };
    var oCItem projectile; projectile = _^(projectilePtr);
    if (!projectile._zCVob_rigidBody) { // In case zCRigidBody* does not exist (should never happen)
        return;
    };

    // Reset projectile gravity after a collision occurred
    if (MEM_ReadInt(arrowAI+oCAIArrowBase_collision_offset)) {
        MEM_WriteInt(projectile._zCVob_rigidBody+zCRigidBody_gravity_offset, FLOATONE); // Set gravity to default
    };

    // Exit if projectiles are not collectable (normal projectile handling)
    if (!FREEAIM_REUSE_PROJECTILES) {
        return;
    };

    // Always keep the projectile alive, set high life time
    MEM_WriteInt(arrowAI+oCAIArrowBase_lifeTime_offset, FLOATONE);

    // Check if the projectile stopped moving
    if (!(projectile._zCVob_bitfield[0] & zCVob_bitfield0_physicsEnabled)) {

        // Make sure the scheduled gravity does not kick in anymore
        if (FF_ActiveData(freeAimDropProjectile, _@(projectile._zCVob_rigidBody))) {
            FF_RemoveData(freeAimDropProjectile, _@(projectile._zCVob_rigidBody));
        };

        // Remove the FX; only if the projectile does not have a different effect (like magic arrows)
        if (Hlp_StrCmp(projectile.effect, FREEAIM_TRAIL_FX)) { // Check for the trail strip FX
            const int call = 0;
            if (CALL_Begin(call)) {
                CALL__thiscall(_@(projectilePtr), oCItem__RemoveEffect);
                call = CALL_End();
            };
        };

        // Replace the projectile if desired:
        // Call customized function to retrieve new projectile instance
        var C_Npc emptyNpc; emptyNpc = MEM_NullToInst(); // No NPC was hit, so pass an empty instance as argument
        MEM_PushIntParam(projectile.instanz);
        MEM_PushInstParam(emptyNpc);
        MEM_Call(freeAimGetUsedProjectileInstance); // freeAimGetUsedProjectileInstance(projectile.instanz, emptyNpc);
        var int projInst; projInst = MEM_PopIntResult();

        // Check if the new projectile instance is valid, -1 for invalid instance, 0 for empty
        if (projInst > 0) {

            // Update projectile instance
            if (projInst != projectile.instanz) {
                const int call2 = 0; const int one = 1;
                if (CALL_Begin(call2)) {
                    CALL_IntParam(_@(one)); // Amount
                    CALL_PtrParam(_@(projInst)); // Instance ID
                    CALL__thiscall(_@(projectilePtr), oCItem__InitByScript);
                    call2 = CALL_End();
                };
            };

            // Make the projectile focusable, i.e. collectable
            projectile.flags = projectile.flags &~ ITEM_NFOCUS;

            // Detach arrow AI from projectile (projectile will have no AI)
            const int call3 = 0; const int zero = 0;
            if (CALL_Begin(call3)) {
                CALL_IntParam(_@(zero));
                CALL__thiscall(_@(projectilePtr), zCVob__SetAI);
                call3 = CALL_End();
            };

        } else { // Else: New projectile instance is empty or invalid. Let oCAIArrow::DoAI remove the projectile
            MEM_WriteInt(arrowAI+oCAIArrowBase_lifeTime_offset, FLOATNULL);
        };
    };
};


/*
 * This function is called when a projectile hits an NPC. It is hooked by the collision detection function of
 * projectiles. It puts the projectile instance into inventory (if desired) and lets the AI die.
 */
func void freeAimOnArrowHitNpc() {
    var int arrowAI; arrowAI = ESI;
    var C_Npc victim; victim = _^(EDI);
    var oCItem projectile; projectile = _^(MEM_ReadInt(arrowAI+oCAIArrowBase_hostVob_offset));

    // Call customized function to retrieve new projectile instance
    MEM_PushIntParam(projectile.instanz);
    MEM_PushInstParam(victim);
    MEM_Call(freeAimGetUsedProjectileInstance); // freeAimGetUsedProjectileInstance(projectile.instanz, victim);
    var int projInst; projInst = MEM_PopIntResult();
    if (projInst > 0) {
        CreateInvItem(victim, projInst); // Put respective instance in inventory
    };

    // Make sure the scheduled gravity does not kick in anymore
    if (FF_ActiveData(freeAimDropProjectile, _@(projectile._zCVob_rigidBody))) {
        FF_RemoveData(freeAimDropProjectile, _@(projectile._zCVob_rigidBody));
    };

    // Set life time to zero to remove this projectile
    MEM_WriteInt(arrowAI+oCAIArrowBase_lifeTime_offset, FLOATNULL);
};


/*
 * This function is called when a projectile gets stuck in the world (static and dynamic). It is hooked by the collision
 * detection function of projectiles. Here, the projectile is properly positioned.
 */
func void freeAimOnArrowGetStuck() {
    var int arrowAI; arrowAI = ESI;
    var oCItem projectile; projectile = _^(MEM_ReadInt(arrowAI+oCAIArrowBase_hostVob_offset));

    // Make sure the scheduled gravity does not kick in anymore
    if (FF_ActiveData(freeAimDropProjectile, _@(projectile._zCVob_rigidBody))) {
        FF_RemoveData(freeAimDropProjectile, _@(projectile._zCVob_rigidBody));
    };

    // Have the projectile not go in too deep. RightVec will be multiplied later
    projectile._zCVob_trafoObjToWorld[0] = mulf(projectile._zCVob_trafoObjToWorld[0], -1096111445); // -15 cm
    projectile._zCVob_trafoObjToWorld[4] = mulf(projectile._zCVob_trafoObjToWorld[4], -1096111445);
    projectile._zCVob_trafoObjToWorld[8] = mulf(projectile._zCVob_trafoObjToWorld[8], -1096111445);
};
