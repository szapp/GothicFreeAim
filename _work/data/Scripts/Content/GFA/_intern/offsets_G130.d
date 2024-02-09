/*
 * Engine offsets for Gothic 2 Classic
 *
 * Gothic Free Aim (GFA) v1.2.0 - Free aiming for the video games Gothic 1 and Gothic 2 by Piranha Bytes
 * Copyright (C) 2016-2019  mud-freak (@szapp)
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
 * All addresses used (Gothic 2 Classic). Hooked functions indicated by the hook length in the in-line comments
 */
const int zCVob__classDef                            =  9948544; //0x97CD80
const int zCVob__SetPositionWorld                    =  6374544; //0x614490
const int zCVob__GetRigidBody                        =  6257520; //0x5F7B70
const int zCVob__TraceRay                            =  6262848; //0x5F9040
const int zCVob__SetAI                               =  6257408; //0x5F7B00
const int zCVob__SetSleeping                         =  6273792; //0x5FBB00
const int zCVob__RotateWorld                         =  6372944; //0x613E50
const int zCRigidBody__SetVelocity                   =  5966688; //0x5B0B60                // Not used for Gothic 2
const int zCCollisionReport__vtbl                    =  8535308; //0x823D0C
const int zCWorld__TraceRayNearestHit_Vob            =  6400016; //0x61A810
const int oCWorld__AddVobAsChild                     =  7472112; //0x7203F0
const int zCWorld__SearchVobListByClass              =  6408896; //0x61CAC0
const int zCTrigger__vtbl                            =  8569812; //0x82C3D4
const int oCTriggerScript__vtbl                      =  8524804; //0x821404
const int zString_CamModRanged                       =  9175732; //0x8C02B4
const int zString_CamModMagic                        =  9176072; //0x8C0408
const int zString_CamModNormal                       =  9175952; //0x8C0390                // Not used for Gothic 2
const int zString_CamModMelee                        =  9176012; //0x8C03CC                // Not used for Gothic 2
const int zString_CamModRun                          =  9176032; //0x8C03E0                // Not used for Gothic 2
const int oCAIHuman__Cam_Normal                      =  9954248; //0x97E3C8                // Not used for Gothic 2
const int oCAIHuman__Cam_Fight                       =  9954228; //0x97E3B4                // Not used for Gothic 2
const int oCAIHuman__CheckFocusVob_ranged            =  6549807; //0x63F12F
const int oCAIHuman__CheckFocusVob_spells            =  6549813; //0x63F135
const int oCAniCtrl_Human__IsStanding                =  6624864; //0x651660
const int oCAniCtrl_Human__Turn                      =  6626496; //0x651CC0
const int oCAniCtrl_Human__CanToggleWalkModeTo       =  6616880; //0x64F730
const int oCAniCtrl_Human__ToggleWalkMode            =  6622336; //0x650C80
const int zCAIPlayer__CheckEnoughSpaceMoveDir        =  5301584; //0x50E550
const int oCNpc__player                              =  9974236; //0x9831DC
const int oCNpc__TurnToEnemy_camCheck                =  7181877; //0x6D9635
const int oCNpc__GetAngles                           =  7962064; //0x797DD0
const int oCNpc__GetFocusVob                         =  7161232; //0x6D4590                // Not used for Gothic 2
const int oCNpc__SetFocusVob                         =  7161152; //0x6D4540
const int oCNpc__SetEnemy                            =  7169440; //0x6D65A0
const int oCNpc__SetBodyState                        =  7338400; //0x6FF9A0
const int oCNpc__GetInteractMob                      =  7258064; //0x6EBFD0
const int oCNpc__EV_Strafe_magicCombat               =  7975099; //0x79B0BB
const int oCNpc__FightAttackMagic                    =  7955840; //0x796580
const int oCNpc__Interrupt_stopAnisLayerA            =  7173410; //0x6D7522
const int oCNpc__RefreshNpc_createAmmoIfNone         =  7223574; //0x6E3916
const int oCNpcFocus__InitFocusModes                 =  6693104; //0x6620F0
const int oCNpcFocus__Init                           =  6694064; //0x6624B0
const int oCNpcFocus__focusnames                     =  9966040; //0x9811D8
const int oCNpcFocus__focuslist                      =  9966160; //0x981250
const int oCNpcFocus__focus                          =  9966224; //0x981290
const int oCItem___CreateNewInstance                 =  7037872; //0x6B63B0
const int oCItem__InitByScript                       =  7028384; //0x6B3EA0
const int oCItem__InsertEffect                       =  0;                                 // Does not exist in Gothic 2
const int oCItem__RemoveEffect                       =  0;                                 // Does not exist in Gothic 2
const int oCItem__MultiSlot                          =  7030896; //0x6B4870                // Not used for Gothic 2
const int oCMag_Book__GetSelectedSpell               =  4678624; //0x4763E0
const int oCMag_Book__GetSelectedSpellNr             =  4678704; //0x476430                // Not used for Gothic 2
const int oCMag_Book__GetSpellItem                   =  4687968; //0x478860                // Not used for Gothic 2
const int oCMag_Book__StopSelectedSpell              =  4679024; //0x476570
const int oCSpell__Open                              =  4735616; //0x484280
const int zCProgMeshProto__classDef                  =  9815072; //0x95C420
const int zCMaterial__classDef                       =  9216136; //0x8CA088
const int oCVisualFX__classDef                       =  9175032; //0x8BFFF8
const int oCVisualFX__Stop                           =  4792752; //0x4921B0
const int oCVisualFX__SetTarget                      =  4782416; //0x48F950
const int zCModel__classDef                          =  9216672; //0x8CA2A0
const int zCModel__TraceRay_softSkinCheck            =  5755584; //0x57D2C0
const int zCModel__CalcNodeListBBoxWorld             =  5717264; //0x573D10
const int zCModel__StartAni                          =  5724752; //0x575A50
const int zCModel__FadeOutAnisLayerRange             =  5741776; //0x579CD0
const int zCModel__StopAnisLayerRange                =  5741856; //0x579D20
const int zCModelPrototype__SearchAniIndex           =  5786208; //0x584A60
const int zVEC3__NormalizeSafe                       =  4812144; //0x496D70
const int zTBBox3D__CalcGreaterBBox3D                =  5502112; //0x53F4A0
const int zTBBox3D__TraceRay                         =  5507872; //0x540B20
const int zCOBBox3D__Transform                       =  5523056; //0x544670
const int oCGame__s_bUseOldControls                  =  9037088; //0x89E520
const int zCInput_Win32__s_mouseEnabled              =  9189132; //0x8C370C
const int oCAIArrow__ReportCollisionToAI             =  6573232; //0x644CB0
const int oCAIArrowBase__ReportCollisionToAI_PFXon1  =  6570348; //0x64416C
const int oCAIArrowBase__ReportCollisionToAI_PFXon2  =  6570420; //0x6441B4
const int oCAIArrowBase__ReportCollisionToAI_collNpc =  6570758; //0x644306
const int oCAIArrow__ReportCollisionToAI_destroyPrj  =  0;                                 // Does not exist in Gothic 2
const int oCAIArrow__ReportCollisionToAI_keepPlyStrp =  0;                                 // Does not exist in Gothic 2
const int oCAIArrow__CanThisCollideWith_skipCheck    =  6573079; //0x644C17
const int oCAIArrow__CanThisCollideWith_npcShooter   =  6573098; //0x644C2A
const int oCAIArrow__SetupAIVob_velocity1            =  0;                                 // Not used for Gothic 2
const int oCAIArrow__SetupAIVob_velocity2            =  0;                                 // Not used for Gothic 2
const int oCAIHuman__MagicMode_g2ctrlCheck           =  4660996; //0x471F04
const int oCAIHuman__BowMode_g2ctrlCheck             =  6527099; //0x63987B
const int oCAIHuman__BowMode_shootingKey             =  6527732; //0x639AF4
const int oCAIHuman__MagicMode_turnToTarget          =  0;                                 // Does not exist in Gothic 2
const int oCAIHuman__PC_ActionMove_aimingKey         =  6543467; //0x63D86B
const int oCAIHuman__PC_Turnings                     =  6545648; //0x63E0F0
const int zCCollObjectLevelPolys__s_oCollObjClass    =  9215184; //0x8C9CD0

