/*
 * Input and controls manipulation
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

/* Disable damage animation. Taken from http://forum.worldofplayers.de/forum/threads/1474431?p=25057480#post25057480 */
func void freeAimDmgAnimation() {
    var C_Npc victim; victim = _^(ECX);
    if (Npc_IsPlayer(victim)) && (freeAimIsActive()) { EAX = 0; }; // Disable damage animation while aiming
};
