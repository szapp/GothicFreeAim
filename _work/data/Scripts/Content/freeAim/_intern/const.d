/*
 * Constants
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


/* Free aim internal constants, do not modify! Change the settings in freeAim\config\settings.d */
const string FREEAIM_VERSION            = "G2 Free Aim v0.1.2"; // Do not change under any circumstances
const int    FREEAIM_DRAWTIME_READY     = 650;                  // Time offset for readying the bow. Fixed by animation
const int    FREEAIM_DRAWTIME_RELOAD    = 1110;                 // Time offset for reloading the bow. Fixed by animation
const int    FREEAIM_RETICLE_MIN_SIZE   = 32;                   // Smallest reticle size in pixels
const int    FREEAIM_RETICLE_MAX_SIZE   = 64;                   // Biggest reticle size in pixels
const string FREEAIM_TRAIL_FX           = "freeAim_TRAIL";      // Trailstrip FX. Should not be changed
const string FREEAIM_BREAK_FX           = "freeAim_DESTROY";    // FX of projectile breaking on impact with world
const int    FREEAIM_MAX_DIST           = 5000;                 // 50m. Shooting/reticle adjustments. Do not change
const int    FREEAIM_ACTIVE             = 0;                    // Internal. Do not change
const int    FREEAIM_FOCUS_COLLECTION   = 1;                    // Internal. Do not change (change in ini-file)
const int    FLOAT1C                    = 1120403456;           // 100 as float
const int    FLOAT3C                    = 1133903872;           // 300 as float
const int    FLOAT1K                    = 1148846080;           // 1000 as float
var   int    freeAimLastAccuracy;                               // Accuracy of the previous shot for hit chance
var   int    freeAimRayInterval;                                // Perform trace ray every x ms (change in ini-file)
var   int    freeAimDebugWSBBox[6];                             // Weaksopt boundingbox for debug visualization
var   int    freeAimDebugWSTrj[6];                              // Projectile trajectory for debug visualization
var   int    freeAimDebugTRBBox[6];                             // Trace ray intersection for debug visualization
var   int    freeAimDebugTRTrj[6];                              // Trace ray trajectory for debug visualization
var   int    freeAimDebugTRPrevVob;                             // Trace ray detected vob bbox pointer for debugging
var   int    freeAimReticleHndl;                                // Holds the handle of the reticle
var   int    freeAimBowDrawOnset;                               // Time onset of drawing the bow


