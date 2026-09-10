import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.Commons
import "lib/Input.js" as Input
import "ui/dock"
import "ui/launcher"
import "ui/overview"
import "ui/switcher"

Item {
  id: root

  readonly property string moduleName: "io.github.tuxclaw.familiar"

  property var service: null
  property var shell: null
  property var manifest: null

  property string surface: "launcher"
  property bool opened: false
  property bool windowShown: false
  property real closedScale: 0.96
  property var payload: ({})
  readonly property var profile: service ? service.currentProfile : ({})
  readonly property var dockProfile: profile.dock || ({})

  Familiar {
    id: familiar
    profile: root.profile
  }

  function setProfile(profileId) {
    if (arguments.length !== 1) return "refused"
    return service ? service.setProfile(profileId) : "unknown"
  }

  function cycleProfile() {
    return service ? service.cycleProfile() : "unknown"
  }

  function getProfile() {
    return service ? service.getProfile() : "unknown"
  }

  function reapply(arg) {
    if (arguments.length > 1) return "refused"
    if (arguments.length === 1 && (typeof arg !== "string" || arg.trim() !== "")) return "refused"
    return service ? service.reapply() : "unknown"
  }

  function open(payloadJson) {
    var result = Input.parsePayload(payloadJson)
    if (result.status !== "ok") return result.status
    var sanitized = result.payload
    var requestedSurface = sanitized.surface
    if (opened && requestedSurface === "switcher" && switcher.visible) {
      switcher.advance(sanitized)
      return "ok"
    }
    closeDelay.stop()
    surface = requestedSurface
    payload = sanitized
    windowShown = true
    opened = false
    closedScale = root.profile.id === "macos" ? 0.92
      : root.profile.id === "plasma" ? 1 : 0.96
    if (requestedSurface === "launcher") launcher.open(sanitized)
    else if (requestedSurface === "overview") overview.open(sanitized)
    else switcher.open(sanitized)
    Qt.callLater(function() { root.opened = true })
    return "ok"
  }

  function close() {
    if (surface === "switcher" && opened) switcher.commit()
    return hideWindow()
  }

  function hideWindow() {
    closedScale = root.profile.id === "plasma" ? 1 : 0.96
    opened = false
    closeDelay.interval = familiar.motionFast
    closeDelay.restart()
    payload = ({})
    return "ok"
  }

  Timer {
    id: closeDelay
    onTriggered: root.windowShown = false
  }

  function toggle(payloadJson) {
    var result = Input.parsePayload(payloadJson)
    if (result.status !== "ok") return result.status
    return opened ? close() : open(JSON.stringify(result.payload))
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
    onShowLauncher: root.open('{"surface":"launcher"}')
  }

  PanelWindow {
    id: overlayWindow

    visible: root.windowShown
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

    WlrLayershell.namespace: root.surface === "switcher" ? "familiar-switcher" : "familiar-overlay"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    onVisibleChanged: if (visible) {
      if (root.surface === "launcher") launcher.open(root.payload)
      else keyCatcher.forceActiveFocus()
    }

    Item {
      id: animatedLayer
      anchors.fill: parent
      enabled: root.opened
      opacity: root.opened ? 1 : 0
      scale: root.opened ? 1 : root.closedScale
      Behavior on opacity { NumberAnimation { duration: root.opened ? familiar.motionBase : familiar.motionFast; easing.type: root.opened ? familiar.motionCurve : Easing.OutCubic; easing.overshoot: root.profile.id === "macos" ? 1.2 : 0 } }
      Behavior on scale { NumberAnimation { duration: root.opened ? familiar.motionBase : familiar.motionFast; easing.type: root.opened ? familiar.motionCurve : Easing.OutCubic; easing.overshoot: root.profile.id === "macos" ? 1.2 : 0 } }

      Rectangle {
        anchors.fill: parent
        color: Color.background
        opacity: Math.max(0, 0.72 + familiar.blurAlphaAdjustment)
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
        if (root.surface === "switcher") root.hideWindow()
        else root.close()
        event.accepted = true
      }
      Keys.onReleased: function(event) {
        if (root.surface === "switcher" && (event.key === Qt.Key_Alt || event.key === Qt.Key_Meta || event.key === Qt.Key_Control)) {
          switcher.commit()
          root.hideWindow()
          event.accepted = true
        }
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

      OverviewSurface { id: overview; anchors.fill: parent; visible: root.surface === "overview"; style: root.profile.overview ? root.profile.overview.style : "gnome"; service: root.service; onDismiss: root.close() }
      SwitcherSurface { id: switcher; anchors.fill: parent; visible: root.surface === "switcher"; style: root.profile.switcher ? root.profile.switcher.style : "iconRow"; service: root.service; onDismiss: root.hideWindow() }
    }
  }
}
