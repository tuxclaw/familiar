# Familiar — desktop-paradigm plugin for Omarchy (Quattro)

**Plugin ID:** `io.github.tuxclaw.familiar`
**Target runtime:** Omarchy 4.0.2 Quattro shell (`omarchy-shell`, single long-running Quickshell process) on Hyprland 0.56.2
**Status:** Spec v0.2 — 2026-09-04
**Author:** Dan (@tuxclaw)

---

## 0. One-paragraph summary

Familiar is a single Omarchy plugin that swaps the shell's *desktop paradigm* between three profiles — **GNOME**, **Plasma** (KDE), and **Mac** — without replacing Omarchy's theming, menu, or keybind philosophy. It ships three plugin kinds under one ID: a full **bar** replacement, a keep-loaded **overlay** that hosts the dock windows and routes summons to the launcher / overview / window switcher, and a headless **service** that owns the active profile, writes a profile-specific Hyprland Lua fragment, and reloads the compositor. Profiles are pure data (JSON) over one shared component set, so adding a fourth paradigm later is a new JSON file plus a Lua fragment, not new QML.

---

## 1. Platform facts the design depends on

Everything below was verified on Omarchy 4.0.2-1 / Hyprland 0.56.2; the design leans on it rather than working around it.

| Fact | Consequence for Familiar |
|---|---|
| The shell is one Quickshell process; every plugin loads into it. | Never spawn a second `quickshell`. Familiar's dock, bar, overlay are all Items inside `omarchy-shell`. |
| Plugin = git repo with `manifest.json` at root, cloned to `~/.config/omarchy/plugins/<id>/`. | One repo, one ID, multiple `kinds`. Precedent: `omarchy.menu` declares `menu` + `bar-widget`, `omarchy.media` declares `service` + `bar-widget`. |
| Kinds: `bar-widget`, `panel`, `overlay`, `menu`, `service`, `bar`. `computePanelEntries()` prefers **panel over overlay** for the same id. Only one `bar` active; fallback is `omarchy.bar`. | Familiar declares `bar`, `overlay`, `service` and **never** `panel`. The dock is a child of the overlay, not its own kind. Disabling Familiar restores stock Omarchy. |
| `summon`, `hide`, `toggle`, and `call` all resolve through `shell.callIfLoaded` to the plugin's **panel/overlay/menu Loader item**, not to the service. `open` receives a **JSON string**. | `Overlay.qml` is the IPC surface. It exposes `open(payloadJson)`, `close()`, and the profile methods, and forwards profile work to the injected `service`. |
| Separate Loaders do not share plugin singletons. The host injects `service` into the overlay (`shell.serviceFor(id)`); the bar can reach it via injected `shell.serviceFor(manifest.id)`. | Profile state lives on the **service instance**. No `pragma Singleton` state bus. |
| `shell.json` is the only persisted config; settings are inline on the plugin entry; no merge layers. `barConfig` injected into a custom bar is the whole `bar:` subtree, so extra keys like `profile` survive. | Profile choice lives on the `bar` entry (`bar.id` = Familiar, `bar.profile` = `"macos"`). Overlay and bar read it through the service. |
| Hyprland config is **Lua**: `~/.config/hypr/hyprland.lua` requires `hypr.monitors`, `hypr.input`, `hypr.looknfeel`, `hypr.bindings`, `hypr.autostart`. Package path includes `~/.config/?.lua`. APIs: `hl.config`, `hl.curve`, `hl.animation`, `hl.layer_rule`, `hl.unbind`, `o.window`, `o.bind(keys, label, cmd, opts)`. Key strings are `"SUPER + SPACE"`. No `bindr`; release binds are `{ release = true }`. | Familiar writes `~/.config/hypr/familiar.lua` and adds one guarded `require("hypr.familiar")` to `hyprland.lua` after the `looknfeel` / `bindings` requires. Never emits Hyprlang. |
| Theme: `~/.local/state/omarchy/current/theme/colors.toml` + `shell.toml`, already loaded by `qs.Commons.Color` and `qs.Commons.Style`. | Familiar binds `Color.*` and `Style.*` directly. No TOML parser in the plugin. |
| Manifest schema `type` vocabulary used by first-party manifests: `string`, `integer`, `boolean`, `enum`, `path`, `multiselect`. | Familiar uses only those. |
| Plugin code hot-reloads on save under `~/.config/omarchy/plugins/`. Checks: `omarchy plugin validate <dir>` + `qmllint -I $OMARCHY_PATH/shell`. | Dev loop is edit → save → look. CI runs validate + qmllint, then `hyprctl reload` + `hyprctl configerrors` for the Lua. |
| Shared UI base lives in `qs.Ui` (`BarWidget`, `WidgetButton`, `Panel`, `KeyboardPanel`, `PanelKeyCatcher`) and `qs.Commons` (`Style.space()`, `Style.font.*`, `Color.*`). | Familiar's kit *wraps* these, it does not fork them, so Omarchy's stock widgets still drop into Familiar's bar sections. |
| No Omarchy Stage or Omni installed on the author machine. | v0.1 ships Familiar's own overview and launcher. Provider keys remain in the schema as a later hook. |

Remaining **[verify]** items are collected in §12; nothing above is open.

---

## 2. Goals / non-goals

**Goals**
1. Switch the whole desktop feel (bar, dock, launcher, overview, alt-tab, window chrome, gaps, animations, key muscle-memory) with one command: `omarchy-shell shell call io.github.tuxclaw.familiar setProfile plasma`.
2. Feel native to each paradigm on the *first minute* of use — placement, sizing, timing, and keybinds matter more than pixel fidelity.
3. Stay Omarchy: use its theme, its menu (`SUPER + ALT + SPACE` still works), its notifications, its lock screen. Familiar only owns the bar, dock, and three overlay surfaces.
4. Zero-config default per profile; every knob exposed through manifest `schema` so Omarchy's Setup > Plugins UI renders the settings.
5. Uninstall = exactly stock Omarchy.

**Non-goals**
- Reproducing GNOME Shell / Plasma / macOS visually or using their trademarks, icons, wallpapers, or fonts. Familiar uses *metaphors* (Activities corner, application launcher button, dock with magnification), not brand assets.
- Replacing Hyprland tiling. Each profile ships a tiling posture (GNOME: tile, Plasma: tile, Mac: float-by-default) but tiling stays available everywhere.
- A settings app. `shell.json` + manifest schema is the settings surface.
- Sandboxing. Plugins run unsandboxed; Familiar runs no network code and does not request elevated permissions.

---

## 3. Architecture

```
┌──────────────────────────── omarchy-shell (Quickshell) ────────────────────────────┐
│                                                                                      │
│  io.github.tuxclaw.familiar                                                          │
│  ├─ service   Service.qml      ProfileStore: owns profile, tokens, keymap;           │
│  │                              writes ~/.config/hypr/familiar.lua; hyprctl reload   │
│  │                              ▲ service (injected)         ▲ shell.serviceFor(id)  │
│  ├─ overlay   Overlay.qml  ─────┘  keepLoaded; IPC surface   │                       │
│  │            ├─ dock PanelWindows (always mounted when profile.dock.enabled)         │
│  │            └─ open(payloadJson) → Launcher | Overview | Switcher                   │
│  └─ bar       Bar.qml   ─────────────────────────────────────┘  full-bar option      │
│                                                                                      │
│  Familiar.qml  (plain helper module, imported per entry point: token math only)      │
│  profiles/*.json  loaded by the service, hot-reload on file change                   │
└──────────────────────────────────────────────────────────────────────────────────────┘
          │ writes                                          │ reads
          ▼                                                 ▼
~/.config/hypr/familiar.lua      ◄── require("hypr.familiar") in ~/.config/hypr/hyprland.lua
~/.config/omarchy/shell.json     (bar.id / bar.profile / plugins[] entry)
qs.Commons.Color / Style         (theme; never read from disk by Familiar)
```

