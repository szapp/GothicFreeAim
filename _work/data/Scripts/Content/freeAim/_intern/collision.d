/*
 * Projectile collision behavior
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
 * Internal helper function for freeAimHitRegNpc(). It is called from freeAimDoNpcHit().
 * This function is necessary for error handling and to supply the readied weapon and respective talent value.
 */
func int freeAimHitRegNpc_(var C_Npc target) {
    // Get readied/equipped ranged weapon
    var int weaponPtr;
    freeAimGetWeaponTalent(_@(weaponPtr), 0);
    var C_Item weapon; weapon = _^(weaponPtr);

    // Get material of equipped armor
    var int material;
    if (Npc_HasEquippedArmor(target)) {
        var C_Item armor; armor = Npc_GetEquippedArmor(target);
        material = armor.material;
    } else {
        // No armor
        material = -1;
    };

    // Call customized function to retrieve collision definition
    MEM_PushInstParam(target);
    MEM_PushInstParam(weapon);
    MEM_PushIntParam(material);
    MEM_Call(freeAimHitRegNpc); // freeAimHitRegNpc(target, weapon, material);
    return MEM_PopIntResult();
};


/*
 * Internal helper function for freeAimHitRegWld(). It is called from freeAimOnArrowCollide().
 * This function is necessary for error handling and to supply the readied weapon and respective talent value.
 */
func int freeAimHitRegWld_(var C_Npc shooter, var int material, var string texture) {
    // Get readied/equipped ranged weapon
    var int weaponPtr;
    freeAimGetWeaponTalent(_@(weaponPtr), 0);
    var C_Item weapon; weapon = _^(weaponPtr);

    // Call customized function to retrieve collision definition
    MEM_PushInstParam(shooter);
    MEM_PushInstParam(weapon);
    MEM_PushIntParam(material);
    MEM_PushStringParam(texture);
    MEM_Call(freeAimHitRegWld); // freeAimHitRegWld(shooter, weapon, material, texture);
    return MEM_PopIntResult();
};


/*
 * Determine the hit chance when shooting at an NPC to manipulate the hit registration. This function hooks
 * oCAIArrow::ReportCollisionToAI() at the offset where the hit chance of the NPC is checked. With freeAimHitRegNpc(),
 * it is decided whether a projectile causes damage, does nothing or bounces of the NPC. Depending on
 * FREEAIM_TRUE_HITCHANCE, the resulting hit chance is either the accuracy or always 100%, where the hit chance is
 * instead determined by scattering in freeAimSetupProjectile().
 * This function is only manipulating anything if the shooter is the player.
 */
