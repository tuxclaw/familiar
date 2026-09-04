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
assert_contains ui/launcher/LauncherSurface.qml 'search.focusInput()'
assert_contains ui/launcher/LauncherSurface.qml '.local/state/familiar/frecency.json'
assert_contains lib/Apps.js 'function rank(entries, query, frecency)'
assert_contains lib/Apps.js 'function menuCommands(text)'
assert_contains ui/bar/WorkspacePips.qml 'Util.shellQuote('\''hl.dsp.focus({ workspace = "'\'''
assert_contains ui/bar/BarSection.qml 'root.registryComponent("omarchy.clock")'
assert_contains ui/bar/BarSection.qml 'barWidgetRegistry.revision'
assert_contains ui/bar/BarSection.qml 'case "clock": return stockClockComponent'
assert_contains ui/bar/BarSection.qml 'if (familiarSlot.hostsStockClock) root.bar.registerHostedItem(item)'
assert_contains ui/bar/BarSection.qml 'root.bar.pressModuleClickTarget(familiarSlot, mouse.button, mouse.x, mouse.y)'
assert_contains ui/bar/BarSection.qml 'root.bar.pressModuleClickTarget(stockSlot, mouse.button, mouse.x, mouse.y)'
assert_contains ui/bar/BarSection.qml 'anchors.fill: parent'
if grep -Fq -- 'implicitHeight:' "$ROOT/ui/bar/BarSection.qml"; then
  printf 'Loader sizing regression in ui/bar/BarSection.qml: implicitHeight assignment found\n' >&2
  exit 1
fi
assert_contains ui/bar/ActivitiesButton.qml 'WidgetButton {'
assert_contains ui/bar/AppMenuButton.qml 'WidgetButton {'
assert_contains ui/bar/NotificationsIndicator.qml 'WidgetButton {'
assert_contains ui/bar/WorkspacePips.qml 'WidgetButton {'
assert_contains ui/bar/NotificationsIndicator.qml 'shell.firstPartyServiceFor("omarchy.notifications")'
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
assert_contains ui/dock/DockHost.qml 'signal showLauncher()'
assert_contains ui/dock/DockHost.qml 'onShowLauncher: host.showLauncher()'
assert_contains ui/dock/DockIcon.qml 'root.dockSurface.pointerPosition = mapToItem(root.dockSurface'
assert_contains ui/dock/DockIcon.qml 'Quickshell.iconPath("application-x-executable", "application-x-executable")'
assert_contains ui/dock/DockIcon.qml 'appLibrary.iconSource(value)'
assert_contains ui/dock/DockIcon.qml 'sourceSize.width: width * Screen.devicePixelRatio'
assert_contains ui/dock/DockIcon.qml 'status === Image.Error'
assert_contains ui/dock/DockIcon.qml 'value.indexOf("file://") === 0 || value.indexOf("image://") === 0'
assert_contains ui/dock/DockContextMenu.qml 'root.entry.pinId || root.entry.desktopId'

mapfile -t qml_files < <(find "$ROOT" -type f -name '*.qml' -not -path '*/.git/*' | sort)
"$QMLLINT" -I "$OMARCHY_SHELL" "${qml_files[@]}"