const int oCGame__HandleEvent_openInvCheck           =  6941684; //0x69EBF4 // Hook len 5
const int cGameManager__ApplySomeSettings_rtn        =  4361956; //0x428EE4 // Hook len 6
const int cGameManager__HandleEvent_clearKeyBuffer   =  4370000; //0x42AE50 // Hook len 6
const int zCModel__CalcModelBBox3DWorld_rtn          =  5717992; //0x573FE8 // Hook len 6
const int zCModel__TraceRay_positiveNodeHit          =  5758028; //0x57DC4C // Hook len 7
const int zCAIPlayer__IsSliding_true                 =  5285645; //0x50A70D // Hook len 5
const int oCAniCtrl_Human__SearchStandAni_walkmode   =  6588203; //0x64872B // Hook len 7
const int oCAIVobMove__DoAI_stopMovement             =  6566468; //0x643244 // Hook len 7
const int oCAIHuman__PC_CheckSpecialStates_lie       =  6541728; //0x63D1A0 // Hook len 5
const int oCAIHuman__PC_ActionMove_bodyState         =  6543155; //0x63D733 // Hook len 6
const int oCAIHuman__BowMode_aimCondition            =  6527998; //0x639BFE // Hook len 5
const int oCAIHuman__BowMode_interpolateAim          =  6527640; //0x639A98 // Hook len 5
const int oCAIHuman__BowMode_notAiming               =  6527773; //0x639B1D // Hook len 6
const int oCAIHuman__BowMode_rtn                     =  6529134; //0x63A06E // Hook len 7
const int oCAIHuman__MagicMode                       =  4660912; //0x471EB0 // Hook len 7
const int oCAIHuman__MagicMode_rtn                   =  4661943; //0x4722B7 // Hook len 7
const int oCAIArrow__SetupAIVob                      =  6572160; //0x644880 // Hook len 6
const int oCAIArrow__CanThisCollideWith_positive     =  6573204; //0x644C94 // Hook len 7 (caution: len 6 in Gothic 1)
const int oCAIArrow__DoAI_rtn                        =  6573065; //0x644C09 // Hook len 6
const int oCAIArrow__ReportCollisionToAI_collAll     =  6570339; //0x644163 // Hook len 8
const int oCAIArrow__ReportCollisionToAI_hitChc      =  6574474; //0x64518A // Hook len 6
const int oCAIArrow__ReportCollisionToAI_damage      =  6574703; //0x64526F // Hook len 5
const int oCAIArrowBase__DoAI_setLifeTime            =  6570116; //0x644084 // Hook len 7
const int oCAIArrowBase__ReportCollisionToAI_hitNpc  =  6570856; //0x644368 // Hook len 5
const int oCAIArrowBase__ReportCollisionToAI_hitVob  =  6570953; //0x6443C9 // Hook len 5
const int oCAIArrowBase__ReportCollisionToAI_hitWld  =  6570484; //0x6441F4 // Hook len 5
const int oCAIArrowBase__ReportCollisionToAI_collVob =  6570464; //0x6441E0 // Hook len 5
const int oCAIArrowBase__ReportCollisionToAI_collWld =  6570936; //0x6443B8 // Hook len 5
const int oCNpc__OnDamage_Hit_criticalHit            =  7856567; //0x77E1B7 // Hook len 5  // Not used for Gothic 2
const int oCNpc__OnDamage_Anim_stumbleAniName        =  7927023; //0x78F4EF // Hook len 5  // Not used for Gothic 2
const int oCNpc__OnDamage_Anim_gotHitAniName         =  7927164; //0x78F57C // Hook len 5
const int oCNpc__SetWeaponMode_player                =  7189041; //0x6DB231 // Hook len 6
const int oCNpc__SetWeaponMode2_walkmode             =  7187232; //0x6DAB20 // Hook len 6
const int oCNpc__EV_AttackRun_playerTurn             =  7285621; //0x6F2B75 // Hook len 7
const int oCNpc__EV_Strafe_commonOffset              =  7973112; //0x79A8F8 // Hook len 5
const int oCNpc__EV_Strafe_g2ctrl                    =  7974361; //0x79ADD9 // Hook len 6
const int oCNpc__Interrupt_stopAnis                  =  7173349; //0x6D74E5 // Hook len 5
const int oCSpell__Setup_initFallbackNone            =  4732233; //0x483549 // Hook len 6
const int oCVisualFX__ProcessCollision_checkTarget   =  4800442; //0x493FBA // Hook len 6
const int mouseUpdate                                =  5053243; //0x4D1B3B // Hook len 5


