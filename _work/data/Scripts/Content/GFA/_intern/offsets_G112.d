/*
 * Engine offsets for Gothic Sequel
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
 * All addresses used (Gothic Sequel). Hooked functions indicated by the hook length in the in-line comments
 */
const int zCVob__classDef                            =  9556416; //0x91D1C0
const int zCVob__SetPositionWorld                    =  6352672; //0x60EF20
const int zCVob__GetRigidBody                        =  6236544; //0x5F2980
const int zCVob__TraceRay                            =  6241712; //0x5F3DB0
const int zCVob__SetAI                               =  6236432; //0x5F2910
const int zCVob__SetSleeping                         =  6252704; //0x5F68A0
const int zCVob__RotateWorld                         =  6350800; //0x60E7D0
const int zCRigidBody__SetVelocity                   =  5968416; //0x5B1220
const int zCCollisionReport__vtbl                    =  8481448; //0x816AA8
const int zCWorld__TraceRayNearestHit_Vob            =  6379008; //0x615600
const int oCWorld__AddVobAsChild                     =  7399232; //0x70E740
const int zCWorld__SearchVobListByClass              =  6384896; //0x616D00
const int zCTrigger__vtbl                            =  8515204; //0x81EE84
const int oCTriggerScript__vtbl                      =  8471320; //0x814318
const int zString_CamModRanged                       =  9107792; //0x8AF950
const int zString_CamModMagic                        =  9108208; //0x8AFAF0
const int zString_CamModNormal                       =  9108040; //0x8AFA48
const int zString_CamModMelee                        =  9108112; //0x8AFA90
const int zString_CamModRun                          =  9108136; //0x8AFAA8
const int oCAIHuman__Cam_Normal                      =  9562152; //0x91E828
const int oCAIHuman__Cam_Fight                       =  9562128; //0x91E810
const int oCAIHuman__CheckFocusVob_ranged            =  6522651; //0x63871B
const int oCAIHuman__CheckFocusVob_spells            =  6522657; //0x638721
const int oCAniCtrl_Human__IsStanding                =  6595344; //0x64A310
const int oCAniCtrl_Human__Turn                      =  6596560; //0x64A7D0
const int oCAniCtrl_Human__CanToggleWalkModeTo       =  6586880; //0x648200
const int oCAniCtrl_Human__ToggleWalkMode            =  6593200; //0x649AB0
const int zCAIPlayer__CheckEnoughSpaceMoveDir        =  5328896; //0x515000
const int oCNpc__player                              =  9580852; //0x923134
const int oCNpc__TurnToEnemy_camCheck                =  0;                                 // Does not exist in Gothic 1
const int oCNpc__GetAngles                           =  7919328; //0x78D6E0
const int oCNpc__GetFocusVob                         =  7082800; //0x6C1330
const int oCNpc__SetFocusVob                         =  7082720; //0x6C12E0
const int oCNpc__SetEnemy                            =  7090336; //0x6C30A0
const int oCNpc__SetBodyState                        =  7260848; //0x6ECAB0
const int oCNpc__GetInteractMob                      =  7180848; //0x6D9230
const int oCNpc__EV_Strafe_magicCombat               =  0;                                 // Does not exist in Gothic 1
const int oCNpc__FightAttackMagic                    =  7912576; //0x78BC80                // Not used for Gothic 1
const int oCNpc__Interrupt_stopAnisLayerA            =  7094467; //0x6C40C3
const int oCNpc__RefreshNpc_createAmmoIfNone         =  7146179; //0x6D0AC3
const int oCNpcFocus__InitFocusModes                 =  6663808; //0x65AE80
const int oCNpcFocus__Init                           =  6664672; //0x65B1E0
const int oCNpcFocus__focusnames                     =  9571120; //0x920B30
const int oCNpcFocus__focuslist                      =  9571240; //0x920BA8
const int oCNpcFocus__focus                          =  9571264; //0x920BC0
const int oCItem___CreateNewInstance                 =  6951424; //0x6A1200
const int oCItem__InitByScript                       =  6942592; //0x69EF80
const int oCItem__InsertEffect                       =  0;                                 // Does not exist in Gothic 1
const int oCItem__RemoveEffect                       =  0;                                 // Does not exist in Gothic 1
const int oCItem__MultiSlot                          =  6944912; //0x69F890
const int oCMag_Book__GetSelectedSpell               =  4692496; //0x479A10
const int oCMag_Book__GetSelectedSpellNr             =  4692592; //0x479A70
const int oCMag_Book__GetSpellItem                   =  4702448; //0x47C0F0
const int oCMag_Book__StopSelectedSpell              =  4692928; //0x479BC0
const int oCSpell__Open                              =  4750368; //0x487C20
const int zCProgMeshProto__classDef                  =  9484792; //0x90B9F8
const int zCMaterial__classDef                       =  9147912; //0x8B9608
const int oCVisualFX__classDef                       =  9106488; //0x8AF438
const int oCVisualFX__Stop                           =  4813744; //0x4973B0
const int oCVisualFX__SetTarget                      =  4803104; //0x494A20                // Not used for Gothic 1
const int zCModel__classDef                          =  9148496; //0x8B9850
const int zCModel__TraceRay_softSkinCheck            =  5771391; //0x58107F
const int zCModel__CalcNodeListBBoxWorld             =  5733152; //0x577B20
const int zCModel__StartAni                          =  5740272; //0x5796F0
const int zCModel__FadeOutAnisLayerRange             =  5757664; //0x57DAE0
const int zCModel__StopAnisLayerRange                =  5757744; //0x57DB30                // Not used for Gothic 1
const int zCModelPrototype__SearchAniIndex           =  5803104; //0x588C60
const int zVEC3__NormalizeSafe                       =  4957840; //0x4BA690
const int zTBBox3D__CalcGreaterBBox3D                =  5534096; //0x547190
const int zTBBox3D__TraceRay                         =  5539632; //0x548730
const int zCOBBox3D__Transform                       =  5556320; //0x54C860
const int oCGame__s_bUseOldControls                  =  0;                                 // Does not exist in Gothic 1
const int zCInput_Win32__s_mouseEnabled              =  9121312; //0x8B2E20
const int oCAIArrow__ReportCollisionToAI             =  6539936; //0x63CAA0
const int oCAIArrowBase__ReportCollisionToAI_PFXon1  =  0;                                 // Does not exist in Gothic 1
const int oCAIArrowBase__ReportCollisionToAI_PFXon2  =  0;                                 // Does not exist in Gothic 1
const int oCAIArrowBase__ReportCollisionToAI_collNpc =  0;                                 // Does not exist in Gothic 1
const int oCAIArrow__ReportCollisionToAI_destroyPrj  =  6540672; //0x63CD80
const int oCAIArrow__ReportCollisionToAI_keepPlyStrp =  6539977; //0x63CAC9
const int oCAIArrow__CanThisCollideWith_skipCheck    =  0;                                 // Not used for Gothic 1
const int oCAIArrow__CanThisCollideWith_npcShooter   =  0;                                 // Not used for Gothic 1
const int oCAIArrow__SetupAIVob_velocity1            =  6539644; //0x63C97C
const int oCAIArrow__SetupAIVob_velocity2            =  6539253; //0x63C7F5
const int oCAIHuman__MagicMode_g2ctrlCheck           =  0;                                 // Does not exist in Gothic 1
const int oCAIHuman__BowMode_g2ctrlCheck             =  0;                                 // Does not exist in Gothic 1
const int oCAIHuman__BowMode_shootingKey             =  6501965; //0x63364D                // Not used for Gothic 1
const int oCAIHuman__MagicMode_turnToTarget          =  4675552; //0x4757E0
const int oCAIHuman__PC_ActionMove_aimingKey         =  6516152; //0x636DB8                // Not used for Gothic 1
const int oCAIHuman__PC_Turnings                     =  6518368; //0x637660                // Not used for Gothic 1
const int zCCollObjectLevelPolys__s_oCollObjClass    =  9147032; //0x8B9298

