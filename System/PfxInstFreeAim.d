/*
 * Free aim projectile trail strip for increase visibility
 */

INSTANCE freeAim_trail (C_PARTICLEFX)
{
     ppsvalue = 100.000000000;
     ppsislooping = 1;
     ppsscalekeys_s = "1";
     shptype_s = "POINT";
     shpfor_s = "object";
     shpoffsetvec_s = "0 0 0";
     dirmode_s = "DIR";
     dirfor_s = "object";
     dirmodetargetfor_s = "OBJECT";
     dirmodetargetpos_s = "0 0 0";
     diranglehead = 270.0;
     dirangleheadvar = 0.000000000;
     dirangleelevvar = 0.000000000;
     velavg = 0.0000001;
     lsppartavg = 300.000000000;
     lsppartvar = 0.0000001;
     flygravity_s = "0 0 0";
     visname_s = "SMK_16BIT_A0.TGA";
     visorientation_s = "NONE";
     vistexisquadpoly = 1;
     vistexaniislooping = 0;
     vistexcolorstart_s = "255 255 255";
     vistexcolorend_s = "255 255 255";
     vissizestart_s = "2 2";
     vissizeendscale = 1;
     visalphafunc_s = "BLEND";
     visalphastart = 255.;
     visalphastart = 200.;
     trlfadespeed = 0.5;
     trltexture_s = "SMK_16BIT_A0.TGA";
     trlwidth = 3;
     useemittersfor = 1;
};
