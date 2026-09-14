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
assert_contains ui/bar/BarSection.qml 'copy.format = bar.clockFormat'
assert_contains ui/bar/BarSection.qml 'function enforceClockFormat()'
assert_contains ui/bar/BarSection.qml 'if (familiarSlot.hostsStockClock && mouse.button === Qt.RightButton) return'
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
assert_contains profiles/plasma.json '"right": ["tray", "omarchyWidgets", "weather", "clock"]'
assert_contains Bar.qml 'readonly property bool centeredBar:'
assert_contains Bar.qml 'Layout.fillWidth: root.centeredBar'
assert_contains Bar.qml 'Layout.preferredWidth: root.centeredBar ? 1 : implicitWidth'
assert_contains Bar.qml 'Layout.minimumWidth: root.centeredBar ? 0 : implicitWidth'
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
assert_contains ui/bar/ActivitiesButton.qml 'fixedWidth: root.style === "gnome" ? 44 : 27'
# Activities chrome stays scoped to GNOME; other overview styles retain their layout.
assert_contains ui/overview/OverviewSurface.qml 'visible: root.style !== "gnome"'
assert_contains ui/overview/OverviewSurface.qml 'visible: root.style === "gnome"'
assert_contains ui/overview/OverviewSurface.qml 'style: root.style'
assert_contains ui/overview/WorkspaceStrip.qml 'visible: root.style === "gnome"'
assert_contains ui/overview/WindowThumb.qml 'model: root.style === "gnome" ? 3 : 0'
assert_contains ui/overview/WindowThumb.qml 'visible: root.style === "gnome" || pointer.hovered'
assert_contains ui/overview/WindowThumb.qml 'text: Input.boundedText('
assert_contains ui/overview/WindowThumb.qml 'textFormat: Text.PlainText'
assert_contains Overlay.qml 'root.surface === "overview" && overview.style === "gnome" ? 0.88 : 0.72'
node - "$ROOT" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert/strict');
const rootPath = process.argv[2];
const plasma = JSON.parse(fs.readFileSync(rootPath + '/profiles/plasma.json', 'utf8'));
assert.equal(plasma.bar.position, 'top');
assert.equal(plasma.dock.enabled, false);
assert.equal(plasma.dock.position, 'bottom');
const bar = fs.readFileSync(rootPath + '/Bar.qml', 'utf8');
const barMotion = bar.match(/readonly property int motionCurve:\s*([^\n]+)/);
assert.ok(barMotion, 'Bar must define its hover/color motion curve');
const Easing = {OutBack: 1, OutCubic: 2, Linear: 3};
for (const id of ['macos', 'gnome', 'plasma']) {
  const inherited = id === 'macos' ? Easing.OutBack : Easing.Linear;
  const actual = vm.runInNewContext(barMotion[1], {
    profile: {id}, familiar: {motionCurve: inherited}, Easing
  });
  assert.equal(actual, id === 'macos' ? Easing.OutCubic : inherited,
    `${id} bar hover/color easing`);
}
assert.doesNotMatch(bar, /Behavior\s+on\s+(?:height|implicitHeight|barSize|exclusiveZone)\b/);
console.log('Plasma top bar, disabled dock, and macOS bar easing checks passed');
const button = fs.readFileSync(rootPath + '/ui/bar/ActivitiesButton.qml', 'utf8');
const handler = button.match(/onPressed: function\(button\) \{([\s\S]*)\n  \}\n\}/)[1];
const calls = [];
const root = {style: 'gnome', bar: {manifest: {id: 'familiar'}, shell: {summon: (...args) => calls.push(args)}}};
const ctx = {root, button: 1, Qt: {LeftButton: 1, RightButton: 2},
  profileMenu: {open: () => calls.push('profile')}, pressFeedback: {restart() {}}};
