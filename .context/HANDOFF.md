# Handoff — 2026-09-04

**Project:** `/home/tux/Documents/Projects/omarchy-familiar`
**Plugin id:** `io.github.tuxclaw.familiar`
**Spec:** `SPEC.md` (v0.2)
**Branch:** `andy/m3-launcher` @ `693c24b`
**Live install:** `~/.config/omarchy/plugins/io.github.tuxclaw.familiar` (still M2 dock QML; do not sync until Tux click-proves launcher)
**Active bar:** Familiar GNOME profile (`omarchy bar use io.github.tuxclaw.familiar`)
**Revert:** `omarchy bar use omarchy.bar`
**shell.json extra:** `bar.dockEnabled=on`, `bar.dockAutohide=on`, `bar.dockPinned=chromium,org.gnome.Nautilus,obsidian`
**shell.json backup:** `~/.config/omarchy/shell.json.bak.familiar.20260904121618`

## Status
M0 + **M1 complete**. **M2 dock live**. **M3 launcher in repo** @ `693c24b` — not live-synced. `tests/validate.sh` + `tests/hypr.sh` + `git diff --check` pass. Hyprland writes still skipped.

Summon: `omarchy-shell shell summon io.github.tuxclaw.familiar '{"surface":"launcher"}'` or GNOME/Plasma **Applications**. Esc / Enter / arrows. Frecency `~/.local/state/familiar/frecency.json`. Commands after 2 chars from omarchy-menu.jsonc.

**Next:** Tux click-prove launcher, then live-sync plugin QML. Do not write `~/.config/hypr/familiar.lua` until Tux wants keybinds/gaps. Click-outside-to-close is unproven (launcher Item fills overlay; Esc is wired).

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