func void freeAimDoNpcHit() {
    var int arrowAI; arrowAI = EBP;
    var C_Npc shooter; shooter = _^(MEM_ReadInt(arrowAI+oCAIArrow_origin_offset));

    // This function does not affect NPCs and also only affects the player if FA is enabled
    if (!Npc_IsPlayer(shooter)) && (FREEAIM_CUSTOM_COLLISIONS) {
        // Reset to Gothic's default hit registration and leave the function
        MEM_WriteByte(projectileDeflectOffNpcAddr, /*74*/ 116); // Reset to default collision behavior on npcs
        MEM_WriteByte(projectileDeflectOffNpcAddr+1, /*3B*/ 59); // jz to 0x6A0BA3
        return;
    };

    // Retrieve some variables
    var oCItem projectile; projectile = _^(MEM_ReadInt(arrowAI+oCAIArrowBase_hostVob_offset));
    var int hitChancePtr; hitChancePtr = ESP+24; // esp+1ACh-194h
    var C_Npc target; target = _^(MEM_ReadInt(ESP+28)); // esp+1ACh-190h

    // Boolean to specify, whether damage will be applied or not
    var int hit;

    if (FREEAIM_CUSTOM_COLLISIONS) {
        var int collision;
        const int DESTROY = 0; // Projectile doest not cause damage and vanishes
        const int DAMAGE  = 1; // Projectile causes damage and may stay in the inventory of the victim
        const int DEFLECT = 2; // Projectile deflects of the surfaces and bounces off

        if (MEM_ReadInt(arrowAI+oCAIArrowBase_creatingImpactFX_offset)) {
            // Adjust collision behavior for NPCs if the projectile bounced off a surface before
            collision = FREEAIM_COLL_PRIOR_NPC;
        } else {
            // Retrieve the collision behavior based on the shooter, target and the material type of their armor
            collision = freeAimHitRegNpc_(target);
        };

        if (collision == DEFLECT) {
            // Deflect projectile (no damage)
            MEM_WriteByte(projectileDeflectOffNpcAddr, ASMINT_OP_nop); // Skip npc armor collision check, deflect always
            MEM_WriteByte(projectileDeflectOffNpcAddr+1, ASMINT_OP_nop);
            hit = FALSE;
        } else if (collision == DAMAGE) {
            // Apply damage or destroy projectile
            MEM_WriteByte(projectileDeflectOffNpcAddr, /*74*/ 116); // Jump beyond armor collision check, deflect never
            MEM_WriteByte(projectileDeflectOffNpcAddr+1, /*60*/ 96); // jz to 0x6A0BC8
            hit = TRUE;
        } else if (collision == DESTROY) {
            // Destroy (no damage)
            MEM_WriteByte(projectileDeflectOffNpcAddr, /*74*/ 116); // Jump beyond armor collision check, deflect never
            MEM_WriteByte(projectileDeflectOffNpcAddr+1, /*60*/ 96); // jz to 0x6A0BC8
            projectile.instanz = -1; // Delete item instance (it will not be put into the inventory)
            hit = FALSE;
        };
    } else {
        // Default behavior (no custom collision behavior)
        hit = TRUE;
    };

    // The hit chance percentage is either determined by skill and distance (default Gothic hit chance) or is always
    // 100%, if free aiming is enabled and the accuracy is defined by the scattering (FREEAIM_TRUE_HITCHANCE == TRUE).
    var int hitchance;
    if (FREEAIM_ACTIVE) && (FREEAIM_RANGED) && (FREEAIM_TRUE_HITCHANCE) {
        // Always hits (100% of all times)
        hitchance = 100;
    } else {
        // Take the default distance-skill-hit chance provided by Gothic's engine
        hitchance = MEM_ReadInt(hitChancePtr);
    };

    // This is a positive hit, depending on the collision (see above) and the hit chance percentage
    MEM_WriteInt(hitChancePtr, hit*hitchance);
};


/*
 * Determine the collision behavior when a projectile collides with the world (static or non-NPC vob). Either destroy,
 * deflect or collide. This function hooks oCAIArrowBase::ReportCollisionToAI() at two different offsets for vobs and
 * the static world.
 */
func void freeAimOnArrowCollide() {
    // Get the material of the collision object. Since this function hooks at two different addresses, it has to be
    // differentiated between zCMaterial and zCPolygon first, before reading the material type from it
    var int matPtr; matPtr = MEM_ReadInt(ECX); // zCMaterial* or zCPolygon* depending on hooked address
    if (MEM_ReadInt(matPtr) != zCMaterial__vtbl) { // Static world: Get the zCMaterial from the zCPolygon
        var zCPolygon polygon; polygon = _^(matPtr);
        matPtr = polygon.material;
    };

    // From the zCMaterial the material type can be read (as defined in Constants.d)
    var zCMaterial mat; mat = _^(matPtr);
    var int material; material = mat.matGroup;

    // Additionally, get the texture of the collision object for more customization of collision behavior
    var string texture;
    if (mat.texture) { // Some objects strangely do not have a texture
        var zCTexture tex; tex = _^(mat.texture);
        texture = tex._zCObject_objectName;
    } else {
        texture = "";
    };

    // Get the shooter
    var int arrowAI; arrowAI = ESI;
    var C_Npc shooter; shooter = _^(MEM_ReadInt(arrowAI+oCAIArrow_origin_offset));

    // Retrieve the collision behavior based on the shooter, the material type and the texture of the collision object
    var int collision; collision = freeAimHitRegWld_(shooter, material, texture);
    const int DESTROY = 0; // Projectile breaks and vanishes
    const int STUCK   = 1; // Projectile stays and is stuck in the surface of the collision object
    const int DEFLECT = 2; // Projectile deflects of the surfaces and bounces off

    if (collision == STUCK) {
        // Collide and get stuck in the object
        EDI = material; // Sets the condition at 0x6A0A45 and 0x6A0C1A to true: Projectile stays
    } else if (collision == DEFLECT) {
        // Deflect the projectile
        EDI = -1;  // Sets the condition at 0x6A0A45 and 0x6A0C1A to false: Projectile deflects
    } else if (collision == DESTROY) {
        // Destroy the projectile
        EDI = -1;  // Sets the condition at 0x6A0A45 and 0x6A0C1A to false: Projectile deflects

        var oCItem projectile; projectile = _^(MEM_ReadInt(arrowAI+oCAIArrowBase_hostVob_offset));

        // Only destroy projectile, if it did not bounce off and is still fast enough to reasonably break
        var int rigidBody; rigidBody = projectile._zCVob_rigidBody;
        var int totalVelocity; totalVelocity = addf(addf(
            absf(MEM_ReadInt(rigidBody+zCRigidBody_velocity_offset)), // zCRigidBody.velocity[3]
            absf(MEM_ReadInt(rigidBody+zCRigidBody_velocity_offset+4))),
            absf(MEM_ReadInt(rigidBody+zCRigidBody_velocity_offset+8)));
        if (gf(totalVelocity, FLOAT1C)) {
            // Total velocity is high enough to break the projectile

            // Better safe than writing to an invalid address
            if (FF_ActiveData(freeAimDropProjectile, rigidBody)) {
                FF_RemoveData(freeAimDropProjectile, rigidBody);
            };

            // Breaking sound and visual effect
            Wld_StopEffect(FREEAIM_BREAK_FX); // Sometimes collides several times, so disable first
            Wld_PlayEffect(FREEAIM_BREAK_FX, projectile, projectile, 0, 0, 0, FALSE);
            MEM_WriteInt(arrowAI+oCAIArrowBase_lifeTime_offset, FLOATNULL); // Set life time to 0: Remove projectile
        };
    };
};


