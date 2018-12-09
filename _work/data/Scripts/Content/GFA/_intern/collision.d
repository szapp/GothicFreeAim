/*
 * Custom projectile collision behaviors feature
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
 * Set/reset the collision behavior of projectiles with NPCs. There are two different behaviors plus one auto (default).
 * This function is specific to Gothic 2, because these behaviors are not implemented in Gothic 1 by default. The
 * function is called from GFA_CC_ProjectileCollisionWithNpc() to update the collision behavior for each projectile.
 */
func void GFA_CC_SetProjectileCollisionWithNpc(var int setting) {
    if (GOTHIC_BASE_VERSION != 2) {
        return;
    };

    // Collision behaviors
    const int AUTO    = 0; // Projectile bounces off depending on material of armor (Gothic 2 default)
    const int VANISH  = 1; // Projectile vanishes
    const int DEFLECT = 2; // Projectile deflects of the surfaces and bounces off

    const int SET = AUTO; // Default collision behavior of Gothic 2
    if (setting == SET) {
        return; // No change necessary
    };

    // Manipulate opcode
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
        // Reset to the default collision behavior of Gothic 2
        MEM_WriteByte(oCAIArrowBase__ReportCollisionToAI_collNpc, /*74*/ 116); // Reset to default collision on NPCs
        MEM_WriteByte(oCAIArrowBase__ReportCollisionToAI_collNpc+1, /*3B*/ 59); // jz to 0x6A0BA3
        SET = AUTO;
    };
};


/*
 * Re-implementation of the deflection behavior of projectiles found in Gothic 2, but missing in Gothic 1. Hence, this
 * function is only of interest for Gothic 1. It is called from GFA_CC_ProjectileCollisionWithNpc() and
 * GFA_CC_ProjectileCollisionWithWorld().
 * This code inspired by oCAIArrowBase::ReportCollisionToAI() (0x6A0ACF) of Gothic 2.
 */
func void GFA_CC_ProjectileDeflect(var int rigidBody) {
    if (!rigidBody) || (GOTHIC_BASE_VERSION != 1) {
        return;
    };

    // Turn on gravity
    var int bitfield; bitfield = MEM_ReadByte(rigidBody+zCRigidBody_bitfield_offset);
    MEM_WriteByte(rigidBody+zCRigidBody_bitfield_offset, bitfield | zCRigidBody_bitfield_gravityActive);

    // Get velocity
    var int vel[3];
    MEM_CopyBytes(rigidBody+zCRigidBody_velocity_offset, _@(vel), sizeof_zVEC3); // zCRigidBody.velocity[3]

    // Adjust velocity
    vel[0] = mulf(vel[0], 1061997773); // 0.8 as in 0x6A0AF7 (Gothic 2)
    vel[1] = mulf(vel[1], 1061997773);
    vel[2] = mulf(vel[2], 1061997773);

    // Apply velocity
    var int velPtr; velPtr = _@(vel);
    const int call2 = 0;
    if (CALL_Begin(call2)) {
        CALL_PtrParam(_@(velPtr));
        CALL__thiscall(_@(rigidBody), zCRigidBody__SetVelocity);
        call2 = CALL_End();
    };
};


/*
 * Gothic 1 does not implement that projectiles stop and get stuck in the surface (as found in Gothic 2). Hence, this
 * function is only of interest for Gothic 1. It is called from GFA_CC_ProjectileCollisionWithWorld().
 * The code is inspired by oCAIArrowBase::ReportCollisionToAI() (0x6A0A54) of Gothic 2.
 */
func void GFA_CC_ProjectileStuck(var int projectilePtr) {
    if (!projectilePtr) || (GOTHIC_BASE_VERSION != 1) {
        return;
    };
    var oCItem projectile; projectile = _^(projectilePtr);

    // Stop movement of projectile
    projectile._zCVob_bitfield[0] = projectile._zCVob_bitfield[0] & ~(zCVob_bitfield0_collDetectionStatic
                                                                    | zCVob_bitfield0_collDetectionDynamic
                                                                    | zCVob_bitfield0_physicsEnabled);
};


/*
 * Flag a projectile for removal (will be done by the engine with oCAIArrow::DoAI()). This function is
 * called also from outside this feature (from outside this file), specifically from the collectable feature.
 * It is called for both Gothic 1 and Gothic 2.
 */
