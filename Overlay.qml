import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.Commons
import "ui/dock"
import "ui/launcher"

Item {
  id: root

  readonly property string moduleName: "io.github.tuxclaw.familiar"

  property var service: null
  property var shell: null
  property var manifest: null

  property string surface: "launcher"
  property bool opened: false
  property var payload: ({})
  readonly property var profile: service ? service.currentProfile : ({})
  readonly property var dockProfile: profile.dock || ({})

  function setProfile(profileId) {
    return service ? service.setProfile(profileId) : "unknown"
  }

  function cycleProfile() {
    return service ? service.cycleProfile() : "unknown"
  }

  function getProfile() {
    return service ? service.getProfile() : "unknown"
  }

  function reapply() {
    return service ? service.reapply() : "unknown"
  }

  function open(payloadJson) {
    var parsed = {}
    try {
      parsed = JSON.parse(payloadJson || "{}")
    } catch (error) {
      console.warn("Familiar: invalid overlay payload: " + error)
      return "invalid"
    }

    var requestedSurface = parsed.surface || "launcher"
    if (["launcher", "overview", "switcher"].indexOf(requestedSurface) < 0)
      return "unknown-surface"

    surface = requestedSurface
    payload = parsed
    if (opened && requestedSurface === "launcher") launcher.open(parsed)
    opened = true
    return "ok"
  }

  function close() {
    opened = false
    payload = ({})
    return "ok"
  }

  function toggle(payloadJson) {
    return opened ? close() : open(payloadJson)
  }

  DockHost {
    service: root.service
    enabled: root.service
      ? root.service.resolved("dockEnabled", root.dockProfile.enabled ? "on" : "off") !== "off"
      : false
    position: root.service ? root.service.resolved("dockPosition", root.dockProfile.position || "bottom") : "bottom"
    iconSize: root.service ? Number(root.service.resolved("dockIconSize", root.dockProfile.iconSize || 48)) : 48
    magnification: root.service
      ? root.service.resolved("dockMagnification", root.dockProfile.magnification ? "on" : "off") === "on"
      : false
    autohide: root.service
      ? root.service.resolved("dockAutohide", root.dockProfile.autohide ? "on" : "off") === "on"
      : false
    pinned: root.service ? root.service.pinnedApps() : []
    runningIndicator: root.dockProfile.runningIndicator || "dot"
    showRunning: root.dockProfile.showRunning !== false
  }

  PanelWindow {
    id: overlayWindow

    visible: root.opened
    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }
    color: "transparent"
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    surfaceFormat.opaque: false

    WlrLayershell.namespace: "familiar-overlay"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    onVisibleChanged: if (visible) {
      if (root.surface === "launcher") launcher.open(root.payload)
      else keyCatcher.forceActiveFocus()
    }

    Rectangle {
      anchors.fill: parent
      color: "#b0000000"
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.close()
    }

    Item {
      id: keyCatcher
      anchors.fill: parent
      focus: true

      Keys.onEscapePressed: function(event) {
        root.close()
        event.accepted = true
      }
    }

    LauncherSurface {
      id: launcher
      anchors.fill: parent
      visible: root.surface === "launcher"
      style: root.profile.launcher ? root.profile.launcher.style : "grid"
      service: root.service
      onDismiss: root.close()
    }

    Rectangle {
      id: card

      visible: root.surface !== "launcher"

      anchors.centerIn: parent
      width: Math.max(1, Math.min(900, overlayWindow.width - 64))
      height: Math.max(1, Math.min(640, overlayWindow.height - 64))
      radius: 16
      color: Color.menu.background
      border.color: Color.menu.border
      border.width: 1

      MouseArea {
        anchors.fill: parent
        onClicked: function(mouse) { mouse.accepted = true }
      }

      Text {
        id: heading
        anchors {
          top: parent.top
          left: parent.left
          right: parent.right
          margins: 28
        }
        text: root.surface === "overview" ? "Activities" : root.surface === "switcher" ? "Window Switcher" : "Application Launcher"
        color: Color.menu.text
        font.pixelSize: 28
        font.bold: true
      }

      Flickable {
        visible: root.surface === "overview"
        anchors {
          top: heading.bottom
          bottom: parent.bottom
          left: parent.left
          right: parent.right
          margins: 28
          topMargin: 20
        }
        clip: true
        contentWidth: width
        contentHeight: windowList.implicitHeight

        Column {
          id: windowList
          width: parent.width
          spacing: 10

          Repeater {
            model: ToplevelManager.toplevels.values || []

            Rectangle {
              id: windowButton
              required property var modelData

              width: windowList.width
              height: 64
              radius: 10
              color: windowMouse.containsMouse ? Color.menu.selectedBackground : Color.menu.background

              Text {
                anchors {
                  fill: parent
                  leftMargin: 18
                  rightMargin: 18
                }
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                text: {
                  var appId = String(windowButton.modelData.appId || "Unknown application")
                  var title = String(windowButton.modelData.title || "Untitled window")
                  return appId + "  —  " + title
                }
                color: Color.menu.text
                font.pixelSize: 17
              }

              MouseArea {
                id: windowMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (windowButton.modelData && typeof windowButton.modelData.activate === "function")
                    windowButton.modelData.activate()
                  root.close()
                }
              }
            }
          }

          Text {
            visible: (ToplevelManager.toplevels.values || []).length === 0
            width: windowList.width
            horizontalAlignment: Text.AlignHCenter
            text: "No open windows"
            color: Color.muted
            font.pixelSize: 17
          }
        }
      }

      Text {
        visible: root.surface === "switcher"
        anchors.centerIn: parent
        text: root.surface === "switcher"
          ? "Window switching is coming soon"
          : ""
        color: Color.menu.text
        font.pixelSize: 20
      }
    }
  }
}
