/*
 * Engine offsets for Gothic 1
 *
 * Gothic Free Aim (GFA) v1.0.0-alpha - Free aiming for the video games Gothic 1 and Gothic 2 by Piranha Bytes
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
 * All addresses used (Gothic 1). Hooked functions indicated by the hook length in the in-line comments
 */
const int zCVob__classDef                            =  9269976; //0x8D72D8
const int zCVob__SetPositionWorld                    =  6219344; //0x5EE650
const int zCVob__GetRigidBody                        =  6109088; //0x5D37A0
const int zCVob__TraceRay                            =  6113760; //0x5D49E0
const int zCVob__SetAI                               =  6108976; //0x5D3730
const int zCVob__SetSleeping                         =  6124112; //0x5D7250
const int zCVob__RotateWorld                         =  6217744; //0x5EE010
const int zCArray_zCVob__IsInList                    =  6590128; //0x648EB0
const int zCRigidBody__SetVelocity                   =  5854080; //0x595380
const int zCWorld__TraceRayNearestHit_Vob            =  6244064; //0x5F46E0
const int oCWorld__AddVobAsChild                     =  7171232; //0x6D6CA0
const int zCWorld__SearchVobListByClass              =  6249792; //0x5F5D40
const int zCTrigger__vtbl                            =  8240940; //0x7DBF2C
const int oCTriggerScript__vtbl                      =  8196940; //0x7D134C
const int zString_CamModRanged                       =  8822828; //0x86A02C
const int zString_CamModMagic                        =  8823168; //0x86A180
const int zString_CamModNormal                       =  8823048; //0x86A108
const int zString_CamModMelee                        =  8823108; //0x86A144
const int zString_CamModRun                          =  8823128; //0x86A158
const int oCAIHuman__Cam_Normal                      =  9275536; //0x8D8890
const int oCAIHuman__Cam_Fight                       =  9275516; //0x8D887C
const int oCAniCtrl_Human__Turn                      =  6445616; //0x625A30
const int oCNpc__TurnToEnemy_camCheck                =  0;                                 // Does not exist in Gothic 1
const int oCNpc__GetAngles                           =  7650560; //0x74BD00
const int oCNpc__SetFocusVob                         =  6881136; //0x68FF70
const int oCNpc__SetEnemy                            =  6888064; //0x691A80
const int oCNpc__GetModel                            =  6902528; //0x695300
const int oCNpcFocus__InitFocusModes                 =  6507760; //0x634CF0
const int oCItem___CreateNewInstance                 =  6764320; //0x673720
const int oCItem__InitByScript                       =  6755936; //0x671660
const int oCItem__InsertEffect                       =  0;                                 // Does not exist in Gothic 1
const int oCItem__RemoveEffect                       =  0;                                 // Does not exist in Gothic 1
const int oCItem__MultiSlot                          =  6758192; //0x671F30
const int oCMag_Book__GetSelectedSpell               =  4655808; //0x470AC0
const int oCMag_Book__GetSelectedSpellNr             =  4655888; //0x470B10
const int oCMag_Book__GetSpellItem                   =  4664896; //0x472E40
const int zCProgMeshProto__classDef                  =  9198408; //0x8C5B48
const int oCVisualFX__classDef                       =  8822272; //0x869E00
const int oCVisualFX__Stop                           =  4766512; //0x48BB30
const int zCModel__SearchNode                        =  5652352; //0x563F80
const int zCModel__GetBBox3DNodeWorld                =  5634160; //0x55F870
const int zCModel__GetNodePositionWorld              =  5634240; //0x55F8C0
const int zVEC3__NormalizeSafe                       =  4900544; //0x4AC6C0
const int zTBBox3D__Draw                             =  5447312; //0x531E90
const int zCLineCache__Line3D                        =  5224976; //0x4FBA10
const int zlineCache                                 =  8844672; //0x86F580
const int ztimer                                     =  9236968; //0x8CF1E8
const int oCGame__s_bUseOldControls                  =  0;                                 // Does not exist in Gothic 1
const int zCInput_Win32__s_mouseEnabled              =  8835836; //0x86D2FC
const int oCAIArrowBase__ReportCollisionToAI_PFXon1  =  0;                                 // Does not exist in Gothic 1
const int oCAIArrowBase__ReportCollisionToAI_PFXon2  =  0;                                 // Does not exist in Gothic 1
const int oCAIArrowBase__ReportCollisionToAI_collNpc =  0;                                 // Does not exist in Gothic 1
const int oCAIArrow__ReportCollisionToAI_destroyPrj  =  6396025; //0x619879
const int oCAIArrow__ReportCollisionToAI_keepPlyStrp =  6395401; //0x619609
const int oCAIHuman__BowMode_g2ctrlCheck             =  0;                                 // Does not exist in Gothic 1
const int oCAIHuman__BowMode_shootingKey             =  0;                                 // Does not exist in Gothic 1
const int oCAIHuman__MagicMode_turnToTarget          =  4641584; //0x46D330
const int oCAIHuman__PC_ActionMove_aimingKey         =  6373222; //0x613F66                // Not used for Gothic 1
const int oCAIHuman__PC_Strafe                       =  6376000; //0x614A40
const int zCCollObjectLevelPolys__s_oCollObjClass    =  8861152; //0x8735E0

