# Familiar

Familiar is an experimental Omarchy Quattro plugin skeleton for switching among GNOME-, Plasma-, and Mac-inspired desktop paradigms. It uses Omarchy's existing theme through `qs.Commons.Color` and `Style` and targets the single long-running `omarchy-shell` Quickshell process.

Familiar is independent software and is not affiliated with, endorsed by, or sponsored by Omarchy, GNOME, KDE, Plasma, or Apple. Product names identify the interaction paradigms described by the profiles; no trademarked artwork, fonts, or wallpapers are included.

## M0 safety status

**Development build:** the bar, dock, and launcher milestones are implemented. Overview and switcher remain preview stubs, and Hyprland application is deliberately safety-gated while profile keybind work is out of scope.

The service deliberately skips pathless applies and refuses every path-bearing apply during M0. Only `tests/hypr.sh` generates Lua, using atomic replacement inside its output directory and refusing symlink destinations. The plugin does not edit `~/.config/hypr`, add a `require` to `hyprland.lua`, reload Hyprland, spawn another Quickshell process, or modify the live desktop when loaded or destroyed.

## Validate

Requirements: Omarchy 4.0.2 Quattro, Qt 6.11's `qmllint`, Bash, and `jq` for the service's future persistence fallback.

```bash
./tests/validate.sh
./tests/hypr.sh
```

The second command writes test-only concatenations to:

- `tests/out/familiar-gnome.lua`
- `tests/out/familiar-plasma.lua`
- `tests/out/familiar-macos.lua`

Each output hoists the shared `familiar`, `id`, and `surface()` locals exactly once. A later installer must add `require("hypr.familiar")` immediately after `require("hypr.looknfeel")`, not after bindings; M0 performs no installation.

## Profile API

The keep-loaded overlay routes `setProfile`, `cycleProfile`, `getProfile`, and pathless `reapply()` to the injected service. `open(payloadJson)` accepts JSON with `surface` set to `launcher`, `overview`, or `switcher`. The launcher is live; overview and switcher are still routing stubs.

Summon the launcher with:

```sh
omarchy-shell shell summon io.github.tuxclaw.familiar '{"surface":"launcher"}'
```

Its layout follows the active profile (`grid`, `kickoff`, or `spotlight`). Type to filter, use the arrow keys to select, Enter to launch, and Escape to close. Launch frequency is stored in `~/.local/state/familiar/frecency.json`; matching Omarchy menu actions appear after two query characters.

The preferred profile persistence path uses the host's `pluginRegistry.shellConfigMutator` and mutates its cloned config in place. If unavailable, the service has a `jq` fallback for the normal installed-plugin runtime. This path is not exercised by validation.

## License

MIT. See [LICENSE](LICENSE).
