import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Commons
import "ui/bar"

Item {
  id: root

  property string omarchyPath: ""
  property var barWidgetRegistry: ({})
  property var barConfig: ({})
  property var shell: null
  property var manifest: null
  property var pluginRegistry: null
  property var activePopout: null
  property var clickTargets: []

  property string fontFamily: Style.font.family
  property var hostedStockItems: []
  readonly property string position: profileBar.position || "top"
  readonly property bool vertical: false
  readonly property int barSize: familiar.px(profileBar.height || 32)
  readonly property color foreground: Color.bar.text
  readonly property color barForeground: Color.bar.text
  readonly property string clockFormat: barConfig.clockFormat && barConfig.clockFormat !== "auto"
    ? barConfig.clockFormat : profileBar.clockFormat || "ddd HH:mm"

  function registerHostedItem(item) {
    if (!item || hostedStockItems.indexOf(item) !== -1) return
    var next = hostedStockItems.slice()
    next.push(item)
    hostedStockItems = next
  }

  function unregisterHostedItem(item) {
    hostedStockItems = hostedStockItems.filter(function(candidate) { return candidate !== item })
  }

  function registerClickTarget(target) {
    if (!target || clickTargets.indexOf(target) !== -1) return
    var next = clickTargets.slice()
    next.push(target)
    clickTargets = next
  }

  function unregisterClickTarget(target) {
    clickTargets = clickTargets.filter(function(item) { return item !== target })
  }

  function hostedBarWidget(pluginId, methodName, openedOnly) {
    var id = String(pluginId || "")
    for (var i = 0; i < hostedStockItems.length; i++) {
      var item = hostedStockItems[i]
      if (!item || String(item.moduleName || "") !== id) continue
      if (openedOnly && item.opened !== true) continue
      if (!methodName || typeof item[methodName] === "function") return item
    }
    return null
  }

  function summonBarWidget(pluginId) {
    var item = hostedBarWidget(pluginId, "open", false)
    if (!item) return false
    item.open()
    return true
  }

  function hideBarWidget(pluginId) {
    var item = hostedBarWidget(pluginId, "close", true)
      || hostedBarWidget(pluginId, "close", false)
    if (!item) return false
    item.close()
    return true
  }

  function isBarWidgetOpen(pluginId) {
    return hostedBarWidget(pluginId, "", true) !== null
  }

  function switchPanelFrom(owner, direction) {
    var current = hostedStockItems.indexOf(owner)
    if (current < 0 || hostedStockItems.length < 2) return false
    var step = direction < 0 ? -1 : 1
    for (var offset = 1; offset < hostedStockItems.length; offset++) {
      var candidate = hostedStockItems[(current + step * offset + hostedStockItems.length) % hostedStockItems.length]
      if (!candidate || candidate === owner) continue
      if (typeof candidate.open === "function") {
        candidate.open()
        return true
      }
      if (typeof candidate.toggle === "function") {
        candidate.toggle()
        return true
      }
    }
    return false
  }

  function requestPopout(owner) {
    if (activePopout === owner) return
    if (activePopout) {
      if ("closeForPopoutSwitch" in activePopout) activePopout.closeForPopoutSwitch()
      else if ("close" in activePopout) activePopout.close()
    }
    activePopout = owner
  }

  function releasePopout(owner) {
    if (activePopout === owner) activePopout = null
  }
  function showTooltip(owner, text) {}
  function hideTooltip(owner) {}

  readonly property var service: shell && manifest && typeof shell.serviceFor === "function"
    ? shell.serviceFor(manifest.id) : null
  readonly property var profile: service ? service.currentProfile : ({})
  readonly property var profileBar: profile.bar || ({
    "position": "top",
    "height": 32,
    "reserve": true,
    "transparent": "solid",
    "left": ["activities", "workspaces"],
    "center": ["clock", "notifications"],
    "right": ["omarchyWidgets"],
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
      anchors.top: root.position === "top"
      anchors.bottom: root.position === "bottom"
      anchors.left: true
      anchors.right: true
      implicitHeight: root.barSize
      exclusiveZone: root.profileBar.reserve === false ? 0 : implicitHeight
      color: "transparent"

      WlrLayershell.namespace: "familiar-bar"
      WlrLayershell.layer: WlrLayer.Top

      BarSurface {
        anchors.fill: parent
        mode: root.profileBar.transparent || "solid"

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: Style.spacing.md
          anchors.rightMargin: Style.spacing.md
          spacing: Style.spacing.md

          BarSection {
            bar: root
            role: "left"
            items: root.profileBar.left || []
            alignment: Qt.AlignLeft
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.fillHeight: true
          }

          BarSection {
            bar: root
            role: "center"
            items: root.profileBar.center || []
            alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.fillHeight: true
          }

          BarSection {
            bar: root
            role: "right"
            items: root.profileBar.right || []
            alignment: Qt.AlignRight
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.fillHeight: true
          }
        }
      }
    }
  }
}
