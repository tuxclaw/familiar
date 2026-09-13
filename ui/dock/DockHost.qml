import QtQuick
import "../../lib/DockPins.js" as DockPins
import Quickshell
import Quickshell.Wayland
import qs.Commons
import "."

Item {
  id: host
  property var service: null
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
        property bool menuOpen: menu.visible
        property bool hovered: dockHover.hovered || edgeHover.hovered || menuOpen || dock.draggingPinned || dock.folderOpen || dock.editMode
        property bool autoHidden: host.autohide
        property bool dockShown: !host.autohide || !autoHidden

        screen: monitor.modelData
        visible: dockShown
        anchors.bottom: host.position === "bottom"
        anchors.left: host.position === "left"
        anchors.right: host.position === "right"
        implicitWidth: host.position === "bottom" ? Math.max(1, dock.implicitWidth, dock.folderPopupWidth) : Math.max(1, dock.implicitHeight)
        implicitHeight: host.position === "bottom" ? dock.implicitHeight + Math.max(dock.popupHeight, menuOpen ? menu.height + 8 : 0) : Math.max(1, dock.implicitWidth)
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

        Item {
          anchors.fill: parent

          DockSurface {
            id: dock
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            service: host.service
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
            onContextRequested: function(entry, position) { menu.openFor(entry, entry.pinned, mapToItem(parent, position.x, position.y).x) }
          }

          HoverHandler { id: dockHover; parent: dock }

          DockContextMenu {
            id: menu
            anchors.bottom: dock.top
            onPinRequested: function(desktopId, pin) {
              if (host.service) host.service.persistPinned(DockPins.toggle(host.pinned, desktopId, pin))
            }
            onNewWindowRequested: function(entry) { dock.launch(entry) }
            onQuitRequested: function(entry) {
              var windows = entry.windows || []
              for (var i = 0; i < windows.length; i++)
                if (typeof windows[i].close === "function") windows[i].close()
            }
          }
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
