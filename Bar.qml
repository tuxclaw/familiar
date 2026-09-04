import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import "ui/bar"

Item {
  id: root

  required property string omarchyPath
  required property var barWidgetRegistry
  required property var barConfig
  property var shell: null
  property var manifest: null
  property var pluginRegistry: null

  property string fontFamily: Style.font.family

  function switchPanelFrom(owner, direction) {
    return false
  }

  readonly property var service: shell && manifest && typeof shell.serviceFor === "function"
    ? shell.serviceFor(manifest.id) : null
  readonly property var profile: service ? service.currentProfile : ({})
  readonly property var profileBar: profile.bar || ({
    "position": "top",
    "height": 32,
    "reserve": true,
    "transparent": "solid",
    "clockFormat": "ddd HH:mm"
  })

  Familiar {
    id: familiar
    profile: root.profile
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: barWindow

      required property var modelData
      screen: modelData
      anchors.top: root.profileBar.position === "top"
      anchors.bottom: root.profileBar.position === "bottom"
      anchors.left: true
      anchors.right: true
      implicitHeight: familiar.px(root.profileBar.height || 32)
      exclusiveZone: root.profileBar.reserve === false ? 0 : implicitHeight
      color: "transparent"

      WlrLayershell.namespace: "familiar-bar"
      WlrLayershell.layer: WlrLayer.Top

      BarSurface {
        anchors.fill: parent
        mode: root.profileBar.transparent || "solid"

        ClockLabel {
          anchors.centerIn: parent
          fontFamily: root.fontFamily
          format: root.barConfig.clockFormat && root.barConfig.clockFormat !== "auto"
            ? root.barConfig.clockFormat : root.profileBar.clockFormat || "ddd HH:mm"
        }
      }
    }
  }
}