const int oCGame__HandleEvent_openInvCheck           =  6858003; //0x68A513 // Hook len 5
const int cGameManager__ApplySomeSettings_rtn        =  4367503; //0x42A48F // Hook len 6
const int cGameManager__HandleEvent_clearKeyBuffer   =  0;                                 // Does not exist in Gothic 1
const int zCModel__CalcModelBBox3DWorld_rtn          =  5733905; //0x577E11 // Hook len 6
const int zCModel__TraceRay_positiveNodeHit          =  5772937; //0x581689 // Hook len 7
const int zCAIPlayer__IsSliding_true                 =  5311869; //0x510D7D // Hook len 5
const int oCAniCtrl_Human__SearchStandAni_walkmode   =  6554680; //0x640438 // Hook len 7
const int oCAIVobMove__DoAI_stopMovement             =  6533464; //0x63B158 // Hook len 7
const int oCAIHuman__PC_CheckSpecialStates_lie       =  6514496; //0x636740 // Hook len 5
const int oCAIHuman__PC_ActionMove_bodyState         =  0;                                 // Does not exist in Gothic 1
const int oCAIHuman__BowMode_aimCondition            =  6502292; //0x633794 // Hook len 5
const int oCAIHuman__BowMode_interpolateAim          =  6501851; //0x6335DB // Hook len 5
const int oCAIHuman__BowMode_notAiming               =  6502012; //0x63367C // Hook len 6
const int oCAIHuman__BowMode_rtn                     =  6501578; //0x6334CA // Hook len 7
const int oCAIHuman__MagicMode                       =  4675344; //0x475710 // Hook len 7
const int oCAIHuman__MagicMode_rtn                   =  4675925; //0x475955 // Hook len 7
const int oCAIArrow__SetupAIVob                      =  6538784; //0x63C620 // Hook len 6
const int oCAIArrow__CanThisCollideWith_positive     =  6539911; //0x63CA87 // Hook len 6 (caution: len 7 in Gothic 2)
const int oCAIArrow__DoAI_rtn                        =  6539786; //0x63CA0A // Hook len 6
const int oCAIArrow__ReportCollisionToAI_collAll     =  6540054; //0x63CB16 // Hook len 8
const int oCAIArrow__ReportCollisionToAI_hitChc      =  6540387; //0x63CC63 // Hook len 6
const int oCAIArrow__ReportCollisionToAI_damage      =  6540473; //0x63CCB9 // Hook len 5
const int oCAIArrowBase__DoAI_setLifeTime            =  6537448; //0x63C0E8 // Hook len 7
const int oCAIArrowBase__ReportCollisionToAI_hitNpc  =  6540478; //0x63CCBE // Hook len 5
const int oCAIArrowBase__ReportCollisionToAI_hitVob  =  0;                                 // Does not exist in Gothic 1
const int oCAIArrowBase__ReportCollisionToAI_hitWld  =  0;                                 // Does not exist in Gothic 1
const int oCAIArrowBase__ReportCollisionToAI_collVob =  0;                                 // Does not exist in Gothic 1
const int oCAIArrowBase__ReportCollisionToAI_collWld =  0;                                 // Does not exist in Gothic 1
const int oCNpc__OnDamage_Hit_criticalHit            =  7804104; //0x7714C8 // Hook len 5
const int oCNpc__OnDamage_Anim_stumbleAniName        =  7885710; //0x78538E // Hook len 5
const int oCNpc__OnDamage_Anim_gotHitAniName         =  7885898; //0x78544A // Hook len 5
const int oCNpc__SetWeaponMode_player                =  7110897; //0x6C80F1 // Hook len 6
const int oCNpc__SetWeaponMode2_walkmode             =  7108852; //0x6C78F4 // Hook len 6
const int oCNpc__EV_AttackRun_playerTurn             =  0;                                 // Does not exist in Gothic 1
const int oCNpc__EV_Strafe_commonOffset              =  7931603; //0x7906D3 // Hook len 5
const int oCNpc__EV_Strafe_g2ctrl                    =  0;                                 // Does not exist in Gothic 1
const int oCNpc__Interrupt_stopAnis                  =  7094461; //0x6C40BD // Hook len 5
const int oCSpell__Setup_initFallbackNone            =  4747048; //0x486F28 // Hook len 6
const int oCVisualFX__ProcessCollision_checkTarget   =  0;                                 // Does not exist in Gothic 1
const int mouseUpdate                                =  5078742; //0x4D7ED6 // Hook len 5