func void GFA_CC_ProjectileDestroy(var int arrowAI) {
    MEM_WriteInt(arrowAI+oCAIArrow_destroyProjectile_offset, 1);
    MEM_WriteInt(arrowAI+oCAIArrowBase_lifeTime_offset, FLOATNULL);
};


/*
 * Wrapper function for the config function GFA_GetCollisionWithNpc(). It is called from
 * GFA_CC_ProjectileCollisionWithNpc().
 * This function is necessary for error handling and to supply the readied weapon.
 */
func int GFA_CC_GetCollisionWithNpc_(var C_Npc shooter, var C_Npc target) {
    // Get readied/equipped ranged weapon
    var int weaponPtr; var C_Item weapon;
    if (GFA_GetWeaponAndTalent(shooter, _@(weaponPtr), 0)) {
        weapon = _^(weaponPtr);
    } else {
        weapon = MEM_NullToInst();
    };

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
    return GFA_GetCollisionWithNpc(shooter, target, weapon, material);
};


/*
 * Wrapper function for the config function GFA_GetCollisionWithWorld(). It is called from
 * GFA_CC_ProjectileCollisionWithWorld().
 * This function is necessary for error handling and to supply the readied weapon.
 */
func int GFA_CC_GetCollisionWithWorld_(var C_Npc shooter, var int materials, var string textures) {
    // Get readied/equipped ranged weapon
    var int weaponPtr; var C_Item weapon;
    if (GFA_GetWeaponAndTalent(shooter, _@(weaponPtr), 0)) {
        weapon = _^(weaponPtr);
    } else {
        weapon = MEM_NullToInst();
    };

    // Retrieve collision definition from config
    return GFA_GetCollisionWithWorld(shooter, weapon, materials, textures);
};


/*
 * Manipulate the hit registration on NPCs. This function hooks oCAIArrow::ReportCollisionToAI() at the offset where the
 * hit chance of the NPC is checked. With GFA_GetCollisionWithNpc(), it is decided whether a projectile causes damage,
 * does nothing or bounces off of the NPC. This function is also called for NPC shooters.
 */
func void GFA_CC_ProjectileCollisionWithNpc() {
    var int arrowAI; arrowAI = MEMINT_SwitchG1G2(ESI, EBP);
    var C_Npc shooter; shooter = _^(MEM_ReadInt(arrowAI+oCAIArrow_origin_offset));

    // Hit chance, calculated from skill (or dexterity in Gothic 1) and distance. G1: float, G2: integer
    var int hitChancePtr; hitChancePtr = MEMINT_SwitchG1G2(/*esp+3Ch-28h*/ ESP+20, /*esp+1ACh-194h*/ ESP+24);
    var int hitChance; hitChance = MEMINT_SwitchG1G2(MEM_ReadInt(hitChancePtr), mkf(MEM_ReadInt(hitChancePtr)));

    // Determine if it is a positive hit (may happen if GFA_TRUE_HITCHANCE == false)
    var int rand; rand = EAX % 100;
    var int hit; hit = lf(mkf(rand), hitChance);

    // This class variable is abused as collision counter
    var int collisionCounter; collisionCounter = MEM_ReadInt(arrowAI+oCAIArrowBase_creatingImpactFX_offset);
    MEM_WriteInt(arrowAI+oCAIArrowBase_creatingImpactFX_offset, collisionCounter+1);

    // Collision behaviors
    const int DESTROY = 0; // Projectile doest not cause damage and vanishes
    const int DAMAGE  = 1; // Projectile causes damage and may stay in the inventory of the victim
    const int DEFLECT = 2; // Projectile deflects off of the surfaces and bounces off

    // Retrieve collision behavior
    var int collision;
    if (collisionCounter > 0) {
        // Adjust collision behavior for NPCs, if the projectile bounced off a surface before
        collision = GFA_COLL_PRIOR_NPC;
    } else if (!hit) {
        // If not a positive hit, restore default behavior
        if (GOTHIC_BASE_VERSION == 1) {
            MEM_WriteInt(arrowAI+oCAIArrow_destroyProjectile_offset, 1); // Destroy projectile on impact
        } else {
            GFA_CC_SetProjectileCollisionWithNpc(0); // Restore default damage behavior (automatic by armor material)
        };
        return;
    } else {
        // Retrieve the collision behavior based on the shooter, target and the material type of their armor
        var C_Npc target; target = _^(MEMINT_SwitchG1G2(EBX, MEM_ReadInt(/*esp+1ACh-190h*/ ESP+28)));
        collision = GFA_CC_GetCollisionWithNpc_(shooter, target);
    };

    // Apply collision behavior
    if (GOTHIC_BASE_VERSION == 1) {
        if (collision == DEFLECT) {
            var oCItem projectile; projectile = _^(MEM_ReadInt(arrowAI+oCAIArrowBase_hostVob_offset));
            GFA_CC_ProjectileDeflect(projectile._zCVob_rigidBody);
            if (GFA_Flags & GFA_REUSE_PROJECTILES) {
                MEM_WriteInt(arrowAI+oCAIArrow_destroyProjectile_offset, -1); // Mark as deflecting to ignored it
            };
        } else {
            MEM_WriteInt(arrowAI+oCAIArrow_destroyProjectile_offset, 1); // Destroy projectile on impact
        };
    } else {
        GFA_CC_SetProjectileCollisionWithNpc((collision == DEFLECT)+1); // 2 == DEFLECT, 1 otherwise
    };

    // Overwrite hit chance to disable the hit registration if it was supposed to be a positive hit, but now is not
    if (hit) && (collision != DAMAGE) {
        MEM_WriteInt(hitChancePtr, MEMINT_SwitchG1G2(FLOATNULL, 0)); // G1: float, G2: integer

        // Update shooting statistics (decrement, if shot was supposed to hit, see GFA_OverwriteHitChance())
        if (Npc_IsPlayer(shooter)) && (GFA_ACTIVE) && (GFA_Flags & GFA_RANGED) {
            GFA_StatsHits -= 1;
        };
    };
};


