/*
 * Custom projectile collision behaviors feature
 *
 * Gothic Free Aim (GFA) v1.0.0-beta.17 - Free aiming for the video games Gothic 1 and Gothic 2 by Piranha Bytes
 * Copyright (C) 2016-2017  mud-freak (@szapp)
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
    if (GOTHIC_BASE_VERSION == 1) {
        MEM_WriteInt(arrowAI+oCAIArrow_destroyProjectile_offset, 1); // Gothic 1
    } else {
        MEM_WriteInt(arrowAI+oCAIArrowBase_lifeTime_offset, FLOATNULL); // Gothic 2
    };
};


/*
 * Wrapper function for the config function GFA_GetCollisionWithNpc(). It is called from
 * GFA_CC_ProjectileCollisionWithNpc().
 * This function is necessary for error handling and to supply the readied weapon.
 */
func int GFA_CC_GetCollisionWithNpc_(var C_Npc shooter, var C_Npc target) {
    // Get readied/equipped ranged weapon
    var int weaponPtr;
    GFA_GetWeaponAndTalent(shooter, _@(weaponPtr), 0);
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
    return GFA_GetCollisionWithNpc(shooter, target, weapon, material);
};


/*
 * Wrapper function for the config function GFA_GetCollisionWithWorld(). It is called from
 * GFA_CC_ProjectileCollisionWithWorld().
 * This function is necessary for error handling and to supply the readied weapon.
 */
