# Handoff — 2026-09-04

**Project:** `/home/tux/Documents/Projects/omarchy-familiar`
**Plugin id:** `io.github.tuxclaw.familiar`
**Spec:** `SPEC.md` (v0.2)
**Branch:** `andy/m3-launcher` @ `cd2e31c`
**Live install:** `~/.config/omarchy/plugins/io.github.tuxclaw.familiar` (M3 launcher + dock Applications tile live). Tux 15:16 PDT: launcher/dock tile working.
**Active bar:** Familiar GNOME profile (`omarchy bar use io.github.tuxclaw.familiar`)
**Revert:** `omarchy bar use omarchy.bar`
**shell.json extra:** `bar.dockEnabled=on`, `bar.dockAutohide=on`, `bar.dockPinned=chromium,org.gnome.Nautilus,obsidian`
**shell.json backup:** `~/.config/omarchy/shell.json.bak.familiar.20260904121618`

## Status
M0 + **M1 complete**. **M2 dock live**. **M3 launcher complete** (Tux 15:16 PDT). Dock Applications tile at right end (hover bottom edge; autohide). GNOME bar has no Applications item — tile is dock-only. Hyprland writes still skipped.

Hot-reload lesson: new dock tiles may not mount until `omarchy restart shell` (Lua dispatch `hl.dsp.exec_cmd("omarchy-launch-shell")`). Do not spawn multiple shells.

**Next:** M4 overview + switcher (`SPEC.md` M4). Do not write `~/.config/hypr/familiar.lua` until Tux wants keybinds/gaps.

## Hard platform facts
- Kinds: `bar`, `overlay`, `service` only. Never `panel` (summon prefers panel).
- IPC `call`/`summon` hit Overlay, not Service. Overlay forwards profile methods.
- No `pragma Singleton` across kinds. No Hyprlang `.conf`. Theme = `qs.Commons.Color`/`Style`.
- Custom bar **must not** use `required` on `omarchyPath` / `barWidgetRegistry` / `barConfig` (Loader injects after create). Host fallback bug: `errorString` undefined in `shell.qml` — Familiar must load or the bar vanishes.
- Never assign Loader `implicitHeight`/`implicitWidth` (read-only; cold-start crash).
- Bar clicks: stock-style ModuleSlot + `pressModuleClickTarget` + `qs.Ui.WidgetButton`.
- Stock workspace focus: `bar.run("hyprctl dispatch " + Util.shellQuote('hl.dsp.focus({ workspace = "' + id + '" })'))`.
- Clock is registry `omarchy.clock`. Dock launch: `uwsm-app -- gtk-launch <id>.desktop`.
- `service.resolved()` is not reactive — `dockEnabled`/`dockAutohide` changes need `omarchy restart shell`.
- Tails ACP often cannot `git commit`/`checkout -b`; Sonic commits.

## Tails
Use ACP `agentId: "codex"`. Isolated auth lives in `~/.openclaw/acpx/codex-home/auth.json` (copy from `~/.codex`, never echo). `agents.entries.codex` + `main.subagents.allowAgents: [codex, grok]`. Do **not** use OpenClaw `openai/gpt-5.6-sol` for long QML — idle-timeouts.

## GitHub
https://github.com/tuxclaw/omarchy-familiar (public). Current work branch `andy/m3-launcher`. Account `tuxclaw`.
