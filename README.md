# Familiar

**GNOME, Plasma, and Mac desktop metaphors — on Omarchy, on Hyprland.**

Familiar is a single plugin that swaps the *feel* of the shell: bar, dock, launcher, overview, and window switcher. It keeps Omarchy’s theme, menu, notifications, and lock screen. It does not ship brand icons, fonts, or wallpapers.

[![License: MIT](https://img.shields.io/badge/license-MIT-0ea5e9.svg)](LICENSE)
[![Omarchy](https://img.shields.io/badge/Omarchy-Quattro_4.0.2-111827.svg)](https://omarchy.org)
[![Hyprland](https://img.shields.io/badge/Hyprland-Lua-0ea5e9.svg)](https://hypr.land)
[![Plugin](https://img.shields.io/badge/id-io.github.tuxclaw.familiar-6366f1.svg)](https://github.com/tuxclaw/familiar)

Repo: [github.com/tuxclaw/familiar](https://github.com/tuxclaw/familiar)

> Independent software. Not affiliated with, endorsed by, or sponsored by Omarchy, GNOME, KDE, Plasma, or Apple. Those names describe interaction paradigms only.

## Contents

- [What it is](#what-it-is)
- [Status](#status)
- [Install](#install)
- [Profiles](#profiles)
- [Using it](#using-it)
- [Hyprland Lua](#hyprland-lua)
- [Configuration](#configuration)
- [Architecture](#architecture)
- [Develop](#develop)
- [Uninstall](#uninstall)
- [Limits](#limits)
- [License](#license)

## What it is

One plugin id, three kinds:

| Kind | File | Role |
|---|---|---|
| `bar` | `Bar.qml` | Full top/bottom bar replacement |
| `overlay` | `Overlay.qml` | Dock + launcher + overview + switcher (IPC surface) |
| `service` | `Service.qml` | Active profile, `shell.json` persistence |

It never declares `panel` — Omarchy prefers panel over overlay for summon, and that would hide the dock.

Target runtime: **Omarchy 4.0.2 Quattro** (`omarchy-shell`, one Quickshell process) on **Hyprland 0.56.2** (Lua config, not Hyprlang).

## Status

| Milestone | What | State |
|---|---|---|
| M0 | Manifest, service, overlay IPC, profile JSON, Lua fragments, tests | Done |
| M1 | Profile bars + stock Omarchy widget host | Done |
| M2 | Overlay dock, pins, running apps, autohide | Done |
| M3 | Launcher (grid / kickoff / spotlight) + dock Applications tile | Done |
| M4 | Overview + switcher | Done in tree |
| M5 | Motion polish, `preview.png`, marketplace | Not started |

Current work branch: `andy/m4-overview`. GitHub default is still `andy/m1-bars` — clone the M4 branch until `main` exists.

## Install

```sh
# Until default branch is main, clone the current work branch:
git clone -b andy/m4-overview \
  https://github.com/tuxclaw/familiar.git \
  ~/.config/omarchy/plugins/io.github.tuxclaw.familiar

omarchy plugin validate ~/.config/omarchy/plugins/io.github.tuxclaw.familiar
omarchy bar use io.github.tuxclaw.familiar
omarchy restart shell
```

Later, when `main` is the default:

```sh
omarchy plugin add https://github.com/tuxclaw/familiar.git --enable --yes
omarchy bar use io.github.tuxclaw.familiar
```

Plugin directory **must** be `~/.config/omarchy/plugins/io.github.tuxclaw.familiar` — that id is the live contract, not the GitHub repo name.

## Profiles

Switch with:

```sh
omarchy-shell shell call io.github.tuxclaw.familiar setProfile gnome
omarchy-shell shell call io.github.tuxclaw.familiar setProfile plasma
omarchy-shell shell call io.github.tuxclaw.familiar setProfile macos
omarchy-shell shell call io.github.tuxclaw.familiar cycleProfile ''
omarchy-shell shell call io.github.tuxclaw.familiar getProfile ''
```

| | GNOME | Plasma | Mac |
|---|---|---|---|
| Bar | Top, 32px. Activities + pips | Bottom, 40px. Applications + tasks | Top, 28px. App menu + active app |
| Dock | Off in profile JSON; enable with `bar.dockEnabled=on` | Off | On, magnify, bottom |
| Launcher | App grid | Kickoff list | Spotlight list |
| Overview | Activities | Present Windows | Mission Control |
| Switcher | App row | Window thumbs | App row |

GNOME’s bar has **no Applications button**. Open the launcher from the **dock Applications tile** (last icon on the right; hover the bottom edge if autohide is on).

Omarchy menu stays on **Super+Alt+Space** in every profile.

## Using it

Summon overlay surfaces (JSON string, hits `Overlay.qml`):

```sh
omarchy-shell shell summon io.github.tuxclaw.familiar '{"surface":"launcher"}'
omarchy-shell shell summon io.github.tuxclaw.familiar '{"surface":"overview"}'
omarchy-shell shell summon io.github.tuxclaw.familiar '{"surface":"switcher","scope":"app"}'
omarchy-shell shell summon io.github.tuxclaw.familiar '{"surface":"switcher","scope":"window"}'
omarchy-shell shell toggle io.github.tuxclaw.familiar '{"surface":"launcher"}'
omarchy-shell shell hide   io.github.tuxclaw.familiar
```

Launcher: type to filter, arrows to move, Enter to launch, Escape to close. Ranking is prefix → word-start → fuzzy, then frecency at `~/.local/state/familiar/frecency.json`. Omarchy menu commands appear after two characters.

Click **Activities** on the GNOME bar for overview.

## Hyprland Lua

Familiar never writes Hyprlang. It concatenates `hypr/common.lua` + `hypr/<profile>.lua`.

Generate (GNOME example):

```sh
./tests/hypr.sh --profile gnome --output ~/.config/hypr/familiar.lua
```

In `~/.config/hypr/hyprland.lua`, insert **immediately after** `require("hypr.looknfeel")` — never after bindings:

```lua
require("hypr.familiar") -- familiar:require
```

Then:

```sh
hyprctl reload
hyprctl configerrors
```

Dock autohide keeps the layer mapped. Compositor blur uses `ignore_alpha = 0.2` so a hidden dock does not leave a blur ghost.

`Service.qml` `applyHypr()` is still **skipped** on the live path. Profile switch does not rewrite `familiar.lua` until that gate is lifted. Disable should leave a loadable no-op so the `require` never 404s.

### GNOME keybinds (when `familiar.lua` is loaded)

| Key | Familiar | Replaces |
|---|---|---|
| Super tap | Overview | Super-only |
| Super+A | Launcher | — |
| Alt+Tab | App switcher | Next window |
| Super+S | Overview | Omarchy scratchpad |
| Super+Shift+F | Cycle profile | — |
| Super+Space | *(unchanged)* | Omarchy menu |

Plasma and Mac fragments rebind a different set (`hypr/plasma.lua`, `hypr/macos.lua`). Mac takes **Super+Space** for Spotlight-style launcher — unbind first.

## Configuration

Persisted in `~/.config/omarchy/shell.json` on the `bar:` object (Familiar is the active bar). Extra keys survive host saves.

| Key | Values | Notes |
|---|---|---|
| `bar.id` | `io.github.tuxclaw.familiar` | Active bar |
| `bar.profile` | `gnome` `plasma` `macos` | |
| `bar.dockEnabled` | `auto` `on` `off` | `auto` → profile default |
| `bar.dockAutohide` | `auto` `on` `off` | Needs `omarchy restart shell` to remount |
| `bar.dockPinned` | comma-separated desktop ids | e.g. `chromium,org.gnome.Nautilus,obsidian` |
| `bar.dockPosition` | `auto` `bottom` `left` `right` | |
| `bar.dockIconSize` | integer | |
| `bar.dockMagnification` | `auto` `on` `off` | |

`service.resolved()` is **not** reactive. Dock enable/autohide changes need `omarchy restart shell`.

## Architecture

```
omarchy-shell (Quickshell)
└─ io.github.tuxclaw.familiar
   ├─ service   profile store ──► ~/.config/hypr/familiar.lua
   ├─ overlay   dock + open(payload) → launcher | overview | switcher
   └─ bar       full bar; stock widgets via barWidgetRegistry
```

Theme comes from `qs.Commons.Color` / `Style` (already loaded from Omarchy’s current theme). Familiar does not parse TOML.

## Develop

```
familiar/
├── manifest.json
├── Bar.qml Overlay.qml Service.qml Familiar.qml
├── profiles/{gnome,plasma,macos}.json
├── hypr/{common,gnome,plasma,macos}.lua
├── ui/bar  ui/dock  ui/launcher  ui/overview  ui/switcher
├── lib/Apps.js
└── tests/{validate.sh,hypr.sh}
```

```sh
./tests/validate.sh
./tests/hypr.sh
```

`qmllint` is `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell`.

Plugin QML under `~/.config/omarchy/plugins/` hot-reloads on save. **New files / new QML types often need** `omarchy restart shell`. Do not spawn a second `quickshell`.

Hard rules learned on this box:

- Never `required` on `omarchyPath` / `barWidgetRegistry` / `barConfig` (host injects after create).
- Never assign Loader `implicitHeight` / `implicitWidth` (read-only; bar vanishes).
- Host fallback bug: if Familiar fails to load, `shell.qml` `errorString` is undefined and the bar is gone. Revert: `omarchy bar use omarchy.bar`.

## Uninstall

```sh
omarchy bar use omarchy.bar
omarchy-shell shell call io.github.tuxclaw.familiar uninstall ''
omarchy plugin disable io.github.tuxclaw.familiar
omarchy plugin remove io.github.tuxclaw.familiar
```

Remove the guarded `require("hypr.familiar")` from `hyprland.lua` if you added it. Backup from this machine: `~/.config/hypr/hyprland.lua.bak.familiar.20260904153012`.

## Limits

- Plugins run **unsandboxed**. Familiar does no network and no `sudo`.
- No `preview.png` yet.
- Overview thumbs cap live `ScreencopyView` at 12.
- Switcher commits on modifier release when detected, else 1.2s fallback.
- Drag-to-workspace in overview is not guaranteed.
- Not listed on plugins.omarchy.org yet.

## License

MIT. See [LICENSE](LICENSE).