/* All addresses used (gothic2). In case of a gothic1 port: There are a lot of hardcoded address offsets in the code! */
const int zCVob__SetPositionWorld                 = 6404976; //0x61BB70
const int zCVob__GetRigidBody                     = 6285664; //0x5FE960
const int zCVob__TraceRay                         = 6291008; //0x5FFE40
const int zCVob__SetAI                            = 6285552; //0x5FE8F0
const int zCArray_zCVob__IsInList                 = 7159168; //0x6D3D80
const int zCWorld__TraceRayNearestHit_Vob         = 6430624; //0x621FA0
const int oCWorld__AddVobAsChild                  = 7863856; //0x77FE30
const int zCMaterial__vtbl                        = 8593940; //0x832214
const int zCTrigger_vtbl                          = 8627196; //0x83A3FC
const int zCTriggerScript_vtbl                    = 8582148; //0x82F404
const int zString_CamModRanged                    = 9234704; //0x8CE910
const int zString_CamModMagic                     = 9235048; //0x8CEA68
const int oCAniCtrl_Human__Turn                   = 7005504; //0x6AE540
const int oCAniCtrl_Human__GetLayerAni            = 7011712; //0x6AFD80
const int oCNpc__TurnToEnemy_737D75               = 7568757; //0x737D75
const int oCNpc__GetAngles                        = 6820528; //0x6812B0
const int oCNpc__SetFocusVob                      = 7547744; //0x732B60
const int oCNpc__SetEnemy                         = 7556032; //0x734BC0
const int oCNpc__GetModel                         = 7571232; //0x738720
const int oCNpcFocus__InitFocusModes              = 7072384; //0x6BEA80
const int oCItem___CreateNewInstance              = 7423040; //0x714440
const int oCItem__InitByScript                    = 7412688; //0x711BD0
const int oCItem__InsertEffect                    = 7416896; //0x712C40
const int oCItem__RemoveEffect                    = 7416832; //0x712C00
const int oCMag_Book__GetSelectedSpell            = 4683648; //0x477780
const int zCModel__SearchNode                     = 5758960; //0x57DFF0
const int zCModel__GetBBox3DNodeWorld             = 5738736; //0x5790F0
const int zCModel__GetNodePositionWorld           = 5738816; //0x579140
const int zTBBox3D__Draw                          = 5529312; //0x545EE0
const int zCLineCache__Line3D                     = 5289040; //0x50B450
const int zlineCache                              = 9257720; //0x8D42F8
const int oCGame__s_bUseOldControls               = 9118144; //0x8B21C0
const int mouseEnabled                            = 9248108; //0x8D1D6C
const int mouseSensX                              = 9019720; //0x89A148
const int mouseDeltaX                             = 9246300; //0x8D165C
const int projectileDeflectOffNpcAddr             = 6949734; //0x6A0B66
const int oCAIVobMove__CreateNewInstance          = 6959968; //0x6A3360
const int oCAIHuman__BowMode_695F2B               = 6905643; //0x695F2B
const int oCAIHuman__BowMode_6962F2               = 6906610; //0x6962F2
const int oCAIHuman__PC_ActionMove_69A0BB         = 6922427; //0x69A0BB
const int zCWorld__AdvanceClock                   = 6447328; //0x6260E0 // Hook length 10
const int oCAIHuman__BowMode                      = 6905600; //0x695F00 // Hook length 6
const int oCAIHuman__BowMode_696296               = 6906518; //0x696296 // Hook length 5
const int oCAIHuman__BowMode_69633B               = 6906683; //0x69633B // Hook length 6
const int oCAIArrow__SetupAIVob                   = 6951136; //0x6A10E0 // Hook length 6
const int oCAIArrow__CanThisCollideWith           = 6952080; //0x6A1490 // Hook length 7
const int oCAIArrow__DoAI_6A1489                  = 6952073; //0x6A1489 // Hook length 6
const int oCAIArrowBase__DoAI_6A06D8              = 6948568; //0x6A06D8 // Hook length 6
const int onArrowHitNpcAddr                       = 6949832; //0x6A0BC8 // Hook length 5
const int onArrowHitVobAddr                       = 6949929; //0x6A0C29 // Hook length 5
const int onArrowHitStatAddr                      = 6949460; //0x6A0A54 // Hook length 5
const int onArrowCollVobAddr                      = 6949440; //0x6A0C18 // Hook length 5
const int onArrowCollStatAddr                     = 6949912; //0x6A0A40 // Hook length 5
const int onArrowHitChanceAddr                    = 6953483; //0x6A1A0B // Hook length 5
const int onArrowDamageAddr                       = 6953621; //0x6A1A95 // Hook length 7
const int onDmgAnimationAddr                      = 6774593; //0x675F41 // Hook length 9
const int oCNpcFocus__SetFocusMode                = 7072800; //0x6BEC20 // Hook length 7
const int oCAIHuman__MagicMode                    = 4665296; //0x472FD0 // Hook length 7
const int oCSpell__Setup_484BA9                   = 4737961; //0x484BA9 // Hook length 6
const int mouseUpdate                             = 5062907; //0x4D40FB // Hook length 5


/* Offsets */
const int zCVob_bbox3D_offset                     = 124; //0x007C

const int oCSpell_spellCasterNpc_offset           = 52;  //0x0034
const int oCSpell_C_Spell_offset                  = 128; //0x0080

const int oCAIArrowBase_collision_offset          = 52;  //0x0034
const int oCAIArrowBase_lifeTime_offset           = 56;  //0x0038
const int oCAIArrowBase_hostVob_offset            = 60;  //0x003C
const int oCAIArrow_origin_offset                 = 92;  //0x005C

const int zCRigidBody_mass_offset                 = 0;   //0x0000
const int zCRigidBody_gravity_offset              = 236; //0x00EC
const int zCRigidBody_velocity_offset             = 188; //0x00BC
const int zCRigidBody_bitfield_offset             = 256; //0x0100
const int zCRigidBody_bitfield_gravityActive      = 1 << 0; // First bit

const int zCModelNodeInst_visual_offset           = 8;   //0x0008

const int sizeof_zVEC3                            = 12;  //0x000C
const int sizeof_zTBBox3D                         = 24;  //0x0018

// Trafo matrix as zMAT4 is divided column wise
const int zMAT4_rightVec                          = 0; // Right vector
const int zMAT4_upVec                             = 1; // Up vector
const int zMAT4_outVec                            = 2; // Out vector (facing direction)
const int zMAT4_position                          = 3; // Position vector
