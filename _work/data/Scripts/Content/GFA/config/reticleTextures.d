/*
 * This file is part of the configurations for reticles (see config\reticle.d).
 */


/*
 * This is a list of available reticle textures by default. Feel free to extend this list with your own textures. Some
 * of them are animated as indicated. Animated textures can be passed to the following functions:
 *  reticle.texture = GFA_AnimateReticleByTime(textureFileName, framesPerSecond, numberOfFrames)
 *  reticle.texture = GFA_AnimateReticleByPercent(textureFileName, 100, numberOfFrames) // Where 100 is a percentage
 */
const string GFA_RETICLE_DOT           = "GFA_RETICLEDOT.TGA";
const string GFA_RETICLE_CROSSTWO      = "GFA_RETICLECROSSTWO.TGA";
const string GFA_RETICLE_CROSSTHREE    = "GFA_RETICLECROSSTHREE.TGA";
const string GFA_RETICLE_CROSSFOUR     = "GFA_RETICLECROSSFOUR.TGA";
const string GFA_RETICLE_X             = "GFA_RETICLEX.TGA";
const string GFA_RETICLE_CIRCLE        = "GFA_RETICLECIRCLE.TGA";
const string GFA_RETICLE_CIRCLECROSS   = "GFA_RETICLECIRCLECROSS.TGA";
const string GFA_RETICLE_DOUBLECIRCLE  = "GFA_RETICLEDOUBLECIRCLE.TGA";    // Can animate (rotation)  10 Frames [00..09]
const string GFA_RETICLE_PEAK          = "GFA_RETICLEPEAK.TGA";            // Can animate (expanding) 17 Frames [00..16]
const string GFA_RETICLE_NOTCH         = "GFA_RETICLENOTCH.TGA";           // Can animate (expanding) 17 Frames [00..16]
const string GFA_RETICLE_TRI_IN        = "GFA_RETICLETRIIN.TGA";           // Can animate (expanding) 17 Frames [00..16]
const string GFA_RETICLE_TRI_IN_DOT    = "GFA_RETICLETRIINDOT.TGA";        // Can animate (expanding) 17 Frames [00..16]
const string GFA_RETICLE_TRI_OUT_DOT   = "GFA_RETICLETRIOUTDOT.TGA";       // Can animate (expanding) 17 Frames [00..16]
const string GFA_RETICLE_DROP          = "GFA_RETICLEDROP.TGA";            // Can animate (expanding)  8 Frames [00..07]
const string GFA_RETICLE_FRAME         = "GFA_RETICLEFRAME.TGA";
const string GFA_RETICLE_EDGES         = "GFA_RETICLEEDGES.TGA";
const string GFA_RETICLE_BOWL          = "GFA_RETICLEBOWL.TGA";
const string GFA_RETICLE_HORNS         = "GFA_RETICLEHORNS.TGA";
const string GFA_RETICLE_BOLTS         = "GFA_RETICLEBOLTS.TGA";
const string GFA_RETICLE_BLAZE         = "GFA_RETICLEBLAZE.TGA";           // Can animate (flames)    10 Frames [00..09]
const string GFA_RETICLE_WHIRL         = "GFA_RETICLEWHIRL.TGA";           // Can animate (rotation)  10 Frames [00..09]
const string GFA_RETICLE_BRUSH         = "GFA_RETICLEBRUSH.TGA";
const string GFA_RETICLE_SPADES        = "GFA_RETICLESPADES.TGA";
const string GFA_RETICLE_SQUIGGLE      = "GFA_RETICLESQUIGGLE.TGA";
