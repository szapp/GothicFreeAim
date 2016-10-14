/*
 * Free aim menu options
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
 *
 *
 * Add these entries to the Menu_Opt_Game.d and adjust the indices:
 *  items[15] = "MENUITEM_OPT_FREEAIM";
 *  items[16] = "MENUITEM_OPT_FREEAIM_CHOICE";
 * Also in Menu_Opt_Game.d in MENUITEM_GAME_BACK change this:
 *  posy = MENU_BACK_Y+300;
 *
 * Adjust the item id (MENU_ID_FREEAIM) below if you added other options and change the labels if needed
 */

const int    MENU_ID_FREEAIM      = 7; // Next available Y-spot in the menu
const string MENU_FREEAIM_LABEL   = "Freies Zielen"; // "Free aiming"
const string MENU_FREEAIM_CHOICES = "aus|an"; // "off|on"
const string MENU_FREEAIM_DESCR   = "Erfordert Gothic 1 controls"; // "Requires Gothic 1 controls"

INSTANCE MENUITEM_OPT_FREEAIM(C_MENU_ITEM_DEF) {
    backpic         = MENU_ITEM_BACK_PIC;
    text[0]         = MENU_FREEAIM_LABEL;
    text[1]         = MENU_FREEAIM_DESCR;
    posx            = 1000;                  posy = MENU_START_Y + MENU_SOUND_DY*MENU_ID_FREEAIM;
    dimx            = 3000;                  dimy = 750;
    onSelAction[0]  = SEL_ACTION_UNDEF;
    flags           = flags | IT_EFFECTS_NEXT;
};

instance MENUITEM_OPT_FREEAIM_CHOICE(C_MENU_ITEM_DEF) {
    backPic               = MENU_CHOICE_BACK_PIC;
    type                  = MENU_ITEM_CHOICEBOX;
    text[0]               = MENU_FREEAIM_CHOICES;
    fontName              = MENU_FONT_SMALL;
    posx                  = 5000;            posy = MENU_START_Y + MENU_SOUND_DY*MENU_ID_FREEAIM + MENU_CHOICE_YPLUS;
    dimx                  = MENU_SLIDER_DX;  dimy = MENU_CHOICE_DY;
    onChgSetOption        = "enabled";
    onChgSetOptionSection = "FREEAIM";
    flags                 = flags & ~IT_SELECTABLE;
    flags                 = flags  | IT_TXT_CENTER;
};
