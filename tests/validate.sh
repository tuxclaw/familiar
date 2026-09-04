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

mapfile -t qml_files < <(find "$ROOT" -type f -name '*.qml' -not -path '*/.git/*' | sort)
"$QMLLINT" -I "$OMARCHY_SHELL" "${qml_files[@]}"
