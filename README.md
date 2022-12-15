# Witcher3Mods

The source of Phaz42's mods for The Witcher 3: Wild Hunt, as released on Nexus Mods. One folder per mod, holding the mod's files as its release archive holds them, plus the string sources it was built from.

This repository holds source only, no downloads. The mods themselves, with their descriptions, pictures and release notes, are on Nexus Mods.

```text
<Mod-Name>/mod<Name>/     the mod as released: mods/mod<Name>/content/... and, where it has a menu, bin/...
<Mod-Name>/W3Strings/     the strings' CSV sources, where the mod has strings
```

## The mods

| Mod | Folder | What it does |
|---|---|---|
| [Alternate Horse Controls](https://www.nexusmods.com/witcher3/mods/8192) | `Alternate-Horse-Controls` | An alternative, more immersive, way to control your horse, with a full options menu that lets you toggle mod features on/off. |
| [Better Torches Next-Gen](https://www.nexusmods.com/witcher3/mods/7186) | `Better-Torches-Next-Gen` | Ride your horse, cast signs, heavy attack, sail, block, parry and climb while holding a torch. |
| [Better Walking](https://www.nexusmods.com/witcher3/mods/8293) | `Better-Walking` | Walk, Run and Sprint, lock to each speed and switch speeds more easily. Both on Controller and Keyboard. |
| [Faster Boat](https://www.nexusmods.com/witcher3/mods/8320) | `Faster-Boat` | Sail significantly faster around Skellige and the Continent. No need to Fast Travel so often because sailing takes toooo long! |
| [Geralt Level Scales - Difficulty Add-on](https://www.nexusmods.com/witcher3/mods/8326) | `Geralt-Level-Scales-Difficulty-Addon` | Adds a menu with an (extra) difficulty slider to use with the "Geralt Level Scales" mod. |
| [Golden Hour](https://www.nexusmods.com/witcher3/mods/8429) | `Golden-Hour` | This is a bit of a strange one: Photo Mode Assistant, Weather Manager, Time dilation controller. |
| [Minimalist Camera](https://www.nexusmods.com/witcher3/mods/8357) | `Minimalist-Camera` | EXPLORATION: Smooth minimalist lazy cam. COMBAT: Dynamic zoom in 8 levels, new camera effects for dodging/rolling/signs. 4 camera range presets. |
| [Minimalist Witcher Senses](https://www.nexusmods.com/witcher3/mods/8358) | `Minimalist-Witcher-Senses` | A minimalist version of Witcher Senses (Focus) with most of the special effects removed. |
| [No Road Following](https://www.nexusmods.com/witcher3/mods/7228) | `No-Road-Following` | Stop horses from automatically following the road. |
| [Obedient Steed](https://www.nexusmods.com/witcher3/mods/7209) | `Obedient-Steed` | Don't get your horse stuck on obstacles and ignore city speed limits. |
| [One for the Road](https://www.nexusmods.com/witcher3/mods/8383) | `One-For-The-Road` | Easily Quick Save and Quick Load your game from the menu or with keyboard/controller shortcuts. |
| [Remember to Sheathe](https://www.nexusmods.com/witcher3/mods/8331) | `Remember-To-Sheathe` | Helps forgetful Geralt to remember to sheathe his sword after combat. |
| [Turn On The Lights](https://www.nexusmods.com/witcher3/mods/7278) | `Turn-On-The-Lights` | Automatically or manually turn lights around Geralt/Ciri ON or OFF. |
| [Tweaks Light (Lite)](https://www.nexusmods.com/witcher3/mods/8388) | `Tweaks-Light` | Tweak your graphics settings in much more detail! |

## How the files are made

Every mod replaces whole game script files, with its changes marked: an added line ends in `// modName`, an added block sits between `// modName START` and `// modName END`, a disabled line is commented out in place, and a changed line is replaced in place, marked. Lines not marked are the game's own, byte for byte, so that a merge tool (Script Merger, or SM-FAE) sees exactly the mod's edits. See NOTICE for what that means for the files' ownership, and LICENSE for the terms of the author's own work.

Each version is built against the game version named in its release notes. A version for a newer game is produced by laying the previous version's marked edits onto the newer game's scripts; nothing is edited by hand that a merge can do.

## How this history was built

The mods were developed outside git, one folder per released version, from 2022 on. This repository was created in October 2026 from those folders: each released version became a commit on top of the previous one, in release order across all mods, with the author and committer dates set to the version's release date on Nexus Mods and a tag `<Mod-Name>-<version>` on each. So the history is backdated, best effort: it shows what changed between releases, not the work in between. The oldest releases, whose folders were gone, were taken from their release archives; versions that were never published are not here.
