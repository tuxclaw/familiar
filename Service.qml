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
  property string profile: "gnome"
  readonly property var currentProfile: profiles[profile] || profiles.gnome || ({})
  property var barConfig: ({})

  signal profileApplied(string profileId)

  readonly property string pluginDir: {
    var path = Qt.resolvedUrl(".").toString()
    return path.startsWith("file://") ? path.slice(7) : path
  }

  function ingest(profileId, contents) {
    try {
      var parsed = JSON.parse(contents || "{}")
      if (parsed.id !== profileId || !parsed.bar || !parsed.keymap)
        throw new Error("profile shape does not match " + profileId)
      var next = Object.assign({}, profiles)
      next[profileId] = parsed
      profiles = next
      if (barConfig.profile && profiles[barConfig.profile]) profile = barConfig.profile
    } catch (error) {
      console.warn("Familiar: unable to load profile " + profileId + ": " + error)
    }
  }

  function setProfile(profileId) {
    if (!profiles[profileId]) return "unknown"
    profile = profileId
    persist(profileId)
    applyHypr("")
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

  function reapply(outputPath) {
    return applyHypr(outputPath || "")
  }

  function resolved(key, profileValue) {
    var value = barConfig[key]
    return value === undefined || value === "auto" ? profileValue : value
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
        + "[ -f \"$config\" ] || exit 0; tmp=$(mktemp); "
        + "jq --arg profile \"$1\" '.bar = (.bar // {}) | .bar.profile = $profile' \"$config\" > \"$tmp\"; "
        + "mv \"$tmp\" \"$config\"; omarchy-shell shell reloadConfig",
      "familiar-persist", profileId
    ]
    persistProcess.running = true
  }

  // M0 safety gate: generation is permitted only under this checkout's tests/out.
  // No live Hyprland path is written and no compositor reload is performed.
  function applyHypr(outputPath) {
    if (!outputPath) return "skipped"
    var outputUrl = Qt.resolvedUrl(outputPath).toString()
    var output = outputUrl.startsWith("file://") ? outputUrl.slice(7) : outputUrl
    var allowedRoot = pluginDir + "tests/out/"
    if (!output.startsWith(allowedRoot)) return "refused"

    hyprProcess.command = [
      "bash", pluginDir + "tests/hypr.sh",
      "--profile", currentProfile.keymap || profile,
      "--output", output
    ]
    hyprProcess.running = true
    return "queued"
  }

  Process { id: persistProcess }
  Process { id: hyprProcess }

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
        if (root.barConfig.profile && root.profiles[root.barConfig.profile])
          root.profile = root.barConfig.profile
      } catch (error) {
        console.warn("Familiar: unable to read shell bar settings: " + error)
      }
    }
    onFileChanged: reload()
  }
}
