#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
QMLLINT=/usr/lib/qt6/bin/qmllint
OMARCHY_SHELL=/usr/share/omarchy/shell

omarchy plugin validate "$ROOT"

assert_contains() {
  local file=$1
  local text=$2
  if ! grep -Fq -- "$text" "$ROOT/$file"; then
    printf 'Missing M1 click contract in %s: %s\n' "$file" "$text" >&2
    return 1
  fi
}

assert_contains Bar.qml 'exclusionMode: ExclusionMode.Auto'
assert_contains Bar.qml 'surfaceFormat.opaque: false'
assert_contains Overlay.qml 'DockHost {'
assert_contains Overlay.qml 'onShowLauncher: root.open('\''{"surface":"launcher"}'\'')'
assert_contains Overlay.qml 'import "ui/launcher"'
assert_contains Overlay.qml 'LauncherSurface {'
assert_contains Overlay.qml 'import "ui/overview"'
assert_contains Overlay.qml 'import "ui/switcher"'
assert_contains Overlay.qml 'switcher.advance(sanitized)'
assert_contains Overlay.qml 'WlrLayershell.namespace: root.surface === "switcher" ? "familiar-switcher" : "familiar-overlay"'
assert_contains ui/overview/OverviewSurface.qml 'style: "gnome"'
assert_contains ui/overview/OverviewSurface.qml 'livePreview: parent.index < 12'
assert_contains ui/overview/WorkspaceStrip.qml 'hl.dsp.focus({ workspace = "'
assert_contains ui/overview/WindowThumb.qml 'ScreencopyView {'
assert_contains ui/overview/WindowThumb.qml 'interval: 67'
assert_contains ui/switcher/SwitcherSurface.qml 'function advance(payload)'
assert_contains ui/switcher/SwitcherSurface.qml 'interval: 1200'
assert_contains ui/launcher/AppGrid.qml 'reuseItems: true'
assert_contains ui/launcher/AppGrid.qml 'WheelHandler {'
assert_contains ui/launcher/LauncherSurface.qml 'search.focusInput()'
assert_contains ui/launcher/LauncherSurface.qml '.local/state/familiar/frecency.json'
assert_contains lib/Apps.js 'function rank(entries, query, frecency)'
assert_contains lib/Apps.js 'function menuCommands(text)'
assert_contains ui/bar/WorkspacePips.qml 'Util.shellQuote('\''hl.dsp.focus({ workspace = "'\'''
assert_contains ui/bar/BarSection.qml 'root.registryComponent("omarchy.clock")'
assert_contains ui/bar/BarSection.qml 'barWidgetRegistry.revision'
assert_contains ui/bar/BarSection.qml 'case "clock": return stockClockComponent'
assert_contains ui/bar/BarSection.qml 'root.registryComponent("omarchy.weather")'
assert_contains ui/bar/BarSection.qml 'case "weather": return stockWeatherComponent'
assert_contains ui/bar/BarSection.qml 'readonly property bool hostsStockWeather: itemName === "weather" && stockWeatherComponent !== null'
assert_contains ui/bar/BarSection.qml 'readonly property bool hostsStockWidget: hostsStockClock || hostsStockWeather'
assert_contains ui/bar/BarSection.qml 'if (familiarSlot.hostsStockWidget) root.bar.registerHostedItem(item)'
assert_contains ui/bar/BarSection.qml 'Component.onDestruction: if (hostsStockWidget && activeItem) root.bar.unregisterHostedItem(activeItem)'
assert_contains ui/bar/BarSection.qml 'if (itemId(entries[i]) === "omarchy.weather") return entries[i]'
assert_contains ui/bar/BarSection.qml '? root.weatherSettings() : root.itemSettings(familiarSlot.modelData)'
assert_contains profiles/gnome.json '"center": ["weather", "clock", "notifications"]'
assert_contains profiles/plasma.json '"right": ["tray", "omarchyWidgets", "weather", "clock", "spacer"]'
assert_contains profiles/macos.json '"right": ["tray", "omarchyWidgets", "weather", "clock"]'
assert_contains ui/bar/BarSection.qml 'root.bar.pressModuleClickTarget(familiarSlot, mouse.button, mouse.x, mouse.y)'
assert_contains ui/bar/BarSection.qml 'root.bar.pressModuleClickTarget(stockSlot, mouse.button, mouse.x, mouse.y)'
assert_contains ui/bar/BarSection.qml 'anchors.fill: parent'
if grep -Fq -- 'implicitHeight:' "$ROOT/ui/bar/BarSection.qml"; then
  printf 'Loader sizing regression in ui/bar/BarSection.qml: implicitHeight assignment found\n' >&2
  exit 1
fi
assert_contains ui/bar/ActivitiesButton.qml 'WidgetButton {'
assert_contains ui/bar/ActivitiesButton.qml 'Qt.resolvedUrl("../../assets/omarchy-logo.svg")'
assert_contains ui/bar/ActivitiesButton.qml 'labelVisible: false'
assert_contains ui/bar/ActivitiesButton.qml 'text: " "'
assert_contains ui/bar/AppMenuButton.qml 'WidgetButton {'
assert_contains ui/bar/NotificationsIndicator.qml 'WidgetButton {'
assert_contains ui/bar/NotificationsIndicator.qml 'text: "󰂛"'
if grep -Eq -- 'Notifications|unreadCount' "$ROOT/ui/bar/NotificationsIndicator.qml"; then
  printf 'Notification bell regression: label or invented unread count found\n' >&2
  exit 1
fi
assert_contains ui/bar/WorkspacePips.qml 'WidgetButton {'
assert_contains ui/bar/NotificationsIndicator.qml 'root.bar.run("omarchy-shell notifications showHistory")'
assert_contains ui/bar/ActivitiesButton.qml 'root.bar.shell.summon(root.bar.manifest.id, '\''{"surface":"overview"}'\'')'
assert_contains ui/dock/DockSurface.qml 'apps[i].startupClass'
assert_contains ui/dock/DockSurface.qml 'DesktopEntries.byId(rawTarget)'
assert_contains ui/dock/DockSurface.qml 'DesktopEntries.heuristicLookup(rawTarget)'
assert_contains ui/dock/DockSurface.qml 'var desktopId = entryId(windowDesktop, appId)'
assert_contains ui/dock/DockSurface.qml 'icon: desktop ? (desktop.icon || "") : ""'
assert_contains ui/dock/DockSurface.qml 'dockSurface: root'
assert_contains ui/dock/DockSurface.qml 'signal showLauncher()'
assert_contains ui/dock/DockSurface.qml 'name: "Applications"'
assert_contains ui/dock/DockSurface.qml 'Quickshell.iconPath("view-app-grid", "view-grid-symbolic")'
assert_contains ui/dock/DockSurface.qml 'showRunningIndicator: false'
assert_contains ui/dock/DockSurface.qml 'contextMenuEnabled: false'
assert_contains ui/dock/DockSurface.qml 'onActivated: root.showLauncher()'
assert_contains ui/dock/DockSurface.qml 'color: Color.menu.background'
assert_contains ui/dock/DockSurface.qml 'border.color: Color.menu.border'
assert_contains ui/dock/DockContextMenu.qml 'Color.menu.selectedBackground'
assert_contains ui/dock/DockContextMenu.qml 'Color.menu.text'
assert_contains ui/dock/DockHost.qml 'signal showLauncher()'
assert_contains ui/dock/DockHost.qml 'onShowLauncher: host.showLauncher()'
assert_contains ui/dock/DockIcon.qml 'root.dockSurface.pointerPosition = mapToItem(root.dockSurface'
assert_contains ui/dock/DockIcon.qml 'Quickshell.iconPath("application-x-executable", "application-x-executable")'
assert_contains ui/dock/DockIcon.qml 'appLibrary.iconSource(value)'
assert_contains ui/dock/DockIcon.qml 'sourceSize.width: width * Screen.devicePixelRatio'
assert_contains ui/dock/DockIcon.qml 'status === Image.Error'
assert_contains ui/dock/DockIcon.qml 'value.indexOf("file://") === 0 || value.indexOf("image://") === 0'
assert_contains ui/dock/DockContextMenu.qml 'root.entry.pinId || root.entry.desktopId'
assert_contains Familiar.qml '["hyprctl", "-j", "getoption", "animations:enabled"]'
assert_contains Familiar.qml 'Util.alpha(Color.foreground, 0.06)'
assert_contains Familiar.qml 'Util.alpha(Color.foreground, 0.12)'
assert_contains Bar.qml 'interval: 120'
assert_contains Bar.qml 'root.summonOverview()'
assert_contains Service.qml 'function applyHypr()'
assert_contains Service.qml '["bash", writerPath, "--apply", keymap]'
assert_contains Overlay.qml 'function reapply(arg)'
assert_contains Overlay.qml 'if (arguments.length > 1) return "refused"'
assert_contains Overlay.qml 'if (arguments.length === 1 && (typeof arg !== "string" || arg.trim() !== "")) return "refused"'
assert_contains Overlay.qml 'return service ? service.reapply() : "unknown"'
assert_contains Service.qml 'if (arguments.length !== 0) return "refused"'
if grep -Fq -- 'applyHypr("' "$ROOT/Service.qml" "$ROOT/Overlay.qml"; then
  printf 'Path-bearing applyHypr call found\n' >&2
  exit 1
fi

node "$ROOT/tests/security.js"

mapfile -t qml_files < <(find "$ROOT" -type f -name '*.qml' -not -path '*/.git/*' | sort)
"$QMLLINT" -I "$OMARCHY_SHELL" "${qml_files[@]}"
