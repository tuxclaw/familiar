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
**Commit:** `Fix M1 bar click targets` (`a6acae9`; Sonic committed). Handoff `51e03da`. Cold start then failed: Loader implicitHeight read-only. Stock bar restored.

## [2026-09-04] M1 ModuleSlot host start
**Agent:** Sonic → Tails (ACP codex)
**Branch:** andy/m1-bars
**Changes:** Fix load crash; copy stock ModuleSlot click host. Do not enable live.
**Commit:** pending Tails

## [2026-09-04] M1 ModuleSlot host complete
**Agent:** Tails (ACP codex)
**Branch:** andy/m1-bars
**Changes:** Removed Loader implicit-size assignments, wrapped Familiar and stock bar items in explicit stock-style slots, forwarded slot clicks through the registered WidgetButton targets, and copied the stock click-target resolution helpers into Familiar's bar host. Added regression assertions for both slot paths and the forbidden `implicitHeight:` assignment.
**Files:** `.context/.active-agent`, `.context/decisions.md`, `.context/history.md`, `.context/notes.md`, `Bar.qml`, `tests/validate.sh`, `ui/bar/BarSection.qml`
**Validation:** `tests/validate.sh`, `tests/hypr.sh`, `grep -F 'implicitHeight:' ui/bar/BarSection.qml` (no match), and `git diff --check` passed. The live bar, shell, Hyprland config, and installed plugin clone were not touched.
**Commit:** `Repair bar module slot hosting` (`24d910a`; Sonic committed). Re-enabled live; `familiar-bar` 32px both monitors.

## [2026-09-04] M1 complete
**Agent:** Sonic
**Branch:** andy/m1-bars @ 24d910a
**Changes:** Tux confirmed Activities, clock, Notifications, pips, and right stock icons all work.
**Commit:** none (proof only)

## [2026-09-04] M2 dock start
**Agent:** Sonic → Tails (ACP codex)
**Branch:** andy/m2-dock (from andy/m1-bars @ a96bf14)
**Changes:** Dispatch DockHost in overlay per SPEC §5.4/§7. No live hypr/bar switch in builder.
**Commit:** pending Tails

## [2026-09-04] M2 overlay dock complete
**Agent:** Tails (ACP codex)
**Branch:** requested `andy/m2-dock`; git metadata write was denied by the managed workspace, so the worktree remains on `andy/m1-bars`
**Changes:** Added the overlay-owned per-screen DockHost and dock kit, desktop-entry pin resolution, running-app grouping, focus-or-launch behavior, safe toplevel close requests, pin persistence, context actions, profile running indicators, Gaussian macOS magnification, and delayed autohide. Wired DockHost into the keep-loaded Overlay without changing its IPC/overview stub or enabling a panel kind.
**Files:** `Overlay.qml`, `Service.qml`, `ui/dock/DockHost.qml`, `ui/dock/DockSurface.qml`, `ui/dock/DockIcon.qml`, `ui/dock/DockSeparator.qml`, `ui/dock/RunningIndicator.qml`, `ui/dock/DockContextMenu.qml`, `tests/validate.sh`, `.context/decisions.md`, `.context/history.md`, `.context/.active-agent`
**Validation:** `tests/validate.sh`, `tests/hypr.sh`, and `git diff --check` passed. No live plugin, shell, Omarchy config, or Hyprland config was touched; `applyHypr()` remains skipped/refused.
**Commit:** `7f8c601` Build M2 overlay dock (Sonic committed on andy/m2-dock after Tails git deny).

## [2026-09-04] M2 dock icon/pin match start
**Agent:** Sonic → Tails
**Branch:** andy/m2-dock
**Changes:** Match running app_id to DesktopEntries.startupClass; never use raw appId as icon; pin desktop id.
**Commit:** pending Tails

