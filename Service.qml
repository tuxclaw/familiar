import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  readonly property string moduleName: "io.github.tuxclaw.familiar"

  property var shell: null
  property var pluginRegistry: null
  property var manifest: null

  property var profiles: ({})
  readonly property var profileIds: ["gnome", "plasma", "macos"]
  property string profile: "gnome"
  readonly property var currentProfile: profiles[profile] || profiles.gnome || ({})
  property var barConfig: ({})
  property string lastHyprResult: "idle"

  signal profileApplied(string profileId)

  function isKnownProfile(profileId) {
    return typeof profileId === "string" && profileIds.indexOf(profileId) >= 0
  }

  function ingest(profileId, contents) {
    try {
      if (!isKnownProfile(profileId))
        throw new Error("unknown profile " + profileId)
      var parsed = JSON.parse(contents || "{}")
      if (parsed.id !== profileId || !parsed.bar || !parsed.keymap)
        throw new Error("profile shape does not match " + profileId)
      var next = Object.assign({}, profiles)
      next[profileId] = parsed
      profiles = next
      if (isKnownProfile(barConfig.profile) && profiles[barConfig.profile])
        profile = barConfig.profile
    } catch (error) {
      console.warn("Familiar: unable to load profile " + profileId + ": " + error)
    }
  }

  function setProfile(profileId) {
    if (arguments.length !== 1) return "refused"
    if (!isKnownProfile(profileId) || !profiles[profileId]) return "unknown"
    profile = profileId
    persist(profileId)
    applyHypr()
    profileApplied(profileId)
    return "ok"
  }

  function cycleProfile() {
    var profileIds = ["gnome", "plasma", "macos"]
    var index = profileIds.indexOf(profile)
    var next = profileIds[(index + 1 + profileIds.length) % profileIds.length]
    return setProfile(next) === "ok" ? profile : "unknown"
  }

  function getProfile() {
    return profile
  }

  function reapply() {
    if (arguments.length !== 0) return "refused"
    return applyHypr()
  }

  function resolved(key, profileValue) {
    var value = barConfig[key]
    return value === undefined || value === "auto" ? profileValue : value
  }

  function pinnedApps() {
    var configured = barConfig.dockPinned
    if (typeof configured === "string") {
      return configured.split(",").map(function(id) { return id.trim() })
        .filter(function(id) { return id.length > 0 })
    }
    var dock = currentProfile.dock || ({})
    return Array.isArray(dock.pinned) ? dock.pinned.slice() : []
  }

  function persistPinned(list) {
    var pins = Array.isArray(list) ? list.map(function(id) { return String(id).trim() })
      .filter(function(id) { return id.length > 0 }) : []
    if (!pluginRegistry || typeof pluginRegistry.shellConfigMutator !== "function")
      return "unavailable"
    pluginRegistry.shellConfigMutator(function(config) {
      if (!config.bar) config.bar = {}
      config.bar.dockPinned = pins.join(",")
    })
    return "ok"
  }

  function persist(profileId) {
    if (pluginRegistry && typeof pluginRegistry.shellConfigMutator === "function") {
      pluginRegistry.shellConfigMutator(function(config) {
        if (!config.bar) config.bar = {}
        config.bar.profile = profileId
      })
      return
    }

    persistProcess.command = [
      "sh", "-c",
      "set -eu; config=\"$HOME/.config/omarchy/shell.json\"; "
        + "[ -f \"$config\" ] || exit 0; config_dir=${config%/*}; "
        + "tmp=$(mktemp \"$config_dir/.shell.json.XXXXXX\"); "
        + "trap 'rm -f -- \"$tmp\"' EXIT HUP INT TERM; "
        + "jq --arg profile \"$1\" '.bar = (.bar // {}) | .bar.profile = $profile' \"$config\" > \"$tmp\"; "
        + "mv -f -- \"$tmp\" \"$config\"; trap - EXIT HUP INT TERM; "
        + "omarchy-shell shell reloadConfig",
      "familiar-persist", profileId
    ]
    persistProcess.running = true
  }

  // The writer owns the fixed live target. IPC can select a profile, never a path.
  function applyHypr() {
    if (arguments.length !== 0) return "refused"
    var keymap = String(currentProfile.keymap || profile)
    if (!isKnownProfile(keymap)) return "unknown"
    if (hyprProcess.running) return "busy"
    var writerUrl = Qt.resolvedUrl("hypr/write.sh").toString()
    var writerPath = writerUrl.indexOf("file://") === 0 ? writerUrl.slice(7) : writerUrl
    lastHyprResult = "running"
    hyprProcess.command = ["bash", writerPath, "--apply", keymap]
    hyprProcess.running = true
    return "started"
  }

  Process { id: persistProcess }

  Process {
    id: hyprProcess
    stdout: StdioCollector { id: hyprStdout; waitForEnd: true }
    stderr: StdioCollector { id: hyprStderr; waitForEnd: true }
    onExited: {
      var message = String(exitCode === 0 ? hyprStdout.text : hyprStderr.text).trim()
      root.lastHyprResult = exitCode === 0 ? (message || "ok") : (message || "failed")
      if (exitCode !== 0) console.warn("Familiar: Hyprland apply failed: " + root.lastHyprResult)
    }
  }

  FileView {
    path: Qt.resolvedUrl("profiles/gnome.json")
    watchChanges: true
    printErrors: true
    onLoaded: root.ingest("gnome", text())
    onFileChanged: reload()
  }

  FileView {
    path: Qt.resolvedUrl("profiles/plasma.json")
    watchChanges: true
    printErrors: true
    onLoaded: root.ingest("plasma", text())
    onFileChanged: reload()
  }

  FileView {
    path: Qt.resolvedUrl("profiles/macos.json")
    watchChanges: true
    printErrors: true
    onLoaded: root.ingest("macos", text())
    onFileChanged: reload()
  }

  FileView {
    path: Quickshell.env("HOME") + "/.config/omarchy/shell.json"
    watchChanges: true
    printErrors: false
    onLoaded: {
      try {
        var config = JSON.parse(text() || "{}")
        root.barConfig = config.bar || {}
        if (root.isKnownProfile(root.barConfig.profile)
            && root.profiles[root.barConfig.profile])
          root.profile = root.barConfig.profile
      } catch (error) {
        console.warn("Familiar: unable to read shell bar settings: " + error)
      }
    }
    onFileChanged: reload()
  }
}