func int GFA_CC_GetCollisionWithWorld_(var C_Npc shooter, var int materials, var string textures) {
    // Get readied/equipped ranged weapon
    var int weaponPtr;
    GFA_GetWeaponAndTalent(shooter, _@(weaponPtr), 0);
    var C_Item weapon; weapon = _^(weaponPtr);

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
            MEM_WriteInt(arrowAI+oCAIArrow_destroyProjectile_offset, -1); // Mark as deflecting, such that it is ignored
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
        if (!matPtr) {
            continue;
        };
        var zCMaterial mat; mat = _^(matPtr);

        // Collect material group (enable bits) and texture name (concatenate texture names in string)
        materials = materials | (1<<mat.matGroup);
        if (mat.texture) {
            textures = ConcatStrings(textures, "|"); // Delimiter
            textures = ConcatStrings(textures, zCTexture_GetName(mat.texture));
        };

        if (firstMat == -1) {
            // Retrieve the material group of the first material to prevent jump in opcode (see below, Gothic 2 only)
            firstMat = mat.matGroup;
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
 * Wrapper function for the config function GFA_GetDamageBehavior(). It is called from GFA_CC_SetDamageBehavior().
 * This function is necessary for error handling and to supply the readied weapon, respective talent value and whether
 * the shot was a critical hit.
 */
func int GFA_CC_GetDamageBehavior_(var C_Npc target) {
    // Get readied/equipped ranged weapon
    var int talent; var int weaponPtr;
    GFA_GetWeaponAndTalent(hero, _@(weaponPtr), _@(talent));
    var C_Item weapon; weapon = _^(weaponPtr);

    // Retrieve damage behavior from config
    var int dmgBehavior; dmgBehavior = GFA_GetDamageBehavior(target, weapon, talent, GFA_LastHitCritical);

    // Reset critical hit
    GFA_LastHitCritical = FALSE;

    // Behaviors
    const int DO_NOT_KNOCKOUT  = 0; // Gothic default: Normal damage, projectiles kill and never knockout (HP != 1)
    const int DO_NOT_KILL      = 1; // Normal damage, projectiles knockout and never kill (HP > 0)
    const int INSTANT_KNOCKOUT = 2; // One shot knockout (1 HP)
    const int INSTANT_KILL     = 3; // One shot kill (0 HP)
    const int MAX_BEHAVIOR     = 4;

    // Must be a valid behavior
    if (dmgBehavior < 0) || (dmgBehavior >= MAX_BEHAVIOR) {
        MEM_Warn("GFA_CC_GetDamageBehavior_: Invalid damage behavior!");
        dmgBehavior = DO_NOT_KNOCKOUT; // Gothic default
    };
    return dmgBehavior;
};


/*
 * Define how the damage of a projectile will be applied: Normal damage (kill or knockout), instant kill or instant
 * knockout. This function hooks oCAIArrow::ReportCollisionToAI() at an offset where the base damage is determined,
 * which this function overwrites.
 * The behavior can be defined with the config function GFA_GetDamageBehavior() of the custom collisions feature.
 *
 * This function will be called irrespective of all enabled or disabled features, because it fixes the "bug",
 * that under certain circumstances NPCs can get knocked out by projectiles (instead of dying) in the original Gothic.
 * In this case always the behavior DO_NOT_KNOCKOUT is the default setting of this function.
 */
func void GFA_CC_SetDamageBehavior() {
    // First check if shooter is player
    var int arrowAI; arrowAI = MEMINT_SwitchG1G2(ESI, EBP);
    var C_Npc shooter; shooter = _^(MEM_ReadInt(arrowAI+oCAIArrow_origin_offset));
    if (!Npc_IsPlayer(shooter)) {
        return;
    };

    // Do this for one damage type only. It gets too complicated for multiple damage types
    var oCItem projectile; projectile = _^(MEM_ReadInt(arrowAI+oCAIArrowBase_hostVob_offset));
    var int iterator; iterator = projectile.damageType;
    var int damageIndex; damageIndex = 0;
    // Find damage index from bit field
    while((iterator > 0) && ((iterator & 1) != 1)); // Check lower bit
        damageIndex += 1;
        // Cut off lower bit
        iterator = iterator >> 1;
    end;
    if (iterator > 1) || (damageIndex == DAM_INDEX_MAX) {
        if (GFA_DEBUG_PRINT) {
            MEM_Info("GFA_CC_SetDamageBehavior: Ignoring projectile due to multiple/invalid damage types.");
        };
        return;
    };

    var int damagePtr; damagePtr = MEMINT_SwitchG1G2(/*esp+48h-48h*/ ESP, /*esp+1ACh-C8h*/ ESP+228); // zREAL*
    var int baseDamage; baseDamage = roundf(MEM_ReadInt(damagePtr));
    var int targetPtr; targetPtr = MEMINT_SwitchG1G2(EBX, MEM_ReadInt(/*esp+1ACh-190h*/ ESP+28)); // oCNpc*
    var C_Npc targetNpc; targetNpc = _^(targetPtr);
    var int protection;
    if (GOTHIC_BASE_VERSION == 1) {
        protection = MEM_ReadStatArr(_@(targetNpc.protection), damageIndex);
    } else {
        // Gothic 2 always considers point protection
        protection = targetNpc.protection[PROT_POINT];
    };

    // Calculate final damage (to be applied to the target) from base damage
    var int finalDamage;
    if (GOTHIC_BASE_VERSION == 1) {
        finalDamage = baseDamage-protection;
        if (finalDamage < 0) {
            finalDamage = 0;
        };
    } else {
        finalDamage = (baseDamage+hero.attribute[ATR_DEXTERITY])-protection;
        if (finalDamage < NPC_MINIMAL_DAMAGE) {
            finalDamage = NPC_MINIMAL_DAMAGE;
        };
    };

    const int DO_NOT_KNOCKOUT  = 0; // Gothic default: Normal damage, projectiles kill and never knockout (HP != 1)
    const int DO_NOT_KILL      = 1; // Normal damage, projectiles knockout and never kill (HP > 0)
    const int INSTANT_KNOCKOUT = 2; // One shot knockout (HP = 1)
    const int INSTANT_KILL     = 3; // One shot kill (HP = 0)
    var int dmgBehavior;
    if (GFA_Flags & GFA_CUSTOM_COLLISIONS) {
        dmgBehavior = GFA_CC_GetDamageBehavior_(targetNpc);
    } else {
        dmgBehavior = DO_NOT_KNOCKOUT;
    };

    // Store behavior for debug output on zSpy
    var string damageBehaviorStr;

    // Manipulate final damage
    var int newFinalDamage; newFinalDamage = finalDamage;
    if (dmgBehavior == DO_NOT_KNOCKOUT) {
        damageBehaviorStr = "Normal damage, prevent knockout (HP != 1) [Gothic default]";
        if (finalDamage == targetNpc.attribute[ATR_HITPOINTS]-1) {
            newFinalDamage = targetNpc.attribute[ATR_HITPOINTS]; // Never 1 HP
        };
    } else if (dmgBehavior == DO_NOT_KILL) {
        damageBehaviorStr = "Normal damage, prevent kill (HP > 0)";
        if (finalDamage >= targetNpc.attribute[ATR_HITPOINTS]) {
            newFinalDamage = targetNpc.attribute[ATR_HITPOINTS]-1; // Never 0 HP
        };
    } else if (dmgBehavior == INSTANT_KNOCKOUT) {
        damageBehaviorStr = "Instant knockout (1 HP)";
        newFinalDamage = targetNpc.attribute[ATR_HITPOINTS]-1; // 1 HP
    } else if (dmgBehavior == INSTANT_KILL) {
        damageBehaviorStr = "Instant kill (0 HP)";
        newFinalDamage = targetNpc.attribute[ATR_HITPOINTS]; // 0 HP
    };

    // Adjustment for minimal damage in Gothic 2
    if (GOTHIC_BASE_VERSION == 2) && (newFinalDamage < NPC_MINIMAL_DAMAGE) {
        targetNpc.attribute[ATR_HITPOINTS] += NPC_MINIMAL_DAMAGE;
        newFinalDamage = NPC_MINIMAL_DAMAGE;
    };

    // Calculate new base damage from adjusted newFinalDamage
    var int newBaseDamage;
    if (GOTHIC_BASE_VERSION == 1) {
        newBaseDamage = newFinalDamage+protection;
    } else {
        newBaseDamage = (newFinalDamage+protection)-hero.attribute[ATR_DEXTERITY];
    };
    if (newBaseDamage < 0) {
        newBaseDamage = 0;
    };

    // Overwrite base damage
    MEM_WriteInt(damagePtr, mkf(newBaseDamage));

    if (GFA_DEBUG_PRINT) {
        MEM_Info("GFA_CC_SetDamageBehavior:");
        var int s; s = SB_New();

        SB("   damage behavior:   ");
        SB(damageBehaviorStr);
        MEM_Info(SB_ToString());
        SB_Clear();

        SB("   base damage (n/o): ");
        SBi(newBaseDamage);
        SB("/");
        SBi(baseDamage);
        MEM_Info(SB_ToString());
        SB_Clear();

        SB("   damage on target:  ");
        SBi(newFinalDamage);
        SB("/");
        SBi(finalDamage);
        MEM_Info(SB_ToString());
        SB_Destroy();
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
 * collides continuously and causes a nerve recking sound. Any trigger collising with a projectile is checked for
 * certain properties to prevent the collision. This function is called from GFA_ExtendCollisionCheck() if
 * GFA_TRIGGER_COLL_FIX == true.
 */
func int GFA_CC_DisableProjectileCollisionWithTrigger(var int vobPtr, var int arrowAI) {
    // Check if the collision object is a trigger
    var zCVob vob; vob = _^(MEM_ReadInt(vobPtr));
    if (vob._vtbl != zCTrigger__vtbl) && (vob._vtbl != oCTriggerScript__vtbl) {
        return TRUE;
    };
    var zCTrigger trigger; trigger = _^(MEM_ReadInt(vobPtr));

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
        if (GFA_Flags & GFA_RANGED) && (GFA_TRUE_HITCHANCE) && (hit) {
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