const int zCWorld__AdvanceClock                      =  6257280; //0x5F7A80 // Hook len 10
const int cGameManager__ApplySomeSettings_rtn        =  4356499; //0x427993 // Hook len 6
const int oCAIVobMove__DoAI_stopMovement             =  6389348; //0x617E64 // Hook len 7
const int oCAIHuman__PC_ActionMove_bodyState         =  0;                                 // Does not exist in Gothic 1
const int oCAIHuman__BowMode_interpolateAim          =  6359260; //0x6108DC // Hook len 5
const int oCAIHuman__BowMode_postInterpolate         =  6359274; //0x6108EA // Hook len 6
const int oCAIHuman__BowMode_notAiming               =  6359422; //0x61097E // Hook len 6
const int oCAIHuman__MagicMode                       =  4641376; //0x46D260 // Hook len 7
const int oCAIArrow__SetupAIVob                      =  6394320; //0x6191D0 // Hook len 6
const int oCAIArrow__CanThisCollideWith              =  6395216; //0x619550 // Hook len 6
const int oCAIArrow__DoAI_rtn                        =  6395210; //0x61954A // Hook len 6
const int oCAIArrow__ReportCollisionToAI_collAll     =  6395474; //0x619652 // Hook len 8
const int oCAIArrow__ReportCollisionToAI_hitChc      =  6395775; //0x61977F // Hook len 6
const int oCAIArrow__ReportCollisionToAI_damage      =  6395861; //0x6197D5 // Hook len 7
const int oCAIArrowBase__ReportCollisionToAI_hitNpc  =  6395866; //0x6197DA // Hook len 5
const int oCAIArrowBase__ReportCollisionToAI_hitVob  =  0;                                 // Does not exist in Gothic 1
const int oCAIArrowBase__ReportCollisionToAI_hitWld  =  0;                                 // Does not exist in Gothic 1
const int oCAIArrowBase__ReportCollisionToAI_collVob =  0;                                 // Does not exist in Gothic 1
const int oCAIArrowBase__ReportCollisionToAI_collWld =  0;                                 // Does not exist in Gothic 1
const int oCNpc__OnDamage_Hit_criticalHit            =  7546035; //0x7324B3 // Hook len 5
const int oCNpc__OnDamage_Anim_getModel              =  7609592; //0x741CF8 // Hook len 9
const int oCNpcFocus__SetFocusMode                   =  6508128; //0x634E60 // Hook len 7
const int oCSpell__Setup_initFallbackNone            =  4704143; //0x47C78F // Hook len 6
const int mouseUpdate                                =  5013602; //0x4C8062 // Hook len 5


