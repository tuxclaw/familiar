import QtQuick
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
  property var pinned: []

  signal showLauncher()

  Variants {
    model: host.enabled ? Quickshell.screens : []

    PanelWindow {
      id: dockWindow
      required property var modelData
      property bool menuOpen: menu.visible
      property bool hovered: dockHover.hovered || revealHover.hovered || menuOpen
      property bool autoHidden: host.autohide
      property bool dockShown: !host.autohide || !autoHidden

      screen: modelData
      anchors.bottom: host.position === "bottom"
      anchors.left: host.position === "left"
      anchors.right: host.position === "right"
      implicitWidth: host.position === "bottom" ? Math.max(1, dock.implicitWidth) : Math.max(1, dock.implicitHeight)
      implicitHeight: host.position === "bottom" ? dock.implicitHeight + (menuOpen ? menu.height + 8 : 0) : Math.max(1, dock.implicitWidth)
      exclusiveZone: host.autohide ? 0 : (host.position === "bottom" ? dock.implicitHeight : dock.implicitHeight)
      exclusionMode: host.autohide ? ExclusionMode.Ignore : ExclusionMode.Auto
      color: "transparent"
      surfaceFormat.opaque: false

      WlrLayershell.namespace: "familiar-dock"
      WlrLayershell.layer: WlrLayer.Top

      onHoveredChanged: {
        if (hovered) {
          hideDelay.stop()
          autoHidden = false
        } else if (host.autohide) {
          hideDelay.restart()
        }
      }

      Timer {
        id: hideDelay
        interval: 400
        onTriggered: dockWindow.autoHidden = true
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

        HoverHandler { id: dockHover; target: dock }
        HoverHandler { id: revealHover; target: revealStrip }
        Item {
          id: revealStrip
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          height: 2
        }

        DockContextMenu {
          id: menu
          anchors.bottom: dock.top
          onPinRequested: function(desktopId, pin) {
            var next = host.pinned.slice()
            var index = next.indexOf(desktopId)
            if (pin && index < 0) next.push(desktopId)
            if (!pin && index >= 0) next.splice(index, 1)
            if (host.service) host.service.persistPinned(next)
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
  }
}
