/*
 * Engine offsets for Gothic 1
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
 * All addresses used (Gothic 1). Hooked functions indicated by the hook length in the in-line comments
 */
const int zCVob__SetPositionWorld                 = 6219344; //0x5EE650
const int zCVob__GetRigidBody                     = 6109088; //0x5D37A0
const int zCVob__TraceRay                         = 6113760; //0x5D49E0
const int zCVob__SetAI                            = 0; //0x5FE8F0
const int zCArray_zCVob__IsInList                 = 6590128; //0x648EB0
const int zCWorld__TraceRayNearestHit_Vob         = 6244064; //0x5F46E0
const int oCWorld__AddVobAsChild                  = 7171232; //0x6D6CA0
const int zCWorld__SearchVobListByClass           = 6249792; //0x5F5D40
const int zCMaterial__vtbl                        = 0; //0x832214
const int zCTrigger__vtbl                         = 0; //0x83A3FC
const int zCTriggerScript__vtbl                   = 0; //0x82F404
const int zString_CamModRanged                    = 8822828; //0x86A02C
const int zString_CamModMagic                     = 8823168; //0x86A180
const int zString_CamModNormal                    = 8823048; //0x86A108
const int zString_CamModMelee                     = 8823108; //0x86A144
const int zString_CamModRun                       = 8823128; //0x86A158
const int oCAIHuman__Cam_Normal                   = 9275536; //0x8D8890
const int oCAIHuman__Cam_Fight                    = 9275516; //0x8D887C
const int oCAniCtrl_Human__Turn                   = 6445616; //0x625A30
const int oCNpc__TurnToEnemy_A5                   = 0;       // Not needed for Gothic 1
const int oCNpc__GetAngles                        = 7650560; //0x74BD00
const int oCNpc__SetFocusVob                      = 6881136; //0x68FF70
const int oCNpc__SetEnemy                         = 6888064; //0x691A80
const int oCNpc__GetModel                         = 0; //0x738720
const int oCNpcFocus__InitFocusModes              = 6507760; //0x634CF0
const int oCItem___CreateNewInstance              = 6764320; //0x673720
const int oCItem__InitByScript                    = 0; //0x711BD0
const int oCItem__InsertEffect                    = 0;       // Does not exist in Gothic 1
const int oCItem__RemoveEffect                    = 0;       // Does not exist in Gothic 1
const int oCItem__MultiSlot                       = 6758192; //0x671F30
const int oCMag_Book__GetSelectedSpell            = 4655808; //0x470AC0
const int oCMag_Book__GetSelectedSpellNr          = 4655888; //0x470B10
const int oCMag_Book__GetSpellItem                = 4664896; //0x472E40
const int oCVisualFX__classDef                    = 8822272; //0x869E00
const int oCVisualFX__Stop                        = 4766512; //0x48BB30
const int zCModel__SearchNode                     = 0; //0x57DFF0
const int zCModel__GetBBox3DNodeWorld             = 0; //0x5790F0
const int zCModel__GetNodePositionWorld           = 0; //0x579140
const int zTBBox3D__Draw                          = 5447312; //0x531E90
const int zCLineCache__Line3D                     = 5224976; //0x4FBA10
const int zlineCache                              = 8844672; //0x86F580
const int ztimer                                  = 9236968; //0x8CF1E8
const int oCGame__s_bUseOldControls               = 0;       // Does not exist in Gothic 1
const int mouseEnabled                            = 8835836; //0x86D2FC
const int projectileDeflectOffNpcAddr             = 0; //0x6A0B66
const int oCAIHuman__BowMode_2B                   = 0; //0x695F2B
const int oCAIHuman__BowMode_3F2                  = 0; //0x6962F2
const int oCAIHuman__MagicMode_D0                 = 4641584; //0x46D330
const int oCAIHuman__PC_ActionMove_15B            = 0; //0x69A0BB
const int oCAIHuman__PC_Strafe                    = 0; //0x69AC80
const int zCWorld__AdvanceClock                   = 6257280; //0x5F7A80 // Hook length 10
const int cGameManager__ApplySomeSettings_rtn     = 4356499; //0x427993 // Hook length 6
const int oCAIHuman__BowMode                      = 6358672; //0x610690 // Hook length 6
const int oCAIHuman__BowMode_interpolateAim       = 6359260; //0x6108DC // Hook length 5
const int oCAIHuman__BowMode_3A4                  = 0; //0x6962A4 // Hook length 6
const int oCAIHuman__BowMode_43B                  = 0; //0x69633B // Hook length 6
const int oCAIArrow__SetupAIVob                   = 6394320; //0x6191D0 // Hook length 6
const int oCAIArrow__CanThisCollideWith           = 0; //0x6A1490 // Hook length 7
const int oCAIArrow__DoAI_29                      = 0; //0x6A1489 // Hook length 6
const int oCAIArrowBase__DoAI_98                  = 0; //0x6A06D8 // Hook length 6
const int onArrowHitNpcAddr                       = 0; //0x6A0BC8 // Hook length 5
const int onArrowHitVobAddr                       = 0; //0x6A0C29 // Hook length 5
const int onArrowHitStatAddr                      = 0; //0x6A0A54 // Hook length 5
const int onArrowCollVobAddr                      = 0; //0x6A0C18 // Hook length 5
const int onArrowCollStatAddr                     = 0; //0x6A0A40 // Hook length 5
const int onArrowHitChanceAddr                    = 0; //0x6A1A0B // Hook length 5
const int onArrowDamageAddr                       = 0; //0x6A1A95 // Hook length 7
const int onDmgAnimationAddr                      = 0; //0x675F41 // Hook length 9
const int oCNpcFocus__SetFocusMode                = 6508128; //0x634E60 // Hook length 7
const int oCAIHuman__MagicMode                    = 4641376; //0x46D260 // Hook length 7
const int oCSpell__Setup_oCVisFXinit              = 4704143; //0x47C78F // Hook length 6
const int mouseUpdate                             = 5013392; //0x4C7F90 // Hook length 5


