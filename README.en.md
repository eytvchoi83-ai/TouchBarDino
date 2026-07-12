# Touch Bar Dino (TouchBarDino)

[한국어](README.md) · **English**

> **TouchBarDino** — An endless runner that lives on your MacBook's Touch Bar.
> Tap the strip to jump. That's the whole game.

![running](docs/screenshot-running.png)
![idle](docs/screenshot-idle.png)

A Chrome-dino-style runner that runs on your MacBook's Touch Bar.
Tap the strip to jump — that's the entire control scheme.
Too lazy to reach for the Touch Bar? Click the floating mini game window with your mouse instead.

- Uses the full Touch Bar width (420pt) as the play field, its OLED black blending into the bezel
- Speeds up over time, with clusters of cacti
- Saves your high score; one tap restarts instantly after a crash
- Taps fire the moment your finger lands (touch down) — no jump lag

## Install (download)

1. Download the latest `TouchBarDino-x.x.x.zip` from
   [Releases](https://github.com/eytvchoi83-ai/TouchBarDino/releases) and unzip it
2. Move `TouchBarDino.app` to your Applications folder
3. **First launch**: right-click the app → Open → confirm "Open"
   (needed once, since this free app isn't Apple-notarized)

## Build & run

```sh
./build.sh          # creates TouchBarDino.app
open TouchBarDino.app
```

The game appears on the Touch Bar right away.
Toggle it with the 🎮 button in the Touch Bar's control strip.

## Controls

**Tap** the game on the Touch Bar, or **click** the floating mini game window — same action.

| State | One tap/click |
|-------|---------------|
| Idle screen | Start the game |
| Playing | Jump |
| Game over | Restart (0.35s lockout to avoid double-tap misfires) |

The mini window floats on top and never steals focus.
Drag its background to move it; toggle it via menu bar 🎮 → "Show on-screen game window" (M).

## Sound

All chiptune, synthesized in code (no copyright worries, `scripts/make_sounds.py`):

- **Jump**: an upward sweep blip / **land**: a low thud / **death**: a descending melody
- **Background music**: a quiet C–Am–F–G 8-second loop — plays only while running,
  and stops automatically on game over or pause
- Toggle sound effects and music separately from the menu bar

## Menu bar (🎮 icon)

- Show/reset high score
- Show/hide game on Touch Bar (G), show on-screen game window (M)
- Toggle sound effects / background music
- Open log (`~/Library/Logs/TouchBarDino.log`), quit (Q)

## How it works

Same structure as TouchBarLyrics:

- Uses the private API (DFRFoundation, as in Pock) to present a system modal on the
  Touch Bar even when the app isn't focused
- On systems where custom views aren't composited, every frame (60fps) is baked to a
  2x bitmap and shown as a borderless NSButton image
- The game item is 420pt wide — anything wider is silently dropped from layout by
  NSTouchBar (a lesson learned in TouchBarLyrics)
- While playing, it periodically declares user activity to keep the Touch Bar from dimming

## Limitations

- Relies on private API, so it can break on macOS updates (same risk as Pock)
- Only meaningful on a MacBook Pro with a Touch Bar (2016–2020)

## Project structure

```
Sources/
  AppDelegate.swift        app logic, menu, 60fps game loop
  GameEngine.swift         physics, obstacles, collision, score (units in pt)
  GameRenderer.swift       frame → 2x bitmap rendering
  TouchBarController.swift Touch Bar item management + touch-down input
  TouchBarPrivate.swift    private API wrapper (same as TouchBarLyrics)
```