## [2026-09-04] M2 dock icon/pin match complete
**Agent:** Tails (ACP codex)
**Branch:** andy/m2-dock
**Changes:** Resolved dock windows through exact, normalized, case-insensitive, and StartupWMClass desktop-entry matches; grouped windows under canonical desktop IDs; retained unresolved pinned tiles; copied AppLibrary-style URL, absolute-path, themed-icon, and executable-fallback handling; and made pinning persist matched desktop IDs while legacy class pins remain removable.
**Files:** `ui/dock/DockSurface.qml`, `ui/dock/DockIcon.qml`, `ui/dock/DockContextMenu.qml`, `tests/validate.sh`, `.context/history.md`, `.context/.active-agent`
**Validation:** `tests/validate.sh`, `tests/hypr.sh`, `git diff --check`, and the Loader `implicitHeight:` guard passed. No shell/bar restart, live Omarchy plugin copy, Hyprland write, or `applyHypr()` call was performed.
**Commit:** this commit (hash reported in handoff)

## [2026-09-04] M2 dock Obsidian icon fix complete
**Agent:** Tails (Codex)
**Branch:** andy/m2-dock
**Changes:** Resolved pinned and running applications through `DesktopEntries.byId()` and `DesktopEntries.heuristicLookup()` before the compatibility scans, so Obsidian's `md.obsidian.Obsidian` app ID groups under its canonical desktop entry. Passed the owning `DockSurface` into icon delegates for pointer-driven magnification, delegated icon lookup to the shell `AppLibrary`, decoded icons at physical pixel size, and switched failed image loads to the executable fallback icon.
**Files:** `ui/dock/DockSurface.qml`, `ui/dock/DockIcon.qml`, `tests/validate.sh`, `.context/history.md`, `.context/.active-agent`
**Validation:** `tests/validate.sh`, `tests/hypr.sh`, and `git diff --check` passed. No shell/bar restart, live Omarchy plugin copy, or Hyprland/config write was performed.
**Commit:** this commit (hash reported in handoff)