### 3.1 Repository layout

```
omarchy-familiar/
├── manifest.json
├── README.md
├── LICENSE                       MIT
├── preview.png
├── Familiar.qml                  helper module (NOT a singleton): token resolution, profile validation
├── Service.qml                   kind: service — profile store, familiar.lua writer
├── Bar.qml                       kind: bar
├── Overlay.qml                   kind: overlay — dock host + surface router + IPC methods
├── profiles/
│   ├── gnome.json
│   ├── plasma.json
│   └── macos.json
├── hypr/
│   ├── common.lua                shared layer rules + cycle bind
│   ├── gnome.lua
│   ├── plasma.lua
│   └── macos.lua
├── ui/                           the UI kit (section 7)
│   ├── tokens/  Tokens.qml  ThemeBridge.qml
│   ├── bar/     BarSurface.qml  BarSection.qml  ActivitiesButton.qml
│   │            AppMenuButton.qml  ActiveAppLabel.qml  TaskButton.qml
│   │            TaskList.qml  TrayArea.qml  ClockLabel.qml  WorkspacePips.qml
│   ├── dock/    DockHost.qml  DockSurface.qml  DockIcon.qml  DockSeparator.qml
│   │            RunningIndicator.qml  DockContextMenu.qml
│   ├── launcher/ LauncherSurface.qml  SearchField.qml  AppGrid.qml
│   │            AppGridCell.qml  ResultRow.qml  PageDots.qml
│   ├── overview/ OverviewSurface.qml  WorkspaceStrip.qml  WindowThumb.qml
│   ├── switcher/ SwitcherSurface.qml  SwitcherCell.qml
│   └── common/  Surface.qml  IconImage.qml  Tooltip.qml  Badge.qml
│                ContextMenu.qml  MenuItem.qml  Divider.qml  Kbd.qml
├── lib/
│   ├── Apps.js                   desktop-entry search / ranking
│   ├── Hypr.js                   hyprctl helpers
│   └── Profiles.js               JSON load + validation
└── tests/
    ├── validate.sh               omarchy plugin validate + qmllint
    ├── hypr.sh                   generate familiar.lua for each profile; hyprctl reload; hyprctl configerrors
    └── smoke.sh                  summon/hide each surface via IPC
```

No symlinks anywhere in the tree (validator rejects them). All entry points are safe relative paths. `ui/dock/DockHost.qml` is an internal component instantiated by `Overlay.qml`; it is not an entry point.

### 3.2 `manifest.json`

```json
{
  "schemaVersion": 1,
  "id": "io.github.tuxclaw.familiar",
  "name": "Familiar",
  "version": "0.2.0",
  "author": "Dan (tuxclaw)",
  "license": "MIT",
  "description": "Switch Omarchy between GNOME, Plasma, and Mac desktop paradigms: bar, dock, launcher, overview, switcher, and matching Hyprland behavior.",
  "kinds": ["bar", "overlay", "service"],
  "entryPoints": {
    "bar": "Bar.qml",
    "overlay": "Overlay.qml",
    "service": "Service.qml"
  },
  "keepLoaded": true,
  "bar": {
    "displayName": "Familiar bar",
    "defaults": {
      "profile": "gnome",
      "clockFormat": "auto",
      "trayVisible": true,
      "hostOmarchyWidgets": true,
      "dockEnabled": "auto",
      "dockPosition": "auto",
      "dockIconSize": 48,
      "dockMagnification": "auto",
      "dockAutohide": "auto",
      "dockPinned": "chromium,alacritty,nautilus,obsidian"
    },
    "schema": [
      { "key": "profile", "type": "enum", "label": "Desktop profile",
        "options": ["gnome", "plasma", "macos"] },
      { "key": "clockFormat", "type": "string", "label": "Clock format (auto = profile default)" },
      { "key": "trayVisible", "type": "boolean", "label": "Show system tray" },
      { "key": "hostOmarchyWidgets", "type": "boolean",
        "label": "Host stock Omarchy bar widgets in the right section" },
      { "key": "dockEnabled", "type": "enum", "label": "Dock", "options": ["auto", "on", "off"] },
      { "key": "dockPosition", "type": "enum", "label": "Dock position",
        "options": ["auto", "bottom", "left", "right"] },
      { "key": "dockIconSize", "type": "integer", "label": "Dock icon size (px)" },
      { "key": "dockMagnification", "type": "enum", "label": "Dock magnify on hover",
        "options": ["auto", "on", "off"] },
      { "key": "dockAutohide", "type": "enum", "label": "Dock auto-hide",
        "options": ["auto", "on", "off"] },
      { "key": "dockPinned", "type": "string",
        "label": "Dock pinned apps (comma-separated desktop IDs)" }
    ]
  },
  "overlay": {
    "displayName": "Familiar surfaces",
    "defaults": { "overviewProvider": "familiar", "launcherProvider": "familiar" },
    "schema": [
      { "key": "overviewProvider", "type": "enum", "label": "Overview",
        "options": ["familiar", "none"] },
      { "key": "launcherProvider", "type": "enum", "label": "Launcher",
        "options": ["familiar", "none"] }
    ]
  },
  "service": {
    "defaults": { "manageHyprland": true, "manageKeybinds": true }
  }
}
```

Decisions baked in:
- **All user-facing settings live on the `bar` entry**, because `bar.schema` is known to render in Setup > Plugins and `barConfig` (the whole `bar:` subtree) is injected into the bar and readable by the service. Dock keys are prefixed `dock*` so they read cleanly in one list. Whether `overlay.schema` also renders is a **[verify]** item; until then the two provider keys are informational and default to `"familiar"`.
- **`dockPinned` is a `string`** of comma-separated desktop IDs, split and trimmed by `Service.qml`. Chosen over `multiselect` because the option set (every installed `.desktop` id) is not known at manifest-write time. Documented in README.
- `keepLoaded: true` applies to the overlay (dock windows stay mounted between summons) and the service.

### 3.3 Enable / disable / uninstall flow

```
omarchy plugin add https://github.com/tuxclaw/omarchy-familiar.git --enable --yes
```
1. Shell clones the repo, validates the manifest, sets `bar.id = io.github.tuxclaw.familiar` (full bar replaces `omarchy.bar`), and enables the overlay and service kinds via a `plugins[]` entry.
2. `Service.qml` mounts at startup (`keepLoaded`), reads `profile` from the `bar:` subtree (default `gnome`), writes `~/.config/hypr/familiar.lua`, appends the guarded line to `~/.config/hypr/hyprland.lua` **once** — after the `require("hypr.bindings")` line, so Familiar can override gaps and binds — then runs `hyprctl reload` and `hyprctl configerrors`.
   ```lua
   require("hypr.familiar") -- familiar:require
   ```
3. `omarchy plugin disable io.github.tuxclaw.familiar` → shell falls back to `omarchy.bar`; the service's `Component.onDestruction` rewrites `familiar.lua` to a **loadable no-op** (header comment only, so the `require` never fails) and runs `hyprctl reload` + `hyprctl configerrors`.
4. `omarchy plugin remove …` → same as 3, plus the guarded `require("hypr.familiar") -- familiar:require` line is deleted from `hyprland.lua` and `familiar.lua` is removed. If the shell kills the service before teardown completes, the no-op `familiar.lua` from the last write is still present, so Hyprland never sees a missing-file `require`. The README documents the one-line manual cleanup (`sed -i '/familiar:require/d' ~/.config/hypr/hyprland.lua`) for the pathological case.

`bindings.lua` and `looknfeel.lua` are never edited.

---

## 4. Profiles

A profile is a JSON document. Every visual and behavioral difference between paradigms is expressed here, and *only* here. The component set is identical.

### 4.1 Profile schema

