# 🏺 Çini Ustası · Iznik Tile Puzzle (Godot 4)

**[▶ Play in your browser](https://furkiozknn.github.io/cini-ustasi-godot/)** · Türkçe & English · desktop & mobile · free, no install

🏟️ Part of **[Claude Game Arena](https://github.com/Furkiozknn/claude-game-arena)**, round 2: every model remakes its own
round-1 browser game in Godot 4. This one was rebuilt by **Claude Fable 5.1** from its Three.js original,
[Çini Ustası](https://github.com/Furkiozknn/cini-ustasi). [See all games and the scorecard →](https://furkiozknn.github.io/claude-game-arena/)

A calm 3D edge-matching puzzle set in a warm tile workshop. Rotate, swap and flip hand-painted Iznik
tiles until every tulip, carnation, saz leaf, rumi scroll and rosette connects across the board, then
watch the finished panel glaze, fire in the kiln and take its place on your wall.

This is the Godot 4 remake of the round-1 browser game (Three.js, single `index.html`) built for the
Claude Game Arena. Same rules, same 30 levels and names, same Turkish/English texts, now on a real engine:
real materials and a shadowed light, a tonemapped and fogged environment, particles, a save system,
settings, data-driven levels and a headless test suite.

| | |
|---|---|
| ![Title](docs/title.png) | ![Board](docs/board.png) |
| ![Kiln](docs/kiln.png) | ![Level complete](docs/end.png) |
| ![Levels](docs/menu.png) | ![Collection](docs/collection.png) |
| ![Settings](docs/settings.png) | ![Phone, 390×780](docs/phone.png) |

The screenshots in `docs/` are Movie Maker frames rendered by the game itself (see below).

## Features

- **30 levels in 3 chapters** (Apprentice / Journeyman / Master), each adding a mechanic: rotate, then
  swap, then fixed tiles, double-sided tiles and 6×6 boards. Plus a **Daily Tile** (4×4) that unlocks
  after chapter 1.
- **Every board is guaranteed solvable**: generated solved, then scrambled with a deterministic seed
  (the same seeds and boards as the browser version). Hints and the autoplay bot plan against that known
  solution, so a hint is instant even on a 6×6 board; a backtracking solver in the tests proves all 30
  levels and several daily boards can be solved from their start position.
- **Hand-painted motifs drawn in code**: five Iznik motifs in cobalt, turquoise, coral and emerald,
  rendered into a per-level texture atlas with Godot's 2D drawing API. The tile faces stay procedural on
  purpose: every motif must meet its twin exactly at the edge midpoint, in one of four exact colours.
- **Moves vs par, 1-3 stars**, a matched-edge counter ("Edges 18/24"), undo (undoing a hint gives it
  back), restart, three hints per level, best results per level and a "New record!" badge.
- **The kiln sequence**: a solved board glows, a glaze sweep shines across it, it lifts into the kiln
  while the camera pans along (fully in portrait, where the kiln is otherwise off-screen), fires with
  sparks and a camera shake, and the framed panel swings out to the gallery wall.
- **A living workshop**: generated 3D models (kiln, a sitting cat on the stool, a paint set), generated
  textures (terracotta floor, lime plaster, walnut table, kilim, the lake view through the window) and
  glaze reflections from a workshop panorama; dust motes in the window light, a flickering kiln, a gently
  drifting camera, 3D shadows, fog and filmic tonemapping (Compatibility renderer, runs on integrated
  GPUs and in the browser). The finished panels on the wall are two draw calls (one picture atlas, one
  merged frame mesh).
- **Synthesised audio**: an oud-like generative music loop on a Hicaz scale with a drone and a delay
  bus, plus clicks, chimes, the kiln's whoosh and a fanfare, all generated at start-up in GDScript.
- **Menus with transitions**, pause, **settings** (master/music/effects volume, language TR/EN, quality
  low/high, fullscreen; music and sound toggles on the title card, in the top bar and on `M` / `X`),
  toasts under the top bar (green edge for good news, coral for "not allowed"), a collection gallery and
  a level select with stars. Every button is reachable with the keyboard or a gamepad (turquoise focus
  ring, Enter / Space presses) and at least 44 px tall. "High" uses a
  2048 soft shadow map, 2× MSAA and glow; "low" (the default in the browser) a 1024 hard shadow map
  and neither MSAA nor glow, which is about half the GPU time on an integrated GPU.
- **Save system** in `user://` (progress and settings as JSON / ConfigFile), tolerant to malformed data.
- **Data in resources**: levels, chapters and the palette live in `.tres` files under `resources/`.

## Controls

| Action | Mouse / keyboard | Touch | Gamepad |
|---|---|---|---|
| Rotate a tile 90° | Click | Tap | — |
| Swap two tiles (chapter 2+) | Drag one onto the other | Drag | — |
| Flip a double-sided tile (chapter 3) | Right-click or `F` on the hovered tile | Long-press | X |
| Tilt the camera / zoom | Drag on the table / mouse wheel | Drag / pinch | — |
| Undo / hint / restart | `Z` / `H` / `R` | Top bar | B / Y |
| Pause / back | `P` or `Esc` | Top bar | Start |
| Music / sound effects on or off | `M` / `X` | Title card, top bar (sound) | — |
| Switch language | `L` or the EN/TR button | Button | — |
| Move between buttons / press | `Tab`, arrows / `Enter`, `Space` | — | D-pad / A |

All bindings live in the Input Map (`project.godot`). `F` stays "flip" (like Hisar keeps `F` for its own
action), so fullscreen is in Settings.

## Run

Requires Godot 4.7.2 (standard build, no C#).

```text
godot --path .                      # play
godot --path . -- --auto            # watch the bot play the whole game
godot --path . -- --level 22 --lang en
```

### Tests

```text
godot --headless --path . --scene res://tests/run_tests.tscn
```

Prints one final line, `TESTS PASSED n/n` or `TESTS FAILED k/n`, and exits with code 0 or 1.
The tests cover the RNG and hash references, level generation validity for all 30 levels, the
evaluator, move planning, the solver (all levels and several daily boards), hints (planned against the
known solution, undo gives them back), scoring, the record badge, the wall order after a replay, toast
kinds, the brush cylinder orientation, the fit of the generated models, the progress format and the
GameState flow. They never touch the player's save data.

### Autoplay bot

```text
godot --headless --path . -- --auto --no-save --quit-on-done --speed 8
```

Prints `BOT DONE levels=30 stars=90 errors=0` and the final `GameState.get_state_text()` JSON.

### Movie Maker (visual check without export templates)

```text
godot --path . --write-movie %TEMP%\frames\f.png --fixed-fps 30 --quit-after 300 -- --auto --no-save --level 3 --solve
```

For a 390×780 portrait check, temporarily add an `override.cfg` next to `project.godot`:

```ini
[display]
window/size/viewport_width=390
window/size/viewport_height=780
```

## User arguments (after `--`)

| Argument | Effect |
|---|---|
| `--auto` | The bot plans every level against its known solution, plays the moves one by one through the player API and moves on through the whole game |
| `--solve` | With `--auto`: apply the whole solution at once (jump straight to the kiln sequence) |
| `--quit-on-done` | With `--auto`: exit with code 0 when done (1 if the bot hit an error) |
| `--stop-after N` | With `--auto`: stop after level N (0-based index) |
| `--no-save` | Never read or write `user://` (fresh in-memory progress and settings) |
| `--fill` | Start with all 30 levels completed (collection and gallery full) |
| `--level N` / `--level daily` | Jump straight into a level |
| `--screen levels\|collection\|settings\|howto\|pause` | Open a screen at start (`--ch N` picks the how-to chapter) |
| `--lang en\|tr` | Interface language |
| `--quality low\|high` | Graphics quality for this run |
| `--web-sim` | Apply the browser defaults natively (quality `low` unless the player chose otherwise) |
| `--stats` | Print frame time, draw calls and primitives every 60 frames (and the synth timing) |
| `--speed X` | `Engine.time_scale` (fast-forward for bot runs) |
| `--nohowto` | Skip the chapter how-to cards |
| `--mute` | Silence the audio and skip sample synthesis |
| `--noassets` | Ignore the generated models and textures (procedural fallback for everything) |
| `--keyboard` | Start as if the last input came from the keyboard (focus rings show; for screenshots) |
| `--debug` | Draw calls, fps, state and bot status overlay |

`GameState.get_state_text()` returns the whole game state as JSON (screen, level, moves, par, stars,
hints, slots, progress summary, bot status).

## Project layout

```text
scenes/main.tscn            main scene (everything is built in code from main.gd)
scripts/autoload/           Loc (TR/EN strings), Settings, GameState (rules + progress), Audio (synth)
scripts/core/               pure puzzle logic: RNG, generation, evaluation, solver (tests), moves
scripts/data/               Resource classes: LevelDef, ChapterDef, LevelSet, PaletteDef
scripts/render/             motif painter, texture baker (SubViewport), tile mesh, mesh builder
scripts/game/               world builder, board, tiles, camera, kiln sequence, gallery, cat, input, bot
scripts/ui/                 theme, HUD, screens, toasts
resources/                  levels/*.tres, chapters/*.tres, level_set.tres, palette.tres
tests/run_tests.tscn        headless test runner
assets/models/              kiln.glb, cat.glb, paint-set.glb (+ their extracted textures)
assets/textures/            floor, plaster, wood, kilim, window view, reflection panorama (WebP)
assets/ui/                  crest (title 256 px, HUD 64 px) and the 32 px project / favicon icon
export_presets.cfg          "Web" preset (threads off, VRAM compression desktop + mobile)
```

## Web export

The `Web` preset exports to `build/web/index.html` with thread support off (so it works on GitHub
Pages without cross-origin isolation headers) and VRAM texture compression for desktop and mobile.
No editor step is needed: `godot --headless --path . --export-release Web build/web/index.html`.

## How it was made

Round 2 of a series in which **every game is built by a different AI model**. Each model gets the same brief,
[`prompts/godot-remake.md`](https://github.com/Furkiozknn/claude-game-arena/blob/main/prompts/godot-remake.md):
remake your own round-1 game in Godot 4.7 (GDScript, Compatibility renderer) and make it better, not just equal.
This one was built by **Claude Fable 5.1** (`claude-fable-5-1`) with [Claude Code](https://claude.com/claude-code).
The orchestrating session re-ran the checks independently before release:

- `TESTS PASSED 21/21`, clean headless import (no errors or warnings).

The overnight pass of 2026-10-21 (Claude Opus 5.5, see `CHANGELOG.md`) brought in the generated assets
and the browser version's fixes and UI structure: `TESTS PASSED 28/28`, `BOT DONE levels=30 stars=90
errors=0`.
- The `--auto` bot solves every level: `BOT DONE levels=30 stars=90 errors=0`.

The web build is exported on GitHub's servers by [`.github/workflows/pages.yml`](.github/workflows/pages.yml)
(pinned, checksum-verified Godot 4.7.2 and export templates) and published to GitHub Pages.

## License

Code: MIT. Audio and the tile art are generated procedurally by the code in this repository.

## Assets

The 3D models were generated with Higgsfield Tripo and the textures and crest with GPT Image (via the
Higgsfield MCP), processed with glTF-Transform, and are **shared with the browser version**
([Çini Ustası](https://github.com/Furkiozknn/cini-ustasi), its `docs/assets.md` lists the prompts).
Placement here matches the browser version:

| File | Used as | Transform |
|---|---|---|
| `models/kiln.glb` | the kiln | turned −90° about Y (the file faces +X), uniform scale to 2.4 m depth (≈ 2.16 × 2.09 × 2.4 m), base centre (4.55, 0, −2.95); the glow quad sits 0.18 m inside its front face, the board flies into the arched mouth, the fired panel comes out in front of it |
| `models/cat.glb` | the cat on the stool | 0.46 m tall, on the stool seat (−4.2, 0.63, 1.4), yaw −0.54 rad ± 0.3 head turn, breathes (scale.y ± 1.5 % at 0.3 Hz), appears after 4 s, stays 18-32 s, away 25-55 s |
| `models/paint-set.glb` | jar, brushes and pots on a tray | no turn, 0.6 m deep, base centre (2.68, 1.0, 1.5); replaces the procedural pots and brushes |
| `textures/floor-terracotta.webp` | floor | one 16 × 12 m plane, repeat (8, 6) |
| `textures/plaster.webp` | the three walls | repeat (4, 1.7), tint `#fbf3e3` |
| `textures/wood.webp` | table top | repeat (1.5, 1) |
| `textures/kilim.webp` | kilim on the left wall | 1.6 × 1.8 m plane facing +X at (−5.975, 2.4, −3.1) |
| `textures/window-view.webp` | window glass | unlit 2.6 × 1.7 m quad at (−4.0, 2.85, −4.195) |
| `textures/workshop-pano.webp` | glaze reflections only | `PanoramaSkyMaterial` (energy 0.45, radiance 128) as the reflection source; background and ambient stay the room colours |
| `ui/crest-256.webp`, `ui/crest-64.png`, `ui/favicon.png` | title crest, HUD mark, project / web icon | — |

Everything falls back to the procedural version when a file is missing or with `--noassets`.