const click = new vm.Script('(function(button) {' + handler + '})(button)');
click.runInNewContext(ctx);
assert.deepEqual(calls.splice(0), [['familiar', '{"surface":"overview"}']]);
ctx.button = 2;
click.runInNewContext(ctx);
assert.deepEqual(calls.splice(0), ['profile']);
ctx.button = 4;
click.runInNewContext(ctx);
assert.equal(calls.length, 0);
root.bar = null;
ctx.button = 1;
click.runInNewContext(ctx);
const overview = fs.readFileSync(rootPath + '/ui/overview/OverviewSurface.qml', 'utf8');
assert.match(overview, /livePreview: parent\.index < 12/);
assert.equal(fs.readFileSync(rootPath + '/ui/overview/WorkspaceStrip.qml', 'utf8').includes('ScreencopyView {'), false);
console.log('Activities left/right click, missing host, and preview cap checks passed');
JS
assert_contains ui/bar/AppMenuButton.qml 'WidgetButton {'
for button in ActivitiesButton AppMenuButton; do
  assert_contains "ui/bar/$button.qml" 'onPressed: function(button)'
  assert_contains "ui/bar/$button.qml" 'button === Qt.RightButton'
  assert_contains "ui/bar/$button.qml" 'profileMenu.open()'
  assert_contains "ui/bar/$button.qml" 'ProfileMenu { id: profileMenu; anchorItem: root; bar: root.bar }'
done
assert_contains ui/bar/ProfileMenu.qml 'PopupWindow {'
assert_contains ui/bar/ProfileMenu.qml '{ label: "GNOME", profileId: "gnome" }'
assert_contains ui/bar/ProfileMenu.qml '{ label: "Plasma", profileId: "plasma" }'
assert_contains ui/bar/ProfileMenu.qml '{ label: "Mac", profileId: "macos" }'
assert_contains ui/bar/ProfileMenu.qml 'service.getProfile()'
assert_contains ui/bar/ProfileMenu.qml 'root.currentProfile === modelData.profileId ? "✓" : ""'
assert_contains ui/bar/ProfileMenu.qml 'targetService.setProfile(profileId)'
assert_contains ui/bar/ProfileMenu.qml 'onClicked: root.pick(modelData.profileId)'
assert_contains ui/bar/ProfileMenu.qml 'HyprlandFocusGrab {'
assert_contains ui/bar/ProfileMenu.qml 'windows: [root]'
assert_contains ui/bar/ProfileMenu.qml 'onCleared: root.close()'
assert_contains Bar.qml 'implicitHeight: root.barSize'
assert_contains Bar.qml 'exclusiveZone: root.profileBar.reserve === false ? 0 : implicitHeight'
if grep -Eq -- 'screen[[:space:]]*\.[[:space:]]*(width|height)' "$ROOT/Bar.qml"; then
  printf 'Bar geometry regression: screen dimensions found in Bar.qml\n' >&2
  exit 1
fi
if grep -Eq -- 'PanelWindow|exclusiveZone|screen[[:space:]]*\.[[:space:]]*(width|height)' "$ROOT/ui/bar/ProfileMenu.qml"; then
  printf 'Profile menu regression: panel or fullscreen geometry found\n' >&2
  exit 1
fi
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
assert_contains ui/dock/DockSurface.qml 'PwaMatcher.matchEntry(target, DesktopEntries.applications.values || [])'
assert_contains ui/dock/DockSurface.qml 'icon: entryIcon(desktop, pinnedId)'
assert_contains ui/dock/DockSurface.qml 'dockSurface: root'
assert_contains ui/dock/DockSurface.qml 'signal showLauncher()'
assert_contains ui/dock/DockSurface.qml 'name: "Applications"'
assert_contains ui/dock/DockSurface.qml 'Qt.resolvedUrl("applications-256.png")'
assert_contains ui/dock/DockSurface.qml 'showRunningIndicator: false'
assert_contains ui/dock/DockSurface.qml 'contextMenuEnabled: false'
assert_contains ui/dock/DockSurface.qml 'onActivated: root.showLauncher()'
assert_contains ui/dock/DockSurface.qml 'color: Color.menu.background'
assert_contains ui/dock/DockSurface.qml 'border.color: Color.menu.border'
assert_contains ui/dock/DockHost.qml 'signal showLauncher()'
assert_contains ui/dock/DockHost.qml 'onShowLauncher: host.showLauncher()'
assert_contains ui/dock/DockIcon.qml 'PanelToolTip {'
assert_contains ui/dock/DockIcon.qml 'text: Input.boundedText(root.tooltipText)'
assert_contains ui/dock/DockIcon.qml 'root.dockSurface.pointerPosition = mapToItem(root.dockSurface'
assert_contains ui/dock/DockIcon.qml 'Quickshell.iconPath("application-x-executable", "application-x-executable")'
assert_contains ui/dock/DockIcon.qml 'Quickshell.iconPath(value, "application-x-executable")'
assert_contains ui/dock/DockIcon.qml 'sourceSize.width: width * Screen.devicePixelRatio'
assert_contains ui/dock/DockIcon.qml 'status === Image.Error'
assert_contains ui/dock/DockIcon.qml 'value.indexOf("file://") === 0 || value.indexOf("image://") === 0'
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

