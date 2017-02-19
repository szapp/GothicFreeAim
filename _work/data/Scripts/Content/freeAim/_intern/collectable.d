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

/* Once a projectile stopped moving keep it alive */
func void freeAimWatchProjectile() {
    var int arrowAI; arrowAI = ECX; // oCAIArrow*
    var int projectilePtr; projectilePtr = MEM_ReadInt(ESP+4); // oCItem*
    var int removePtr; removePtr = MEM_ReadInt(ESP+8); // int* (call-by-reference argument)
    if (!projectilePtr) { return; }; // oCItem* might not exist
    var oCItem projectile; projectile = _^(projectilePtr);
    if (!projectile._zCVob_rigidBody) { return; }; // zCRigidBody* might not exist the first time
    // Reset projectile gravity (zCRigidBody.gravity) after collision (oCAIArrow.collision)
    if (MEM_ReadInt(arrowAI+52)) { MEM_WriteInt(projectile._zCVob_rigidBody+236, FLOATONE); }; // Set gravity to default
    if (!FREEAIM_REUSE_PROJECTILES) { return; }; // Normal projectile handling
    // If the projectile stopped moving (and did not hit npc)
    if (MEM_ReadInt(arrowAI+56) != -1073741824) && !(projectile._zCVob_bitfield[0] & zCVob_bitfield0_physicsEnabled) {
        if (FF_ActiveData(freeAimDropProjectile, _@(projectile._zCVob_rigidBody))) {
            FF_RemoveData(freeAimDropProjectile, _@(projectile._zCVob_rigidBody)); };
        if (Hlp_StrCmp(projectile.effect, FREEAIM_TRAIL_FX)) { // Remove trail strip fx
            const int call2 = 0;
            if (CALL_Begin(call2)) {
                CALL__thiscall(_@(projectilePtr), oCItem__RemoveEffect);
                call2 = CALL_End();
            };
        };
        var C_Npc emptyNpc; emptyNpc = MEM_NullToInst();
        // Call customized function
        MEM_PushIntParam(projectile.instanz);
        MEM_PushInstParam(emptyNpc);
        MEM_Call(freeAimGetUsedProjectileInstance); // freeAimGetUsedProjectileInstance(projectile.instanz, emptyNpc);
        var int projInst; projInst = MEM_PopIntResult();
        if (projInst > 0) { // Will be -1 on invalid item
            if (projInst != projectile.instanz) { // Only change the instance if different
                const int call3 = 0; const int one = 1;
                if (CALL_Begin(call3)) {
                    CALL_IntParam(_@(one)); // Amount
                    CALL_PtrParam(_@(projInst)); // Instance ID
                    CALL__thiscall(_@(projectilePtr), oCItem__InitByScript);
                    call3 = CALL_End();
                };
            };
            projectile.flags = projectile.flags &~ ITEM_NFOCUS; // Focusable
            MEM_WriteInt(arrowAI+56, FLOATONE); // oCAIArrow.lifeTime // Set high lifetime to ensure item visibility
            MEM_WriteInt(removePtr, 0); // Do not remove vob on AI destruction
            MEM_WriteInt(ESP+8, _@(FREEAIM_ARROWAI_REDIRECT)); // Divert the actual "return" value
        };
    } else if (MEM_ReadInt(arrowAI+56) == -1073741824) { // Marked as positive hit on npc: do not keep alive
        MEM_WriteInt(arrowAI+56, FLOATNULL); // oCAIArrow.lifeTime
    };
};

/* Arrow gets stuck in npc: put projectile instance into inventory and let ai die */
func void freeAimOnArrowHitNpc() {
    var oCItem projectile; projectile = _^(MEM_ReadInt(ESI+88));
    var C_Npc victim; victim = _^(EDI);
    // Call customized function
    MEM_PushIntParam(projectile.instanz);
    MEM_PushInstParam(victim);
    MEM_Call(freeAimGetUsedProjectileInstance); // freeAimGetUsedProjectileInstance(projectile.instanz, victim);
    var int projInst; projInst = MEM_PopIntResult();
    if (projInst > 0) { CreateInvItem(victim, projInst); }; // Put respective instance in inventory
    if (FF_ActiveData(freeAimDropProjectile, _@(projectile._zCVob_rigidBody))) {
        FF_RemoveData(freeAimDropProjectile, _@(projectile._zCVob_rigidBody)); };
    MEM_WriteInt(ESI+56, -1073741824); // oCAIArrow.lifeTime // Mark this AI for freeAimWatchProjectile()
};

/* Arrow gets stuck in static or dynamic world (non-npc): keep ai alive */
func void freeAimOnArrowGetStuck() {
    var int projectilePtr; projectilePtr = MEM_ReadInt(ESI+88);
    var oCItem projectile; projectile = _^(projectilePtr);
    if (FF_ActiveData(freeAimDropProjectile, _@(projectile._zCVob_rigidBody))) {
        FF_RemoveData(freeAimDropProjectile, _@(projectile._zCVob_rigidBody)); };
    // Have projectile not go to deep in. Might not make sense but trust me. (RightVec will be multiplied later)
    projectile._zCVob_trafoObjToWorld[0] = mulf(projectile._zCVob_trafoObjToWorld[0], -1096111445);
    projectile._zCVob_trafoObjToWorld[4] = mulf(projectile._zCVob_trafoObjToWorld[4], -1096111445);
    projectile._zCVob_trafoObjToWorld[8] = mulf(projectile._zCVob_trafoObjToWorld[8], -1096111445);
};
