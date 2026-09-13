import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import "."

Item {
  id: host
  property var service: null
  property var shell: service ? service.shell : null
  property bool enabled: false
  property string position: "bottom"
  property int iconSize: 48
  property bool magnification: false
  property bool autohide: false
  property bool showRunning: true
  property string runningIndicator: "dot"
  property var pinned: service ? service.pinnedIds : []

  signal showLauncher()

  Variants {
    model: host.enabled ? Quickshell.screens : []

    Item {
      id: monitor
      required property var modelData

      PanelWindow {
        id: dockWindow
        property bool hovered: dockHover.hovered || edgeHover.hovered || dock.draggingPinned || dock.folderOpen || dock.widgetPickerOpen || dock.editMode || dockWidgetBar.activePopout !== null
        property bool autoHidden: host.autohide
        property bool dockShown: !host.autohide || !autoHidden

        screen: monitor.modelData
        visible: dockShown
        anchors.bottom: host.position === "bottom"
        anchors.left: host.position === "left"
        anchors.right: host.position === "right"
        implicitWidth: host.position === "bottom" ? Math.max(1, dock.implicitWidth) : Math.max(1, dock.implicitHeight)
        implicitHeight: host.position === "bottom" ? dock.implicitHeight : Math.max(1, dock.implicitWidth)
        exclusiveZone: host.autohide ? 0 : (host.position === "bottom" ? dock.implicitHeight : dock.implicitHeight)
        exclusionMode: host.autohide ? ExclusionMode.Ignore : ExclusionMode.Auto
        color: "transparent"
        surfaceFormat.opaque: false

        WlrLayershell.namespace: "familiar-dock"
        WlrLayershell.layer: host.autohide ? WlrLayer.Overlay : WlrLayer.Top
        WlrLayershell.keyboardFocus: dock.folderOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        onHoveredChanged: {
          if (hovered) {
            hideDelay.stop()
            autoHidden = false
          } else if (host.autohide) {
            hideDelay.restart()
          }
        }

        Connections {
          target: host
          function onAutohideChanged() {
            hideDelay.stop()
            dockWindow.autoHidden = host.autohide && !dockWindow.hovered
          }
        }

        Timer {
          id: hideDelay
          interval: 400
          onTriggered: if (host.autohide && !dockWindow.hovered) dockWindow.autoHidden = true
        }

        DockWidgetBar {
          id: dockWidgetBar
          hostShell: host.shell
          barWidgetRegistry: host.shell && host.shell.bar ? host.shell.bar.barWidgetRegistry || null : null
          barConfig: host.service ? host.service.barConfig : ({})
          position: host.position
        }

        Item {
          anchors.fill: parent

          DockSurface {
            id: dock
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            service: host.service
            widgetBar: dockWidgetBar
            iconSize: host.iconSize
            magnification: host.magnification
            pinned: host.pinned
            running: ToplevelManager.toplevels.values || []
            showRunning: host.showRunning
            runningIndicator: host.runningIndicator
            opacity: dockWindow.dockShown ? 1 : 0
            transform: Translate { y: dockWindow.dockShown ? 0 : dock.height - 2; Behavior on y { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } } }
            Behavior on opacity { NumberAnimation { duration: 120 } }
            onShowLauncher: host.showLauncher()
          }

          HoverHandler { id: dockHover; parent: dock }
        }
      }

      PanelWindow {
        id: pickerWindow
        screen: monitor.modelData
        visible: host.enabled && dock.widgetPickerOpen
        anchors.bottom: host.position === "bottom"
        anchors.left: host.position === "left"
        anchors.right: host.position === "right"
        margins.bottom: host.position === "bottom" ? dock.implicitHeight + 8 : 0
        margins.left: host.position === "left" ? dockWindow.implicitWidth + 8 : 0
        margins.right: host.position === "right" ? dockWindow.implicitWidth + 8 : 0
        implicitWidth: widgetPicker.width
        implicitHeight: widgetPicker.height
        exclusiveZone: 0
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        surfaceFormat.opaque: false
        WlrLayershell.namespace: "familiar-dock-picker"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        DockWidgetPicker {
          id: widgetPicker
          dockSurface: dock
          focus: true
          Keys.onEscapePressed: dock.widgetPickerOpen = false
        }
      }

      PanelWindow {
        id: edgeWindow
        screen: monitor.modelData
        visible: host.autohide
        anchors.bottom: host.position === "bottom"
        anchors.left: host.position === "left"
        anchors.right: host.position === "right"
        implicitWidth: host.position === "bottom" ? dockWindow.implicitWidth : 2
        implicitHeight: host.position === "bottom" ? 2 : dockWindow.implicitHeight
        exclusiveZone: 0
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        surfaceFormat.opaque: false
        WlrLayershell.namespace: "familiar-dock-edge"
        WlrLayershell.layer: WlrLayer.Overlay

        HoverHandler {
          id: edgeHover
          onHoveredChanged: if (hovered) dockWindow.autoHidden = false
        }
      }
    }
  }
}
