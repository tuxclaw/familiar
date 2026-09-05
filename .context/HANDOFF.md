# Handoff — 2026-09-04 18:26 PDT

**Project (local):** `/home/tux/Documents/Projects/omarchy-familiar`
**GitHub:** https://github.com/tuxclaw/familiar (public; renamed from omarchy-familiar)
**Plugin id:** `io.github.tuxclaw.familiar` (do not rename — live path depends on it)
**Spec:** `SPEC.md` (v0.2)
**Branch:** `main` @ `1e2b59c` (default). Milestone `andy/m*` branches kept as history.
**Account:** `tuxclaw`
**Live install:** `~/.config/omarchy/plugins/io.github.tuxclaw.familiar`
**Active bar:** Familiar GNOME (`omarchy bar use io.github.tuxclaw.familiar`)
**Revert bar:** `omarchy bar use omarchy.bar`
**shell.json extra:** `bar.dockEnabled=on`, `bar.dockAutohide=on`, `bar.dockPinned=chromium,org.gnome.Nautilus,obsidian`
**shell.json backup:** `~/.config/omarchy/shell.json.bak.familiar.20260904121618`
**hyprland.lua backup:** `~/.config/hypr/hyprland.lua.bak.familiar.20260904153012`

## Status
M0–**M4 complete** and live on this box. Marketplace submitted: https://github.com/omacom/omarchy-plugin-marketplace/issues/4948 (Desktop; Bar/Launcher/Hyprland). Awaiting maintainer approval — listing ≠ security review.

**Next session: M5 polish** — motion table, light-theme pass, hot corner, `preview.png`, README polish if needed, ungate `Service.qml` `applyHypr()` so profile switch rewrites `familiar.lua`, follow marketplace issue.

Tux 18:26 PDT: save progress, new session for polish.

## Proven on this machine
- M1 bar clicks (Activities, clock, Notifications, pips, stock right icons).
- M2 dock autohide + icons (Obsidian/OpenClaw via `DesktopEntries.byId` + `heuristicLookup`).
- M3 launcher + dock Applications tile (GNOME bar has no Applications item).
- M4 overview/switcher live-synced. Super tap / Activities for overview.
- Dock blur ghost on autohide: `ignore_alpha = 0.2` on `familiar-dock` (`0c0b498`). Tux 15:33: fixed.
- `hyprctl configerrors` empty after dropping invalid `ignore_zero`.

## Hyprland
GNOME `~/.config/hypr/familiar.lua` loaded. `require("hypr.familiar") -- familiar:require` immediately after `require("hypr.looknfeel")`.
GNOME rebinds: Super-tap overview, Super+A launcher, Alt+Tab switcher, **Super+S overview (was scratchpad)**. Super+Space still Omarchy menu.
`Service.qml` `applyHypr()` still returns `skipped`/`refused` — live writer not ungated. Profile switch does not regenerate Lua.

## Hard platform facts
- Kinds: `bar`, `overlay`, `service` only. Never `panel`.
- IPC `call`/`summon` hit Overlay, not Service.
- No `pragma Singleton`. No Hyprlang. Theme = `qs.Commons.Color`/`Style`.
- Custom bar **must not** `required` on `omarchyPath` / `barWidgetRegistry` / `barConfig`. Host fallback: `errorString` undefined in `shell.qml` — Familiar must load or the bar vanishes.
- Never assign Loader `implicitHeight`/`implicitWidth`.
- Bar clicks: ModuleSlot + `pressModuleClickTarget` + `qs.Ui.WidgetButton`.
- Workspace focus: `bar.run("hyprctl dispatch " + Util.shellQuote('hl.dsp.focus({ workspace = "' + id + '" })'))`.
- Dock launch: `uwsm-app -- gtk-launch <id>.desktop`.
- `service.resolved()` is not reactive — dock enable/autohide needs `omarchy restart shell`.
- New QML types often need a **single** `omarchy restart shell` (`hl.dsp.exec_cmd("omarchy-launch-shell")`). Do not spawn multiple shells.
- Tails ACP often cannot `git commit`/`checkout -b`; Sonic commits.

## Tails
ACP `agentId: "codex"`. Isolated auth `~/.openclaw/acpx/codex-home/auth.json` (copy from `~/.codex`, never echo). Do **not** use OpenClaw `openai/gpt-5.6-sol` for long QML.

## Install (others)
```sh
omarchy plugin add https://github.com/tuxclaw/familiar.git --enable --yes
omarchy bar use io.github.tuxclaw.familiar
```