/*
 * Class offsets (Gothic Sequel)
 */
const int zCClassDef_baseClassDef_offset             = 60;  //0x003C

const int zCVob_bbox3D_offset                        = 124; //0x007C
const int zCVob_trafoObjToWorld_offset               = 60;  //0x003C

const int oCNpc_hitChance_offset                     = 0;                                  // Does not exist in Gothic 1

const int oSDamageDescriptor_origin_offset           = 8;   //0x0008

const int oCItem_effect_offset                       = 0;                                  // Does not exist in Gothic 1

const int oCSpell_spellCasterNpc_offset              = 52;  //0x0034
const int oCSpell_manaInvested_offset                = 72;  //0x0048
const int oCSpell_C_Spell_offset                     = 128; //0x0080

const int oCVisualFX_originVob_offset                = 1112;//0x0458
const int oCVisualFX_targetVob_offset                = 1120;//0x0460
const int oCVisualFX_instanceName_offset             = 1140;//0x0474

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
const int oCAIArrowBase_hasHit_offset                = 0;                                  // Does not exist in Gothic 1
const int oCAIArrow_origin_offset                    = 88;  //0x0058
const int oCAIArrow_destroyProjectile_offset         = 92;  //0x005C
const int oCAIArrow_target_offset                    = 96;  //0x0060

