#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
QMLLINT=/usr/lib/qt6/bin/qmllint
OMARCHY_SHELL=/usr/share/omarchy/shell

omarchy plugin validate "$ROOT"

"$QMLLINT" -I "$OMARCHY_SHELL" \
  "$ROOT/Familiar.qml" \
  "$ROOT/Service.qml" \
  "$ROOT/Overlay.qml" \
  "$ROOT/Bar.qml" \
  "$ROOT/ui/bar/BarSurface.qml" \
  "$ROOT/ui/bar/ClockLabel.qml"