```jsonc
{
  "id": "macos",
  "label": "Mac",
  "bar": {
    "position": "top",
    "height": 28,
    "reserve": true,                // exclusive zone
    "transparent": "blur",          // "solid" | "blur" | "transparent"
    "left":   ["appMenu", "activeApp"],
    "center": [],
    "right":  ["tray", "omarchyWidgets", "clock"],
    "clockFormat": "ddd d MMM  h:mm AP"
  },
  "dock": { "enabled": true, "position": "bottom", "iconSize": 52,
            "magnification": true, "autohide": false, "showRunning": true,
            "runningIndicator": "dot" },
  "launcher": { "style": "spotlight", "hotkey": "SUPER + SPACE" },
  "overview":  { "style": "missionControl", "hotkey": "CTRL + UP" },
  "switcher":  { "style": "iconRow", "hotkey": "SUPER + TAB", "scope": "app" },
  "tokens": { "radius": 10, "density": 1.0, "font": "sans", "motion": "springy" },
  "hypr": {
    "gapsIn": 6, "gapsOut": 10, "border": 0, "rounding": 10, "blur": true,
    "shadow": true, "floatByDefault": true, "focusFollowsMouse": false,
    "titlebarButtonsLeft": true
  },
  "keymap": "macos"                 // selects hypr/<keymap>.lua
}
```

### 4.2 The three shipped profiles

| Axis | `gnome` | `plasma` | `macos` |
|---|---|---|---|
| Bar position / height | top / 32 | bottom / 40 | top / 28 |
| Bar left | Activities button, workspace pips (on hover) | App-launcher button, task list (window buttons w/ labels) | App-menu button (Omarchy logo), active-app name |
| Bar center | Clock + date, notifications indicator | — | — |
| Bar right | Stock Omarchy widgets (network/audio/power) as one "quick settings" cluster | Tray, stock widgets, clock, "peek desktop" sliver | Tray, stock widgets, clock |
| Dock | Off by default (dash lives *inside* overview) | Off (tasks are in the bar) | On, bottom, magnify, running dots |
| Launcher | App grid, 6×4, paged, search on type | Kickoff-style: two-column (favorites / categories) with search | Spotlight-style: centered search field, results list, no grid |
| Overview | Workspaces as horizontal strip on top, windows scattered in a grid, dash at bottom | Grid of windows (Present Windows), workspaces on side | Mission Control: workspace thumbnails strip top, windows grouped by app |
| Switcher | Alt+Tab app icons row, Alt+` cycles windows in app | Alt+Tab thumbnail list with titles | Cmd+Tab icon row, app-scoped |
| Tiling posture | tile, gaps 8/12, border 1, rounding 12 | tile, gaps 4/6, border 2, rounding 6 | float by default, gaps 6/10, border 0, rounding 10, shadow on |
| Motion | fast ease-out (GNOME-like 150–250ms) | linear-ish 120ms | spring/overshoot 250–350ms |
| Font role | sans, 10.5pt | sans, 10pt | sans, 13px w/ tighter tracking |

### 4.3 Keymaps

Written into `hypr/<keymap>.lua`. Omarchy's own binds stay; Familiar adds a layer and **unbinds only what it overrides**. Every override is an explicit `hl.unbind(...)` immediately followed by its `o.bind(...)`, so users can audit the fragment top to bottom.

| Action | `gnome` | `plasma` | `macos` |
|---|---|---|---|
| Launcher | `SUPER` (release) → overview; `SUPER + A` app grid | `ALT + F1`, `SUPER` (release) | `SUPER + SPACE` (unbinds Omarchy menu; menu stays on `SUPER + ALT + SPACE`) |
| Overview | `SUPER` (release), `SUPER + S` | `SUPER + W` | `SUPER + TAB` hold, `CTRL + UP` |
| Switcher | `ALT + TAB` (apps), `` ALT + ` `` (windows) | `ALT + TAB` (windows) | `SUPER + TAB` (apps), `` SUPER + ` `` (windows) |
| Close window | `SUPER + Q` (Omarchy) + `ALT + F4` | `ALT + F4` | `SUPER + Q` (app), `SUPER + W` (window) |
| Workspace prev/next | `SUPER + PAGE_UP/PAGE_DOWN`, `CTRL + ALT + LEFT/RIGHT` | `CTRL + F1..F4`, `SUPER + CTRL + LEFT/RIGHT` | `CTRL + LEFT/RIGHT` |
| Show desktop | — | `SUPER + D` | `F11` |
| Screenshot | `PRINT` (Omarchy) | `PRINT` | `SUPER + SHIFT + 3/4/5` |
| Lock | `SUPER + L` | `SUPER + L` | `SUPER + CTRL + Q` |
| Terminal | `SUPER + RETURN` (Omarchy, kept in all) | same | same |
| Cycle profile | `SUPER + SHIFT + F` (all profiles, from `common.lua`) | same | same |

"`SUPER` (release)" is `o.bind("SUPER", "…", "…", { release = true })`. Mac's `SUPER` is the Super/Win key playing Command; Familiar does **not** remap Alt/Super at the keyboard layer — that stays user opt-in via `input:kb_options` in `input.lua` and is documented.

### 4.4 Hyprland Lua fragments

`hypr/common.lua` (all profiles):
```lua
-- Familiar — managed. Regenerated by io.github.tuxclaw.familiar; do not edit.
local familiar = "omarchy-shell shell"
local id = "io.github.tuxclaw.familiar"

hl.unbind("SUPER + SHIFT + F")
o.bind("SUPER + SHIFT + F", "Familiar: cycle desktop profile",
  familiar .. " call " .. id .. " cycleProfile ''")

hl.layer_rule({ match = { namespace = "familiar-bar" }, blur = true })
hl.layer_rule({ match = { namespace = "familiar-dock" }, blur = true, ignore_zero = true })
hl.layer_rule({ match = { namespace = "familiar-switcher" }, no_anim = true, animation = "none" })
```

`hypr/macos.lua` (excerpt; the same behavioral values as v0.1):
```lua
local familiar = "omarchy-shell shell"
local id = "io.github.tuxclaw.familiar"
local function surface(name, extra)
  return familiar .. " toggle " .. id .. " '{\"surface\":\"" .. name .. "\"" .. (extra or "") .. "}'"
end

hl.config({
  general = { gaps_in = 6, gaps_out = 10, border_size = 0 },
  decoration = {
    rounding = 10,
    blur = { enabled = true, size = 8, passes = 2 },
    shadow = { enabled = true, range = 24, render_power = 3 },
  },
})

hl.curve("familiarSpring", { type = "bezier", points = { { 0.2, 0.9 }, { 0.1, 1.05 } } })
hl.animation({ leaf = "windows",    enabled = true, speed = 4, bezier = "familiarSpring", style = "popin 85%" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "familiarSpring", style = "slide" })

o.window({ class = ".*" }, { float = true })                        -- float by default
o.window({ class = "^(chromium|Alacritty|code)$" }, { tile = true }) -- sensible exceptions

-- Overrides (each unbind is listed so the change is auditable)
hl.unbind("SUPER + SPACE")            -- stock: Omarchy menu (still on SUPER + ALT + SPACE)
o.bind("SUPER + SPACE", "Familiar launcher", surface("launcher"))

hl.unbind("SUPER + TAB")
o.bind("SUPER + TAB", "Familiar app switcher",
  familiar .. " summon " .. id .. " '{\"surface\":\"switcher\",\"scope\":\"app\"}'")

hl.unbind("SUPER + GRAVE")
o.bind("SUPER + GRAVE", "Familiar window switcher",
  familiar .. " summon " .. id .. " '{\"surface\":\"switcher\",\"scope\":\"window\"}'")

hl.unbind("CTRL + UP")
o.bind("CTRL + UP", "Familiar overview", surface("overview"))

hl.unbind("SUPER + Q")
o.bind("SUPER + Q", "Quit app", hl.dsp.killactive)
hl.unbind("SUPER + W")
o.bind("SUPER + W", "Close window", hl.dsp.killactive)

