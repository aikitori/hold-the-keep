# Hold the Keep

[![Pages](https://github.com/aikitori/hold-the-keep/actions/workflows/pages.yml/badge.svg)](https://github.com/aikitori/hold-the-keep/actions/workflows/pages.yml)
[![License: GPL v3](https://img.shields.io/badge/license-GPL--3.0--or--later-blue.svg)](LICENSE)
![Godot 4.7](https://img.shields.io/badge/Godot-4.7-478cbf.svg)

**An isometric medieval tower defense game, inspired by the classic Warcraft III tower defense maps.**

The dead march from the graveyard to your keep. You build towers and walls, shape the ground into mazes,
and hold out for 30 waves of skeletons, orcs, ghouls, necromancers, flying ghosts and vampire bosses.

**[Play in the browser](https://aikitori.github.io/hold-the-keep/)** ·
**[Android APK (alpha)](https://github.com/aikitori/hold-the-keep/releases)**

> Status: alpha. The game is playable from start to finish, but values and content are still changing.

## Features

- **Maze building.** On open maps you wall off and lengthen the enemy path as much as you like. The one rule:
  the way to the keep may never be blocked completely, and no enemy may be trapped.
- **16 buildings.** Walls, archers, spearmen, ballistae, catapults, mages, anti-air, a trebuchet, poison,
  pitch, a war banner, a war horn, a bell and a toll house for income.
- **Upgrades and specialisations.** Three levels per tower, and on level 3 a choice between two
  specialisations.
- **Varied enemies.** Armored knights, healing ghouls, burrowing gravers, shield bearers, berserkers,
  necromancers who summon skeletons, and flyers that ignore your maze. Bosses every five waves.
- **Four maps** with different ideas of what a maze is (see below), three difficulty levels and endless
  play after wave 30.
- **Plays anywhere.** Mouse and keyboard, or touch with a scaled-up interface (phone, tablet, portrait and
  landscape). Saves between waves, German and English UI, music and sound effects.

## Maps

| Map | Idea |
|---|---|
| Four Fields | Four build areas joined by fixed paths, each asking for its own maze |
| Round Trip | A lap around a plateau through four checkpoints, like Circle TD |
| Serpent Path | A fixed winding path; you build beside it on the plateau |
| Open Field | An open field where checkpoints send the enemies across it again and again |

## How to play

- Pick a tower in the build bar, then click a grass tile. Hold Shift to keep building.
  On touch devices, the first tap shows a preview and the second tap on the same tile builds.
- Drag a tower out of the build bar onto the map, or drag across tiles to build a row of walls.
- Tap a tower to upgrade, specialise or sell it. Tap an enemy to see what it can do.
- Move the camera with right-drag, WASD or arrow keys, or by pushing the mouse to the screen edge.
  Zoom with the mouse wheel or two fingers, rotate in quarter turns with Q and E.
- "Next wave" calls the wave early for bonus gold.

The full rules, enemy list, tower values and controls are in [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md)
(written in German).

## Building from source

You need [Godot](https://godotengine.org) 4.7.2 (standard build, no .NET). The project is pure GDScript and
uses the Compatibility renderer, so it runs on Android and in the browser.

```bash
git clone https://github.com/aikitori/hold-the-keep.git
cd hold-the-keep
godot --headless --import                              # first time only
godot res://scenes/menu.tscn                           # play
godot --headless res://scenes/dev/logic_test.tscn      # run the tests, look for "LOGIC-TEST OK"
```

`tools/install_godot.sh` downloads Godot, and `tools/build_android.sh` builds a debug APK (needs JDK 17 and
the Android SDK). Releases are built by GitHub Actions when an `alpha-X.Y.Z` tag is pushed; the web version
is deployed from `main` to GitHub Pages.

Balance work: `godot --headless res://scenes/dev/balance.tscn -- <map> [easy|normal|hard]` lets a bot play
30 waves, and `dps.tscn` prints damage per second and per gold for every tower.

## Contributing

Issues and pull requests are welcome. Please read [CLAUDE.md](CLAUDE.md) first: it describes the code layout
and pitfalls (code comments and commit messages are in German, all UI text goes through `tr()` / `Lang.t()`
with an English translation in `scripts/lang.gd`). Run the logic test before sending a change, and record
new features in [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md).

## License

Code: GNU General Public License v3.0 or later, see [LICENSE](LICENSE). Copyright (C) 2026 aikitori.

Assets, all under free licenses:

- 3D models by [Kenney](https://kenney.nl) (CC0): Tower Defense Kit, Castle Kit, Mini Dungeon, Graveyard Kit.
  License texts are in `assets/models/*/License.txt`.
- Font: MedievalSharp by wmk69, SIL Open Font License (`assets/fonts/OFL.txt`).
- Sound effects and music jingles (CC0): Kenney (RPG Audio, Impact Sounds, Interface Sounds, Music Jingles)
  and rubberduck on OpenGameArt (80 CC0 RPG SFX, 100 CC0 SFX). Sources are listed in `tools/import_sfx.py`.
