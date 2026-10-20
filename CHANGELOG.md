# Changelog

## 2026-10-21 overnight pass

Ported the browser version's overnight pass (generated assets, fixes, UI structure) and fixed the Godot
bugs from the arena review. Checked with `TESTS PASSED 28/28` (was 21/21), `BOT DONE levels=30 stars=90
errors=0`, a clean headless import and Movie Maker frames (title, board, kiln, end card, levels,
collection, settings, pause, 390×780 portrait).

### Fixed
- Hints and the autoplay bot no longer run the backtracking solver on the main thread: they plan against
  the level's known solution (O(N)), so a hint on a 6×6 board is instant. The solver stays for the tests.
- Undoing a hint gives the hint back.
- Brush cylinders: X is now applied before Y, so the three handles fan out and the collars and tips sit
  on their handles (all handles used to point straight along +Z with the tips floating beside them).
- Window glass sits in front of the wall (it was 4 cm inside it, so the window showed the wall colour).
- Plate rims sit on the plates' front face (x 5.52 / 5.515) instead of inside the discs.
- Props clear the board: pots at x 2.4-3.0, the cloth (now 0.5 m wide) and the tile stack at x −2.65;
  the kiln moved to x 4.55 so it no longer cuts the shelf.
- Restart reuses the level's tile atlas: the tiles no longer vanish for a few frames.
- The collection bakes its pictures one after another (cached ones appear at once) and the picture cache
  drops the least recently used entry instead of clearing itself.
- The wall gallery is two draw calls (one 6 × 2 picture atlas composed from the cached pictures, one
  merged frame and nail mesh) instead of about 36.
- Replaying a panel that is no longer among the 12 on the wall hangs it up again as the newest one.
- Level generation moves on to seed + 1 if every attempt fails (same rule as the browser version; the
  30 levels and the dailies are unchanged).
- Esc on the end card goes to the title screen; the UI no longer refreshes twice per solve.

### Assets (shared with the browser version)
- Kiln, cat and paint-set GLBs, floor / plaster / wood / kilim / window-view textures, the reflection
  panorama and the crest, with the browser version's transforms (see the README's Assets table).
- The procedural room parts they replace are only built when a file is missing or with `--noassets`.
- The cat now sits on the stool next to the table (appears, breathes, turns its head, leaves); the box cat
  on the shelf remains as the fallback.
- The kiln model casts a shadow; the board flies into its arched mouth and the fired panel swings out in
  front of it before heading for the wall.

### UI and controls (shared design language)
- Keys: `P` / `Esc` pause and back, `M` music, `X` sound, `L` language, `F` flip the hovered tile.
- Music and sound toggles (title card, HUD sound button, keys), saved in `settings.cfg`.
- Every button, level card, slider and switch is keyboard / gamepad reachable with a turquoise focus ring;
  each card focuses its main button (the ring only shows after a key press). Buttons and icon buttons are
  at least 44 px.
- HUD: matched-edge counter ("Kenar 11/84"), crest mark, sound button; on phones help and settings move
  to the pause menu and the level lines shrink with an ellipsis.
- End card: "New record!" badge when the best result improved, Title screen button.
- Toasts stack under the top bar with an emerald (good) or coral (bad) edge.
- Title: generated crest, sound and music toggles, footer "Claude Game Arena · built by Claude Fable 5.1 ·
  assets remastered". Pause menu in the shared order (Resume; Restart, Settings; Levels, Collection;
  Title screen).
- Camera: kiln focus = (mouth − target) × 0.95, applied at 0.22 in landscape (was 0.35); in portrait the
  camera also backs off to 1.15 × distance and follows the panel to the wall.
- Defaults for new players: master 0.8, music 0.6, effects 0.8, language from the OS.
- Restart toast "Pano baştan başladı" / "Board reset"; how-to lines mention `P` and `F`.

### Performance (`--web-sim`, level 30, 1280×720, Intel UHD)
- GPU 9.8-10.0 ms per frame (was 10.0-10.1), 225 draw calls (was 210); with a full wall 228 (was 270).
- Start-up is about 0.4 s longer (three GLBs and the reflection radiance map).

### Not done
- Blurred pause backdrop, `<kbd>`-style key caps in the how-to card, atlas padding against mip bleeding
  on the tile bevel (review G13; not visible in the frames checked).
