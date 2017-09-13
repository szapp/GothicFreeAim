Gothic Free Aim
===============

**Script package for the video games Gothic and Gothic II that enables free aiming for ranged weapons and spells.**

[![Trailer on Youtube](http://i.imgur.com/1smu8Az.jpg)](http://www.youtube.com/watch?v=9CrFlxo21Qw)

Here is a list of playable modifications featuring this script package (all available in
[Spine](http://forum.worldofplayers.de/forum/threads/1499872)):

 - Gothic - Freies Zielen (comming soon)
 - [Gothic II - Freies Zielen](http://forum.worldofplayers.de/forum/threads/1482039)
 - Gothic II - Free Aiming (comming soon)
 - [RespawnModEnhanced](http://forum.worldofplayers.de/forum/threads/1493169)
 - [Dirty Swamp 2.0](http://forum.worldofplayers.de/forum/threads/1490097) (coming soon)

<br/><br/>

Contents of this Readme
-----------------------

 1. [Features](#features)
 2. [Installation](#installation)
 3. [Project Architecture](#project-architecture)
 4. [Customization](#customization)
 5. [Debugging](#debugging)
 6. [Contact and Discussion](#contact-and-discussion)

<br/><br/>


Features
--------

 - Free aiming for ranged weapons (bows, crossbows)
 - Free aiming for spells
 - Shot projectiles (arrows, bolts) can be picked up and re-used
 - Critical hit detection (e.g. head shots)
 - Modifiable collision behavior by different criteria
 - Movement during aiming
 - True shooting accuracy by scattering
 - Draw force (projectiles drop faster if the bow is not fully drawn)
 - High customizability with easy to use configuration
<br/>


Installation
------------

#### Requirements:

| Gothic                                                                                               | Gothic II: Night of the Raven                                                                                                                 |
| :--------------------------------------------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------- |
|                                                                                                      | [Reportversion 2.6.0.0](http://www.worldofgothic.de/dl/download_278.htm)                                                                      |
| [G1 Mod Development Kit (MDK)](http://www.worldofgothic.de/dl/download_28.htm)                       | [G2 Mod Development Kit (MDK)](http://www.worldofgothic.de/dl/download_94.htm) + [patch 2.6a](http://www.worldofgothic.de/dl/download_99.htm) |
| [Ikarus 1.2](http://forum.worldofplayers.de/forum/threads/1299679)                                   | [Ikarus 1.2](http://forum.worldofplayers.de/forum/threads/1299679)                                                                           |
| [LeGo dev-branch](https://app.assembla.com/spaces/lego2/subversion/source/HEAD/dev) until supported  | [LeGo 2.4.0](http://lego.worldofplayers.de) or higher                                                                                         |


#### Installation Steps:

 1. Make sure Ikarus and LeGo are installed and parsed with `_work\data\Scripts\Content\Gothic.src`.
 2. Copy all files from this repository into your Gothic II installation. Mind the relative paths. Do not forget the
    binary files (textures) that come with the [release](http://github.com/szapp/GothicFreeAim/releases/latest).
 3. Have the files parsed:
    1. **[GOTHIC 1]** Add the line `FREEAIM\freeAim_G1.src` to `_work\data\Scripts\Content\Gothic.src` somewhere
       **after** Ikarus, LeGo and `ANIMS\FOCUS.D`.  
       **[GOTHIC 2]** Add the line `FREEAIM\freeAim_G2.src` to `_work\data\Scripts\Content\Gothic.src` somewhere
       **after** Ikarus, LeGo and `AI\AI_INTERN\FOCUS.D`.
    2. Add the line `camera\caminstfreeaim.d` to the end of `_work\data\Scripts\System\Camera.src`.
    3. **[GOTHIC 1]** Add the line `Pfx\PfxInstFreeAim_G1.d` to the end of `_work\data\Scripts\System\PFX.src`.  
       **[GOTHIC 2]** Add the line `Pfx\PfxInstFreeAim_G2.d` to the end of `_work\data\Scripts\System\PFX.src`.
    4. Add the line `sfx\sfxinstfreeaim.d` to the end of `_work\data\Scripts\System\SFX.src`.
    5. Add the line `visualfx\visualfxfreeaim.d` to the end of `_work\data\Scripts\System\VisualFX.src`.
    6. Add the line `menu\menu_opt_game_freeaim.d` to `_work\data\Scripts\System\Menu.src` between `_intern\menu.d` and
       `menu\menu_main.d`
 4. Add a new menu entry to the options game menu. With this you can enable and
    disable free aim from the options menu. Keep in mind, that there are still players preferring keyboard controls
    over mouse. Without this setting you drive away a fraction of potential players!
    1. Extend the instance `MENU_OPT_GAME` in `_work\data\Scripts\System\Menu\Menu_Opt_Game.d` with the following two
    lines just before `items[XX] = "MENUITEM_GAME_BACK";`, where `XX` is the index. Of course, increase `XX` to `XX+2`
    for `MENUITEM_GAME_BACK`.
    
        ```
            items[XX]       = "MENUITEM_OPT_GFA";
            items[XX+1]     = "MENUITEM_OPT_GFA_CHOICE";
        ```
    
    2. In the same file change `posy = MENU_BACK_Y;` in the instance `MENUITEM_GAME_BACK` to `posy = MENU_BACK_Y+300;`.
    This repositions the menu entries such that everything fits vertically.
    3. Set the constant `MENU_ID_GFA` in `Menu_Opt_Game_FreeAim.d` to the next available slot in the menu, typically
    `(XX-1)/2`. For example:

        ```
        const int  MENU_ID_GFA      = 7; // Next available Y-spot in the menu
        ```
        
    4. You might have to adjust the labels in `_work\data\Scripts\System\Menu\Menu_Opt_Game_FreeAim.d`. By default they
    are in German.

 7. Initialize free aim by adding the line `GFA_Init(GFA_ALL);` in to the function `INIT_Global()` in
    `_work\data\Scripts\Content\Story\Startup.d` either somewhere *after* Ikarus and LeGo or *instead* of them.  
    **[GOTHIC 1]** If you do not have the function `INIT_Global()` yet, create it and call it from all `INIT_*()`
    functions.
 8. Add the lines as indicated in `_work\data\Anims\Humans.mds.additions` into `_work\data\Anims\Humans.mds`. Do the
    same analogous for `_work\data\Anims\MDS_Overlay\Humans_BowT2.mds.additions` and
    `_work\data\Anims\MDS_Overlay\Humans_CBowT2.mds.additions`.
 9. Delete the files `_work\data\Anims\_compiled\HUMANS.MSB`, `_work\data\Anims\_compiled\HUMANS_BOWT2.MSB` and
    `_work\data\Anims\_compiled\HUMANS_CBOWT2.MSB`.  
    **[GOTHIC 1]** You might have to start the game twice for the animations to fully work.

After parsing the scripts, GFA should be fully implemented. Read on to find out how to adjust GFA to your preferences.


#### Usage (Important!):

By using these scripts, you agree to the terms of the **[MIT License](http://opensource.org/licenses/MIT)**.
Please respect my efforts and accredit my work in your project accordingly, i.e.
> This modification utilizes Gothic Free Aim, (C) Copyright 2016-2017  mud-freak (@szapp).  
> < http://github.com/szapp/GothicFreeAim >  
> Released under the MIT License.

If you omit this, you are stating this was your own work which is effectively violating the license.

<br/>


Project Architecture
--------------------

This diagram shows how all the functions of GFA are connected. When not otherwise specified, arrows denote one function
calling another. The left column represents the engine, the middle shows the internal functions of GFA and on the right
are the configuration functions. To understand the architecture, it is recommended to read from right to left (config ->
wrapper functions -> unterlying mechanics -> engine hooks). Features are color coded (see legend). This is a vector
graphic: Open it in your web browser and zoom in to read everything.

![Project architecture](https://rawgit.com/szapp/GothicFreeAim/master/architecture.svg)

<br/>


Customization
-------------

As the mechanisms of the script are rather complex, the script is divided into two parts in
`_work\data\Scripts\Content\freeAim\`. One part is the core functionality and should **not** be edited: `_intern\`.
The other one holds all possible customizations and can be freely adjusted and changed: `config\`.

The customization is mostly implemented by calling outsourced functions. These are functions you can freely adjust. The
only restrictions are the function signature and the type of return value. What happens inside the functions is fully up
to you. Other binary settings are offered as constants that can simply be changed.

In the files `config\` the following things can be adjusted. For more details see `config\` and read the in-line
comments of each listed function. There are a lot of possibilities and a lot of information is already provided to each
function (in form of function arguments). For some examples and ideas see **Examples** above.

 - Reusable Projectiles
 - Draw Force
 - Initial Damage
 - Accuracy
 - Hit Registration
 - Critical Hits
 - Reticles
 - Additional Settings
 - Eligible Spells


#### Reusable Projectiles

While free aiming technically has nothing to do with it, the ability to pick up and reuse projectiles was a side-product
of this script. When a projectile is shot, it will not be removed from the world. It can be collected from the world and
from killed targets' inventories. Although a great feature, this can be disabled by setting `GFA_REUSE_PROJECTILES`
to zero in `freeAimInitConstants()`. If it is enabled, however, the function `freeAimGetUsedProjectileInstance()` may be
used to change/replace the instance of the landed projectile. This allows for "used" arrows/bolts that need repairment
or might be less effective on future usage. Projectiles can be destroyed the same way, by setting their instance to
`-1`. See `freeAimGetUsedProjectileInstance()` for more details.
> Mind the balancing: If projectiles may be reused, you should re-balance the amount of them in the world. Otherwise
their value and barely decreasing number can be exploited during trading.

#### Draw Force

Draw force is the time of drawing the weapon. The longer one draws the weapon the more power is behind the projectile.
This power manifests itself in the trajectory of the projectile. Full draw force results in the most straight flight
path. Anything below will decrease the arc of the projectile, leading to a faster dropping shot. The curved trajectory
is implemented by applying gravity to the projectile after a certain amount of time. The less the draw force, the
earlier the projectile drops. This is all calculated internally, all you need to supply is a percentage (integer between
0 and 100) of draw force in `freeAimGetDrawForce()`. This function is called once you shoot your weapon to determine the
trajectory of the projectile, but it may also be called by yourself in any of the consecutive functions listed below
(e.g. to animate the reticle by draw force/draw time, or manipulate the accuracy). By default, this function returns the
time since drawing the bow (scaled between 0 and 100), while crossbows always have a draw force of 100% (since they are
mechanic). This can, of course, be changed. Possible implementations: Quick-draw talent, different draw time for
different bows. Additional settings are `GFA_DRAWTIME_MAX`, `GFA_TRAJECTORY_ARC_MAX` and `GFA_PROJECTILE_GRAVITY`
(already well balanced and should not be changed). See `freeAimInitConstants()` for details. To monitor the settings see
**Debugging** below.

#### Initial Damage

Once a projectile leaves the weapon, it is assigned a base damage (which is essentially the weapon damage). There is no
reason to ever change this base damage, as it could just be adjusted in the weapon-item script. Nevertheless, scaling
this base damage by draw force is very useful. This is done in `freeAimScaleInitialDamage()`. To monitor the settings
see **Debugging** below.

#### Accuracy

Gothics native implementation of hit chance is to only register a percentage of the hits, while the others still visibly
collide. Here, this method is overwritten, with a true shooting accuracy. The accuracy is a percentage (integer between
0 and 100) that can be adjusted in `freeAimGetAccuracy()`. This function is called once you shoot your weapon to
determine the deviation of the projectile. By default this function combines weapon talent and draw force. The amount of
**maximum** scattering (when the returned percentage of accuracy is 0) can be adjusted in `GFA_SCATTER_DEG` in
`freeAimInitConstants()`. However, this value is already well balanced. To monitor the settings see **Debugging** below.

#### Hit Registration

Related to accuracy is the hit registration. You may change the behavior of projectiles by the surface they collide
with. When a projectile collides with an npc the function `freeAimHitRegNpc()` is called. There, you are supplied with
the target npc instance, the material of the armor they wear (as defined in `Constants.d`) and more, to decide whether
the projectile should hit and cause damage, deflect and cause no damage or be destroyed and cause no damage. The
function `freeAimHitRegWld()` is called when a projectile collides with the world. There, you can decide by material and
texture of the surface, whether the projectile should get stuck, deflect or be destroyed on impact. When a projectile is
destroyed, it is accompanied by a sound and subtle visual effect of bursting wood (collision with world only). Possible
implementations: Disabled friendly-fire, ineffective weapons, break-on-impact chance. Additionally, I implemented a hit
detection that sits on top of the engine's hit detection. Originally, the idea was to make the hit detection more
precise. However, this method is only experimental and if anything it only yields false negatives (no hits when there
should be hits). By default it is disabled. If you want to check it out, see `GFA_HITDETECTION_EXP` in
`freeAimInitConstants()`. In Gothic, there is a bug by which projectiles collide with triggers, causing a loud metallic
clatter. This is prevented by a fix introduced
[here](http://forum.worldofplayers.de/forum/threads/1126551/page10?p=20894916). This fix is enabled here by default.
Should this compromise the functionality of your triggers you can disable it by setting `GFA_TRIGGER_COLL_FIX` to
zero in `freeAimInitConstants()`.

#### Critical Hits

Something that is a must-have in a free aiming implementation is a damage multiplier for critical hits. Instead of
pre-defining critical hits to be head shots for all creatures, the function `freeAimCriticalHitDef()` allows for
dynamically defined critical hit zones ("weakspots"), their size and the damage multiplier. This function is called on
every positive hit on an npc and aids to decide whether a critical hit happened. When there was a critical hi, the
function `freeAimCriticalHitEvent()` is called, in which you can define an event on getting a critical hit. Possible
implementations: Headshot counter, sound notification, hit marker, print on the screen. Both functions are supplied with
the target npc in question. Thus, it is very well possible to discern those and define varying cases. As it is very
difficult to guess the dimensions of a defined weakspot, the console command `debug GFA weakspot` will visualize the
projectile trajectory and the bounding box of the currently defined weakspot for the target. This will help deciding on
suitable sizes for weakspots. For thorough testing this debug visualization can be enabled by default with
`GFA_DEBUG_WEAKSPOT` in `freeAimInitConstants()`.

#### Reticles

Reticles can be dynamically customized. The functions `freeAimGetReticleRanged()` (for ranged combat) and
`freeAimGetReticleSpell()` (for magic combat) are called continuously while holding down the action button in the
respective fight mode. By weapon/spell, their properties, aiming distance and by calling any of the previously defined
functions (like draw force and accuracy), the visualization of reticles is extremely flexible. There are a lot of
possibilities waiting. See the mentioned functions for details.

#### Additional Settings

There is a variety of miscellaneous configurations. While a large number is omitted here, as they should not be touched,
a few are enumerated and explained here briefly.

 - `GFA_DISABLE_SPELLS` in `freeAimInitConstants()` will disable free aiming for spells. (Free aiming only for
   ranged weapons.)
 - `GFA_DEBUG_TRACERAY` in `freeAimInitConstants()` will enable trace ray debug visualization by default (see below
   for more information).
 - `GFA_ROTATION_SCALE`  in `freeAimInitConstants()` will adjust the rotation speed while aiming. This is **not**
   the mouse sensitivity. This setting should not be changed.
 - `GFA_CAMERA` in `freeAimInitConstants()` will set a different camera setting for aiming. The camera setting
   should not be changed, as the aiming becomes less accurate (intersection miss-match, parallax effect).
 - `GFA_CAMERA_X_SHIFT` in `freeAimInitConstants()` has to be set to true, if the camera has an X offset. This is
   not recommended at all (parallax effect), see above.
 - `freeAimShiftAimVob()` will shift the offset along the camera viewing axis. This is only useful for spells that
   visualize the aim vob. For an example (SPL_Blink) visit the forum thread (see link in **Contact and Discussion**
   or check out the branch `SPL_Blink`).

There are quite some more things that can be changed (listed at the top of `_intern\const.d`) but they should not be
altered under normal circumstances. Changing those settings will most certainly make GFA unstable.

#### Eligible Spells

Gothic offers very different types of spells (attack spells, area of effect spells, summoning spells, enhancement
spells). Of course, not all of those require free aiming, let alone a reticle. Here is a description of how GFA
decides which spell is eligible for free aiming.

 - The property `targetCollectAlgo` in the spell instance needs to be set to `TARGET_COLLECT_FOCUS_FALLBACK_NONE`
 - The property `canTurnDuringInvest` in the spell instance needs to be set to `TRUE`
 - The property `canChangeTargetDuringInvest` in the spell instance needs to be set to `TRUE`

This list of conditions works without exception with all Gothic 2 tNotR spells and rather than ever changing these
conditions (which will make them inconsistent across all Gothic spells) all newly created spells should meet/not meet
these conditions, because they make sense.

<br/>


Debugging
---------

Some steps have been taken to make debugging GFA easier and to help with customizing it (see **Customization**
above).
 1. Information about shots from bows and crossbows is sent to the zSpy at time of shooting, containing
    - Draw force (percent)
    - Accuracy (percent) and resulting scatter (X and Y offset in degrees)
    - Adjusted base damage (see **Customization** above) and original base damage
 2. Information about critical hits from bows and crossbows is sent to the zSpy at time of collision, containing
    - Whether or not it was a critical hit
    - Critical base damage and original base damage
    - Critical hit zone (body node/weakspot) and its dimensions
 3. For finding good critical hit zones (weakspots), the console command `debug GFA weakspot` will visualize the
    projectile trajectory and the bounding box of the currently defined weakspot for the target. This will help deciding
    on suitable sizes for weakspots.
 4. The console command `debug GFA traceray` will visualize the aiming trace ray and the determined nearest
    intersection. This should only be useful if the underlying GFA mechanics are modified (which is not
    recommended).
 5. Additional information about the selected settings of GFA can be displayed in the console by the commands
    - `GFA version` displays the current version of GFA, e.g. "Gothic Free Aim v1.0.0-alpha"
    - `GFA license` displays the license information of GFA
    - `GFA info` displays the settings of GFA
        - Whether free aiming is enabled
        - Whether focus collection is enabled (ini-file setting for performance)
        - Whether projectiles are enabled to be reusable
        - Whether free aiming is enabled for spells
<br/>


Contact and Discussion
----------------------

Head over to the [World of Gothic Forum](http://forum.worldofplayers.de/forum/threads/1473223) to share your thoughts or
questions that you might have or to join the discussion about this script. Forum language is German or English. It is
easiest to keep everything in one place.
