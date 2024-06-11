<div align="center">

[![Gothic Free Aim](https://github.com/szapp/GothicFreeAim/wiki/media/GFA_TITLE_LARGE_FA_trans.png)](https://github.com/szapp/GothicFreeAim)

[![Syntax](https://github.com/szapp/GothicFreeAim/actions/workflows/syntax.yml/badge.svg)](https://github.com/szapp/GothicFreeAim/actions/workflows/syntax.yml)
[![Documentation](https://img.shields.io/badge/docs-wiki-blue)](https://github.com/szapp/GothicFreeAim/wiki)
[![GitHub release](https://img.shields.io/github/v/release/szapp/GothicFreeAim.svg)](https://github.com/szapp/GothicFreeAim/releases/latest)
[![Combined downloads](https://api.szapp.de/downloads/gfa/total/badge)](https://github.com/szapp/GothicFreeAim/releases)  
[![World of Gothic](https://raw.githubusercontent.com/szapp/patch-template/main/.github/actions/initialization/badges/wog.svg)](https://www.worldofgothic.de/dl/download_613.htm)
[![Spine](https://raw.githubusercontent.com/szapp/patch-template/main/.github/actions/initialization/badges/spine.svg)](https://clockwork-origins.com/spine)
[![Steam Gothic 1](https://img.shields.io/badge/steam-Gothic%201-2a3f5a?logo=steam&labelColor=1b2838)](https://steamcommunity.com/sharedfiles/filedetails/?id=2786959658)
[![Steam Gothic 2](https://img.shields.io/badge/steam-Gothic%202-2a3f5a?logo=steam&labelColor=1b2838)](https://steamcommunity.com/sharedfiles/filedetails/?id=2786958841)

**Script package for the Gothic video game series that enables free aiming for ranged weapons and spells.**  
<kbd>Gothic</kbd> <kbd>Gothic Sequel</kbd> <kbd>Gothic II</kbd> <kbd>Gothic II: Night of the Raven</kbd>

<br />

[![Trailer on Youtube](https://raw.githubusercontent.com/wiki/szapp/GothicFreeAim/media/thumb_medium.png)](https://www.youtube.com/watch?v=9CrFlxo21Qw)
</div>

## Features

- Free aiming for ranged weapons (bows, crossbows) and spells
- Critical hit detection by body parts (e.g. head shots)
- Customizable collision and damage behaviors (e.g. instant knockout/kill)
- Shot projectiles (arrows, bolts) can be picked up and may be re-used
- True shooting accuracy by scattering
- Movement while aiming (animations are provided)
- Adjustable projectile trajectory, gravity and damage, as well as weapon recoil
- High customizability with easy to use configuration

## Wiki

[Visit the wiki](https://github.com/szapp/GothicFreeAim/wiki) for all information on this script package, including
requirements and installation steps, a complete list of features and elaborate information on configuration.

## Usage in a Git repository

If you intend to use (portions of) GFA in your git repository, it is recommended to incorporate it using a [git-submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules).
This not only helps to maintain your scripts at the latest version, but also ensures proper licensing and directs users to the original source.

Since submodules do not allow directly referring to sub-directories of the target repository, implement the following procedure.

First add GFA as a submodule into a suitable sub-directory off to the side in your repository. Then refer to the relevant sub-directories using relative symlinks.
Symlinks are supported in git (also in Windows) and will resolve the file paths as desired.

> [!TIP]
> Have a look at the repository [szapp/FreeAiming](https://github.com/szapp/FreeAiming) for an example of using submodules.

This can be achieved by entering the following code into the Windows Command Prompt with administrative privileges (for creating symlinks). Mind the use of forward slashes.

```cmd
mkdir .github\submodules
git submodule add --name GothicFreeAim https://github.com/szapp/GothicFreeAim.git .github/submodules/GothicFreeAim
git config core.symlinks true
```

The file `.gitmodules` should now look like this (compare the use of forward slashes):

```
[submodule "GothicFreeAim"]
    path = .github/submodules/GothicFreeAim
    url = https://github.com/szapp/GothicFreeAim.git
```

Now, you can add relevant symlinks to desired sub-directories within the GFA scripts.

For example, the internal content scripts (`Content/GFA/_intern`) should never be modified and can be linked to the submodule.

```cmd
cd path\to\Scripts\Content\GFA
mklink /d _intern ..\..\..\..\..\.github\submodules\GothicFreeAim\_work\data\Scripts\Content\GFA\_intern
```

The configuration (`Content/GFA/config`), on the other hand, will not be linked to be modified by you. Likewise, most of the system scripts do not need adjustment and can be linked as well.

```cmd
cd path\to\Scripts\System
mklink /d GFA ..\..\..\..\.github\submodules\GothicFreeAim\_work\data\Scripts\System\GFA
```

The menu scripts, however, can be copied and placed in a separate file to adjust the menu positioning and language following the documentation.

The directory tree would like something like this:
```
.
├── .gitmodules
├── .github/
│   └── submodules/
│       └── GothicFreeAim/
│           └── ..
└── path/
    └── to/
        └── Scripts/
            ├── Content/
            │   └── GFA/
            │       ├── [_intern/]     <- symlink
            │       ├── config/
            │       │   └── ...
            │       └── GFA_*.src
            └── System/
                ├── [GFA/]             <- symlink
                └── Menu_Opt_GFA.d
```

When following these steps, this setup
- prevents you from accidentally modifying the internal scripts which should never be altered
- allows you to easily update the GFA core scripts in the event of an update with

  ```cmd
  git submodule update --remote
  git add .github\submodules\GothicFreeAim
  git commit -m "Update GFA core"
  ```
