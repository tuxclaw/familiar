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
