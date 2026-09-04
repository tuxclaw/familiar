import QtQuick

Item {
  id: root

  readonly property string moduleName: "io.github.tuxclaw.familiar"

  property var service: null
  property var shell: null
  property var manifest: null

  property string surface: "launcher"
  property bool opened: false
  property var payload: ({})

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
}
