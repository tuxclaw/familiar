# Handoff — 2026-09-10 12:30 PDT

**Project (local):** `/home/tux/Documents/Projects/omarchy-familiar`
**GitHub:** https://github.com/tuxclaw/familiar (public)
**Plugin id:** `io.github.tuxclaw.familiar` (do not rename — live path depends on it)
**Spec:** `SPEC.md` (v0.2)
**Default branch:** `main` @ `c7dc4bf` (marketplace security). Live Overlay also has the reapply IPC fix.
**Working branch:** `andy/m5-reapply-ipc` @ `ede9307` (pushed). Do not merge to `main` until HANCORE re-validates `c7dc4bf`.
**Live install:** `~/.config/omarchy/plugins/io.github.tuxclaw.familiar`
**Active bar:** Familiar GNOME (`omarchy bar use io.github.tuxclaw.familiar`)
**Revert bar:** `omarchy bar use omarchy.bar`

## Status
M0–**M5 live** on this box. Tux 12:35 PDT: working perfect (includes hot corner). Profile-switch still unproven.

**Marketplace:** https://github.com/omacom/omarchy-plugin-marketplace/issues/4948 — HANCORE blockers closed at `c7dc4bf`; awaiting re-validation. Listing ≠ security review.

**This session:** documented `reapply ''` was `refused` because host `call(id, method, arg: string)` always passes one string. Overlay now accepts blank arg and calls pathless `Service.reapply()`. Live after one `omarchy restart shell`: `reapply ''` → `started`; `familiar.lua` rewritten 12:30 PDT; `reapply /tmp/x` → `refused`; `getProfile` = gnome; familiar-bar 32px + familiar-dock both monitors; `hyprctl configerrors` empty.

## Still unproven
- `setProfile plasma` / `macos` / cycle (not run; compositor rewrite).

## Hard platform facts
- Kinds: `bar`, `overlay`, `service` only. Never `panel`.
- IPC `call`/`summon` hit Overlay, not Service. `call` always supplies one string arg.
- No `pragma Singleton`. No Hyprlang. Theme = `qs.Commons.Color`/`Style`.
- Never assign Loader `implicitHeight`/`implicitWidth`.
- Bar clicks: ModuleSlot + `pressModuleClickTarget` + `qs.Ui.WidgetButton`.
- `applyHypr()` is pathless; writer is `hypr/write.sh --apply <gnome|plasma|macos>`.
- New Overlay.qml needs **one** `omarchy restart shell`. Do not spawn multiple shells.
- Tails = ACP `codex`. Sam = OpenClaw `openai/gpt-6-astra`. Sonic commits.

## Install (others)
```sh
omarchy plugin add https://github.com/tuxclaw/familiar.git --enable --yes
omarchy bar use io.github.tuxclaw.familiar
```
