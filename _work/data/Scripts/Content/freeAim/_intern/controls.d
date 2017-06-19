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


/*
 * Mouse handling for manually turning the player model by mouse input. This function hooks an engine function that
 * records physical(!) mouse movement and is called every frame.
 *
 * Usually when holding the action button down, rotating the player model is prevented. To allow free aiming the has to
 * be disabled. This can be (and was at some point) done by just skipping the condition by which turning is prevented.
 * However, it turned out to be very inaccurate and the movement was too jaggy for aiming. Instead, this function here
 * reads the (unaltered) change in mouse movement along the x-axis and performs the rotation manually the same way the
 * engine does it.
 *
 * To adjust the turn rate (translation between mouse movement and model rotation), modify FREEAIM_ROTATION_SCALE.
 * By this implementation of free aiming, the manual turning of the player model is only necessary when using Gothic 1
 * controls.
 *
 * Since this function is called so frequently and regularly, it also serves to call the function to update the free aim
 * active/enabled state to set the constant FREEAIM_ACTIVE.
 */
func void freeAimManualRotation() {
    // Retrieve free aim state and exit if player is not currently aiming
    freeAimIsActive();
    if (FREEAIM_ACTIVE < FMODE_FAR) {
        return;
    };

    // Gothic 2 controls only need the rotation if currently shooting
    if (!MEM_ReadInt(oCGame__s_bUseOldControls)) {
        // Separate if-conditions to increase performance (Gothic checks ALL chained if-conditions)
        if (!MEM_KeyPressed(MEM_GetKey("keyAction"))) && (!MEM_KeyPressed(MEM_GetSecondaryKey("keyAction"))) {
            return;
        };
    };

    // Retrieve vertical mouse movement (along x-axis) and apply mouse sensitivity
    var int deltaX; deltaX = mulf(mkf(MEM_ReadInt(mouseDeltaX)), MEM_ReadInt(mouseSensX));
    if (deltaX == FLOATNULL) {
        return; // Only rotate if there was movement along x position
    };

    // Apply turn rate
    deltaX = mulf(deltaX, castToIntf(FREEAIM_ROTATION_SCALE));

    // Turn player model
    var oCNpc her; her = Hlp_GetNpc(hero);
    var int hAniCtrl; hAniCtrl = her.anictrl;
    const int call = 0; var int zero;
    if (CALL_Begin(call)) {
        CALL_IntParam(_@(zero)); // 0 = disable turn animation (there is none while aiming anyways)
        CALL_FloatParam(_@(deltaX));
        CALL__thiscall(_@(hAniCtrl), oCAniCtrl_Human__Turn);
        call = CALL_End();
    };
};


/*
 * Disable damage animation while aiming. This function hooks the function that deals damage to NPCs and prevents the
 * damage animation for the player while aiming, as it looks questionable if the reticle stays centered but the player
 * model is crooked.
 * Taken from http://forum.worldofplayers.de/forum/threads/1474431?p=25057480#post25057480
 */
func void freeAimDmgAnimation() {
    var C_Npc victim; victim = _^(ECX);
    if (Npc_IsPlayer(victim)) && (FREEAIM_ACTIVE > 1) {
        EAX = 0; // Disable animation by removing 'this'
    };
};