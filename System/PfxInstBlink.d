///                                                                   XXXXXXXXXXXXXXXXX
///                                                                   XX  B L I N K  XX
///                                                                   XXXXXXXXXXXXXXXXX

INSTANCE MFX_BLINK_INIT (C_PARTICLEFX)
{
     ppsvalue = 350.0;
     ppsscalekeys_s = "1";
     ppsislooping = 1;
     ppsissmooth = 1;
     ppsfps = 5.0;
     shptype_s = "SPHERE";
     shpdim_s = "8";
     shpfor_s = "WORLD";
     shpoffsetvec_s = "0 5 0";
     shpscalekeys_s = "1";
     shpisvolume = 1;
     dirmode_s = "NONE";
     dirfor_s = "OBJECT";
     velavg = 0.08;
     lsppartavg = 400.0;
     lsppartvar = 0;
     visname_s = "MFX_MASTEROFDISASTER_AURA_16BIT.TGA";
     visorientation_s = "NONE";
     vistexisquadpoly = 1;
     vistexcolorstart_s = "250 180 150";
     vistexcolorend_s = "40 100 250";
     vissizestart_s = "6 6";
     vissizeendscale = 2.0;
     visalphafunc_s = "ADD";
     visalphastart = 255.0;
     visalphaend = 10.0;
     useemittersfor = 1;
};

INSTANCE MFX_BLINK_DEST (C_PARTICLEFX)
{
     ppsvalue = 400.0;
     ppsscalekeys_s = "1.0";
     ppsislooping = 1;
     ppsfps = 1;
     shptype_s = "CIRCLE";
     shpfor_s = "object";
     shpoffsetvec_s = "0 0 0";
     shpdistribtype_s = "RAND";
     shpisvolume = 0;
     shpdim_s = "75";
     dirmode_s = "DIR";
     dirfor_s = "object";
     velavg = 0.001;
     lsppartavg = 450.0;
     flygravity_s = "0 0.0001 0";
     visname_s = "MFX_LIGHT_SINGLERAY.TGA";
     visorientation_s = "NONE";
     vistexisquadpoly = 1;
     vistexcolorstart_s = "250 180 150";
     vistexcolorend_s = "40 100 250";
     vissizestart_s = "3 20";
     vissizeendscale = 6.0;
     visalphafunc_s = "ADD";
     visalphastart = 255.0;
     visalphaend = 0.0;
     useemittersfor = 1;
};

INSTANCE MFX_BLINK_CAST (C_PARTICLEFX)
{
     ppsvalue = 1000.0;
     ppsscalekeys_s = "1.0";
     ppsislooping = 0;
     ppsfps = 2;
     shptype_s = "CIRCLE";
     shpfor_s = "WORLD";
     shpoffsetvec_s = "0 -100 0";
     shpdistribtype_s = "RAND";
     shpisvolume = 0;
     shpdim_s = "75";
     dirmode_s = "NONE";
     dirfor_s = "OBJECT";
     velavg = 0.00000001;
     lsppartavg = 650.0;
     flygravity_s = "0 0.0008 0";
     visname_s = "MFX_MASTEROFDISASTER_AURA_16BIT.TGA";
     visorientation_s = "NONE";
     vistexisquadpoly = 1;
     vistexcolorstart_s = "250 180 150";
     vistexcolorend_s = "40 100 250";
     vissizestart_s = "15 15";
     vissizeendscale = 1.5;
     visalphafunc_s = "ADD";
     visalphastart = 255.0;
     visalphaend = 50.0;
     useemittersfor = 0;
};
