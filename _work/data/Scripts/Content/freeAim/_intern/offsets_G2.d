/*
 * Engine offsets for Gothic 2
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
 * All addresses used (Gothic 2). Hooked functions indicated by the hook length in the in-line comments
 */
const int zCVob__classDef                            = 10106072; //0x9A34D8
const int zCVob__SetPositionWorld                    =  6404976; //0x61BB70
const int zCVob__GetRigidBody                        =  6285664; //0x5FE960
const int zCVob__TraceRay                            =  6291008; //0x5FFE40
const int zCVob__SetAI                               =  6285552; //0x5FE8F0
const int zCVob__SetSleeping                         =  6302000; //0x602930
const int zCArray_zCVob__IsInList                    =  7159168; //0x6D3D80
const int zCRigidBody__StopTransRot                  =  5989776; //0x5B6590                // Not used for Gothic 2
const int zCRigidBody__SetVelocity                   =  5990096; //0x5B66D0                // Not used for Gothic 2
const int zCWorld__TraceRayNearestHit_Vob            =  6430624; //0x621FA0
const int oCWorld__AddVobAsChild                     =  7863856; //0x77FE30
const int zCWorld__SearchVobListByClass              =  6439504; //0x624250
const int zCTrigger__vtbl                            =  8627196; //0x83A3FC
const int oCTriggerScript__vtbl                      =  8582148; //0x82F404
const int zString_CamModRanged                       =  9234704; //0x8CE910
const int zString_CamModMagic                        =  9235048; //0x8CEA68
const int zString_CamModNormal                       =  9234928; //0x8CE9F0                // Not used for Gothic 2
const int zString_CamModMelee                        =  9234988; //0x8CEA2C                // Not used for Gothic 2
const int zString_CamModRun                          =  9235008; //0x8CEA40                // Not used for Gothic 2
const int oCAIHuman__Cam_Normal                      = 11195896; //0xAAD5F8                // Not used for Gothic 2
const int oCAIHuman__Cam_Fight                       = 11195876; //0xAAD5E4                // Not used for Gothic 2
const int oCAniCtrl_Human__Turn                      =  7005504; //0x6AE540
const int oCNpc__TurnToEnemy_camCheck                =  7568757; //0x737D75
const int oCNpc__GetAngles                           =  6820528; //0x6812B0
const int oCNpc__SetFocusVob                         =  7547744; //0x732B60
const int oCNpc__SetEnemy                            =  7556032; //0x734BC0
const int oCNpc__GetModel                            =  7571232; //0x738720
const int oCNpcFocus__InitFocusModes                 =  7072384; //0x6BEA80
const int oCItem___CreateNewInstance                 =  7423040; //0x714440
const int oCItem__InitByScript                       =  7412688; //0x711BD0
const int oCItem__InsertEffect                       =  7416896; //0x712C40
const int oCItem__RemoveEffect                       =  7416832; //0x712C00
const int oCMag_Book__GetSelectedSpell               =  4683648; //0x477780
const int zCProgMeshProto__classDef                  =  9972552; //0x982B48
const int oCVisualFX__classDef                       =  9234008; //0x8CE658
const int oCVisualFX__Stop                           =  4799456; //0x493BE0
const int zCModel__SearchNode                        =  5758960; //0x57DFF0
const int zCModel__GetBBox3DNodeWorld                =  5738736; //0x5790F0
const int zCModel__GetNodePositionWorld              =  5738816; //0x579140
const int zTBBox3D__Draw                             =  5529312; //0x545EE0
const int zCLineCache__Line3D                        =  5289040; //0x50B450
const int zlineCache                                 =  9257720; //0x8D42F8
const int ztimer                                     = 10073044; //0x99B3D4                // Not used for Gothic 2
const int oCGame__s_bUseOldControls                  =  9118144; //0x8B21C0
const int zCInput_Win32__s_mouseEnabled              =  9248108; //0x8D1D6C
const int oCAIArrowBase__ReportCollisionToAI_PFXon1  =  6949324; //0x6A09CC
const int oCAIArrowBase__ReportCollisionToAI_PFXon2  =  6949396; //0x6A0A14
const int oCAIArrowBase__ReportCollisionToAI_collNpc =  6949734; //0x6A0B66
const int oCAIArrow__ReportCollisionToAI_destroyPrj  =  0;                                 // Does not exist in Gothic 2
const int oCAIArrow__ReportCollisionToAI_keepPlyStrp =  0;                                 // Does not exist in Gothic 2
const int oCAIHuman__BowMode_g2ctrlCheck             =  6905643; //0x695F2B
const int oCAIHuman__BowMode_shootingKey             =  6906610; //0x6962F2
const int oCAIHuman__MagicMode_turnToTarget          =  0;                                 // Does not exist in Gothic 2
const int oCAIHuman__PC_ActionMove_aimingKey         =  6922427; //0x69A0BB
const int oCAIHuman__PC_Strafe                       =  6925440; //0x69AC80
const int zCCollObjectLevelPolys__s_oCollObjClass    =  9274192; //0x8D8350