/*
 * Class offsets (Gothic 2 Classic)
 */
const int zCClassDef_baseClassDef_offset             = 60;  //0x003C

const int zCVob_bbox3D_offset                        = 124; //0x007C
const int zCVob_trafoObjToWorld_offset               = 60;  //0x003C

const int oCNpc_hitChance_offset                     = 472; //0x01D8

const int oSDamageDescriptor_origin_offset           = 8;   //0x0008                       // Not used for Gothic 2

const int oCItem_effect_offset                       = 0;                                  // Does not exist in Gothic 2

const int oCSpell_spellCasterNpc_offset              = 52;  //0x0034
const int oCSpell_manaInvested_offset                = 72;  //0x0048
const int oCSpell_C_Spell_offset                     = 128; //0x0080

const int oCVisualFX_originVob_offset                = 1192;//0x04A8
const int oCVisualFX_targetVob_offset                = 1200;//0x04B0
const int oCVisualFX_instanceName_offset             = 1220;//0x04C4

const int zCAICamera_elevation_offset                = 56;  //0x0038

const int zCAIPlayer_bitfield1_forceModelHalt        = 1<<0;

const int oCAniCtrl_Human_npc_offset                 = 300; //0x012C
const int oCAniCtrl_Human_walkmode_offset            = 352; //0x0160
const int oCAniCtrl_Human_t_stand_2_cast_offset      = 4572;//0x11DC
const int oCAniCtrl_Human_s_cast_offset              = 4576;//0x11E0
const int oCAniCtrl_Human_t_cast_2_shoot_offset      = 4580;//0x11E4
const int oCAniCtrl_Human_s_shoot_offset             = 4588;//0x11EC
const int oCAniCtrl_Human_t_shoot_2_stand_offset     = 4592;//0x11F0