hl.unbind("CTRL + LEFT")
o.bind("CTRL + LEFT",  "Previous workspace", "hyprctl dispatch workspace e-1")
hl.unbind("CTRL + RIGHT")
o.bind("CTRL + RIGHT", "Next workspace",     "hyprctl dispatch workspace e+1")
```

`hypr/gnome.lua` (excerpt):
```lua
hl.config({
  general = { gaps_in = 8, gaps_out = 12, border_size = 1 },
  decoration = { rounding = 12, blur = { enabled = true, size = 6, passes = 2 }, shadow = { enabled = false } },
})
hl.curve("familiarOut", { type = "bezier", points = { { 0.2, 0.0 }, { 0.0, 1.0 } } })
hl.animation({ leaf = "windows",    enabled = true, speed = 3, bezier = "familiarOut", style = "popin 90%" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "familiarOut", style = "slide" })

o.bind("SUPER", "Familiar overview", surface("overview"), { release = true })
hl.unbind("SUPER + A")
o.bind("SUPER + A", "Familiar app grid", surface("launcher"))
hl.unbind("ALT + TAB")
o.bind("ALT + TAB", "Familiar app switcher",
  familiar .. " summon " .. id .. " '{\"surface\":\"switcher\",\"scope\":\"app\"}'")
hl.unbind("ALT + GRAVE")
o.bind("ALT + GRAVE", "Familiar window switcher",
  familiar .. " summon " .. id .. " '{\"surface\":\"switcher\",\"scope\":\"window\"}'")
hl.unbind("ALT + F4")
o.bind("ALT + F4", "Close window", hl.dsp.killactive)
```

`hypr/plasma.lua` follows the same shape with gaps 4/6, border 2, rounding 6, a 120ms near-linear curve, `ALT + F1` and `SUPER` (release) → launcher, `SUPER + W` → overview, `SUPER + D` → `hyprctl dispatch togglespecialworkspace` stand-in for show-desktop, `CTRL + F1..F4` → `workspace 1..4`.

The service concatenates `common.lua` + `<keymap>.lua` (with `local familiar`, `local id`, and `surface()` hoisted once into the generated header) into `~/.config/hypr/familiar.lua`, then runs `hyprctl reload` and `hyprctl configerrors`. A non-empty `configerrors` output is surfaced as an Omarchy notification and logged; the previous `familiar.lua` is restored from `~/.local/state/familiar/familiar.lua.prev`.

---

## 5. Component contracts (QML)

### 5.1 `Familiar.qml` — helper module (not a singleton)

A plain `QtObject` each entry point instantiates locally. It holds no cross-kind state; it turns a profile object plus `Color` / `Style` into resolved tokens.

```qml
import QtQuick
import qs.Commons
import "ui/tokens"

QtObject {
  id: helper
  property var profile: ({})                          // set by the owner from service.currentProfile
  readonly property var tokens: Tokens.resolve(profile, Color, Style)
  function validate(p) { return Profiles.validate(p) } // lib/Profiles.js
}
```

### 5.2 `Service.qml` — kind: service (profile store)

Owns: the loaded `profiles` map, the active `profile` id, the `bar:` subtree snapshot, `familiar.lua` generation, Hyprland reload, and persistence. Every other kind reads it: the overlay through its injected `service` property, the bar through `shell.serviceFor(manifest.id)`.

```qml
import QtQuick
import Quickshell
import Quickshell.Io
import "lib/Profiles.js" as Profiles

Item {
  id: root
  readonly property string moduleName: "io.github.tuxclaw.familiar"

  // injected by the host when available
  property var shell: null
  property var pluginRegistry: null
  property var manifest: null

  property var    profiles: ({})          // id → parsed JSON
  property string profile: "gnome"
  readonly property var currentProfile: profiles[profile] || profiles["gnome"] || ({})
  property var barConfig: ({})            // snapshot of shell.json bar: subtree
  signal profileChanged(string id)

  // ---- public API (called by Overlay.qml) ----
  function setProfile(id) {
    if (!profiles[id]) return "unknown"
    profile = id
    persist(id)
    applyHypr()
    profileChanged(id)
    return "ok"
  }
  function cycleProfile() {
    const ids = Object.keys(profiles).sort()
    return setProfile(ids[(ids.indexOf(profile) + 1) % ids.length]) === "ok" ? profile : "unknown"
  }
  function getProfile() { return profile }
  function reapply()    { applyHypr(); return "ok" }

  // ---- dock / bar setting resolution: explicit shell.json value > "auto" → profile default ----
  function resolved(key, profileValue) {
    const v = barConfig[key]
    return (v === undefined || v === "auto") ? profileValue : v
  }
  function pinnedApps() {
    const s = barConfig.dockPinned
    return typeof s === "string" && s.length
      ? s.split(",").map(x => x.trim()).filter(Boolean)
      : (currentProfile.dock && currentProfile.dock.pinned) || []
  }

  // ---- persistence ----
  function persist(id) {
    // Preferred: host mutator, which clones the JSON so extra bar keys survive.   [verify exact API]
    if (pluginRegistry && pluginRegistry.shellConfigMutator) {
      pluginRegistry.shellConfigMutator(cfg => { cfg.bar = cfg.bar || {}; cfg.bar.profile = id; return cfg })
      return
    }
    // Fallback: jq edit + reloadConfig.
    persistProc.command = ["sh", "-c",
      `tmp=$(mktemp) && jq --arg p "${id}" '.bar.profile=$p' ~/.config/omarchy/shell.json > "$tmp" ` +
      `&& mv "$tmp" ~/.config/omarchy/shell.json && omarchy-shell shell reloadConfig`]
    persistProc.running = true
  }

  // ---- Hyprland ----
  readonly property string pluginDir: Qt.resolvedUrl(".").toString().replace("file://", "")
  function applyHypr() {
    const keymap = currentProfile.keymap || profile
    hyprProc.command = ["sh", "-c",
      `set -e; mkdir -p ~/.local/state/familiar; ` +
      `[ -f ~/.config/hypr/familiar.lua ] && cp ~/.config/hypr/familiar.lua ~/.local/state/familiar/familiar.lua.prev || true; ` +
      `{ printf '%s\\n' '-- Familiar — managed. Regenerated by io.github.tuxclaw.familiar; do not edit.'; ` +
      `  cat "${pluginDir}hypr/common.lua" "${pluginDir}hypr/${keymap}.lua"; } > ~/.config/hypr/familiar.lua; ` +
      `grep -q 'familiar:require' ~/.config/hypr/hyprland.lua || ` +
      `  sed -i '/require("hypr.bindings")/a require("hypr.familiar") -- familiar:require' ~/.config/hypr/hyprland.lua; ` +
      `hyprctl reload; hyprctl configerrors`]
    hyprProc.running = true
  }
  function teardownHypr(removeRequire) {
    Quickshell.execDetached(["sh", "-c",
      `printf '%s\\n' '-- Familiar — managed no-op. Plugin disabled.' > ~/.config/hypr/familiar.lua; ` +
      (removeRequire ? `sed -i '/familiar:require/d' ~/.config/hypr/hyprland.lua; rm -f ~/.config/hypr/familiar.lua; ` : ``) +
      `hyprctl reload; hyprctl configerrors`])
  }

  Process { id: persistProc }
  Process { id: hyprProc; stdout: StdioCollector { onStreamFinished: root.reportConfigErrors(text) } }
  function reportConfigErrors(text) {
    if (!text.trim().length || /no errors/i.test(text)) return
    Quickshell.execDetached(["notify-send", "Familiar", "Hyprland config errors:\n" + text.trim()])
  }

  // profiles: hot-reload on save
  FileView { path: Qt.resolvedUrl("profiles/gnome.json");  watchChanges: true; onLoaded: root.ingest("gnome",  text()) }
  FileView { path: Qt.resolvedUrl("profiles/plasma.json"); watchChanges: true; onLoaded: root.ingest("plasma", text()) }
  FileView { path: Qt.resolvedUrl("profiles/macos.json");  watchChanges: true; onLoaded: root.ingest("macos",  text()) }
  function ingest(id, text) {
    const m = Object.assign({}, profiles); m[id] = Profiles.validate(JSON.parse(text)); profiles = m
  }

  // bar: subtree — from the host when injected, else watched from disk
  FileView {
    id: shellJson
    path: Quickshell.env("HOME") + "/.config/omarchy/shell.json"
    watchChanges: true
    onLoaded: {
      const cfg = JSON.parse(text() || "{}")
      root.barConfig = cfg.bar || {}
      if (root.barConfig.profile && root.barConfig.profile !== root.profile) root.profile = root.barConfig.profile
    }
  }

  Component.onCompleted: applyHypr()
  Component.onDestruction: teardownHypr(false)
}
```

Notes:
- `teardownHypr(true)` (delete the guarded `require`) is invoked by the overlay's `uninstall()` method, which `omarchy plugin remove` can call before deleting the checkout; `Component.onDestruction` only does the no-op rewrite so a disable never breaks the config.
- The service does not touch `bindings.lua`, `looknfeel.lua`, or any other user Lua file.

### 5.3 `Overlay.qml` — kind: overlay (IPC surface, dock host, surface router)

This is the item the shell's `callIfLoaded` reaches for `summon`, `hide`, `toggle`, and `call`. It is `keepLoaded`, so the dock windows it hosts persist across summons.

```qml
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "ui/dock"
import "ui/launcher"
import "ui/overview"
import "ui/switcher"

