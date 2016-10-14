﻿/*
 * Free aim projectile trail strip for increase visibility
 *
 * G2 Free Aim - Free aiming for the video game Gothic 2 by Piranha Bytes
 * Copyright (C) 2016  mud-freak (@szapp)
 *
 * This file is part of G2 Free Aim.
 * http://github.com/szapp/g2freeAim
 *
 * G2 Free Aim is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * On redistribution this notice must remain intact and all copies must
 * identify the original author.
 *
 * G2 Free Aim is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with G2 Free Aim.  If not, see <http://www.gnu.org/licenses/>.
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