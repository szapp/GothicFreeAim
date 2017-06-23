/*
 * Definition of all console commands
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


/*
 * Console function to enable/disable weak spot debug output. This function is registered as console command.
 * When enabled, the trajectory of the projectile and the defined weak spot of the last shot NPC is visualized with
 * bounding boxes and lines.
 */
func string freeAimDebugWeakspot(var string command) {
    FREEAIM_DEBUG_WEAKSPOT = !FREEAIM_DEBUG_WEAKSPOT;
    if (FREEAIM_DEBUG_WEAKSPOT) {
        return "Debug weak spot on.";
    } else {
        return "Debug weak spot off.";
    };
};


/*
 * Console function to enable/disable trace ray debug output. This function is registered as console command.
 * When enabled, the trace ray is continuously drawn, as well as the intersection of it.
 */
func string freeAimDebugTraceRay(var string command) {
    FREEAIM_DEBUG_TRACERAY = !FREEAIM_DEBUG_TRACERAY;
    if (FREEAIM_DEBUG_TRACERAY) {
        return "Debug trace ray on.";
    } else {
        return "Debug trace ray off.";
    };
};


/*
 * Console function to show freeAim version. This function is registered as console command.
 * When entered in the console, the current g2freeAim version is displayed as the console output.
 */
func string freeAimVersion(var string command) {
    return FREEAIM_VERSION;
};


/*
 * Console function to show freeAim license. This function is registered as console command.
 * When entered in the console, the g2freeAim license information is displayed as the console output.
 */
func string freeAimLicense(var string command) {
    var int s; s = SB_New();
    SB(FREEAIM_VERSION); SB(", Copyright "); SBc(169 /* (C) */); SB(" 2016  mud-freak (@szapp)"); SBc(13); SBc(10);
    SB("<http://github.com/szapp/g2freeAim>"); SBc(13); SBc(10);
    SB("Released under the MIT License."); SBc(13); SBc(10);
    SB("For more details see <http://opensource.org/licenses/MIT>."); SBc(13); SBc(10);
    var string ret; ret = SB_ToString();
    SB_Destroy();

    return ret;
};


/*
 * Console function to show freeAim info. This function is registered as console command.
 * When entered in the console, the g2freeAim config is displayed as the console output.
 */
func string freeAimInfo(var string command) {
    const string onOff[2] = {"off", "on"};

    var int s; s = SB_New();
    SB(FREEAIM_VERSION); SBc(13); SBc(10);
    SB("Enabled: "); SB(MEM_ReadStatStringArr(onOff, STR_ToInt(MEM_GetGothOpt("FREEAIM", "enabled")))); SBc(13);SBc(10);
    SB("Focus: "); SB(MEM_ReadStatStringArr(onOff, FREEAIM_FOCUS_COLLECTION));
    SB(" ("); SBi(freeAimRayInterval); SB(" ms collection frequency)"); SBc(13); SBc(10);
    SB("Reuse projectiles: "); SB(MEM_ReadStatStringArr(onOff, FREEAIM_REUSE_PROJECTILES)); SBc(13); SBc(10);
    SB("Free aim for spells: "); SB(MEM_ReadStatStringArr(onOff, !FREEAIM_DISABLE_SPELLS)); SBc(13); SBc(10);
    var string ret; ret = SB_ToString();
    SB_Destroy();

    return ret;
};