## [2026-09-04] M3 launcher complete
**Agent:** Tails (ACP codex) + Sonic review
**Branch:** andy/m3-launcher @ 693c24b
**Changes:** Replaced overlay launcher stub with profile styles (grid/kickoff/spotlight), SearchField focus, ranking/frecency in lib/Apps.js, Omarchy menu commands when query length >= 2, gtk-launch via uwsm-app. Dock/bar unchanged. No live plugin sync. No familiar.lua write.
**Files:** Overlay.qml, README.md, tests/validate.sh, lib/Apps.js, ui/launcher/*
**Validation:** tests/validate.sh, tests/hypr.sh, git diff --check passed.
**Commit:** 693c24b Build M3 overlay launcher

## [2026-09-04 18:26] Session save for M5 polish
**Agent:** Sonic
**Branch:** main @ 1e2b59c (will bump after this handoff commit)
**Changes:** Handoff rewritten for next session. M0–M4 live. Marketplace #4948. applyHypr still skipped.
**Next:** M5 polish.

## [2026-09-04 18:46] M5 polish in-tree
**Agent:** Tails (ACP codex) + Sonic review
**Branch:** andy/m5-polish
**Changes:** Motion tokens + light theme in Familiar.qml; GNOME 3px hot corner; overlay open/close motion; macos dock bounce; hypr/write.sh shared writer; Service.applyHypr() no path, --apply profile only. Sonic swapped generate-before-require so a failed first write cannot leave a dangling hyprland.lua require.
**Validation:** tests/validate.sh, tests/hypr.sh, git diff --check passed. No live plugin/hypr writes. No preview.png.
**Next:** Tux click-prove after live-sync; screenshot preview.png; marketplace #4948 still OPEN.

## [2026-09-10 08:20] Marketplace security audit
**Agent:** Sam (`openai/gpt-6-astra`)
**Branch:** main @ e9c3471 (clean)
**Verdict:** blocker
**HANCORE #4948 comment 5581787997:** #1 confirmed (unbounded IPC JSON.parse / retained payload / launcher query). #2 confirmed (Wayland titles/app IDs → Text.AutoText; extra launcher/tooltip sinks).
**Prior:** `reapply(outputPath)` escape remains closed.
**Blockers:** Overlay.qml:53; ui/bar/ActiveAppLabel.qml:11 (+ TaskButton, WindowThumb, SwitcherCell, AppGridCell, ResultRow, DockIcon tooltip).
**Warnings:** hypr/write.sh backup/rollback symlink + non-transactional apply; LauncherSurface frecency persist; DockSurface prototype-key collision.
**GitHub:** no comment posted.

## [2026-09-10] Marketplace security blockers fixed
**Agent:** Tails
**Branch:** andy/marketplace-security, based on e9c3471; left uncommitted for Sonic.
**Files:** Overlay.qml; lib/Input.js, lib/Apps.js; ui/bar/{ActiveAppLabel,TaskButton}.qml; ui/overview/WindowThumb.qml; ui/switcher/{SwitcherCell,SwitcherSurface}.qml; ui/launcher/{AppGridCell,ResultRow,LauncherSurface,SearchField}.qml; ui/dock/{DockIcon,DockSurface}.qml; hypr/write.sh; tests/{validate.sh,hypr.sh,security.js}.
**Changes:** 4096-byte pre-parse IPC cap; flat string-only allowlisted schema with sanitized retention; query/display cap 256, surface/scope cap 32; PlainText external sinks including custom tooltip content; atomic guarded frecency/backup/rollback; staged Hypr require validation and two-file rollback; null-prototype grouping maps.
**Assumptions:** Missing IPC input defaults to {}; omitted surface defaults to launcher; scope remains a bounded string to preserve existing behavior. Hypr preflight validates the existing require-insertion contract; runtime errors trigger rollback.
**Tests:** tests/validate.sh exit 0 (Security regression tests passed; qmllint import/unqualified-access warnings remain); tests/hypr.sh exit 0 (Hypr writer tests passed); git diff --check clean. Regression coverage includes oversized/multibyte input before parse, null/extra keys/nested values, sanitized open/toggle/advance, PlainText sinks, prototype keys, frecency symlink refusal, backup symlinks, invalid require order, first-apply and existing-file rollback.
**Handoff:** No push, GitHub comment, live-sync, restart, or branch switch. Active-agent marker cleared.

## [2026-09-10 12:21] M5 closeout start — reapply IPC refused
**Agent:** Sonic → Tails (ACP codex)
**Branch:** andy/m5-reapply-ipc from main @ c7dc4bf
**Changes:** Live-prove found `getProfile ''` = gnome; familiar-bar 32px + familiar-dock both monitors; `hyprctl configerrors` empty. `reapply ''` = refused because host `call()` always passes `arg: string`. Dispatching Tails to accept empty arg only.
**Files:** Overlay.qml, tests/validate.sh, tests/security.js, .context/decisions.md
**Commit:** pending Tails

## [2026-09-10] M5 reapply IPC fix complete
**Agent:** Tails
**Branch:** andy/m5-reapply-ipc; left uncommitted for Sonic.
**Changes:** Overlay accepts omitted or one empty/whitespace-only string and calls Service.reapply with zero arguments; nonblank, non-string, and extra arguments are refused. Service.reapply/applyHypr and setProfile guards remain unchanged. Updated validation contract and VM regression coverage.
**Files:** Overlay.qml, tests/validate.sh, tests/security.js, .context/history.md, .context/.active-agent.
**Tests:** tests/validate.sh passed (QML lint warnings); tests/hypr.sh passed; git diff --check passed.
**Assumptions:** Supplied live host proof is authoritative; whitespace-only strings count as empty. No live IPC rerun, plugin sync, restart, host config writes, commit, push, or branch switch. Active-agent marker cleared.

## [2026-09-10 12:28] M5 reapply IPC Sonic verify
**Agent:** Sonic
**Branch:** andy/m5-reapply-ipc
**Changes:** Independent verify. Overlay accepts omitted/blank host arg, calls Service.reapply() with 0 args, refuses non-empty. Restored Service zero-arg assert in validate.sh. tests/validate.sh 0, tests/hypr.sh 0, git diff --check 0. Committing then live-sync Overlay.qml only.
**Commit:** pending