/*
 * Determine the collision behavior when a projectile collides with the world (static or non-NPC vobs). Either destroy,
 * deflect or get stuck. This function hooks oCAIArrowBase::ReportCollisionToAI() at two different offsets for vobs and
 * the static world (Gothic 2), or at an offset where a valid collision was determined (Gothic 1).
 * Because the surface may belong to several material groups and have several textures, they are iterated over and
 * collected in a bit field (materials) and in a concatenated string (textures).
 */
func void GFA_CC_ProjectileCollisionWithWorld() {
    // Retrieve the projectile or leave if does not exist
    var int arrowAI; arrowAI = ESI;
    var int projectilePtr; projectilePtr = MEM_ReadInt(arrowAI+oCAIArrowBase_hostVob_offset);
    if (!projectilePtr) {
        return;
    };
    var oCItem projectile; projectile = _^(projectilePtr);

    // Abusing this class variable as collision counter (starting at zero, will be incremented at end of function)
    var int collisionCounter; collisionCounter = MEM_ReadInt(arrowAI+oCAIArrowBase_creatingImpactFX_offset);

    // Retrieve the collision object (collision surface)
    var int collReport; collReport = MEMINT_SwitchG1G2(/*esp+3Ch+4h*/ MEM_ReadInt(ESP+64), // zCCollisionReport*
                                                       /*esp+30h+4h*/ MEM_ReadInt(ESP+52));
    // Collision object: the surface
    var int collObj; collObj = MEM_ReadInt(collReport+zCCollisionReport_hitCollObj_offset); // zCCollisionObject*

    // The collision surface may have different materials and textures, all of which need to be considered
    var int numMaterials; // Number of materials on the collision surface
    var int materialList; // This is not an actual list. It will be iterated to collect all materials

    // Differentiate between static world and vobs
    if (MEM_GetClassDef(collObj) == zCCollObjectLevelPolys__s_oCollObjClass) {
        // Projectile collided with static world

        // Get material list (it is actually a zCPolygon array)
        var zCArray polyList; polyList = _^(collObj+zCCollObjectLevelPolys_polyList_offset); // zCArray<zCPolygon*>
        numMaterials = polyList.numInArray;
        materialList = _@(polyList);
    } else {
        // Projectile collided with zCVob
        var int vobPtr; vobPtr = MEM_ReadInt(collObj+zCCollisionObject_parent_offset); // zCVob*
        if (!vobPtr) {
            return;
        };

        // Get visual
        var zCVob vob; vob = _^(vobPtr);
        if (!vob.visual) || (Hlp_Is_oCNpc(vobPtr))  {
            return;
        };
        if (!objCheckInheritance(vob.visual, zCProgMeshProto__classDef)) {
            // Adjust the projectile to deflect (Gothic 2 does it by default)
            if (GOTHIC_BASE_VERSION == 1) {
                GFA_CC_ProjectileDeflect(rigidBody);
            };

            // Increase collision counter before leaving this function
            MEM_WriteInt(arrowAI+oCAIArrowBase_creatingImpactFX_offset, collisionCounter+1);
            return;
        };

        // Get material list (this is not a list or an array, just a concatenation of zCMaterial(?) instances)
        numMaterials = MEM_ReadInt(vob.visual+zCVisual_numMaterials_offset);
        materialList = MEM_ReadInt(vob.visual+zCVisual_materials_offset); // First item
    };

    var int firstMat; firstMat = -1; // Material group of the first material. -1 causes deflection of projectile
    var int materials; materials = 0; // Bit field of all materials
    var string textures; textures = ""; // Concatenated string of all textures delimited by the pipe character

    // Iterate over all materials part of the collision surface
    repeat(i, numMaterials); var int i;
        var int matPtr;
        if (MEM_GetClassDef(collObj) == zCCollObjectLevelPolys__s_oCollObjClass) {
            // Static world iterates over polygons (zCPolygon)
            matPtr = MEM_ArrayRead(materialList, i); // zCPolygon*
            matPtr = MEM_ReadInt(matPtr+zCPolygon_material_offset); // zCMaterial*
        } else {
            // Vob iterates over materials (zCMaterial) directly
            matPtr = MEM_ReadInt(materialList+i*88); // 0x0058 magic number? Taken from 0x6A0C20 in Gothic 2
        };
        if (!objCheckInheritance(matPtr, zCMaterial__classDef)) {
            continue;
        };

        var int matGroup; matGroup = MEM_ReadInt(matPtr+zCMaterial_matGroup_offset);
        var int texture; texture = MEM_ReadInt(matPtr+zCMaterial_texture_offset);

        // Collect material group (enable bits) and texture name (concatenate texture names in string)
        materials = materials | (1<<matGroup);
        if (texture) {
            textures = ConcatStrings(textures, "|"); // Delimiter
            textures = ConcatStrings(textures, zCTexture_GetName(texture));
        };

        // Retrieve the material group of the first material to prevent jump in opcode (see below, Gothic 2 only)
        if (firstMat == -1) {
            firstMat = matGroup;
        };
    end;

    // Get the shooter and the rigid body
    var C_Npc shooter; shooter = _^(MEM_ReadInt(arrowAI+oCAIArrow_origin_offset));
    if (!projectile._zCVob_rigidBody) {
        return;
    };
    var int rigidBody; rigidBody = projectile._zCVob_rigidBody;

    // Calculate the speed of the projectile to decide whether to break it and whether to play a collision sound
    var int vel[3];
    MEM_CopyBytes(rigidBody+zCRigidBody_velocity_offset, _@(vel), sizeof_zVEC3); // zCRigidBody.velocity[3]
    var int speed; speed = sqrtf(addf(addf(sqrf(vel[0]), sqrf(vel[1])), sqrf(vel[2]))); // Norm of vel

    // Retrieve the collision behavior based on the shooter, the material types and the textures of the collision object
    var int collision; collision = GFA_CC_GetCollisionWithWorld_(shooter, materials, textures);
    const int DESTROY = 0; // Projectile breaks and vanishes
    const int STUCK   = 1; // Projectile stays and is stuck in the surface of the collision object
    const int DEFLECT = 2; // Projectile deflects off of the surfaces and bounces off

    if (collision == STUCK) {
        // Prevent projectiles from getting stuck on rebound. Otherwise, they get stuck in awkward orientations.
        if (!MEM_ReadInt(arrowAI+oCAIArrowBase_creatingImpactFX_offset)) { // Abusing as collision counter
            // Has not collided yet

            if (GOTHIC_BASE_VERSION == 1) {
                // Gothic 1: Adjust the projectile to get stuck
                GFA_CC_ProjectileStuck(projectilePtr);
            } else {
                // Gothic 2: Has this already implemented
                EDI = firstMat; // Sets the condition at 0x6A0A45 and 0x6A0C1A to true: Projectile stays
            };
        } else {
            collision = DEFLECT;
        };

    } else if (collision == DESTROY) {
        if (GOTHIC_BASE_VERSION == 2) {
            EDI = -1;  // Sets the condition at 0x6A0A45 and 0x6A0C1A to false: Projectile deflects
        };

        // Destroy the projectile only if it is still fast enough and check number of prior collisions
        if (gf(speed, FLOAT3C)) && (collisionCounter < 2) {
            // For both Gothic 1 and Gothic 2
            GFA_CC_ProjectileDestroy(arrowAI);

            // Speed is high enough to break the projectile: Breaking sound and visual effect
            Wld_StopEffect(GFA_BREAK_FX); // Sometimes collides several times, so disable first
            Wld_PlayEffect(GFA_BREAK_FX, projectile, projectile, 0, 0, 0, FALSE);
        } else {
            // If the projectile is too slow, it bounces off instead
            collision = DEFLECT;
        };
    };

    if (collision == DEFLECT) {

        // Aesthetics: Slightly rotate the projectile, such that they do not all lie/stay in parallel
        if (GFA_Flags & GFA_REUSE_PROJECTILES) && (collisionCounter < 2) {
            // Rotate around y-axis
            var int vec[3];
            vec[0] = FLOATNULL;
            vec[1] = FLOATONE;
            vec[2] = FLOATNULL;

            // Randomize the degrees
            var int degrees; degrees = fracf(r_MinMax(7, 50), 10); // [0.7, 5.0] degrees (at least 0.7 degrees!)
            if (r_Max(1)) {
                degrees = negf(degrees);
            };

            var int vecPtr; vecPtr = _@(vec);
            const int call = 0;
            if (CALL_Begin(call)) {
                CALL_FloatParam(_@(degrees));
                CALL_PtrParam(_@(vecPtr));
                CALL__thiscall(_@(projectilePtr), zCVob__RotateWorld);
                call = CALL_End();
            };
        };

        if (GOTHIC_BASE_VERSION == 1) {
            // Gothic 1: Adjust the projectile to deflect
            GFA_CC_ProjectileDeflect(rigidBody);
        } else {
            // Gothic 2: Has this already implemented
            EDI = -1; // Sets the condition at 0x6A0A45 and 0x6A0C1A to false: Projectile deflects
        };
    };


    // Extra settings
    if (GOTHIC_BASE_VERSION == 1) {
        // Gothic 1: Play collision sounds. This was never fully implemented in the original Gothic 1 for some reason.
        // Additionally, the material sounds of Gothic 1 do not really work well with a small projectile. Therefore,
        // here are some other sound instances that resemble the different sounds quite well

        const int UNDEF = 1<<0;
        const int METAL = 1<<1;
        const int STONE = 1<<2;
        const int WOOD  = 1<<3;
        const int EARTH = 1<<4;
        const int WATER = 1<<5;
        const int SNOW  = 1<<6;

        if (gf(speed, FLOAT3C)) && (collisionCounter < 3) {
            // Play sound on first collisions and if fast enough only
            if (materials & METAL) {
                Snd_Play3d(projectile, "RUN_METAL_A4");
            } else if (materials & STONE) && (collisionCounter < 2) {
                Snd_Play3d(projectile, "RUN_WOOD_A4");
            } else if (collision == STUCK) || (collision == DESTROY) {
                Snd_Play3d(projectile, "CS_IHL_ST_EA");
            } else {
                Snd_Play3d(projectile, "SCRATCH_SMALL");
            };
        };

    } else {
        // Gothic 2: Fulfill exit condition of material check loop (EAX is incremented until reaching numMaterials)
        EAX = numMaterials;
    };

    // Play PFX on impact and increment property as counter (needed for GFA_CC_DisableProjectileCollisionOnRebound())
    MEM_WriteInt(arrowAI+oCAIArrowBase_creatingImpactFX_offset, collisionCounter+1);
};


