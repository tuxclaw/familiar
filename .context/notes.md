# notes.md

## [2026-09-04] Sonic — live box facts
- Omarchy 4.0.2-1, Hyprland 0.56.2, `OMARCHY_PATH=/usr/share/omarchy`.
- Bar contract (`shell/plugins/bar/Bar.qml` + `shell.qml`): root `Item`; required `omarchyPath`, `barWidgetRegistry`, `barConfig`; optional `shell`, `manifest`, `pluginRegistry`; expose `fontFamily` and `switchPanelFrom(owner, direction)`.
- Overlay `open(payloadJson)` receives a JSON string (see `omarchy.clipboard`, `omarchy.osd`).
- Host injects `service` into overlay if the item has `property var service`.
- Bar reaches service via `shell.serviceFor(manifest.id)` — configureBar does not inject `service`.
- `omarchy plugin validate <dir>` is `/usr/bin/omarchy-plugin-validate`. No symlinks. kinds need matching entryPoints (`bar`, `overlay`, `service`).
- `qmllint` is `/usr/lib/qt6/bin/qmllint` (not on PATH). Use `-I /usr/share/omarchy/shell`.
- Lua APIs: `hl.config`, `hl.curve`, `hl.animation`, `hl.layer_rule`, `hl.unbind`, `o.bind("SUPER + SPACE", label, cmd, opts)`, `o.window`, `{ release = true }`. No `bindr`. Key form `"SUPER + SPACE"`.
- Stock `"SUPER + SPACE"` is Omarchy menu; Mac profile must `hl.unbind` first. Menu stays on `SUPER + ALT + SPACE`.
- Disable path (later): `familiar.lua` becomes a loadable no-op so `require("hypr.familiar")` never 404s.

## [2026-09-04] Sonic — M1 click gotchas
- Stock workspace click: `/usr/share/omarchy/shell/plugins/bar/widgets/Workspaces.qml` `focusWorkspace()` runs `bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))`.
- Stock clock is `BarWidget` + nested `Panel.qml` (`KeyboardPanel`). WidgetButton has its own MouseArea; it also `registerClickTarget`s on the bar.
- `isEnabled(familiar)` is true when `bar.id` is Familiar even with `plugins: []` — overlay/service should still load.
- Live clone: `~/.config/omarchy/plugins/io.github.tuxclaw.familiar` (separate git checkout). Repo edits do not apply until synced.
- Revert bar: `omarchy bar use omarchy.bar`.
