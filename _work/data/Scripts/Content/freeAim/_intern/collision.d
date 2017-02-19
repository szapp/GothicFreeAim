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

/* Internal helper function for freeAimHitRegNpc() */
func int freeAimHitRegNpc_(var C_Npc target) {
    var C_Item weapon; weapon = MEM_NullToInst(); // Daedalus pseudo locals
    if (Npc_IsInFightMode(hero, FMODE_FAR)) { weapon = Npc_GetReadiedWeapon(hero); }
    else if (Npc_HasEquippedRangedWeapon(hero)) { weapon = Npc_GetEquippedRangedWeapon(hero); };
    var int material; material = -1; // No armor
    if (Npc_HasEquippedArmor(target)) {
        var C_Item armor; armor = Npc_GetEquippedArmor(target);
        material = armor.material;
    };
    // Call customized function
    MEM_PushInstParam(target);
    MEM_PushInstParam(weapon);
    MEM_PushIntParam(material);
    MEM_Call(freeAimHitRegNpc); // freeAimHitRegNpc(target, weapon, material);
    return MEM_PopIntResult();
};

/* Internal helper function for freeAimHitRegWld() */
func int freeAimHitRegWld_(var C_Npc shooter, var int material, var string texture) {
    var C_Item weapon; weapon = MEM_NullToInst(); // Daedalus pseudo locals
    if (Npc_IsInFightMode(shooter, FMODE_FAR)) { weapon = Npc_GetReadiedWeapon(shooter); }
    else if (Npc_HasEquippedRangedWeapon(shooter)) { weapon = Npc_GetEquippedRangedWeapon(shooter); };
    // Call customized function
    MEM_PushInstParam(shooter);
    MEM_PushInstParam(weapon);
    MEM_PushIntParam(material);
    MEM_PushStringParam(texture);
    MEM_Call(freeAimHitRegWld); // freeAimHitRegWld(shooter, weapon, material, texture);
    return MEM_PopIntResult();
};

/* Determine the hit chance. For the player it's always 100%. True hit chance is calculated in freeAimGetAccuracy() */
func void freeAimDoNpcHit() {
    var int hitChance; hitChance = MEM_ReadInt(ESP+24); // esp+1ACh+194h
    var C_Npc target; target = _^(MEM_ReadInt(ESP+28)); // esp+1ACh+190h // oCNpc*
    var C_Npc shooter; shooter = _^(MEM_ReadInt(EBP+92)); // ebp+5Ch // oCNpc*
    var int projectile; projectile = MEM_ReadInt(EBP+88); // ebp+58h // oCItem*
    if (FREEAIM_ACTIVE_PREVFRAME != 1) || (!Npc_IsPlayer(shooter)) { // Default hitchance for npcs or if fa is disabled
        MEM_WriteByte(projectileDeflectOffNpcAddr, /*74*/ 116); // Reset to default collision behavior on npcs
        MEM_WriteByte(projectileDeflectOffNpcAddr+1, /*3B*/ 59); // jz to 0x6A0BA3
        return;
    };
    var int intersection; intersection = 1; // Hit registered (positive hit determined by the engine at this point)
    if (FREEAIM_HITDETECTION_EXP) { // Additional hit detection test (EXPERIMENTAL). Will lead to some hits not detected
        intersection = 0; // Check here if "any" point along the line of the projectile direction lies inside the bbox
        var zTBBox3D targetBBox; targetBBox = _^(_@(target)+124); // oCNpc.bbox3D
        var int dir[3]; // Direction of collision line along the right-vector of projectile (projectile flies sideways)
        dir[0] = MEM_ReadInt(projectile+60); dir[1] = MEM_ReadInt(projectile+76); dir[2] = MEM_ReadInt(projectile+92);
        var int line[6]; // Collision line
        line[0] = addf(MEM_ReadInt(projectile+ 72), mulf(dir[0], FLOAT3C)); // Start 3m behind the projectile
        line[1] = addf(MEM_ReadInt(projectile+ 88), mulf(dir[1], FLOAT3C)); // So far because of bbox at close range
        line[2] = addf(MEM_ReadInt(projectile+104), mulf(dir[2], FLOAT3C));
        var int i; i=0; var int iter; iter = 700/5; // 7meters
        while(i <= iter); i += 1; // Walk along the line in steps of 5cm
            line[3] = subf(line[0], mulf(dir[0], mkf(i*5))); // Next point along the collision line
            line[4] = subf(line[1], mulf(dir[1], mkf(i*5)));
            line[5] = subf(line[2], mulf(dir[2], mkf(i*5)));
            if (lef(targetBBox.mins[0], line[3])) && (lef(targetBBox.mins[1], line[4]))
            && (lef(targetBBox.mins[2], line[5])) && (gef(targetBBox.maxs[0], line[3]))
            && (gef(targetBBox.maxs[1], line[4])) && (gef(targetBBox.maxs[2], line[5])) {
                intersection = 1; break; }; // Current point is inside the bbox
        end;
    };
    var int hit;
    if (intersection) { // By default this is always true
        var int collision; collision = freeAimHitRegNpc_(target); // 0=destroy, 1=stuck, 2=deflect
        if (collision == 2) { // Deflect (no damage)
            MEM_WriteByte(projectileDeflectOffNpcAddr, ASMINT_OP_nop); // Skip npc armor collision check, deflect always
            MEM_WriteByte(projectileDeflectOffNpcAddr + 1, ASMINT_OP_nop);
            hit = FALSE;
        } else {
            MEM_WriteByte(projectileDeflectOffNpcAddr, /*74*/ 116); // Jump beyond armor collision check, deflect never
            MEM_WriteByte(projectileDeflectOffNpcAddr+1, /*60*/ 96); // jz to 0x6A0BC8
            if (!collision) { // Destroy (no damage)
                MEM_WriteInt(projectile+816, -1); // Delete item instance (it will not be put into the directory)
                hit = FALSE;
            } else { // Collide (damage)
                hit = TRUE;
            };
        };
    } else { // Destroy the projectile if it did not physically hit
        MEM_WriteByte(projectileDeflectOffNpcAddr, /*74*/ 116); // Jump beyond the armor collision check, deflect never
        MEM_WriteByte(projectileDeflectOffNpcAddr+1, /*60*/ 96); // jz to 0x6A0BC8
        MEM_WriteInt(projectile+816, -1); // Delete item instance (it will not be put into the directory)
        hit = FALSE;
    };
    MEM_WriteInt(ESP+24, hit*100); // Player always hits = 100%
};

