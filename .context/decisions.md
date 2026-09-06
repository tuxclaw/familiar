# decisions.md

## [2026-09-04] Familiar M0 — platform contract
**By:** Sonic
**Context:** Spec v0.2 vs live Omarchy 4.0.2-1 / Hyprland 0.56.2 Quattro.
**Decision:**
- Plugin id `io.github.tuxclaw.familiar`. Kinds: `bar`, `overlay`, `service` only. Never `panel`.
- Dock is an overlay child (`ui/dock/DockHost.qml`), not an entry point.
- IPC (`call`/`summon`/`hide`/`toggle`) hits Overlay. Overlay forwards profile methods to Service.
- No `pragma Singleton` across kinds. Profile store lives on the service instance.
- Hyprland is Lua. Generate `hypr/common.lua` + `hypr/{gnome,plasma,macos}.lua`. Runtime write target is `~/.config/hypr/familiar.lua` with guarded `require("hypr.familiar")` inserted **after** `require("hypr.looknfeel")` in `hyprland.lua`. Never edit `bindings.lua` / `looknfeel.lua`.
- Theme via `qs.Commons.Color` / `Style`. No TOML parser.
- Schema types: `string`, `integer`, `boolean`, `enum`, `path`, `multiselect`.
- `shellConfigMutator` mutates the clone in place; ignore return value.
**Alternatives considered:** Hyprlang `.conf` (wrong on this host); `kind: panel` for dock (steals summon).
**Status:** Active

## [2026-09-04] M0 does not enable the plugin on the live desktop
**By:** Sonic
**Context:** Scaffolding must not change Tux's running Hyprland/bar until validate is clean and Tux says enable.
**Decision:** Tails writes only inside this repo. Do not write `~/.config/hypr/familiar.lua`, do not edit `hyprland.lua`, do not `omarchy plugin add/enable`. `tests/hypr.sh` concatenates Lua into `tests/out/` only.
**Status:** Active

## [2026-09-04] M1 complete = live clicks, not just layout
**By:** Sonic
**Context:** Tux: finish M1 completely before M2. Plugin is enabled (GNOME look OK). Clock / Notifications / Activities / workspace pips still reported dead after `d0e12ef`.
**Decision:**
- Stay on `andy/m1-bars`. No M2 dock work.
- Do not write `~/.config/hypr/familiar.lua` or edit `hyprland.lua`.
- Workspace focus must match stock Omarchy 4.0.2 `plugins/bar/widgets/Workspaces.qml`: `bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))`. `hyprctl dispatch workspace N` is the wrong dispatcher on this Lua Hyprland. Not `Hyprland.dispatch`.
- Clock click must open the stock `omarchy.clock` calendar (`BarWidget` + `Panel.qml` / `KeyboardPanel`). Host the registry component; keep `requestPopout` / `releasePopout` / `activePopout` / `clickTargets` / `barSize` / `position` / `foreground` / `barForeground` on Familiar `Bar.qml` so KeyboardPanel can anchor.
- Notifications click must hit `shell.firstPartyServiceFor("omarchy.notifications").showRecentHistory()`.
- Activities click must `shell.summon(manifest.id, '{"surface":"overview"}')` into the keep-loaded overlay `PanelWindow`. Overlay stub is enough for M1; do not build M4 overview.
- Builders write only in the git repo. Sonic syncs the live plugin clone after verify.
**Alternatives considered:** Custom ClockLabel summon fallback (already failed); classic `hyprctl dispatch workspace N` (HANDOFF was wrong vs live stock widget).
**Status:** Active

## [2026-09-04] M1 click iteration 2 — WidgetButton, not MouseArea-on-Text
**By:** Sonic
**Context:** Tux 13:44 PDT: only right-side stock icons work. Activities, date, time, Notifications dead. That proves Familiar `bar` + registry + KeyboardPanel popouts work. Dead items are custom `MouseArea` on `Text`/`Item` (ClockLabel fallback, Activities, Notifications).
**Decision:** Iteration 2 (hard stop after this). Use `qs.Ui.WidgetButton` (the working right-icon path) for Activities, Notifications, pips, app menu. Clock must be the live registry `omarchy.clock` BarWidget — bind `barWidgetRegistry.revision` so it reloads when the catalogue fills; do not leave ClockLabel as the visible GNOME clock. Size Loaders like stock ModuleSlot (`implicitWidth/Height` from item, `Layout.fillHeight: true`). Repo only; Sonic syncs live clone.
**Alternatives considered:** More summon fallbacks on ClockLabel (handlers never fire).
**Status:** Active