/*
 * Class offsets (Gothic 1)
 */
const int zCClassDef_baseClassDef_offset             = 60;  //0x003C

const int zCVob_bbox3D_offset                        = 124; //0x007C
const int zCVob_trafoObjToWorld_offset               = 60;  //0x003C

const int oCNpc_hitChance_offset                     = 0;                                  // Does not exist in Gothic 1

const int oSDamageDescriptor_origin_offset           = 8;   //0x0008
const int oSDamageDescriptor_damageType_offset       = 32;  //0x0x20

const int oCItem_effect_offset                       = 0;                                  // Does not exist in Gothic 1

const int oCSpell_spellCasterNpc_offset              = 52;  //0x0034
const int oCSpell_manaInvested_offset                = 72;  //0x0048
const int oCSpell_C_Spell_offset                     = 128; //0x0080

const int oCVisualFX_originVob_offset                = 1112;//0x0458
const int oCVisualFX_targetVob_offset                = 1120;//0x0460
const int oCVisualFX_instanceName_offset             = 1140;//0x0474

const int zCAICamera_elevation_offset                = 56;  //0x0038
const int zCAICamera_azimuth_offset                  = 68;  //0x0044

const int oCAIArrowBase_collision_offset             = 52;  //0x0034
const int oCAIArrowBase_lifeTime_offset              = 56;  //0x0038
const int oCAIArrowBase_hostVob_offset               = 60;  //0x003C
const int oCAIArrowBase_creatingImpactFX_offset      = 64;  //0x0040
const int oCAIArrowBase_hasHit_offset                = 0;                                  // Does not exist in Gothic 1
const int oCAIArrow_origin_offset                    = 88;  //0x0058
const int oCAIArrow_destroyProjectile_offset         = 92;  //0x005C

const int zCRigidBody_mass_offset                    = 0;   //0x0000
const int zCRigidBody_xPos_offset                    = 80;  //0x0050
const int zCRigidBody_gravity_offset                 = 236; //0x00EC
const int zCRigidBody_velocity_offset                = 188; //0x00BC
const int zCRigidBody_bitfield_offset                = 256; //0x0100
const int zCRigidBody_bitfield_gravityActive         = 1<<0;

const int zCModelNodeInst_visual_offset              = 8;   //0x0008

const int zCVisual_materials_offset                  = 164; //0x00A4
const int zCVisual_numMaterials_offset               = 168; //0x00A8

const int zCPolygon_material_offset                  = 24;  //0x0018

const int zCCollisionReport_hitCollObj_offset        = 48;  //0x0030

const int zCCollisionObject_parent_offset            = 132; //0x0084
const int zCCollObjectLevelPolys_polyList_offset     = 140; //0x008C

const int zTraceRay_vob_ignore_no_cd_dyn             = 1<<0;  // Ignore vobs without collision
const int zTraceRay_vob_bbox                         = 1<<2;  // Intersect bounding boxes (important to detect NPCs)
const int zTraceRay_poly_ignore_transp               = 1<<8;  // Ignore alpha polys (without this, trace ray is bugged)
const int zTraceRay_poly_test_water                  = 1<<9;  // Intersect water
const int zTraceRay_vob_ignore_projectiles           = 1<<14; // Ignore projectiles

const int zTTraceRayReport_foundIntersection_offset  = 12;  //0x000C

const int sizeof_zVEC3                               = 12;  //0x000C
const int sizeof_zTBBox3D                            = 24;  //0x0018
const int sizeof_zTTraceRayReport                    = 40;  //0x0028
const int sizeof_zMAT4                               = 64;  //0x0040

// Trafo matrix as zMAT4 is divided column wise
const int zMAT4_rightVec                             = 0; // Right vector
const int zMAT4_upVec                                = 1; // Up vector
const int zMAT4_outVec                               = 2; // Out vector/at vector (facing direction)
const int zMAT4_position                             = 3; // Position vector
