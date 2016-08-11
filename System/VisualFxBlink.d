///                                                     XXXXXXXXXXXXXXXXX
///                                                     XX  B L I N K  XX
///                                                     XXXXXXXXXXXXXXXXX

INSTANCE spellFX_Blink (CFx_Base_Proto)
{
    visname_S               = "MFX_Blink_INIT";
    emtrjmode_s             = "TARGET";
    emtrjloopmode_s         = "HALT";
    emtrjdynupdatedelay     = 0.; // No update delay
    emtrjeasevel            = 0.; // No velocity (so the FX stays in the hand)
    emFXInvestOrigin_S      = "spellFX_Blink_HAND";
    };
    INSTANCE spellFX_Blink_KEY_INVEST_1 (C_ParticleFXEmitKey) { }; // Do not remove!
    INSTANCE spellFX_Blink_KEY_INVEST_2 (C_ParticleFXEmitKey)
    {
        visName_S           = "MFX_BLINK_DEST"; // Aim FX
        sfxid               = "MFX_Fireball_invest1";
        sfxisambient        = 1;
        emtrjeasevel        = 6000; // There is virtually no drag when aiming
    };
    INSTANCE spellFX_Blink_KEY_CAST (C_ParticleFXEmitKey)
    {
        emCreateFXID        = "spellFX_Blink_CAST";
        pfx_ppsisloopingchg = 1; // Stop invest effect when releasing spell
};

/* A helper instance to keep the effect in the hand while investing (aiming) */
INSTANCE spellFX_Blink_HAND (CFx_Base_Proto) { visname_S = "MFX_Blink_INIT"; };

/* Circle around caster after arriving at new position */
INSTANCE spellFX_Blink_CAST (CFX_Base_Proto)
{
    visname_S               = "MFX_BLINK_CAST";
    emTrjOriginNode         = "BIP01";
    sfxid                   = "MFX_Fireball_invest2";
    sfxisambient            = 1;
    emFXCreate_S            = "spellFX_Blink_SCX"; // Add child FX (remove this line to disable BOTH screen effects)
    emFXCreatedOwnTrj       = 1;
};

/* Screenblend while transitioning */
INSTANCE spellFX_Blink_SCX (CFx_Base_Proto)
{
    visName_S               = "screenblend.scx";
    userString[0]           = "1";
    userString[1]           = "0 0 0 150"; // Alpha set to 150 to make it less striking. Change it to 255 for max effect
    userString[2]           = "0.1";
    userString[3]           = "BLINK_BLEND.TGA";
    visAlphaBlendFunc_S     = "ADD";
    emFXLifeSpan            = 0.23; // Short enough
    emFXCreate_S            = "spellFX_Blink_FOV"; // Add child FX (remove this line to disable screen morph effect)
};

/* A subtle screen morph while/after traversing */
INSTANCE spellFX_Blink_FOV (CFx_Base_Proto)
{
    visName_S               = "morph.fov";
    userString[0]           = "0.75";
    userString[1]           = "0.2";
    userString[2]           = "90";
    userString[3]           = ""; // Only distort along x-dimension
    emFXLifeSpan            = 1; // For safety (life is set by parent)
};