const int oCAIHuman_bitfield_offset                  = 4612;//0x1204
const int oCAIHuman_bitfield_startObserveIntruder    = 1<<5;
const int oCAIHuman_bitfield_dontKnowAniPlayed       = 1<<6;
const int oCAIHuman_bitfield_spellReleased           = 1<<7;

const int oCAIArrowBase_ignoreVobList_offset         = 48;  //0x0030
const int oCAIArrowBase_lifeTime_offset              = 56;  //0x0038
const int oCAIArrowBase_hostVob_offset               = 60;  //0x003C
const int oCAIArrowBase_creatingImpactFX_offset      = 64;  //0x0040
const int oCAIArrowBase_hasHit_offset                = 84;  //0x0054
const int oCAIArrow_origin_offset                    = 92;  //0x005C
const int oCAIArrow_destroyProjectile_offset         = 96;  //0x0060
const int oCAIArrow_target_offset                    = 100; //0x0064

const int zCRigidBody_mass_offset                    = 0;   //0x0000
const int zCRigidBody_xPos_offset                    = 80;  //0x0050
const int zCRigidBody_gravity_offset                 = 236; //0x00EC
const int zCRigidBody_velocity_offset                = 188; //0x00BC
const int zCRigidBody_bitfield_offset                = 256; //0x0100
const int zCRigidBody_bitfield_gravityActive         = 1<<0;