Item {                                     // [verify] qs.Ui base type for a keep-loaded multi-window overlay
  id: root
  readonly property string moduleName: "io.github.tuxclaw.familiar"

  // injected by the host
  property var service: null               // shell.serviceFor(id)
  property var shell: null
  property var manifest: null

  readonly property var prof: service ? service.currentProfile : ({})
  property string surface: "launcher"
  readonly property bool opened: surfaceWin.visible

  // ---- IPC: profile methods (forwarded to the service) ----
  function setProfile(id)  { return service ? service.setProfile(id)  : "unknown" }
  function cycleProfile()  { return service ? service.cycleProfile()  : "unknown" }
  function getProfile()    { return service ? service.getProfile()    : "unknown" }
  function reapply()       { return service ? service.reapply()       : "unknown" }
  function uninstall()     { if (service) service.teardownHypr(true); return "ok" }

  // ---- IPC: summon / hide / toggle ----
  function open(payloadJson) {
    const p = JSON.parse(payloadJson || "{}")
    surface = p.surface || "launcher"
    if (surface === "overview" && overviewProvider === "none") return
    if (surface === "launcher" && launcherProvider === "none") return
    if (surfaceWin.visible && surface === "switcher") { loader.item.advance(p); return }
    loader.sourceComponent = table[surface]
    surfaceWin.visible = true
    loader.item.open(p)
  }
  function close() {
    if (loader.item && loader.item.commit) loader.item.commit()
    surfaceWin.visible = false
    loader.sourceComponent = null
  }
  function toggle(payloadJson) { surfaceWin.visible ? close() : open(payloadJson) }

  property string overviewProvider: "familiar"
  property string launcherProvider: "familiar"

  readonly property var table: ({ launcher: launcherC, overview: overviewC, switcher: switcherC })
  Component { id: launcherC; LauncherSurface { style: root.prof.launcher.style; service: root.service; onDismiss: root.close() } }
  Component { id: overviewC; OverviewSurface { style: root.prof.overview.style; service: root.service; onDismiss: root.close() } }
  Component { id: switcherC; SwitcherSurface { style: root.prof.switcher.style; service: root.service; onDismiss: root.close() } }

  // ---- fullscreen surface window (one per focused screen) ----
  PanelWindow {
    id: surfaceWin
    visible: false
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) || Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    WlrLayershell.namespace: root.surface === "switcher" ? "familiar-switcher" : "familiar-overlay"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    color: "transparent"
    Loader { id: loader; anchors.fill: parent }
  }

  // ---- dock: always mounted while enabled; lives here because the dock is not its own kind ----
  DockHost {
    service: root.service
    enabled: service ? service.resolved("dockEnabled", root.prof.dock && root.prof.dock.enabled ? "on" : "off") !== "off" : false
    position: service ? service.resolved("dockPosition", root.prof.dock ? root.prof.dock.position : "bottom") : "bottom"
    iconSize: service ? service.resolved("dockIconSize", root.prof.dock ? root.prof.dock.iconSize : 48) : 48
    magnification: service ? service.resolved("dockMagnification", root.prof.dock && root.prof.dock.magnification ? "on" : "off") === "on" : false
    autohide: service ? service.resolved("dockAutohide", root.prof.dock && root.prof.dock.autohide ? "on" : "off") === "on" : false
    pinned: service ? service.pinnedApps() : []
  }
}
```

Switcher semantics: the bind `summon`s on key-down; the first `open` mounts the switcher and advances one step; each further `summon` while open calls `advance(p)`; the surface listens for the modifier release via `Keys.onReleased` on the focused key catcher (the window has `keyboardFocus: Exclusive`) and calls `commit()` then `dismiss`. Fallback if release is not observed within 1.2 s: commit anyway. Whether Exclusive focus reliably delivers modifier release inside a layer surface is a **[verify]** item; the fallback timer makes the feature usable either way.

### 5.4 `ui/dock/DockHost.qml` — internal (instantiated by the overlay)

```qml
import QtQuick
import Quickshell
import Quickshell.Wayland
import "."

Item {
  id: host
  property var service: null
  property bool enabled: false
  property string position: "bottom"
  property int iconSize: 48
  property bool magnification: false
  property bool autohide: false
  property var pinned: []

  Variants {
    model: host.enabled ? Quickshell.screens : []
    PanelWindow {
      required property var modelData
      screen: modelData
      anchors { bottom: host.position === "bottom"; left: host.position === "left"; right: host.position === "right" }
      exclusiveZone: host.autohide ? 0 : dock.implicitHeight
      WlrLayershell.namespace: "familiar-dock"
      WlrLayershell.layer: WlrLayer.Top
      color: "transparent"
      implicitHeight: dock.implicitHeight
      implicitWidth: dock.implicitWidth
      DockSurface {
        id: dock
        iconSize: Tokens.px(host.iconSize)
        magnification: host.magnification
        pinned: host.pinned
        running: ToplevelManager.toplevels
        onLaunch: id => Apps.launch(id)
        onFocus: tl => tl.activate()
        onContextMenu: (entry, pos) => menu.openFor(entry, pos)
      }
      DockContextMenu { id: menu }            // Pin/Unpin, New window, Show all windows, Quit
    }
  }
}
```

Autohide: `HoverHandler` on a 2px reveal strip at the screen edge; hide after 400 ms once the pointer leaves and no dock menu is open. When bar and dock share an edge, the dock offsets by the bar's exclusive zone.

### 5.5 `Bar.qml` — kind: bar

Verified contract: the root is an `Item`. The host injects `omarchyPath`, `barWidgetRegistry`, `barConfig` (required) and `shell`, `manifest`, `pluginRegistry` (optional). The bar must expose `property string fontFamily` and `function switchPanelFrom(owner, direction)`. Stock widgets come from `barWidgetRegistry.widgets[id].component` for each entry in `barConfig.layout`.

```qml
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "ui/bar"
import "ui/tokens"

