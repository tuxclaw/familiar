# Familiar

Familiar is an Omarchy Quattro plugin that switches among GNOME-, Plasma-, and Mac-inspired desktop paradigms. It uses Omarchy's theme through `qs.Commons.Color` and `Style` and runs inside the single long-running `omarchy-shell` Quickshell process.

Plugin id: `io.github.tuxclaw.familiar`

Familiar is independent software and is not affiliated with, endorsed by, or sponsored by Omarchy, GNOME, KDE, Plasma, or Apple. Product names identify interaction paradigms; no trademarked artwork, fonts, or wallpapers are included.

## Status (2026-09-04)

| Milestone | State |
|---|---|
| M0 skeleton | done |
| M1 bars | done (GNOME bar clicks proven) |
| M2 dock | done (autohide, icons/pins) |
| M3 launcher | done (grid / kickoff / spotlight + dock Applications tile) |
| M4 overview + switcher | in tree; live-sync separately |
| M5 polish | not started |

Kinds are `bar`, `overlay`, and `service` only. Never `panel`. Revert the bar with `omarchy bar use omarchy.bar`.

## Enable

```sh
omarchy plugin add https://github.com/tuxclaw/omarchy-familiar.git --enable --yes
omarchy bar use io.github.tuxclaw.familiar
```

GNOME bar left is Activities + workspace pips. Open the launcher from the dock Applications tile (hover the bottom edge when autohide is on) or:

```sh
omarchy-shell shell summon io.github.tuxclaw.familiar '{"surface":"launcher"}'
omarchy-shell shell summon io.github.tuxclaw.familiar '{"surface":"overview"}'
omarchy-shell shell summon io.github.tuxclaw.familiar '{"surface":"switcher","scope":"app"}'
```

Type to filter, arrows to select, Enter to launch, Escape to close. Frecency: `~/.local/state/familiar/frecency.json`. Omarchy menu commands appear after two query characters.

## Hyprland Lua

Profile Lua lives in `hypr/common.lua` plus `hypr/{gnome,plasma,macos}.lua`. Generate a file with:

```sh
./tests/hypr.sh --profile gnome --output ~/.config/hypr/familiar.lua
```

Insert this **immediately after** `require("hypr.looknfeel")`, never after bindings:

```lua
require("hypr.familiar") -- familiar:require
```

Then `hyprctl reload` and `hyprctl configerrors`. GNOME profile rebinds Super-tap (overview), Super+A (launcher), Alt+Tab (switcher), and Super+S (overview; was Omarchy scratchpad).

Disable leaves a loadable no-op so the `require` never 404s. `Service.qml` `applyHypr` is still pathless-skip until the live writer is ungated.

## Validate

```sh
./tests/validate.sh
./tests/hypr.sh
```

## License

MIT. See [LICENSE](LICENSE).