/* Arrow collides with world (static or non-npc vob). Either destroy, deflect or collide */
func void freeAimOnArrowCollide() {
    var oCItem projectile; projectile = _^(MEM_ReadInt(ESI+60)); // esi+3Ch
    var C_Npc shooter; shooter = _^(MEM_ReadInt(esi+92)); // esi+5Ch
    var int matobj; matobj = MEM_ReadInt(ECX); // zCMaterial* or zCPolygon*
    if (MEM_ReadInt(matobj) != zCMaterial__vtbl) { matobj = MEM_ReadInt(matobj+24); }; // Static world: Read zCPolygon
    var int material; material = MEM_ReadInt(matobj+64);
    var string texture; texture = "";
    if (MEM_ReadInt(matobj+52)) { // For the case that the material has no assigned texture (which should not happen)
        texture = MEM_ReadString(MEM_ReadInt(matobj+52)+16); // zCMaterial.texture._zCObject_objectName
    };
    var int collision; collision = freeAimHitRegWld_(shooter, material, texture); // 0=destroy, 1=stay, 2=deflect
    if (collision == 1) { // Collide
        EDI = material; // Sets the condition at 0x6A0A45 and 0x6A0C1A to true: Projectile stays
    } else {
        EDI = -1;  // Sets the condition at 0x6A0A45 and 0x6A0C1A to false: Projectile deflects
        if (!collision) {
            if (FF_ActiveData(freeAimDropProjectile, _@(projectile._zCVob_rigidBody))) {
                FF_RemoveData(freeAimDropProjectile, _@(projectile._zCVob_rigidBody)); };
            if (FREEAIM_REUSE_PROJECTILES) { // Destroy
                Wld_StopEffect(FREEAIM_BREAK_FX); // Sometimes collides several times
                Wld_PlayEffect(FREEAIM_BREAK_FX, projectile, projectile, 0, 0, 0, FALSE);
                MEM_WriteInt(ESI+56, -1073741824); // oCAIArrow.lifeTime // Mark this AI for freeAimWatchProjectile()
            };
        };
    };
};

/* Fix trigger collision bug. Taken from http://forum.worldofplayers.de/forum/threads/1126551/page10?p=20894916 */
func void freeAimTriggerCollisionCheck() {
    var int vobPtr; vobPtr = ESP+4;
    var int shooter; shooter = MEM_ReadInt(ECX+92);
    var int vtbl; vtbl = MEM_ReadInt(MEM_ReadInt(vobPtr));
    if (vtbl != zCTrigger_vtbl) && (vtbl != zCTriggerScript_vtbl) { return; }; // It is no Trigger
    var zCTrigger trigger; trigger = _^(MEM_ReadInt(vobPtr));
    if (trigger.bitfield & zCTrigger_bitfield_respondToObject)
    && (trigger.bitfield & zCTrigger_bitfield_reactToOnTouch) { return; }; // Object-reacting trigger
    MEM_WriteInt(vobPtr, shooter); // The engine ignores the shooter
};
