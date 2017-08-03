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
 * Set/reset the collision behavior of projectiles with NPCs. There are two different behaviors plus one auto (default).
 * This function is specific to Gothic 2 only. This function is called from freeAimDoNpcHit() and from
 * freeAimUpdateSettings().
 */
func void freeAimCollisionWithNPC(var int setting) {
    if (GOTHIC_BASE_VERSION != 2) || (!FREEAIM_CUSTOM_COLLISIONS) {
        return;
    };

    // Collision behaviors
    const int AUTO    = 0; // Projectile bounces off depending on material of armor (Gothic 2 default)
    const int VANISH  = 1; // Projectile vanishes
    const int DEFLECT = 2; // Projectile deflects of the surfaces and bounces off

    const int SET = AUTO; // Default is Gothic's default collision behavior
    if (setting == SET) {
        return; // No change necessary
    };

    // Manipulate op code
    if (setting == DEFLECT) {
        // Deflect off target
        MEM_WriteByte(oCAIArrowBase__ReportCollisionToAI_collNpc, ASMINT_OP_nop); // Skip NPC armor collision check
        MEM_WriteByte(oCAIArrowBase__ReportCollisionToAI_collNpc+1, ASMINT_OP_nop); // Deflect always
        SET = DEFLECT;
    } else if (setting == VANISH) {
        // Collide with target
        MEM_WriteByte(oCAIArrowBase__ReportCollisionToAI_collNpc, /*74*/ 116); // Jump beyond NPC armor collision check:
        MEM_WriteByte(oCAIArrowBase__ReportCollisionToAI_collNpc+1, /*60*/ 96); // Deflect never (jz to 0x6A0BC8)
        SET = VANISH;
    } else if (setting == AUTO) {
        // Reset to Gothic's default collision behavior
        MEM_WriteByte(oCAIArrowBase__ReportCollisionToAI_collNpc, /*74*/ 116); // Reset to default collision on NPCs
        MEM_WriteByte(oCAIArrowBase__ReportCollisionToAI_collNpc+1, /*3B*/ 59); // jz to 0x6A0BA3
        SET = AUTO;
    };
};


/*
 * Wrapper function for the config function freeAimHitRegNpc(). It is called from freeAimDoNpcHit().
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

    // Retrieve collision definition from config
    return freeAimHitRegNpc(target, weapon, material);
};


/*
 * Wrapper function for the config function freeAimHitRegWld(). It is called from freeAimOnArrowCollide().
 * This function is necessary for error handling and to supply the readied weapon and respective talent value.
 */
func int freeAimHitRegWld_(var C_Npc shooter, var int material, var string texture) {
    // Get readied/equipped ranged weapon
    var int weaponPtr;
    freeAimGetWeaponTalent(_@(weaponPtr), 0);
    var C_Item weapon; weapon = _^(weaponPtr);

    // Retrieve collision definition from config
    return freeAimHitRegWld(shooter, weapon, material, texture);
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
    var int arrowAI; arrowAI = MEMINT_SwitchG1G2(ESI, EBP);
    var C_Npc shooter; shooter = _^(MEM_ReadInt(arrowAI+oCAIArrow_origin_offset));

    // This function does not affect NPCs and also only affects the player if FA is enabled
    if (!Npc_IsPlayer(shooter)) {
        // Reset to Gothic's default hit registration and leave the function
        freeAimCollisionWithNPC(0); // Gothic 2
        MEM_WriteInt(arrowAI+oCAIArrow_destroyProjectile_offset, 1); // Gothic 1
        return;
    };

    // Boolean to specify, whether damage will be applied or not
    var int hit;

    if (FREEAIM_CUSTOM_COLLISIONS) {
        var int collision;
        const int DESTROY = 0; // Projectile doest not cause damage and vanishes
        const int DAMAGE  = 1; // Projectile causes damage and may stay in the inventory of the victim
        const int DEFLECT = 2; // Projectile deflects of the surfaces and bounces off

        if (MEM_ReadInt(arrowAI+oCAIArrowBase_creatingImpactFX_offset)) {
            // Adjust collision behavior for NPCs if the projectile bounced off a surface before (Gothic 2 only)
            collision = FREEAIM_COLL_PRIOR_NPC;
        } else {
            // Retrieve the collision behavior based on the shooter, target and the material type of their armor
            var C_Npc target; target = _^(MEMINT_SwitchG1G2(EBX, MEM_ReadInt(/*esp+1ACh-190h*/ ESP+28)));
            collision = freeAimHitRegNpc_(target);
        };

        // Set collision behavior
        freeAimCollisionWithNPC((collision == DEFLECT)+1); // 1 == DAMAGE or DESTROY, 2 == DEFLECT // G2
        MEM_WriteInt(arrowAI+oCAIArrow_destroyProjectile_offset, (collision != DEFLECT)); // Remove projectile //G1
        hit = (collision == DAMAGE); // FALSE == DESTROY or DEFLECT, TRUE == DAMAGE

        // Delete projectile instance if collectable feature enabled, such that it will not be put into the inventory
        if (collision == DESTROY) && (FREEAIM_REUSE_PROJECTILES) {
            var oCItem projectile; projectile = _^(MEM_ReadInt(arrowAI+oCAIArrowBase_hostVob_offset));
            projectile.instanz = -1;
        };

    } else {
        // Default behavior (no custom collision behavior)
        hit = TRUE;
    };

    // The hit chance percentage is either determined by skill and distance (default Gothic hit chance) or is always
    // 100%, if free aiming is enabled and the accuracy is defined by the scattering (FREEAIM_TRUE_HITCHANCE == TRUE).
    var int hitChancePtr; hitChancePtr = MEMINT_SwitchG1G2(/*esp+3Ch-28h*/ ESP+20, /*esp+1ACh-194h*/ ESP+24);
    var int hitchance;
    if (FREEAIM_ACTIVE) && (FREEAIM_RANGED) && (FREEAIM_TRUE_HITCHANCE) {
        // Always hits (100% of all times)
        hitchance = MEMINT_SwitchG1G2(FLOAT1C, 100); // Gothic 1 takes the hit chance as float
    } else {
        // Take the default distance-skill-hit chance provided by Gothic's engine
        hitchance = MEM_ReadInt(hitChancePtr);
    };

    // It is a positive hit depending on the collision (see above) and the hit chance percentage
    hitchance = MEMINT_SwitchG1G2(mulf(mkf(hit), hitchance), // Gothic 1 takes the hit chance as float
                                  hit*hitchance);            // Gothic 2 has it as integer
    MEM_WriteInt(hitChancePtr, hitchance);
};