/*
 * This function disables collision of projectiles with NPCs once the projectiles have bounced of another surface. Like
 * freeAimTriggerCollisionCheck(), this function hooks oCAIArrow::CanThisCollideWith() and checks whether the object in
 * question is an NPC to prevent the collision, if the projectiles has collided before. The hook is done in a separate
 * function to increase performance, if only one of the two settings is enabled.
 *
 * Note: This hook is only initialized if FREEAIM_COLL_PRIOR_NPC == -1.
 */
func void freeAimDisableNpcCollisionOnBounce() {
    var int arrowAI; arrowAI = ECX;

    // Check if the projectile bounced off a surface before
    if (!MEM_ReadInt(arrowAI+oCAIArrowBase_creatingImpactFX_offset)) {
        return;
    };

    var int vobPtr; vobPtr = ESP+4;
    if (!Hlp_Is_oCNpc(MEM_ReadInt(vobPtr))) {
        return;
    };

    // Replace the collision object with the shooter, because the shooter is always ignored
    var int shooter; shooter = MEM_ReadInt(arrowAI+oCAIArrow_origin_offset);
    MEM_WriteInt(vobPtr, shooter);
};


/*
 * Fix trigger collision bug. When shooting a projectile inside a trigger of certain properties, the projectile collides
 * continuously causing a nerve recking sound. Like freeAimDisableNpcCollisionOnBounce(), this function hooks
 * oCAIArrow::CanThisCollideWith() and checks whether the object in question is a trigger with certain properties to
 * prevent the collision. The hook is done in a separate function to increase performance, if only one of the two
 * settings is enabled.
 * Taken from http://forum.worldofplayers.de/forum/threads/1126551/page10?p=20894916
 *
 * Note: This hook is only initialized if FREEAIM_TRIGGER_COLL_FIX is true.
 */
func void freeAimTriggerCollisionCheck() {
    var int vobPtr; vobPtr = ESP+4;
    var zCVob vob; vob = _^(MEM_ReadInt(vobPtr));

    // Check if the collision object is a trigger
    if (vob._vtbl != zCTrigger_vtbl) && (vob._vtbl != zCTriggerScript_vtbl) {
        return;
    };
    var zCTrigger trigger; trigger = _^(MEM_ReadInt(vobPtr));

    if (trigger.bitfield & zCTrigger_bitfield_respondToObject)
    && (trigger.bitfield & zCTrigger_bitfield_reactToOnTouch) {
        // Object-reacting trigger. This kind of trigger needs the collision, e.g. to react to projectiles
        return;
    };

    // Replace the collision object with the shooter, because the shooter is always ignored
    var int arrowAI; arrowAI = ECX;
    var int shooter; shooter = MEM_ReadInt(arrowAI+oCAIArrow_origin_offset);
    MEM_WriteInt(vobPtr, shooter);
};