Item {
  id: root

  // ---- host-injected ----
  required property string omarchyPath
  required property var barWidgetRegistry
  required property var barConfig            // whole shell.json bar: subtree, incl. Familiar keys
  property var shell: null
  property var manifest: null
  property var pluginRegistry: null

  // ---- contract surface ----
  property string fontFamily: Style.font.family
  function switchPanelFrom(owner, direction) { return rightSection.switchFrom(owner, direction) }

  // ---- profile via the service (configureBar does not inject `service`) ----
  readonly property var service: (shell && manifest && typeof shell.serviceFor === "function")
                                 ? shell.serviceFor(manifest.id) : null
  readonly property var prof: service ? service.currentProfile.bar : ({ position: "top", height: 32, left: [], center: ["clock"], right: [] })
  readonly property bool hostOmarchyWidgets: barConfig.hostOmarchyWidgets !== false
  readonly property bool trayVisible: barConfig.trayVisible !== false

  Variants {                                   // one bar per monitor
    model: Quickshell.screens
    PanelWindow {
      id: win
      required property var modelData
      screen: modelData
      anchors { top: root.prof.position === "top"; bottom: root.prof.position === "bottom"; left: true; right: true }
      implicitHeight: Tokens.px(root.prof.height)
      exclusiveZone: root.prof.reserve === false ? 0 : implicitHeight
      WlrLayershell.namespace: "familiar-bar"
      WlrLayershell.layer: WlrLayer.Top
      color: "transparent"

      BarSurface {
        anchors.fill: parent
        mode: root.prof.transparent
        BarSection { role: "left";   items: root.prof.left;   bar: root }
        BarSection { role: "center"; items: root.prof.center; bar: root }
        BarSection { id: rightSection; role: "right"; items: root.prof.right; bar: root
                     hostOmarchyWidgets: root.hostOmarchyWidgets
                     registry: root.barWidgetRegistry
                     layout: root.barConfig.layout }   // stock widgets rendered in-place via registry
      }
    }
  }
}
```

`BarSection` resolves each item string to a component:

| item id | component | notes |
|---|---|---|
| `activities` | `ActivitiesButton` | GNOME. Click → overview; hover shows `WorkspacePips`. |
| `appMenu` | `AppMenuButton` | Plasma/Mac. Click → launcher (Plasma) or Omarchy menu (Mac). |
| `activeApp` | `ActiveAppLabel` | Mac. Bold app name from active toplevel's desktop entry. |
| `tasks` | `TaskList` | Plasma. `ToplevelManager` toplevels grouped by app, click focus/minimize, middle-click new instance. |
| `workspaces` | `WorkspacePips` | Any. `Hyprland.workspaces`; active/occupied/urgent states. |
| `clock` | `ClockLabel` | Any. Format from profile unless `barConfig.clockFormat` overrides. Click → stock `omarchy.clock` panel if present in layout. |
| `tray` | `TrayArea` | `Quickshell.Services.SystemTray`; hidden when `trayVisible` is false. |
| `omarchyWidgets` | registry host | Every entry in `barConfig.layout.left/center/right` instantiated from `barWidgetRegistry.widgets[entry.id].component` with the entry's inline settings. `omarchy bar move` keeps working. |
| `notifications` | indicator | `omarchy.notifications` service DND/unread count. |
| `spacer` | Item | flexible gap |

---

## 6. Data sources

| Need | Source | Fallback |
|---|---|---|
| Windows (title, app_id, focus, minimized) | `Quickshell.Wayland.ToplevelManager` | `hyprctl -j clients` via `Process` |
| Workspaces, active monitor, urgent | `Quickshell.Hyprland.Hyprland` singleton (`workspaces`, `focusedMonitor`, `dispatch()`) | `hyprctl -j workspaces` |
| App list, icons, categories, launch | `Quickshell.DesktopEntries` | `ls /usr/share/applications ~/.local/share/applications` |
| Icons | `Quickshell.iconPath(name)` against the user's icon theme (Omarchy theme sets it) | generic `application-x-executable` |
| Window previews (overview) | `ScreencopyView` (Quickshell) per toplevel | app icon on a placeholder card |
| Tray | `Quickshell.Services.SystemTray` | hide section |
| Theme colors and type | `qs.Commons.Color` (`bar`, `foreground`, `background`, `accent`, `urgent`, `muted`, popup/menu surfaces) and `qs.Commons.Style` — both already loaded from `~/.local/state/omarchy/current/theme/colors.toml` + `shell.toml` | none; if a needed token is missing from `Color`, **[verify]** before adding any parser |
| Profile / settings | `service.currentProfile`, `service.barConfig` | service reads `shell.json` from disk with `watchChanges` when `pluginRegistry` is not injected |
| Recent/frecency for launcher | `~/.local/state/familiar/frecency.json` | none (alphabetical) |

---

## 7. UI kit

The kit is the set of components every profile renders through. Profiles vary tokens and layout; they never subclass components.

### 7.1 Token model

Three layers, resolved per entry point by `ui/tokens/Tokens.qml` whenever the service's `profileChanged` fires:

1. **Theme layer** (from `qs.Commons.Color` / `Style`): `bg` ← `Color.background`, `fg` ← `Color.foreground`, `barBg` ← `Color.bar`, `accent` ← `Color.accent`, `danger` ← `Color.urgent`, `muted` ← `Color.muted`, `surface` / `surfaceAlt` ← popup/menu surface colors, `border` ← `muted@0.5`. Read-only. `ThemeBridge.qml` is a thin binding shim over `Color`; it parses nothing.
2. **Profile layer** (from `profiles/*.json → tokens`): `radius`, `density`, `motion`, `font`, `elevation`.
3. **Semantic layer** (computed): everything components actually bind to.

```
Semantic token            gnome        plasma       macos        derivation
----------------------------------------------------------------------------------------
space.unit                8            6            8            Style.space(1) * density
bar.height                32           40           28           profile.bar.height
bar.bg                    barBg@0.92   barBg@1.0    barBg@0.55+blur transparent mode → alpha
bar.fg                    fg           fg           fg
bar.hover                 fg@0.10      accent@0.18  fg@0.12
bar.active                fg@0.18      accent@0.35  fg@0.18
bar.font.size             14           13           13
bar.font.weight           600          500          600
dock.bg                   surface@0.85 —            surface@0.60+blur
dock.radius               16           —            18
dock.iconSize             48           —            52
dock.magnify.scale        1.0          —            1.55
dock.magnify.spread       0            —            2 (neighbors)
dock.indicator            pill 3×16    —            dot 4×4
launcher.width            0.80*screen  560          680
launcher.radius           24           12           14
launcher.grid             6×4          list         list
launcher.bg               bg@0.94      surface@0.98 surface@0.75+blur
overview.thumb.radius     12           6            10
overview.thumb.border     accent 3px   accent 2px   accent 3px
switcher.cell             icon 96, label below   thumb 160×100 + title   icon 96, no label
radius.sm/md/lg           6/12/24      4/6/12       6/10/18
motion.fast/base/slow     100/180/260ms 80/120/200ms 150/260/380ms
motion.curve              OutCubic     OutQuad      OutBack(1.2)
font.family               Style.font.family  — same in all
font.tracking             0            0            -0.2
shadow.elevated           0 4 16 @0.25 0 2 8 @0.30  0 8 32 @0.35
```

`Tokens.px(n)` applies `density` and the screen's scale so numbers above are the 1× reference.

### 7.2 Color mapping to Omarchy themes

Omarchy themes are dark-or-light with a single accent. Familiar never introduces its own palette; `Color.accent` drives active states, focus rings, the running indicator, and the overview selection border. Light themes flip `bar.hover`/`bar.active` to `fg@0.06`/`fg@0.12` and drop blur alpha by 0.1 so text stays legible on light wallpapers. `ThemeBridge.qml` exposes `isLight` computed from `Color.background` luminance. Theme switches propagate live because `Color` is the shell's own reactive singleton.

### 7.3 Component inventory

Each entry: purpose · props · states · notes.

**common/**
- `Surface` — root container for any floating shell surface. Props: `radius`, `mode` (`solid|blur|transparent`), `elevation`. Handles background, border (1px `border@0.5` when solid), and the open/close transition per `motion.*`.
- `IconImage` — resolves `iconName` or `desktopId` → path via `Quickshell.iconPath`; square; fallback glyph; `size`.
- `Tooltip` — delayed 600 ms, follows anchor, hides on press. Profile decides above/below via bar position.
- `Badge` — numeric or dot; used for notification count and window count on dock icons.
- `ContextMenu` / `MenuItem` — keyboard navigable, `Divider`, submenu-free by design. Mac profile uses 4px radius items inside 10px surface; Plasma 4px flat; GNOME 8px pill items.
- `Kbd` — shows a shortcut chip in launcher results ("⌘ Space" style glyphs on Mac, "Super+Space" text elsewhere).

**bar/**
- `BarSurface` — full-width strip; `mode`; draws bottom/top hairline in Plasma only.
- `BarSection` — `role`, `items[]`, `hostOmarchyWidgets`, `registry`, `layout`; lays out children with `space.unit`; implements `switchFrom(owner, dir)` so stock Omarchy panels can tab between widgets.
- `ActivitiesButton` — text "Activities" (GNOME) with pill hover; hot-corner companion: top-left 1×1 px `HoverHandler` region triggers overview after 120 ms dwell.
- `AppMenuButton` — icon-only (Omarchy logo from `omarchyPath` or a generic 9-dot grid glyph); Plasma shows "Applications" label at width ≥ 1600 px.
- `ActiveAppLabel` — bold app name; empty on desktop.
- `TaskButton` — icon + label (Plasma), states: normal/hover/active/minimized/urgent (urgent pulses accent underline 3× then holds). Middle-click launches new instance. Width clamps 48–220.
- `TaskList` — groups by `appId`, `maxWidth` distributes; overflow → "…" chevron menu.
- `TrayArea` — `SystemTray.items`, 18 px icons, left-click activate, right-click menu (Quickshell's `QsMenuAnchor`).
- `ClockLabel` — one `SystemClock` shared; format from profile; Mac shows "Fri 4 Sep  9:41 AM", GNOME "Fri 09:41", Plasma two-line time/date at height 40.
- `WorkspacePips` — dots/pills; GNOME reveals on Activities hover; Plasma shows always as small squares in left section.

**dock/**
- `DockHost` — internal window host (§5.4); one `PanelWindow` per screen; owned by the overlay.
- `DockSurface` — horizontal or vertical `Row/Column`, computes magnification via distance-from-pointer Gaussian (`scale = 1 + (magnify-1) * exp(-(d/spread)^2)`), animates with `motion.fast`. Running-but-unpinned apps append after `DockSeparator`.
- `DockIcon` — `IconImage` + `RunningIndicator` + bounce-on-launch (Mac: 2 bounces, 320 ms each; GNOME: none; not applicable Plasma). Drag-to-reorder pins (long-press 250 ms) writes back through `service.persistPinned(list)` to `bar.dockPinned`.
- `RunningIndicator` — `dot` (Mac) or `pill` (GNOME dash inside overview); count 1–3 shown as multiple dots on GNOME style.
- `DockContextMenu` — Pin/Unpin, Open new window, Show all windows (→ overview filtered to app), Quit.

**launcher/**
- `LauncherSurface` — `style: grid|kickoff|spotlight`. Opens with `SearchField` focused; Esc closes; typing filters live; Enter launches top result; arrow keys navigate.
- `SearchField` — pill (GNOME), inset field (Plasma), large 28 px-text field (Mac). Shows "Search" placeholder; right-side `Kbd` hint.
- `AppGrid` — paged `GridView`, `PageDots`, horizontal swipe/scroll; drag app to dock = pin.
- `AppGridCell` — 96 px icon (GNOME) with label under; hover raise; focus ring uses `accent`.
- `ResultRow` — icon, primary, secondary (category or path), right `Kbd`; sections: Applications / Recent / Commands (commands are Omarchy menu actions surfaced from `omarchy-menu.jsonc` so the Mac Spotlight search can run "Set theme…" etc.).
- Ranking (`lib/Apps.js`): prefix match on name > word-start match > fuzzy; ties broken by frecency; "Commands" only when query ≥ 2 chars.

**overview/**
- `OverviewSurface` — `style: gnome|presentWindows|missionControl`. Full-screen `Surface` with dimmed wallpaper (`bg@0.6`). Esc/click-empty closes.
- `WorkspaceStrip` — thumbnails of each workspace (per-workspace screencopy is not feasible; render icons of that workspace's windows on a mini card instead). Click switches; drag window thumb onto strip moves it. Position: top (GNOME/Mac) or right (Plasma).
- `WindowThumb` — `ScreencopyView` of the toplevel, title chip on hover, close button top-right on hover, `accent` border when focused. Layout algorithm: rows packed to keep aspect, max 4 per row, spacing `space.unit*2`. Mac groups thumbs of the same app under one label.
- GNOME style adds a dash (a `DockSurface` in `embedded` mode) at the bottom of the overview and a search field at top that switches the surface into `LauncherSurface` on typing.

**switcher/**
- `SwitcherSurface` — centered `Surface`, appears after 80 ms hold (so a quick Alt+Tab flip doesn't flash UI); cells in a row (Mac/GNOME) or column of thumbs (Plasma). `scope: app|window`. Exposes `open(p)`, `advance(p)`, `commit()`.
- `SwitcherCell` — selected cell gets `bar.active` bg + `accent` ring; Plasma shows title + workspace number.

### 7.4 Motion spec

| Interaction | gnome | plasma | macos |
|---|---|---|---|
| Surface open | scale 0.96→1, fade, 180 ms OutCubic | fade 120 ms | scale 0.92→1 with OutBack, 260 ms |
| Surface close | fade 100 ms | fade 80 ms | scale 1→0.96 fade 150 ms |
| Dock magnify | — | — | per-icon scale 100 ms OutQuad, continuous |
| Dock launch | — | — | 2× bounce 320 ms |
| Bar hover | bg 100 ms | bg 80 ms | bg 120 ms |
| Workspace switch | Hyprland `slide`, speed 3 | `slidefade`, speed 2 | `slide` on `familiarSpring`, speed 5 |
| Overview enter | windows fly from position to grid 260 ms, dash rises 260 ms | crossfade + scale 200 ms | thumbs scale from position 300 ms spring, strip slides down |
| Switcher advance | selection bg slides 100 ms | 80 ms | 120 ms |

All durations multiplied by `Tokens.motionScale`, which reads `hyprctl -j getoption animations:enabled` (0 → instant) so Omarchy's "disable animations" respects Familiar.

### 7.5 Iconography

Familiar ships **no** brand icons. Requirements:
- Uses the user's current icon theme via `Quickshell.iconPath`.
- Symbolic glyphs inside the kit (Activities, search, close, chevrons, pin) come from a small inline SVG set drawn for the plugin (MIT), stroke 1.5 px at 16 px grid, tinted with `fg`.
- The app-menu button uses the Omarchy logo from the injected `omarchyPath` if present, else a generic 9-dot grid glyph.

### 7.6 Accessibility & input

- Every surface fully keyboard operable; focus ring is 2 px `accent` outside the element, radius `radius.sm`.
- Pointer targets ≥ 32 px in bar, ≥ 40 px in dock, ≥ 44 px in launcher.
- Respects `Tokens.motionScale` and Hyprland cursor size for hit-testing hot corners.
- Text never below 12 px at 1× scale.

---

## 8. Config surface (`shell.json` after enable)

```json
{
  "version": 1,
  "bar": {
    "id": "io.github.tuxclaw.familiar",
    "position": "top",
    "profile": "macos",
    "trayVisible": true,
    "hostOmarchyWidgets": true,
    "dockEnabled": "auto",
    "dockPosition": "auto",
    "dockIconSize": 52,
    "dockMagnification": "auto",
    "dockAutohide": "auto",
    "dockPinned": "chromium,alacritty,nautilus",
    "layout": {
      "right": [ { "id": "omarchy.network" }, { "id": "omarchy.audio" }, { "id": "omarchy.power" } ]
    }
  },
  "plugins": [
    { "id": "io.github.tuxclaw.familiar", "overviewProvider": "familiar", "launcherProvider": "familiar" }
  ]
}
```

`bar.layout.*` is still honored: the `omarchyWidgets` bar item renders exactly those entries through `barWidgetRegistry`, so `omarchy bar move omarchy.audio --section right` keeps working under Familiar. Extra keys on `bar:` (`profile`, `dock*`) survive because the host persist clones the JSON.

Precedence for any dock/launcher option: explicit value in `shell.json` > `"auto"` → profile JSON default (implemented by `service.resolved()`).

---

## 9. CLI / IPC reference

All of these hit `Overlay.qml` (the shell routes `call`/`summon`/`hide`/`toggle` to the overlay item, which forwards profile methods to the service).

```
omarchy plugin add https://github.com/tuxclaw/omarchy-familiar.git --enable --yes
omarchy-shell shell call   io.github.tuxclaw.familiar setProfile gnome
omarchy-shell shell call   io.github.tuxclaw.familiar setProfile plasma
omarchy-shell shell call   io.github.tuxclaw.familiar setProfile macos
omarchy-shell shell call   io.github.tuxclaw.familiar cycleProfile ''
omarchy-shell shell call   io.github.tuxclaw.familiar getProfile ''
omarchy-shell shell call   io.github.tuxclaw.familiar reapply ''        # regenerate familiar.lua + hyprctl reload + configerrors
omarchy-shell shell summon io.github.tuxclaw.familiar '{"surface":"launcher"}'
omarchy-shell shell summon io.github.tuxclaw.familiar '{"surface":"overview"}'
omarchy-shell shell summon io.github.tuxclaw.familiar '{"surface":"switcher","scope":"app"}'
omarchy-shell shell toggle io.github.tuxclaw.familiar '{"surface":"launcher"}'
omarchy-shell shell hide   io.github.tuxclaw.familiar
omarchy plugin disable io.github.tuxclaw.familiar     # back to omarchy.bar; familiar.lua becomes a loadable no-op
omarchy-shell shell call   io.github.tuxclaw.familiar uninstall ''      # removes the guarded require; run before `omarchy plugin remove`
omarchy plugin remove  io.github.tuxclaw.familiar
```

An Omarchy menu extension (`~/.config/omarchy/extensions/omarchy-menu.jsonc`) is installed by the README's optional step so **Setup ▸ Desktop profile ▸ GNOME / Plasma / Mac** appears in the stock menu (still on `SUPER + ALT + SPACE` in every profile):

```jsonc
{ "label": "Desktop profile", "items": [
  { "label": "GNOME",  "action": "omarchy-shell shell call io.github.tuxclaw.familiar setProfile gnome",
    "checked": "[ \"$(omarchy-shell shell call io.github.tuxclaw.familiar getProfile '')\" = gnome ]" },
  { "label": "Plasma", "action": "omarchy-shell shell call io.github.tuxclaw.familiar setProfile plasma",
    "checked": "[ \"$(omarchy-shell shell call io.github.tuxclaw.familiar getProfile '')\" = plasma ]" },
  { "label": "Mac",    "action": "omarchy-shell shell call io.github.tuxclaw.familiar setProfile macos",
    "checked": "[ \"$(omarchy-shell shell call io.github.tuxclaw.familiar getProfile '')\" = macos ]" }
]}
```

---

## 10. Build plan

| Milestone | Scope | Exit criteria |
|---|---|---|
| **M0 — skeleton** (1–2 days) | manifest (`bar`, `overlay`, `service`), `Service.qml`, `Overlay.qml` stub with `open(payloadJson)`/`close()`/profile methods, `Bar.qml` rendering a clock through the injected contract, profile JSONs, Lua fragments, `tests/validate.sh`, `tests/hypr.sh` | `omarchy plugin validate` + `qmllint` clean; enable/disable round-trips to stock bar; `setProfile` via `call` rewrites `familiar.lua`, `hyprctl reload` then `hyprctl configerrors` clean for all three profiles; persist path settled (§12 item 1); `qs.Ui` base type settled (§12 item 3) |
| **M1 — bars** | all bar items, three bar layouts, stock widget hosting via `barWidgetRegistry`, tray | Each profile's bar matches §4.2; `omarchy bar move` still works; `switchPanelFrom` tabs into stock panels |
| **M2 — dock** | `DockHost` inside the overlay, `DockSurface`, pins, running, magnify, context menu, autohide | Mac profile dock feels right at 60 fps on the 7900 XT and on an integrated GPU; dock survives summon/hide cycles (`keepLoaded`) |
| **M3 — launcher** | three launcher styles, ranking, frecency, Omarchy commands in results | Type-to-launch < 100 ms first paint from keypress |
| **M4 — overview + switcher** | `ScreencopyView` thumbs, strip, drag-to-workspace, switcher with modifier-release commit + 1.2 s fallback | All three overview styles; Alt/Cmd+Tab commits on release (§12 item 4 settled or fallback accepted) |
| **M5 — polish** | motion table, light-theme pass, hot corner, README, preview.png, marketplace submission | Published on plugins.omarchy.org; Okomart listing |

Testing checklist per PR: click, Esc, `summon`/`hide`/`toggle`, `call` for each profile method, disable, re-enable, `omarchy-restart-shell`, `uninstall` + remove, theme switch mid-session (colors follow `Color` live), monitor hotplug, scale 1×/1.5×/2×, `hyprctl configerrors` empty after every generated Lua write.

---

## 11. Risks and mitigations

| Risk | Mitigation |
|---|---|
| Quattro shell API surface (`qs.Ui` names, `serviceFor`, config mutator) is still moving. | Pin to the Omarchy 4.0.2 / Quattro commit in README; keep all shell-contract touchpoints in `Bar.qml`, `Overlay.qml`, `Service.qml` only; kit components are pure QtQuick. |
| A future shell change routes `summon`/`call` differently for multi-kind plugins. | Kinds stay `bar`, `overlay`, `service`; `panel` is never added back. The dock remains an overlay child regardless. |
| `ScreencopyView` cost with many windows. | Cap live thumbs to 12, static snapshot beyond; throttle to 15 fps while overview is open. |
| Modifier-release detection for the switcher inside a layer surface. | `keyboardFocus: Exclusive` while open; fallback timer commit at 1.2 s. |
| Generated Lua breaks the user's Hyprland config. | Every write is followed by `hyprctl reload` + `hyprctl configerrors`; a non-empty result restores `familiar.lua.prev` and notifies. Familiar never edits `bindings.lua` / `looknfeel.lua`. Disable leaves a loadable no-op so the `require` never fails. |
| Hyprland config drift if the user edits `familiar.lua`. | File header says "managed"; `reapply` is explicit; only the one guarded `require` line is ever added to `hyprland.lua`. |
| Trademark / look-alike concerns. | No brand icons, fonts, or wallpapers; profile labels are "GNOME"/"Plasma"/"Mac" as descriptors; README states no affiliation. |

---

## 12. Open questions for day one

Only what the verified platform did not settle:

1. **Persist API for `bar.profile`.** Whether `pluginRegistry.shellConfigMutator` (or an equivalent on `shell`) is injected into the service/overlay and what its signature is. Fallback is the jq edit + `omarchy-shell shell reloadConfig` shown in §5.2. Settle in M0 by reading `shell.qml`.
2. **Does overlay metadata `schema` render in Setup > Plugins**, or only `barWidget.schema` / `bar.schema`? If only the bar's renders, the two provider keys stay documented in README and remain editable by hand in `plugins[]`.
3. **`qs.Ui` base type** for a keep-loaded overlay that owns multiple layer windows (surface + dock). Candidates: plain `Item` (as written in §5.3) or `qs.Ui.Panel`. Routing is settled; only the base type name is open.
4. **Modifier-release detection** for the switcher inside a layer surface with `WlrKeyboardFocus.Exclusive`. If `Keys.onReleased` does not see the modifier, the 1.2 s fallback commit ships as the behavior and the hold-to-browse gesture is documented as approximate.