/*
 * Reset and enable gravity after collision with any surface for Gothic 1. Gothic 2 already implements a deflection
 * behavior of projectiles, while projectiles are destroyed immediately in Gothic 1. When keeping the projectiles alive
 * in Gothic 1, the gravity after collision needs to be enabled (this is already done in Gothic 2).
 * This function hooks oCAIArrow::ReportCollisionToAI at an offset, where a positive collision with an object/world was
 * determined.
 */
func void freeAimCollisionGravity() {
    var int arrowAI; arrowAI = ESI;
    var oCItem projectile; projectile = _^(MEM_ReadInt(arrowAI+oCAIArrowBase_hostVob_offset));
    if (!projectile._zCVob_rigidBody) {
        return;
    };
    var int rigidBody; rigidBody = projectile._zCVob_rigidBody;

    // Better safe than writing to an invalid address
    if (FF_ActiveData(freeAimDropProjectile, rigidBody)) {
        FF_RemoveData(freeAimDropProjectile, rigidBody);
    };

    // Reset projectile gravity (zCRigidBody.gravity) after collision (oCAIArrow.collision) to default
    MEM_WriteInt(rigidBody+zCRigidBody_gravity_offset, FLOATONE);

    // Turn on gravity
    var int bitfield; bitfield = MEM_ReadByte(rigidBody+zCRigidBody_bitfield_offset);
    MEM_WriteByte(rigidBody+zCRigidBody_bitfield_offset, bitfield | zCRigidBody_bitfield_gravityActive);
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
        if (GOTHIC_BASE_VERSION == 1) {
            // Not sure yet: zCPolygon does not seem to have a material in Gothic 1
            return;
        } else {
            matPtr = MEM_ReadInt(matPtr+zCPolygon_material_offset);
        };
    };

    // From the zCMaterial the material type can be read (as defined in Constants.d)
    var zCMaterial mat; mat = _^(matPtr);
    var int material; material = mat.matGroup;

    // Additionally, get the texture of the collision object for more customization of collision behavior
    var string texture;
    if (mat.texture) { // Some objects strangely do not have a texture
        var zCObject tex; tex = _^(mat.texture);
        texture = tex.objectName;
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

    var int vobPtr; vobPtr = MEMINT_SwitchG1G2(ESP+4, ESP+8);
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
    var int vobPtr; vobPtr = MEMINT_SwitchG1G2(ESP+4, ESP+8);
    var zCVob vob; vob = _^(MEM_ReadInt(vobPtr));

    // Check if the collision object is a trigger
    if (vob._vtbl != zCTrigger__vtbl) && (vob._vtbl != zCTriggerScript__vtbl) {
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
