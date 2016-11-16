G2 Free Aim
===========

**Script for the video game Gothic II: Night of the Raven enabling free aiming for ranged weapons and spells.**

**Note**: This is a script (i.e. source code). If you are interested in a playable version instead, checkout this
modification [Gothic II - Freies Zielen](http://example.com) (German language).


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
modification [Gothic II - Freies Zielen](http://example.com) (German language).

Requirements:

 - Gothic II: Night of the Raven (Reportversion 2.6.0.0)
 - **Mod Development Kit (MDK)** with scripts
 - Ikarus 1.2
 - LeGo 2.3.6 or higher with HookEngine, FrameFunctions and ConsoleCommands (not included in LeGo 2.3.6 yet)

A [setup](http://github.com/szapp/g2freeAim/releases/latest) is available to take care of the integration. Just run it,
and all scripts should be fully working. Alternatively, you can do these following steps manually.

 1. Make sure Ikarus and LeGo are installed and initialized with *FrameFunctions* and *ConsoleCommands*.
 2. Copy all files from this repository into your Gothic II installation. Mind the relative paths.
 3. Have the files parsed:
    1. Add the line `FREEAIM\freeAim.src` to `_work\data\Scripts\Content\Gothic.src` somewhere **after** Ikarus, LeGo
    and `AI\AI_INTERN\FOCUS.D`.
    2. Add the line `camera\caminstfreeaim.d` to the end of `_work\data\Scripts\System\Camera.src`.
    3. Add the line `Pfx\PfxInstFreeAim.d` to the end of `_work\data\Scripts\System\PFX.src`.
    4. Add the line `sfx\sfxinstfreeaim.d` to the end of `_work\data\Scripts\System\SFX.src`.
    5. Add the line `visualfx\visualfxfreeaim.d` to the end of `_work\data\Scripts\System\VisualFX.src`.
    6. Add the line `menu\menu_opt_game_freeaim.d` to the end of `_work\data\Scripts\System\Menu.src`.
 4. Add a new menu entry to the options game menu. Extend the instance `MENU_OPT_GAME` in
 `_work\data\Scripts\System\Menu\Menu_Opt_Game.d` with these to lines just before `items[XX] = "MENUITEM_GAME_BACK";`.

    ```
        items[XX]       = "MENUITEM_OPT_FREEAIM";
        items[XX]       = "MENUITEM_OPT_FREEAIM_CHOICE";
    ```
    Replace `XX` by the next increasing index. With this you can enable and disable free aim from the options menu.
 5. In the same file change `posy = MENU_BACK_Y;` in the instance `MENUITEM_GAME_BACK` to `posy = MENU_BACK_Y+300;`.
 This repositions the menu entries such that everything fits.
 6. Finally initialize free aim by adding the line `freeAim_Init();` in to the function `INIT_GLOBAL()` in
 `_work\data\Scripts\Content\Story\Startup.d` somewhere after Ikarus and LeGo.

> Again: The [setup](http://github.com/szapp/g2freeAim/releases/latest) will perform all these steps for you.

After parsing the scripts free aim should be fully implemented. Read on to find out how to adjust free aim to your
preferences.

> **Note**: By using these scripts, you agree to the terms of the **GNU General Public License**. Please respect my
efforts and accredit my work in your project accordingly (i.e. *"This modification utilizes G2 Free Aim written by
mud-freak (@szapp)"* in the credits). If you omit this, you are stating this was your own work which is effectively
violating the license.


Customization
-------------

As the mechanisms of the script are rather complex, the script is devided into two parts in
`_work\data\Scripts\Content\freeAim\`. One part is the core functionality and should **not** be edited: `_intern.d`.
The other holds all possible customizations and can be freely adjusted and changed: `config.d`.

The customization is mostly implemented by calling outsourced functions. These are functions you can freely adjust. The
only restrictions are the function signature and the type of return value. What happens inside the functions is fully up
to you. Other binary settings are offered as constants that can simply be changed.

In the file `config.d` the following things can be adjusted.

| Function/Constant                                             | Description                                      |
| ------------------------------------------------------------- | ------------------------------------------------ |
| FREEAIM_DRAWTIME_MAX                                          | Maximum bow draw time (ms)                       |
| FREEAIM_DISABLE_SPELLS                                        | Disable free aiming for spells (true/false)      |
| FREEAIM_REUSE_PROJECTILES                                     | Collect and re-use shot projectiles (true/false) |
| freeAimGetUsedProjectileInstance(instance, targetNpc)         | Projectile instance for re-using                 |
| freeAimGetDrawForce(weapon, talent)                           | Draw force (gravity/drop-off) calculation        |
| freeAimGetAccuracy(weapon, talent)                            | Accuracy calculation                             |
| freeAimGetReticleRanged(target, weapon, talent, distance)     | Reticle style (texture, color, size)             |
| freeAimGetReticleSpell(target, spellID, spellInst, ..)        | Reticle style for spells                         |
| freeAimHitRegNpc(target, weapon, material)                    | Hit registration on npcs (e.g. friendly-fire)    |
| freeAimHitRegWld(shooter, weapon, material, texture)          | Hit registration on world                        |
| freeAimScaleInitialDamage(basePointDamage, weapon, talent)    | Change the base damage at time of shooting       |
| freeAimCriticalHitDef(target, weapon, damage)                 | Critical hit calculation (position, damage)      |
| freeAimCriticalHitEvent(target, weapon)                       | Critical hit event (print, sound, xp, ...)       |
| FREEAIM_DEBUG_WEAKSPOT                                        | Show weakspot debug visualization by default     |
| FREEAIM_DEBUG_TRACERAY                                        | Show trace ray debug visualization by default    |
| FREEAIM_DEBUG_CONSOLE                                         | Allow freeAim console commands (cheats)          |
|                                                               | **Advanced Settings** (not recommended)          |
| FREEAIM_SCATTER_DEG                                           | Scatter radius for accuracy                      |
| FREEAIM_CAMERA and FREEAIM_CAMERA_X_SHIFT                     | Camera view (shoulder view)                      |
| FREEAIM_TRAJECTORY_ARC_MAX                                    | Max time before projectile drop-off              |
| FREEAIM_PROJECTILE_GRAVITY                                    | Gravity of projectile after drop-off             |
| FREEAIM_ROTATION_SCALE                                        | Turn speed while aiming                          |
| freeAimShiftAimVob                                            | Shift the aim vob                                |

For more details see `config.d` and read the inline comments of each listed function. There are a lot of possiblities
and a lot of information (in form of variables) is already provided to the function. For some examples and ideas see
**Examples** above.

There are quite some more things that can be changed (listed at the top of `_intern.d`) but they should not be altered
under normal circumstances. Changing those settings will most certainly make G2freeAim unstable.


Unfinished Features
-------------------

These features were not fully implemented.

 - Strafing with aiming
 - Bow draw animations while aiming

Attempts, progress and unstable implementations for both features are availabe in the branches `strafing` and `drawAni`.
Keep in mind that they are far behind `master`. If you think you can finish these features, feel free to create a pull
request. Consult with the issue tracker for information on possible limitations and different attempts.


Contact and Discussion
----------------------

Head over to [World of Gothic DE](http://forum.worldofplayers.de/forum/threads/1473223) to share your thoughts or
questions that you might have or to join the discussion about this script.


Future
------

This scipt will not be worked on after 2016. Nevertheless, feel free to create **pull request** if you implement new
features.


Gothic 1 Compatibility
----------------------

This script is only compatible with Gothic II: The Night of the Raven (Reportversion 2.6.0.0). It is not meant for
Gothic 1. At the moment it is difficult to port it to Gothic 1, as there is no working version LeGo for Gothic 1. Also
all memory addresses G2freeAim is using, would need to be adjusted. A lot of stack offsets are hardcoded at various
places in the code.
