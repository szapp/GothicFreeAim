/*
 * This file is part of the configurations for reticles (see config\reticle.d).
 */


/*
 * This is a list of available reticle textures by default. Feel free to extend this list with your own textures. Some
 * of them are animated as indicated. Animated textures can be passed to the following functions:
 *  reticle.texture = GFA_AnimateReticleByTime(textureFileName, framesPerSecond, numberOfFrames)
 *  reticle.texture = GFA_AnimateReticleByPercent(textureFileName, 100, numberOfFrames) // Where 100 is a percentage
 */
const string RETICLE_DOT           = "RETICLEDOT.TGA";
const string RETICLE_CROSSTWO      = "RETICLECROSSTWO.TGA";
const string RETICLE_CROSSTHREE    = "RETICLECROSSTHREE.TGA";
const string RETICLE_CROSSFOUR     = "RETICLECROSSFOUR.TGA";
const string RETICLE_X             = "RETICLEX.TGA";
const string RETICLE_CIRCLE        = "RETICLECIRCLE.TGA";
const string RETICLE_CIRCLECROSS   = "RETICLECIRCLECROSS.TGA";
const string RETICLE_DOUBLECIRCLE  = "RETICLEDOUBLECIRCLE.TGA";       // Can be animated (rotation)  10 Frames [00..09]
const string RETICLE_PEAK          = "RETICLEPEAK.TGA";               // Can be animated (expanding) 17 Frames [00..16]
const string RETICLE_NOTCH         = "RETICLENOTCH.TGA";              // Can be animated (expanding) 17 Frames [00..16]
const string RETICLE_TRI_IN        = "RETICLETRIIN.TGA";              // Can be animated (expanding) 17 Frames [00..16]
const string RETICLE_TRI_IN_DOT    = "RETICLETRIINDOT.TGA";           // Can be animated (expanding) 17 Frames [00..16]
const string RETICLE_TRI_OUT_DOT   = "RETICLETRIOUTDOT.TGA";          // Can be animated (expanding) 17 Frames [00..16]
const string RETICLE_DROP          = "RETICLEDROP.TGA";               // Can be animated (expanding)  8 Frames [00..07]
const string RETICLE_FRAME         = "RETICLEFRAME.TGA";
const string RETICLE_EDGES         = "RETICLEEDGES.TGA";
const string RETICLE_BOWL          = "RETICLEBOWL.TGA";
const string RETICLE_HORNS         = "RETICLEHORNS.TGA";
const string RETICLE_BOLTS         = "RETICLEBOLTS.TGA";
const string RETICLE_BLAZE         = "RETICLEBLAZE.TGA";              // Can be animated (flames)    10 Frames [00..09]
const string RETICLE_WHIRL         = "RETICLEWHIRL.TGA";              // Can be animated (rotation)  10 Frames [00..09]
const string RETICLE_BRUSH         = "RETICLEBRUSH.TGA";
const string RETICLE_SPADES        = "RETICLESPADES.TGA";
const string RETICLE_SQUIGGLE      = "RETICLESQUIGGLE.TGA";