/*
 * Complete the half-implemented feature in Gothic 1 of fading out the visibility of a projectile before removing it.
 * This function hooks oCAIArrowBase::DoAI(), if the collectable feature is not enabled.
 */
func void GFA_CC_FadeProjectileVisibility() {
    // Check if AI was already removed
    var int destroyed; destroyed = MEM_ReadInt(EDI);
    if (destroyed) {
        return;
    };

    // Check validity of projectile
    var int projectilePtr; projectilePtr = EBX; // oCItem*
    if (!projectilePtr) {
        return;
    };
    var zCVob projectile; projectile = _^(projectilePtr);

    // Check if the projectile stopped moving
    if (!(projectile.bitfield[0] & zCVob_bitfield0_physicsEnabled)) {
        var int arrowAI; arrowAI = ESI; // oCAIArrow*
        var int lifeTime; lifeTime = MEM_ReadInt(arrowAI+oCAIArrowBase_lifeTime_offset);
        if (lifeTime == FLOATONE_NEG) {
            MEM_WriteInt(arrowAI+oCAIArrowBase_lifeTime_offset, FLOATONE);
        };
    };
};


/*
 * Disable collision of projectiles with NPCs once the projectiles have bounced off of another surface. This function is
 * called from GFA_ExtendCollisionCheck() only if GFA_COLL_PRIOR_NPC == -1.
 */
