/*
 * Free aim menu options
 *
 * This file is part of Gothic Free Aim.
 * Copyright (C) 2016-2024  Sören Zapp (aka. mud-freak, szapp)
 * https://github.com/szapp/GothicFreeAim
 *
 * Gothic Free Aim is free software: you can redistribute it and/or
 * modify it under the terms of the MIT License.
 * On redistribution this notice must remain intact and all copies must
 * identify the original author.
 *
 *
 * Instructions
 * ============
 *
 * Add these entries to the Menu_Opt_Game.d and adjust the indices:
 *  items[15] = "MENUITEM_OPT_GFA";
 *  items[16] = "MENUITEM_OPT_GFA_CHOICE";
 * Also in Menu_Opt_Game.d in MENUITEM_GAME_BACK change this:
 *  posy = MENU_BACK_Y+300;
 *
 * Adjust the item id (GFA_MENU_ID) below to the next available item number and change the labels if needed
 */

// Menu text labels
const string GFA_MENU_LABEL           = "Freies Zielen";            // "Free aiming"
const string GFA_MENU_CHOICES         = "aus|an";                   // "off|on"
const string GFA_MENU_DESCR           = "Erfordert Maus Steuerung"; // "Requires mouse controls"

// Positioning and textures
const int    GFA_MENU_ID              = 7;                          // Next available Y-spot in game menu = entry number
const int    GFA_MENU_START_Y         = 2400;                       // Match MENU_START_Y: height of first menu entry
const int    GFA_MENU_DY              = 550;                        // Match MENU_SOUND_DY: space between entries
const int    GFA_MENU_CHC_H           = 120;                        // Match MENU_CHOICE_YPLUS: height of choice entry
const string GFA_MENU_ITEM_BACK_PIC   = "";                         // Match MENU_ITEM_BACK_PIC
const string GFA_MENU_CHOICE_BACK_PIC = "MENU_CHOICE_BACK.TGA";     // Match MENU_CHOICE_BACK_PIC
const string GFA_MENU_FONT_DEFAULT    = "FONT_OLD_20_WHITE.TGA";    // Match MENU_FONT_DEFAULT
const string GFA_MENU_FONT_SMALL      = "FONT_OLD_10_WHITE.TGA";    // Match MENU_FONT_SMALL

// Redefinition of fixed menu constants to ensure their existence (do not change)
const int    GFA_MENU_ITEM_TEXT      = 1;                           // MENU_ITEM_TEXT
const int    GFA_MENU_ITEM_CHOICEBOX = 5;                           // MENU_ITEM_CHOICEBOX
const int    GFA_IT_CHROMAKEYED      = 1;                           // IT_CHROMAKEYED
const int    GFA_IT_TRANSPARENT      = 2;                           // IT_TRANSPARENT
const int    GFA_IT_SELECTABLE       = 4;                           // IT_SELECTABLE
const int    GFA_IT_TXT_CENTER       = 16;                          // IT_TXT_CENTER
const int    GFA_IT_EFFECTS_NEXT     = 128;                         // IT_EFFECTS_NEXT


Instance MENUITEM_OPT_GFA (GFA_C_Menu_Item) {
    backPic               = GFA_MENU_ITEM_BACK_PIC;
    type                  = MENU_ITEM_TEXT;
    fontName              = MENU_FONT_DEFAULT;
    text[0]               = GFA_MENU_LABEL;
    text[1]               = GFA_MENU_DESCR;
    posx                  = 1000;
    posy                  = GFA_MENU_START_Y + GFA_MENU_DY * GFA_MENU_ID;
    dimx                  = 5550;
    dimy                  = 750;
    flags                 = GFA_IT_CHROMAKEYED | GFA_IT_TRANSPARENT | GFA_IT_SELECTABLE | GFA_IT_EFFECTS_NEXT;
    // Defaults (see C_Menu_Item_Def)
    alphaMode             = "BLEND";
    alpha                 = 254;
    openDuration          = -1;
    sizeStartScale        = 1;
    userFloat[0]          = 100;
    userFloat[1]          = 200;
};


Instance MENUITEM_OPT_GFA_CHOICE (GFA_C_Menu_Item) {
    backPic               = GFA_MENU_CHOICE_BACK_PIC;
    type                  = GFA_MENU_ITEM_CHOICEBOX;
    fontName              = GFA_MENU_FONT_SMALL;
    text[0]               = GFA_MENU_CHOICES;
    posx                  = 5000;
    posy                  = GFA_MENU_START_Y + GFA_MENU_DY*GFA_MENU_ID + GFA_MENU_CHC_H;
    dimx                  = 2000;
    dimy                  = 350;
    flags                 = GFA_IT_CHROMAKEYED | GFA_IT_TRANSPARENT | GFA_IT_TXT_CENTER;
    onChgSetOption        = "freeAimingEnabled";
    onChgSetOptionSection = "GFA";
    // Defaults (see C_Menu_Item_Def)
    alphaMode             = "BLEND";
    alpha                 = 254;
    openDuration          = -1;
    sizeStartScale        = 1;
    userFloat[0]          = 100;
    userFloat[1]          = 200;
};
