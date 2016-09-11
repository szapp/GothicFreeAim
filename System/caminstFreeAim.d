/*
 * Free aim camera mode
 */

INSTANCE CamModRngeFA (CCamSys_Def)
{
    bestRange           = 1.8; // Decrease from 2.5
    minRange            = 1.4;
    maxRange            = 5.0; // Decreased from 10.0
    bestElevation       = 23.0; // Decreased from 35.0
    minElevation        = 0.0;
    maxElevation        = 89.0;
    bestAzimuth         = 0.0;
    minAzimuth          = -90.0;
    maxAzimuth          = 90.0;
    rotOffsetX          = 23.0; // Increased from 20.0
    rotOffsetY          = 0.0;
    targetOffsetY       = 40.0;  // A little up for more visibility
    targetOffsetX       = 15.0;  // A little to the right (make the projectile fly in a straigh line). Most important
};