const int zCWorld__AdvanceClock                      =  6447328; //0x6260E0 // Hook len 10
const int cGameManager__ApplySomeSettings_rtn        =  4362866; //0x429272 // Hook len 6
const int oCAIVobMove__DoAI_stopMovement             =  6945300; //0x69FA14 // Hook len 7
const int oCAIHuman__BowMode_interpolateAim          =  6906518; //0x696296 // Hook len 5
const int oCAIHuman__BowMode_postInterpolate         =  6906532; //0x6962A4 // Hook len 6
const int oCAIHuman__BowMode_notAiming               =  6906078; //0x6960DE // Hook len 6
const int oCAIArrow__SetupAIVob                      =  6951136; //0x6A10E0 // Hook len 6
const int oCAIArrow__CanThisCollideWith              =  6952081; //0x6A1491 // Hook len 6
const int oCAIArrow__DoAI_rtn                        =  6952073; //0x6A1489 // Hook len 6
const int oCAIArrowBase__ReportCollisionToAI_hitNpc  =  6949832; //0x6A0BC8 // Hook len 5
const int oCAIArrowBase__ReportCollisionToAI_hitVob  =  6949929; //0x6A0C29 // Hook len 5
const int oCAIArrowBase__ReportCollisionToAI_hitWld  =  6949460; //0x6A0A54 // Hook len 5
const int oCAIArrowBase__ReportCollisionToAI_collVob =  6949440; //0x6A0C18 // Hook len 5
const int oCAIArrowBase__ReportCollisionToAI_collWld =  6949912; //0x6A0A40 // Hook len 5
const int oCAIArrow__ReportCollisionToAI_collAll     =  6949315; //0x6A09C3 // Hook len 8
const int oCAIArrow__ReportCollisionToAI_hitChc      =  6953483; //0x6A1A0B // Hook len 5
const int oCAIArrow__ReportCollisionToAI_damage      =  6953711; //0x6A1AEF // Hook len 7
const int oCNpc__OnDamage_Hit_criticalHit            =  6718100; //0x668294 // Hook len 5  // Not used for Gothic 2
const int oCNpc__OnDamage_Anim_getModel              =  6774593; //0x675F41 // Hook len 9
const int oCNpcFocus__SetFocusMode                   =  7072800; //0x6BEC20 // Hook len 7
const int oCAIHuman__MagicMode                       =  4665296; //0x472FD0 // Hook len 7
const int oCSpell__Setup_oCVisFXinit                 =  4737961; //0x484BA9 // Hook len 6
const int mouseUpdate                                =  5062907; //0x4D40FB // Hook len 5


/*
 * Class offsets (Gothic 2)
 */
const int zCClassDef_baseClassDef_offset             = 60;  //0x003C

const int zCVob_bbox3D_offset                        = 124; //0x007C
const int zCVob_trafoObjToWorld_offset               = 60;  //0x003C

const int oCNpc_hitChance_offset                     = 472; //0x01D8

const int oSDamageDescriptor_origin_offset           = 8;   //0x0008                       // Not used for Gothic 2
const int oSDamageDescriptor_damageType_offset       = 36;  //0x0x24

const int oCItem_effect_offset                       = 564; //0x0234

const int oCSpell_spellCasterNpc_offset              = 52;  //0x0034
const int oCSpell_manaInvested_offset                = 72;  //0x0048
const int oCSpell_C_Spell_offset                     = 128; //0x0080

const int oCVisualFX_originVob_offset                = 1192;//0x04A8
const int oCVisualFX_targetVob_offset                = 1200;//0x04B0
const int oCVisualFX_instanceName_offset             = 1220;//0x04C4

const int oCAIArrowBase_collision_offset             = 52;  //0x0034
const int oCAIArrowBase_lifeTime_offset              = 56;  //0x0038
const int oCAIArrowBase_hostVob_offset               = 60;  //0x003C
const int oCAIArrowBase_creatingImpactFX_offset      = 64;  //0x0040
const int oCAIArrowBase_hasHit_offset                = 84;  //0x0054
const int oCAIArrow_origin_offset                    = 92;  //0x005C
const int oCAIArrow_destroyProjectile_offset         = 96;  //0x0060                       // Not used for Gothic 2

const int zCRigidBody_mass_offset                    = 0;   //0x0000
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