assert_contains Service.qml 'readonly property var pinnedIds:'
assert_contains Service.qml 'Qt.resolvedUrl("lib/dock-pins.py")'
assert_contains Service.qml 'pinnedPersistProcess.write(JSON.stringify(root.writingDock) + "\n")'
assert_contains Service.qml 'else root.ingestPinned(pinnedStdout.text)'
python3 "$ROOT/tests/dock-pins-race.py"
assert_contains ui/dock/DockHost.qml 'WlrLayershell.layer: host.autohide ? WlrLayer.Overlay : WlrLayer.Top'
assert_contains ui/dock/DockHost.qml 'WlrLayershell.namespace: "familiar-dock-edge"'
assert_contains ui/dock/DockHost.qml 'visible: dockShown'
assert_contains ui/dock/DockHost.qml 'exclusionMode: host.autohide ? ExclusionMode.Ignore : ExclusionMode.Auto'
assert_contains Overlay.qml 'pinned: root.service ? root.service.pinnedIds : []'
assert_contains ui/dock/DockHost.qml 'property var pinned: service ? service.pinnedIds : []'
assert_contains ui/dock/DockHost.qml 'pinned: host.pinned'
assert_contains ui/dock/DockIcon.qml 'root.pinned && pressed && (pressedButtons & Qt.LeftButton)'
assert_contains ui/dock/DockIcon.qml 'interval: 450'
assert_contains ui/dock/DockSurface.qml 'DockPins.merge('
assert_contains ui/dock/DockSurface.qml 'DockPins.move('
assert_contains ui/dock/DockSurface.qml 'Behavior on x'
assert_contains ui/dock/DockFolderPopup.qml 'Behavior on y'
assert_contains Service.qml 'return DockPins.normalize(list)'
assert_contains ui/dock/DockIcon.qml 'Qt.styleHints.startDragDistance'
assert_contains ui/dock/DockIcon.qml 'if (reorderGesture) return'
assert_contains ui/dock/DockWidgetCluster.qml 'registry.entryPointUrl(manifest, "barWidget")'
assert_contains ui/dock/DockWidgetCluster.qml 'root.bar.registerHostedItem(item)'
assert_contains ui/dock/DockWidgetCluster.qml 'root.bar.pressModuleClickTarget(slot, mouse.button, mouse.x, mouse.y)'
assert_contains ui/dock/DockHost.qml 'shell.bar.barWidgetRegistry'
assert_contains ui/dock/DockHost.qml 'DockWidgetPicker {'
assert_contains Service.qml 'function persistWidgets(widgets, side)'
# Dock icons consume RMB without opening a menu; editing remains a long press.
if [[ -e "$ROOT/ui/dock/DockContextMenu.qml" ]] || grep -Eq 'DockContextMenu|menuOpen|[Cc]ontextRequested' "$ROOT"/ui/dock/*.qml; then
  printf 'Removed dock context menu wiring found\n' >&2
  exit 1
fi
assert_contains ui/dock/DockIcon.qml 'if (mouse.button !== Qt.LeftButton) return'
assert_contains ui/dock/DockIcon.qml 'root.dockSurface.editMode = true'
assert_contains ui/dock/DockIcon.qml 'if (!root.contextMenuEnabled) root.dockSurface.widgetPickerOpen = true'
assert_contains ui/dock/DockIcon.qml 'else root.dockSurface.togglePin(root.entry)'

# Includes scoped running/Applications Row-centering and shared glyph-baseline checks.
node "$ROOT/tests/dock.js"
node "$ROOT/tests/security.js"

mapfile -t qml_files < <(find "$ROOT" -type f -name '*.qml' -not -path '*/.git/*' | sort)
"$QMLLINT" -I "$OMARCHY_SHELL" "${qml_files[@]}"
