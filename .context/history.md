# history.md

## [2026-09-04] M0 start
**Agent:** Sonic
**Branch:** andy/m0-skeleton (to be created by Tails)
**Changes:** Seeded `.context/`, copied SPEC.md (v0.2). Dispatching Tails for skeleton.
**Files:** `.context/decisions.md`, `.context/notes.md`, `SPEC.md`
**Commit:** none yet

## [2026-09-04] M0 skeleton complete
**Agent:** Tails
**Branch:** andy/m0-skeleton
**Changes:** Added the valid `bar`/`overlay`/`service` manifest, safe profile service and overlay IPC stubs, per-monitor clock bar, theme helper and UI pieces, three profile documents, three Hyprland Lua profiles with one shared-local prelude, offline validation/generation tests, documentation, and MIT license. M0 performs no live Hyprland write or reload.
**Validation:** `omarchy plugin validate .` passed; `tests/validate.sh` passed; `tests/hypr.sh` generated all three test Lua files; `luac -p` passed on each generated file; no repository symlinks.
**Assumptions:** Global `keepLoaded` covers both overlay and service; Quattro's documented `shellConfigMutator` remains the preferred installed-runtime persistence path; qmllint's known `qs.*` and `PanelWindow` environmental warnings are acceptable because the same warnings occur for the stock bar and lint exits 0.
**Commit:** `Build Familiar M0 plugin skeleton` (this commit)

## [2026-09-04] M0 review
**Agent:** Sam (ok), Shadow (timeout — not re-dispatched)
**Branch:** andy/m0-skeleton @ 8fd2fbc
**Changes:** none (read-only)
**Sam verdict:** blocker. `Service.qml` `reapply(outputPath)` lexical `startsWith` + `tests/hypr.sh` follows symlinks under `tests/out/`. Warnings: prototype-key profile ids; jq tmp not beside shell.json.
**Shadow partial:** `hl.dsp.killactive` not in `/usr/share/hypr/stubs/hl.meta.lua` (used in gnome/macos.lua). No final sign-off.

## [2026-09-04] M0 review fixes complete
**Agent:** Tails
**Branch:** andy/m0-skeleton
**Changes:** Removed path arguments from overlay/service `reapply()`, kept all M0 live applies skipped/refused, allowlisted profile ids, made fallback persistence use an adjacent atomic tempfile, replaced invalid close dispatchers, and made test Lua generation atomically replace regular destinations while refusing symlinks.
**Validation:** `tests/validate.sh` passed; `tests/hypr.sh` passed its embedded symlink-refusal case; explicit `--output` symlink test exited 3 without changing its target; `luac -p` passed for all three generated Lua files; `git diff --check` passed; no repository symlinks or test temp artifacts remained.
**Commit:** `Fix M0 review safety findings` (this commit)

## [2026-09-04] M1 attempt 1 incomplete
**Agent:** Tails
**Branch:** andy/m1-bars (from 040779c)
**Changes:** none. Researched Quattro widget injection then idle-timed out. No commit.

## [2026-09-04] M1 profile bars complete
**Agent:** Tails
**Branch:** andy/m1-bars
**Changes:** Replaced the clock-only surface with GNOME, Plasma, and macOS profile-driven left/center/right sections; added activities, app menu, active-app, grouped task, tray, workspace, notification, clock, spacer, and stock Omarchy-widget hosts; added stock-panel navigation and expanded QML validation to every plugin QML file.
**Validation:** `omarchy plugin validate .`, `tests/validate.sh`, `tests/hypr.sh`, generated-profile `luac -p`, and `git diff --check` passed. No plugin enablement or live Hyprland/config writes were performed.
**Commit:** `Build profile-driven Familiar bars` (this commit)

## [2026-09-04] M1 click-complete start
**Agent:** Sonic → Tails (ACP codex)
**Branch:** andy/m1-bars
**Changes:** Tux asked to finish M1 before M2. Seeding click-complete dispatch. Live bar enabled; clicks unproven. Stock workspace dispatcher is `hl.dsp.focus`, not `workspace N`.
**Files:** `.context/decisions.md`, `.context/notes.md`
**Commit:** pending Tails

## [2026-09-04] M1 bar clicks completed
**Agent:** Tails
**Branch:** andy/m1-bars
**Changes:** Matched workspace focus to the stock Lua dispatcher; made the stock `omarchy.clock` registry widget the primary clock path with settings discovered in any bar section; routed notifications through the first-party service and Activities through Familiar's overlay summon; matched stock layer-shell input and transparent-surface settings; added validation assertions for the click contracts.
**Files:** `Bar.qml`, `Overlay.qml`, `ui/bar/ActivitiesButton.qml`, `ui/bar/BarSection.qml`, `ui/bar/NotificationsIndicator.qml`, `ui/bar/WorkspacePips.qml`, `tests/validate.sh`, `.context/decisions.md`, `.context/notes.md`, `.context/history.md`
**Validation:** `tests/validate.sh`, `tests/hypr.sh`, `git diff --check`, and generated Lua syntax checks passed. QML lint produced its existing warning-only output and no errors. No live plugin, shell configuration, or Hyprland configuration was changed.
**Assumptions:** The installed Omarchy 4.0.2 registry exposes `omarchy.clock` as observed under `/usr/share/omarchy/shell`; Sonic will sync this commit to the separate live clone and perform pointer-level verification.
**Commit:** `Finish M1 bar click contracts` (`15819f3`; Sonic committed after Tails left the tree dirty). Handoff `a7a8f60`.

## [2026-09-04] M1 click iteration 2 start
**Agent:** Sonic → Tails (ACP codex)
**Branch:** andy/m1-bars
**Changes:** Confirmed from Tux's live proof that the injected Familiar bar painted all controls, while only stock right-side widgets accepted clicks. Replaced Activities, Notifications, workspace pips, and AppMenu custom MouseAreas with `qs.Ui.WidgetButton`; made the clock resolve and host only registry `omarchy.clock` with a `barWidgetRegistry.revision` dependency; and gave both Familiar and stock loaders stock-style implicit sizing and layout hints.
**Files:** `.context/decisions.md`, `.context/history.md`, `ui/bar/ActivitiesButton.qml`, `ui/bar/AppMenuButton.qml`, `ui/bar/BarSection.qml`, `ui/bar/NotificationsIndicator.qml`, `ui/bar/WorkspacePips.qml`, `tests/validate.sh`
**Validation:** `tests/validate.sh`, `tests/hypr.sh`, and `git diff --check` passed. QML lint retained its warning-only output and returned success. No live plugin, shell configuration, or Hyprland configuration was changed.
**Commit:** `Fix M1 bar click targets`