func int GFA_CC_DisableProjectileCollisionOnRebound(var int vobPtr, var int arrowAI) {
    // Check if the projectile bounced off of a surface before
    if (MEM_ReadInt(arrowAI+oCAIArrowBase_creatingImpactFX_offset)) {
        return FALSE;
    } else {
        return TRUE;
    };
};


/*
 * Fix trigger collision bug. When shooting a projectile inside a trigger with certain properties, the projectile
 * collides continuously and causes a nerve wrecking sound. Any trigger colliding with a projectile is checked for
 * certain properties to prevent the collision. This function is called from GFA_ExtendCollisionCheck() if
 * GFA_TRIGGER_COLL_FIX == true.
 */
func int GFA_CC_DisableProjectileCollisionWithTrigger(var int vobPtr, var int arrowAI) {
    // Check if the collision object is a trigger
    var zCVob vob; vob = _^(vobPtr);
    if (vob._vtbl != zCTrigger__vtbl) && (vob._vtbl != oCTriggerScript__vtbl) {
        return TRUE;
    };
    var zCTrigger trigger; trigger = _^(vobPtr);

    if (trigger.bitfield & zCTrigger_bitfield_respondToObject)
    && (trigger.bitfield & zCTrigger_bitfield_reactToOnTouch) {
        // Object-reacting trigger. This kind of trigger needs the collision, e.g. to react to projectiles
        return TRUE;
    } else {
        return FALSE;
    };
};


