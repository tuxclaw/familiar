# Handoff — 2026-09-04

**Project:** `/home/tux/Documents/Projects/omarchy-familiar`
**Plugin id:** `io.github.tuxclaw.familiar`
**Spec:** `SPEC.md` (v0.2)
**Branch:** `andy/m1-bars` @ `d0e12ef`
**Live install:** `~/.config/omarchy/plugins/io.github.tuxclaw.familiar` (tracks this branch)
**Active bar:** Familiar GNOME profile (`omarchy bar use io.github.tuxclaw.familiar`)
**Revert:** `omarchy bar use omarchy.bar`
**shell.json backup:** `~/.config/omarchy/shell.json.bak.familiar.20260904121618`

## Status
M0 skeleton + M1 thin bars are in. Plugin **is enabled**. Tux likes the GNOME bar look. **Clock, Notifications, Activities, workspace pips clicks still reported dead** after `d0e12ef` (hyprctl workspace dispatch + clock summon fallback). Next session: prove clicks with logs, then M2 dock.

## Hard platform facts
- Kinds: `bar`, `overlay`, `service` only. Never `panel` (summon prefers panel).
- IPC `call`/`summon` hit Overlay, not Service. Overlay forwards profile methods.
- No `pragma Singleton` across kinds. No Hyprlang `.conf`. Theme = `qs.Commons.Color`/`Style`.
- Custom bar **must not** use `required` on `omarchyPath` / `barWidgetRegistry` / `barConfig` (Loader injects after create). Host fallback bug: `errorString` undefined in `shell.qml`.
- Stock workspace focus: `bar.run("hyprctl dispatch workspace N")` (Omarchy `Util.execDetached`). Not `Hyprland.dispatch`.
- Clock calendar needs `bar.requestPopout` / `releasePopout` / `activePopout`.
- Hyprland Lua fragments exist in-repo; **do not write** `~/.config/hypr/familiar.lua` until Tux wants keybinds/gaps.

## Tails
Use ACP `agentId: "codex"`. Isolated auth lives in `~/.openclaw/acpx/codex-home/auth.json` (copy from `~/.codex`, never echo). `agents.entries.codex` + `main.subagents.allowAgents: [codex, grok]`. Do **not** use OpenClaw `openai/gpt-5.6-sol` for long QML — idle-timeouts.

## GitHub
Repo not created. `gh` not logged in on this host. After `gh auth login` (or Agent Settings → GitHub): `gh repo create eosdev-x/omarchy-familiar --private --source=. --remote=origin --push` from this checkout on `andy/m1-bars`.
