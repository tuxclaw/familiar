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