## [2026-09-04] M1 load crash + ModuleSlot host
**By:** Sonic
**Context:** `a6acae9` assigned `implicitHeight` on Loader. Cold start 13:56: `BarSection.qml:83 implicitHeight is a read-only property` → Type unavailable → host `errorString` crash. Stock bar restored.
**Decision:** Do not assign `implicitWidth`/`implicitHeight` on Loader. Host each bar item in a stock-style ModuleSlot: Item with width/height from child implicit size, Loader `anchors.fill`, covering MouseArea calling `bar.pressModuleClickTarget` (copy from `/usr/s…/Bar.qml`). Add those helpers on Familiar `Bar.qml`. Do not `omarchy bar use familiar` until Sonic verifies load. No hypr writes. No M2.
**Status:** Active

## [2026-09-04] M2 dock — overlay child, no Hyprland writes
**By:** Sonic
**Context:** Tux 14:09: M1 proven, go on M2.
**Decision:** Dock is Overlay-owned `ui/dock/DockHost.qml`, never `kind: panel`. GNOME/Plasma dock off; macOS on. App launch = Omarchy `uwsm-app -- gtk-launch <id>.desktop`. `Service.applyHypr` stays skipped. No Loader `implicitHeight` assignments. Branch `andy/m2-dock` from current `andy/m1-bars`. Builder does not touch live bar/shell/hypr.
**Status:** Active — `applyHypr` skip superseded by M5 polish 2026-09-04

## [2026-09-04] M5 polish — motion, light theme, hot corner, applyHypr
**By:** Sonic
**Context:** M0–M4 live. HANDOFF next is M5. Marketplace #4948 open; validation wants `preview.png`; scanner false-positive on README wording about elevated permissions.
**Decision:**
- Branch `andy/m5-polish` from `main` @ `bb00289`. Tails implements in-repo only. No live plugin copy, no shell restart, no `~/.config/hypr` writes, no push.
- Motion: SPEC §7.4 table + `Tokens.motionScale` from `hyprctl -j getoption animations:enabled` (0 → instant). Extend existing `Familiar.qml` token object (or add `ui/tokens` wired through it). Do not create a parallel token system.
- Light theme: `ThemeBridge`/`isLight` from `Color.background` luminance. Hover/active `fg@0.06`/`fg@0.12`; blur alpha -0.1. No custom palette.
- Hot corner: GNOME only. Top-left of each familiar-bar, 120 ms dwell → overlay overview. Do not break Activities WidgetButton / ModuleSlot clicks.
- Ungate `Service.applyHypr()` with **no path argument**. Fixed output `~/.config/hypr/familiar.lua`. Refuse symlink/non-file. Adjacent tempfile like `tests/hypr.sh`. Allowlisted `gnome|plasma|macos`. Backup `~/.local/state/familiar/familiar.lua.prev`. `hyprctl reload` + restore prev on configerrors. Require insert only if `familiar:require` missing, and only after `require("hypr.looknfeel")` — never after bindings, never `sed` the SPEC way. `reapply()` calls `applyHypr()` with no path. Extra IPC path arg → refuse.
- Prefer one shipped writer (`hypr/write.sh` or equivalent) shared with `tests/hypr.sh`. Do not make live Service call `tests/hypr.sh`.
- README: do not name elevated-permission tools (scanner hit README:219); do not claim marketplace listing. Leave `preview.png` to Sonic (no fake image).
- Still: no `required` on host-injected bar props; no Loader `implicitHeight`/`implicitWidth`; no `pragma Singleton`; no `kind: panel`.
**Status:** Active
