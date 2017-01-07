G2 Free Aim
===========

**Script for the video game Gothic II: Night of the Raven enabling free aiming for ranged weapons and spells.**

**Note**: This is a script (i.e. source code). If you are interested in a playable version instead, checkout this
modification [Gothic II - Freies Zielen](http://forum.worldofplayers.de/forum/threads/1482039) (German language).

[![Trailer on Youtube](http://i.imgur.com/PhJ3gcm.jpg)](http://www.youtube.com/watch?v=9CrFlxo21Qw)


Features
--------

 - Free aiming for ranged weapons (bows, crossbows)
 - Free aiming for spells
 - Shot projectiles (arrows, bolts) can be picked up and re-used
 - Dynamic critical hit detection (e.g. head shots)
 - Modifiable hit registration by different criteria (surface material and texture)
 - True shooting accuracy
 - Draw force (projectiles drop faster if the bow is not fully drawn)
 - High customizability (see **Examples** and **Customization** below)

**Examples**

Here short list of some examples which are easily implementable (or already included) in `config.d`. There is a lot
more freedom, however.

 - Change the way the draw force (projectile gravity) is calculated (by weapon stats, skill level, ..)
 - Change the way the accuracy is calculated (by weapon stats, skill level, ..)
 - Change the initial damage when an arrow is shot (by draw force, accuracy, skill level, ..)
 - Change the reticle style (by draw force, accuracy, weapon, aiming distance, enemy, ..)
 - Different critical hit zones (body parts like head, torso, limbs) (by guild, weapon, ..)
 - Different damage for critical hits
 - Notification when getting a critical hit (sound, screen print, ..)
 - *Head shot* counter that gives XP every 25 head shots.
 - Disable friendly-fire for quest/party members
 - Define collision behavior of projectiles by surface material or texture (e.g. arrows break or deflect when hitting
   stone or get stuck in wood)
 - Change the projectiles when they have been shot (e.g. used arrows that need to be repaired)
 - Enable/Disable retrieving projectiles (e.g. the player first has to learn to retrieve arrows from animals)
 - And much more. Get creative!


Installation
------------

Again, this is the installation **for developers**. If you are interested in a playable version instead, checkout this
modification [Gothic II - Freies Zielen](http://forum.worldofplayers.de/forum/threads/1482039) (German language).

Requirements:

 - Gothic II: Night of the Raven ([Reportversion 2.6.0.0](http://www.worldofgothic.de/dl/download_278.htm))
 - [Mod Development Kit (MDK)](http://www.worldofgothic.de/dl/download_94.htm) with scripts
   (+ [patch 2.6a](http://www.worldofgothic.de/dl/download_99.htm))
 - [Ikarus 1.2](http://forum.worldofplayers.de/forum/threads/1299679)
 - [LeGo 2.4.0](http://lego.worldofplayers.de) or higher with HookEngine, FrameFunctions and ConsoleCommands

A [setup](http://github.com/szapp/g2freeAim/releases/latest) is available to take care of the integration. Just run it,
and all scripts should be fully working (originals will be backed up). Alternatively, you can do these following steps
manually.

 1. Make sure Ikarus and LeGo are installed and initialized with *FrameFunctions* and *ConsoleCommands*.
 2. Copy all files from this repository into your Gothic II installation. Mind the relative paths. Do not forget the
    binary files (textures) that come with the [release](http://github.com/szapp/g2freeAim/releases/latest).
 3. Have the files parsed:
    1. Add the line `FREEAIM\freeAim.src` to `_work\data\Scripts\Content\Gothic.src` somewhere **after** Ikarus, LeGo
       and `AI\AI_INTERN\FOCUS.D`.
    2. Add the line `camera\caminstfreeaim.d` to the end of `_work\data\Scripts\System\Camera.src`.
    3. Add the line `Pfx\PfxInstFreeAim.d` to the end of `_work\data\Scripts\System\PFX.src`.
    4. Add the line `sfx\sfxinstfreeaim.d` to the end of `_work\data\Scripts\System\SFX.src`.
    5. Add the line `visualfx\visualfxfreeaim.d` to the end of `_work\data\Scripts\System\VisualFX.src`.
    6. Add the line `menu\menu_opt_game_freeaim.d` to the end of `_work\data\Scripts\System\Menu.src`.
 4. Add a new menu entry to the options game menu. Extend the instance `MENU_OPT_GAME` in
    `_work\data\Scripts\System\Menu\Menu_Opt_Game.d` with these two lines just before
    `items[XX] = "MENUITEM_GAME_BACK";`.

    ```
        items[XX]       = "MENUITEM_OPT_FREEAIM";
        items[XX+1]     = "MENUITEM_OPT_FREEAIM_CHOICE";
    ```

    Where `XX` is the index. Of course, increase `XX` to `XX+2` for `MENUITEM_GAME_BACK`. With this you can enable and
    disable free aim from the options menu.
 5. In the same file change `posy = MENU_BACK_Y;` in the instance `MENUITEM_GAME_BACK` to `posy = MENU_BACK_Y+300;`.
    This repositions the menu entries such that everything fits.
 6. Set the constant `MENU_ID_FREEAIM` either in `Menu_Opt_Game.d` or in `Menu_Opt_Game_FreeAim.d` to the next available
    slot in the menu, typically `(XX-1)/2`. For example:

    ```
    const int  MENU_ID_FREEAIM      = 7; // Next available Y-spot in the menu
    ```

 7. Finally initialize free aim by adding the line `freeAim_Init();` in to the function `INIT_GLOBAL()` in
    `_work\data\Scripts\Content\Story\Startup.d` somewhere after Ikarus and LeGo.

> Again: The [setup](http://github.com/szapp/g2freeAim/releases/latest) will perform all these steps for you.

You will have to adjust the labels in `_work\data\Scripts\System\Menu\Menu_Opt_Game_FreeAim.d`. By default they are in
German. After parsing the scripts g2freeAim should be fully implemented. Read on to find out how to adjust g2freeAim to
your preferences.

> **Note**: By using these scripts, you agree to the terms of the **[MIT License](http://opensource.org/licenses/MIT)**.
Please respect my efforts and accredit my work in your project accordingly (i.e. *"This modification utilizes G2 Free
Aim written by mud-freak (@szapp)"* in the credits). If you omit this, you are stating this was your own work which is
effectively violating the license.


Customization
-------------

As the mechanisms of the script are rather complex, the script is divided into two parts in
`_work\data\Scripts\Content\freeAim\`. One part is the core functionality and should **not** be edited: `_intern.d`.
The other one holds all possible customizations and can be freely adjusted and changed: `config.d`.

The customization is mostly implemented by calling outsourced functions. These are functions you can freely adjust. The
only restrictions are the function signature and the type of return value. What happens inside the functions is fully up
to you. Other binary settings are offered as constants that can simply be changed.

In the file `config.d` the following things can be adjusted. For more details see `config.d` and read the in-line
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
from killed targets' inventories. Although a great feature, this can be disabled by setting `FREEAIM_REUSE_PROJECTILES`
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
different bows. Additional settings are `FREEAIM_DRAWTIME_MAX`, `FREEAIM_TRAJECTORY_ARC_MAX` and
`FREEAIM_PROJECTILE_GRAVITY` (already well balanced and should not be changed). See `freeAimInitConstants()` for
details. To monitor the settings see **Debugging** below.

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
**maximum** scattering (when the returned percentage of accuracy is 0) can be adjusted in `FREEAIM_SCATTER_DEG` in
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
should be hits). By default it is disabled. If you want to check it out, see `FREEAIM_HITDETECTION_EXP` in
`freeAimInitConstants()`. In Gothic, there is a bug by which projectiles collide with triggers, causing a loud metallic
clatter. This is prevented by a fix introduced
[here](http://forum.worldofplayers.de/forum/threads/1126551/page10?p=20894916). This fix is enabled here by default.
Should this compromise the functionality of your triggers you can disable it by setting `FREEAIM_TRIGGER_COLL_FIX` to
zero in `freeAimInitConstants()`.

#### Critical Hits

Something that is a must-have in a free aiming implementation is a damage multiplier for critical hits. Instead of
pre-defining critical hits to be head shots for all creatures, the function `freeAimCriticalHitDef()` allows for
dynamically defined critical hit zones ("weakspots"), their size and the damage multiplier. This function is called on
every positive hit on an npc and aids to decide whether a critical hit happened. When there was a critical hi, the
function `freeAimCriticalHitEvent()` is called, in which you can define an event on getting a critical hit. Possible
implementations: Headshot counter, sound notification, hit marker, print on the screen. Both functions are supplied with
the target npc in question. Thus, it is very well possible to discern those and define varying cases. As it is very
difficult to guess the dimensions of a defined weakspot, the console command `debug freeaim weakspot` will visualize the
projectile trajectory and the bounding box of the currently defined weakspot for the target. This will help deciding on
suitable sizes for weakspots. For thorough testing this debug visualization can be enabled by default with
`FREEAIM_DEBUG_WEAKSPOT` in `freeAimInitConstants()`.

#### Reticles

Reticles can be dynamically customized. The functions `freeAimGetReticleRanged()` (for ranged combat) and
`freeAimGetReticleSpell()` (for magic combat) are called continuously while holding down the action button in the
respective fight mode. By weapon/spell, their properties, aiming distance and by calling any of the previously defined
functions (like draw force and accuracy), the visualization of reticles is extremely flexible. There are a lot of
possibilities waiting. See the mentioned functions for details.

#### Additional Settings

There is a variety of miscellaneous configurations. While a large number is omitted here, as they should not be touched,
a few are enumerated and explained here briefly.

 - `FREEAIM_DISABLE_SPELLS` in `freeAimInitConstants()` will disable free aiming for spells. (Free aiming only for
   ranged weapons.)
 - `FREEAIM_DEBUG_TRACERAY` in `freeAimInitConstants()` will enable trace ray debug visualization by default (see below
   for more information).
 - `FREEAIM_ROTATION_SCALE`  in `freeAimInitConstants()` will adjust the rotation speed while aiming. This is **not**
   the mouse sensitivity. This setting should not be changed.
 - `FREEAIM_CAMERA` in `freeAimInitConstants()` will set a different camera setting for aiming. The camera setting
   should not be changed, as the aiming becomes less accurate (intersection miss-match, parallax effect).
 - `FREEAIM_CAMERA_X_SHIFT` in `freeAimInitConstants()` has to be set to true, if the camera has an X offset. This is
   not recommended at all (parallax effect), see above.
 - `freeAimShiftAimVob()` will shift the offset along the camera viewing axis. This is only useful for spells that
   visualize the aim vob. For an example (SPL_Blink) visit the forum thread (see link in **Contact and Discussion**
   or check out the branch `SPL_Blink`).

There are quite some more things that can be changed (listed at the top of `_intern.d`) but they should not be altered
under normal circumstances. Changing those settings will most certainly make g2freeAim unstable.

#### Eligible Spells

Gothic offers very different types of spells (attack spells, area of effect spells, summoning spells, enhancement
spells). Of course, not all of those require free aiming, let alone a reticle. Here is a description of how g2freeAim
decides which spell is eligible for free aiming.

 - The property `targetCollectAlgo` in the spell instance needs to be set to `TARGET_COLLECT_FOCUS_FALLBACK_NONE`
 - The property `canTurnDuringInvest` in the spell instance needs to be set to `TRUE`
 - The property `canChangeTargetDuringInvest` in the spell instance needs to be set to `TRUE`

This list of conditions works without exception with all Gothic 2 tNotR spells and rather than ever changing these
conditions (which will make them inconsistent across all Gothic spells) all newly created spells should meet/not meet
these conditions, because they make sense.


Debugging
---------

Some steps have been taken to make debugging g2freeAim easier and to help with customizing it (see **Customization**
above).
 1. Information about shots from bows and crossbows is sent to the zSpy at time of shooting, containing
    - Draw force (percent)
    - Accuracy (percent) and resulting scatter (X and Y offset in degrees)
    - Adjusted base damage (see **Customization** above) and original base damage
 2. Information about critical hits from bows and crossbows is sent to the zSpy at time of collision, containing
    - Whether or not it was a critical hit
    - Critical base damage and original base damage
    - Critical hit zone (body node/weakspot) and its dimensions
 3. For finding good critical hit zones (weakspots), the console command `debug freeaim weakspot` will visualize the
    projectile trajectory and the bounding box of the currently defined weakspot for the target. This will help deciding
    on suitable sizes for weakspots.
 4. The console command `debug freeaim traceray` will visualize the aiming trace ray and the determined nearest
    intersection. This should only be useful if the underlying g2freeAim mechanics are modified (which is not
    recommended).
 5. Additional information about the selected settings of g2freeAim can be displayed in the console by the commands
    - `freeaim version` displays the current version of g2freeAim, e.g. "G2 Free Aim v0.1.2"
    - `freeaim license` displays the license information of g2freeAim
    - `freeaim info` displays the settings of g2freeAim
        - Whether free aiming is enabled
        - Whether focus collection is enabled (ini-file setting for performance)
        - Whether projectiles are enabled to be reusable
        - Whether free aiming is enabled for spells


Unfinished Features
-------------------

These features were not fully implemented.

 - Strafing while aiming
 - Bow draw animations while aiming

Attempts, progress and unstable implementations for both features are available in the branches `strafing` and
`drawAni`. Keep in mind that they are far behind `master`. If you think you can finish these features, feel free to
create a pull request. Consult with the issue tracker for information on possible limitations and different attempts.


FAQ
---

Q: **Do balancing issues arise from g2freeAim?**

A:
No. The option, to collect/re-use projectiles, however, increases the amount of arrows/bolts (since the player will need
less of them). This should be kept in mind. If you disable this features, there is absolutely no impact on balance.

Q: **Is there an easy way to try and get a feel for this script?**

A:
Anyone can try the free aiming by downloading the demo modification (see link above). This can be done without much
effort. Note that this demo is in German.

Q: **How do I install g2freeAim into my scripts?**

A:
You can find the latest release [here](http://github.com/szapp/g2freeAim/releases/latest). Follow the instructions
above.

Q: **I am getting an error while parsing: *"Syntax error : ï»¿ ( line 1 )"*, what now?**

A:
In the zSpy log you should see which file was parsed last, before the error occured (presumably `Startup.d`). Open the
file and save it with the encoding *ANSI (Windows-1252)*.

Q: **I am getting and error telling me *"CC_Register"* is missing, what now?**

A:
Your version of LeGo is out dated: g2freeAim requires LeGo 2.4.0 or higher.

Q: **It does not work? What now?**

A:
Should the installation of g2freeAim fail, please read through this README.md first. If this does not help, post your
problem into the mentioned forum thread (see **Contact and Discussion** below) with the following information:

  - What exaclty is not working: Is the game not launching (list possible parser errors)? Is nothing happing in the game
    (as if g2freeAim was not installed)? Does the game crash (when and how)?
  - Attach possible error messages/codes
  - Attach the zSpy log
  - If possible, please post the output when entering `freeaim info` into the F2-ingame-console.

Q: **Why does my game crash?**

A:
See **"It does not work? What now?"**. Additionally, it will be essential to describe your configuration, ideally by
attaching your `freeAim/config.d`.

Q: **What is the deal with the license? May I use g2freeAim in my modification?**

A:
In the section **Installation** above, I have written what the license implies. Please read it, keep it in mind and
respect it. If you see a modification making use of this script and not mentioning it in the credits, feel free to
remind the creator of that mod of the license conditions or report them to me.

Q: **Why is the reticle not in the center of my screen?**

A:
You seem to be using version v0.1.0 of g2freeAim. Update it to the
[latest version](http://github.com/szapp/g2freeAim/releases/latest).

Q: **Why do I have a rock-like texture instead of a reticle on my screen?**

A:
You seem to have missed the textures. You can download them [here](http://github.com/szapp/g2freeAim/releases/latest).

Q: **How can I define critical hit zones for different monsters?**

A:
In the default configuration the critical hit zones are defined very loosely as the head for all NPCs. This should be
adjusted if possible, since these definitions are very inaccurate. This has not been done to not conflict with mods that
do not include all monsters from Gothic II and to encourage you to put in a little work yourself. Nevertheless, well
defined critical hit zones (head for all native Gothic II creatures) are available in the
[mod scripts](http://www.worldofgothic.de/?go=moddb&action=view&fileID=1330) of the demo modification
*"Gothic II - Freies Zielen"*. Furthermore, in order to design your own critical hit zones, I created a script to help
with that. You can find it in the forum thread linked in the section **Contact and Discussion** below.

Q: **Is this script still being developed?**

A:
No, it is complete. See **Future** and **Contact and Discussion** below for more information.

Q: **I have a great idea for a feature! Could you implement it, please?**

A:
See **Future** and **Contact and Discussion** below for more information.

Q: **(I think) I have found a bug. How can I report it?**

A:
You can report bugs either in the forum thread or to me directly via the information in the section
**Contact and Discussion** or create a ticket directly here in the Github Issue Tracker. A good bug report should
include the following information:

 - Detailed description of what happened.
 - Detailed description of how it happened.
 - Output when entering `freeaim info` into the F2-ingame-console.
 - zSpy Log.
 - The Access Violation message (if applicable).
 - Your configuration (attach the file `freeAim/config.d`).
 - Used versions of Ikarus/LeGo.
 - If possible: Your own attempts to isolate and reproduce the bug.


If your question is not listed here, please read through this README.md first, before posting into the forum thread or
asking for help (see **Contact and Discussion**).


Contact and Discussion
----------------------

Head over to the [World of Gothic Forum](http://forum.worldofplayers.de/forum/threads/1473223) to share your thoughts or
questions that you might have or to join the discussion about this script. It is easiest to keep everything in one
place.


Future
------

This script will not be worked on after 2016. Nevertheless, feel free to create **pull requests** if you implement new
features.


Gothic 1 Compatibility
----------------------

This script is only compatible with Gothic II: The Night of the Raven. It is not meant for Gothic 1. At the moment it is
difficult to port it to Gothic 1, as there is no working version LeGo for Gothic 1. Also all memory addresses g2freeAim
is using, would need to be adjusted. A lot of stack offsets are hard-coded at various places in the code.
