#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
QMLLINT=/usr/lib/qt6/bin/qmllint
OMARCHY_SHELL=/usr/share/omarchy/shell

omarchy plugin validate "$ROOT"

mapfile -t qml_files < <(find "$ROOT" -type f -name '*.qml' -not -path '*/.git/*' | sort)
"$QMLLINT" -I "$OMARCHY_SHELL" "${qml_files[@]}"