const int zCModel_numActAnis_offset                  = 52;  //0x0034
const int zCModel_actAniList_offset                  = 56;  //0x0037
const int zCModel_hostVob_offset                     = 96;  //0x0060
const int zCModel_prototypes_offset                  = 100; //0x0064
const int zCModel_modelNodeInstArray_offset          = 112; //0x0070
const int zCModel_meshSoftSkinList_offset            = 124; //0x007C
const int zCModel_meshSoftSkinList_numInArray_offset = 132; //0x0084
const int zCModel_masterFrameCtr_offset              = 200; //0x00C8
const int zCModel_bbox3d_offset                      = 216; //0x00D8

const int zCModelAni_aniID_offset                    = 76;  //0x004C

const int zCModelNodeInst_protoNode_offset           = 4;   //0x0004
const int zCModelNodeInst_visual_offset              = 8;   //0x0008
const int zCModelNodeInst_trafoObjToCam_offset       = 76;  //0x004C
const int zCModelNodeInst_bbox3D_offset              = 140; //0x008C

const int zCModelNode_nodeName_offset                = 4;   //0x0004

const int zCMeshSoftSkin_nodeIndexList_offset        = 216; //0x00D8
const int zCMeshSoftSkin_nodeObbList_offset          = 228; //0x00E4

const int zCVisual_materials_offset                  = 164; //0x00A4
const int zCVisual_numMaterials_offset               = 168; //0x00A8

const int zCPolygon_material_offset                  = 24;  //0x0018

const int zCMaterial_texture_offset                  = 52; //0x0034
const int zCMaterial_matGroup_offset                 = 64; //0x0040

const int zCCollisionReport_pos_offset               = 8;   //0x0008
const int zCCollisionReport_thisCollObj_offset       = 44;  //0x002C
const int zCCollisionReport_hitCollObj_offset        = 48;  //0x0030

const int zCCollisionObject_parent_offset            = 132; //0x0084
const int zCCollObjectLevelPolys_polyList_offset     = 140; //0x008C

const int zTraceRay_vob_ignore_no_cd_dyn             = 1<<0;  // Ignore vobs without collision
const int zTraceRay_vob_bbox                         = 1<<2;  // Intersect bounding boxes (important to detect NPCs)
const int zTraceRay_poly_normal                      = 1<<7;  // Report normal vector of intersection
const int zTraceRay_poly_ignore_transp               = 1<<8;  // Ignore alpha polys (without this, trace ray is bugged)
const int zTraceRay_poly_test_water                  = 1<<9;  // Intersect water
const int zTraceRay_vob_ignore_projectiles           = 1<<14; // Ignore projectiles

const int zTTraceRayReport_foundIntersection_offset  = 12;  //0x000C

const int sizeof_zVEC3                               = 12;  //0x000C
const int sizeof_zTBBox3D                            = 24;  //0x0018
const int sizeof_zCOBBox3D                           = 68;  //0x0044
const int sizeof_zTTraceRayReport                    = 40;  //0x0028
const int sizeof_zCCollisionReport                   = 52;  //0x0034
const int sizeof_zMAT4                               = 64;  //0x0040
const int sizeof_zCSubMesh                           = 88;  //0x0058

const int oCNpcFocus__num                            = 6;   // Number of different focus modes
const int GFA_ITEM_NFOCUS                            = 1<<23; // Ensure it's defined (value differs across versions

// Trafo matrix as zMAT4 is divided column wise
const int zMAT4_rightVec                             = 0; // Right vector
const int zMAT4_upVec                                = 1; // Up vector
const int zMAT4_outVec                               = 2; // Out vector/at vector (facing direction)
const int zMAT4_position                             = 3; // Position vector
