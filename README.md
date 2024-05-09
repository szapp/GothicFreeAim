<div align="center">

[![Gothic Free Aim](https://github.com/szapp/GothicFreeAim/wiki/media/GFA_TITLE_LARGE_FA_trans.png)](https://github.com/szapp/GothicFreeAim)

[![Documentation](https://img.shields.io/badge/docs-wiki-blue)](https://github.com/szapp/GothicFreeAim/wiki)
[![GitHub release](https://img.shields.io/github/v/release/szapp/GothicFreeAim.svg)](https://github.com/szapp/GothicFreeAim/releases/latest)
[![Combined downloads](https://api.szapp.de/downloads/gfa/total/badge)](https://github.com/szapp/GothicFreeAim/releases)
[![Steam Gothic 1](https://img.shields.io/badge/steam-Gothic%201-2a3f5a?logo=steam&labelColor=1b2838)](https://steamcommunity.com/sharedfiles/filedetails/?id=2786959658)
[![Steam Gothic 2](https://img.shields.io/badge/steam-Gothic%202-2a3f5a?logo=steam&labelColor=1b2838)](https://steamcommunity.com/sharedfiles/filedetails/?id=2786958841)

**Script package for the Gothic video game series that enables free aiming for ranged weapons and spells.**
*Gothic, Gothic Sequel, Gothic II, Gothic II: Night of the Raven*

<br />

[![Trailer on Youtube](https://raw.githubusercontent.com/wiki/szapp/GothicFreeAim/media/thumb_small.jpg)](https://www.youtube.com/watch?v=9CrFlxo21Qw)
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

After adding GFA as submodule into a suitable sub-directory in your repository, refer to the relevant sub-directories using relative symlinks.
Symlinks are supported in git (also in Windows) and will resolve the file paths as desired.

The following is done in the Windows Command Prompt with administrative privileges (for creating symlinks).

```cmd
mkdir .github\submodules
git submodule add -b https://github.com/szapp/GothicFreeAim.git .github\submodules\GothicFreeAim
git config core.symlinks true
```

Now, you can add relevant symlinks to desired sub-directories within the GFA scripts.

```cmd
mklink /d path\to\Scripts\GFA\_intern .github\submodules\GothicFreeAim\_work\data\Scripts\Content\GFA\_intern
```