/*
 * Class offsets (Gothic 1)
 */
const int zCVob_bbox3D_offset                       = 124; //0x007C
const int zCVob_trafoObjToWorld_offset              = 60;  //0x003C

const int oCNpc_hitChance_offset                    = 0;   // Does not exist in Gothic 1

const int oCItem_effect_offset                      = 0;   // Does not exist in Gothic 1

const int oCSpell_spellCasterNpc_offset             = 52;  //0x0034
const int oCSpell_manaInvested_offset               = 72;  //0x0048
const int oCSpell_C_Spell_offset                    = 128; //0x0080

const int oCVisualFX_instanceName_offset            = 1140;//0x0474

const int oCAIArrowBase_collision_offset            = 52;  //0x0034
const int oCAIArrowBase_lifeTime_offset             = 56;  //0x0038
const int oCAIArrowBase_hostVob_offset              = 60;  //0x003C
const int oCAIArrowBase_creatingImpactFX_offset     = 64;  //0x0040
const int oCAIArrowBase_hasHit_offset               = 84;  //0x0054
const int oCAIArrow_origin_offset                   = 92;  //0x005C

const int zCRigidBody_mass_offset                   = 0;   //0x0000
const int zCRigidBody_gravity_offset                = 236; //0x00EC
const int zCRigidBody_velocity_offset               = 188; //0x00BC
const int zCRigidBody_bitfield_offset               = 256; //0x0100
const int zCRigidBody_bitfield_gravityActive        = 1<<0;

const int zCModelNodeInst_visual_offset             = 8;   //0x0008

const int zCPolygon_material_offset                 = 0;   // zCPolygon does not have a zCMaterial in Gothic 1

const int zTraceRay_vob_ignore_no_cd_dyn            = 1<<0;  // Ignore vobs without collision
const int zTraceRay_vob_bbox                        = 1<<2;  // Intersect with bounding boxes (important to detect NPCs)
const int zTraceRay_poly_ignore_transp              = 1<<8;  // Ignore alpha polygons (without this trace ray is bugged)
const int zTraceRay_poly_test_water                 = 1<<9;  // Intersect with water
const int zTraceRay_vob_ignore_projectiles          = 1<<14; // Ignore projectiles

const int zTTraceRayReport_foundIntersection_offset = 12;  //0x000C

const int sizeof_zVEC3                              = 12;  //0x000C
const int sizeof_zTBBox3D                           = 24;  //0x0018
const int sizeof_zTTraceRayReport                   = 40;  //0x0028
const int sizeof_zMAT4                              = 64;  //0x0040

// Trafo matrix as zMAT4 is divided column wise
const int zMAT4_rightVec                            = 0; // Right vector
const int zMAT4_upVec                               = 1; // Up vector
const int zMAT4_outVec                              = 2; // Out vector/at vector (facing direction)
const int zMAT4_position                            = 3; // Position vector
