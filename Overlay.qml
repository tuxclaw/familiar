import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.Commons
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

    if (opened && requestedSurface === "switcher" && switcher.visible) {
      switcher.advance(parsed)
      return "ok"
    }
    surface = requestedSurface
    payload = parsed
    opened = true
    if (requestedSurface === "launcher") launcher.open(parsed)
    else if (requestedSurface === "overview") overview.open(parsed)
    else switcher.open(parsed)
    return "ok"
  }

  function close() {
    if (surface === "switcher" && opened) switcher.commit()
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
    onShowLauncher: root.open('{"surface":"launcher"}')
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

    WlrLayershell.namespace: root.surface === "switcher" ? "familiar-switcher" : "familiar-overlay"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    onVisibleChanged: if (visible) {
      if (root.surface === "launcher") launcher.open(root.payload)
      else keyCatcher.forceActiveFocus()
    }

    Rectangle {
      anchors.fill: parent
      color: Color.background
      opacity: 0.72
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
        if (root.surface === "switcher") root.opened = false
        else root.close()
        event.accepted = true
      }
      Keys.onReleased: function(event) {
        if (root.surface === "switcher" && (event.key === Qt.Key_Alt || event.key === Qt.Key_Meta || event.key === Qt.Key_Control)) {
          switcher.commit()
          root.opened = false
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
    SwitcherSurface { id: switcher; anchors.fill: parent; visible: root.surface === "switcher"; style: root.profile.switcher ? root.profile.switcher.style : "iconRow"; service: root.service; onDismiss: root.opened = false }
  }
}