/*
 * Perform additional collision checks after Gothic determines a positive collision of a projectile with a vob bounding
 * box. This function calls various functions from different features to have the projectile ignore the vob in question.
 * Additionally, this vob is added at the beginning of the vob ignore list of the projectile, such that this function is
 * only called once for each projectile-vob-combination for minimum impact on performance. This function hooks
 * oCAIArrow::CanThisCollideWith() at an offset where positive collision with the bounding box was determined, just
 * before leaving the function.
 */
func void GFA_ExtendCollisionCheck() {
    // Retrieve oCAIArrow and collision vob
    var int vobPtr; vobPtr = MEM_ReadInt(MEMINT_SwitchG1G2(/*esp+4h+4h*/ ESP+8, /*esp+8h+4h*/ ESP+12));
    var int arrowAI; arrowAI = MEMINT_SwitchG1G2(ESI, EDI);

    // Perform refined collision checks (in priority order to exit ASAP)
    var int hit; hit = TRUE;
    if (Hlp_Is_oCNpc(vobPtr)) {
        // Ignore NPCs on rebound
        if (GFA_Flags & GFA_CUSTOM_COLLISIONS) && (GFA_COLL_PRIOR_NPC == -1) {
            hit = GFA_CC_DisableProjectileCollisionOnRebound(vobPtr, arrowAI);
        };

        // Ignore by refined collision check with NPCs
        if (GFA_Flags & GFA_RANGED) && (hit) {
            hit = GFA_RefinedProjectileCollisionCheck(vobPtr, arrowAI);
        };
    } else if (GFA_Flags & GFA_CUSTOM_COLLISIONS) && (GFA_TRIGGER_COLL_FIX) && (GOTHIC_BASE_VERSION == 2) {
        // Ignore when colliding with triggers
        hit = GFA_CC_DisableProjectileCollisionWithTrigger(vobPtr, arrowAI);
    };

    // Ignore vob in question
    if (!hit) {
        // Add vob to ignore list
        var int ignoreVobList; ignoreVobList = MEM_ReadInt(arrowAI+oCAIArrowBase_ignoreVobList_offset);
        List_AddFront(ignoreVobList, vobPtr);

        // Increase reference counter, otherwise NPC/vob will be deleted on list destruction!
        var zCVob vob; vob = _^(vobPtr);
        vob._zCObject_refCtr += 1;

        // Set return value of collision check to false
        ECX = 0;
    };
};
