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

## [2026-09-04] Sonic — official click/host docs (not guesses)
Sources: `https://omarchy.org/manual/shell-plugins/`, `https://omarchy.org/manual/the-top-bar/`, `/usr/share/omarchy/shell/README.md`, `/usr/share/omarchy/shell/plugins/bar/README.md`, `/usr/share/omarchy/shell/plugins/bar/Bar.qml`, Quickshell QsWindow/PanelWindow (`https://quickshell.org/docs/v0.2.1/types/Quickshell/QsWindow/`).
- Omarchy: "the source is the documentation." Full `kind: bar` replaces `omarchy.bar`. Widgets inside the stock bar are `bar-widget`s loaded into **ModuleSlot**.
- Stock click path (Bar.qml): WidgetButton `registerClickTarget` + slot `MouseArea` `pressModuleClickTarget` → `triggerPress`. Custom QML module example in bar/README.md: Item with **explicit** `implicitWidth`/`implicitHeight: bar.barSize` and `MouseArea anchors.fill`.
- Host injects bar props after create (`configureBar`); plugin bar Loader is `asynchronous: true`. No `required` on those props.
- `bar` must expose: foreground/background/urgent, fontFamily, position, vertical, barSize, run, shellQuote, showTooltip/hideTooltip, requestPopout/releasePopout.
- QsWindow.mask default null = full window clickable. Non-null mask is the clickthrough region. Familiar bar does not set mask.
- Plugin QML under `~/.config/omarchy/plugins/` is watched with `inotifywait -r close_write,create,delete,move` → `reloadPlugins()`. Hard apply: `omarchy restart shell`.
- Tux 13:52: left/center still dead after WidgetButton pass. Right stock icons still work. Next change must copy stock ModuleSlot click delivery, not more summon fallbacks.
- 13:56 restart: bar gone. Log: `BarSection.qml:83 Invalid property assignment: implicitHeight is a read-only property` → `Type BarSection unavailable` → host `@shell.qml errorString is not defined` (no fallback). Reverted `omarchy bar use omarchy.bar` + restart 13:57. Stock `omarchy-bar` layer back on DP-1/DP-2.