const int zCRigidBody_mass_offset                    = 0;   //0x0000
const int zCRigidBody_xPos_offset                    = 80;  //0x0050
const int zCRigidBody_gravity_offset                 = 236; //0x00EC
const int zCRigidBody_velocity_offset                = 188; //0x00BC
const int zCRigidBody_bitfield_offset                = 256; //0x0100
const int zCRigidBody_bitfield_gravityActive         = 1<<0;

const int zCModel_numActAnis_offset                  = 52;  //0x0034
const int zCModel_actAniList_offset                  = 56;  //0x0037
const int zCModel_hostVob_offset                     = 84;  //0x0054
const int zCModel_prototypes_offset                  = 88;  //0x0058
const int zCModel_modelNodeInstArray_offset          = 100; //0x0064
const int zCModel_meshSoftSkinList_offset            = 112; //0x0070
const int zCModel_meshSoftSkinList_numInArray_offset = 120; //0x0078
const int zCModel_masterFrameCtr_offset              = 188; //0x00BC
const int zCModel_bbox3d_offset                      = 204; //0x00CC

const int zCModelAni_aniID_offset                    = 76;  //0x004C

const int zCModelNodeInst_protoNode_offset           = 4;   //0x0004
const int zCModelNodeInst_visual_offset              = 8;   //0x0008
const int zCModelNodeInst_trafoObjToCam_offset       = 76;  //0x004C
const int zCModelNodeInst_bbox3D_offset              = 140; //0x008C

const int zCModelNode_nodeName_offset                = 4;   //0x0004

const int zCMeshSoftSkin_nodeIndexList_offset        = 212; //0x00D4
const int zCMeshSoftSkin_nodeObbList_offset          = 224; //0x00E0

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
const int GFA_ITEM_NFOCUS                            = 1<<24; // Ensure it's defined (value differs across versions

// Trafo matrix as zMAT4 is divided column wise
const int zMAT4_rightVec                             = 0; // Right vector
const int zMAT4_upVec                                = 1; // Up vector
const int zMAT4_outVec                               = 2; // Out vector/at vector (facing direction)
const int zMAT4_position                             = 3; // Position vector
