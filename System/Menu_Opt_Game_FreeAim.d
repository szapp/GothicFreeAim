/*
 * FREEAIM OPTIONS
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
