# Handoff — 2026-09-04

**Project:** `/home/tux/Documents/Projects/omarchy-familiar`
**Plugin id:** `io.github.tuxclaw.familiar`
**Spec:** `SPEC.md` (v0.2)
**Branch:** `andy/m2-dock` @ `8aa31e0`
**Live install:** `~/.config/omarchy/plugins/io.github.tuxclaw.familiar` (QML synced; git checkout may lag)
**Active bar:** Familiar GNOME profile (`omarchy bar use io.github.tuxclaw.familiar`)
**Revert:** `omarchy bar use omarchy.bar`
**shell.json backup:** `~/.config/omarchy/shell.json.bak.familiar.20260904121618`

## Status
M0 + **M1 complete**. **M2 dock live** (`8aa31e0`): overlay `DockHost`, GNOME bar + `dockEnabled=on` + autohide. Tux 14:42: Obsidian/OpenClaw icons work (`heuristicLookup`/`byId`). Hyprland writes still skipped.
Do not write `~/.config/hypr/familiar.lua` until keybinds/gaps.

## Hard platform facts
- Kinds: `bar`, `overlay`, `service` only. Never `panel` (summon prefers panel).
- IPC `call`/`summon` hit Overlay, not Service. Overlay forwards profile methods.
- No `pragma Singleton` across kinds. No Hyprlang `.conf`. Theme = `qs.Commons.Color`/`Style`.
- Custom bar **must not** use `required` on `omarchyPath` / `barWidgetRegistry` / `barConfig` (Loader injects after create). Host fallback bug: `errorString` undefined in `shell.qml`.
- Stock workspace focus: `bar.run("hyprctl dispatch " + Util.shellQuote('hl.dsp.focus({ workspace = "' + id + '" })'))`. Not `hyprctl dispatch workspace N`. Not `Hyprland.dispatch`.
- Clock calendar is stock `omarchy.clock` (`requestPopout` / `releasePopout` / `activePopout` / `clickTargets`).
- `isEnabled(familiar)` is true from `bar.id` even with `plugins: []`.
- Hyprland Lua fragments exist in-repo; **do not write** `~/.config/hypr/familiar.lua` until Tux wants keybinds/gaps.

## Tails
Use ACP `agentId: "codex"`. Isolated auth lives in `~/.openclaw/acpx/codex-home/auth.json` (copy from `~/.codex`, never echo). `agents.entries.codex` + `main.subagents.allowAgents: [codex, grok]`. Do **not** use OpenClaw `openai/gpt-5.6-sol` for long QML — idle-timeouts.

## GitHub
https://github.com/tuxclaw/omarchy-familiar (public, default `andy/m1-bars`). Account `tuxclaw`.
