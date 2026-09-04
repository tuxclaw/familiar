import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons

Rectangle {
  id: root
  property var service: null
  property var pinned: []
  property var running: []
  property int iconSize: 48
  property bool magnification: false
  property bool showRunning: true
  property string runningIndicator: "dot"
  property point pointerPosition: Qt.point(-10000, -10000)
  property var pinnedEntries: []
  property var runningEntries: []

  signal contextRequested(var entry, point position)

  function normalize(id) {
    var value = String(id || "").trim()
    return value.slice(-8) === ".desktop" ? value.slice(0, -8) : value
  }

  function desktopEntry(id) {
    var rawTarget = String(id || "").trim()
    var target = normalize(rawTarget)
    if (!target) return null
    var indexed = DesktopEntries.byId(rawTarget) || DesktopEntries.byId(target)
    if (indexed) return indexed
    var heuristic = DesktopEntries.heuristicLookup(rawTarget) || DesktopEntries.heuristicLookup(target)
    if (heuristic) return heuristic
    var foldedTarget = target.toLowerCase()
    var apps = DesktopEntries.applications.values || []
    for (var i = 0; i < apps.length; i++) {
      if (String(apps[i].id || "").trim() === rawTarget) return apps[i]
    }
    for (var i = 0; i < apps.length; i++) {
      if (normalize(apps[i].id) === target) return apps[i]
    }
    for (var i = 0; i < apps.length; i++) {
      if (normalize(apps[i].id).toLowerCase() === foldedTarget) return apps[i]
    }
    for (var i = 0; i < apps.length; i++) {
      if (String(apps[i].startupClass || "").trim() === rawTarget) return apps[i]
    }
    return null
  }

  function entryId(desktop, fallback) {
    var id = desktop ? normalize(desktop.id) : ""
    return id || normalize(fallback)
  }

  function rebuild() {
    var windows = running || []
    var byId = ({})
    var desktops = ({})
    for (var i = 0; i < windows.length; i++) {
      var appId = normalize(windows[i].appId)
      if (!appId) continue
      var windowDesktop = desktopEntry(appId)
      var desktopId = entryId(windowDesktop, appId)
      if (!byId[desktopId]) byId[desktopId] = []
      byId[desktopId].push(windows[i])
      if (windowDesktop) desktops[desktopId] = windowDesktop
    }
    var nextPinned = []
    var nextRunning = []
    var included = ({})
    for (var p = 0; p < pinned.length; p++) {
      var pinnedId = normalize(pinned[p])
      var desktop = desktopEntry(pinnedId)
      var canonicalId = entryId(desktop, pinnedId)
      if (!canonicalId || included[canonicalId]) continue
      var pinnedWindows = byId[canonicalId] || []
      nextPinned.push({ desktopId: canonicalId, pinId: pinnedId, name: desktop ? (desktop.name || canonicalId) : canonicalId, icon: desktop ? (desktop.icon || "") : "", windows: pinnedWindows, windowCount: pinnedWindows.length, pinned: true })
      included[canonicalId] = true
    }
    if (showRunning) Object.keys(byId).forEach(function(desktopId) {
      if (included[desktopId]) return
      var desktop = desktops[desktopId] || root.desktopEntry(desktopId)
      nextRunning.push({ desktopId: root.entryId(desktop, desktopId), pinId: "", name: desktop ? (desktop.name || desktopId) : desktopId, icon: desktop ? (desktop.icon || "") : "", windows: byId[desktopId], windowCount: byId[desktopId].length, pinned: false })
    })
    pinnedEntries = nextPinned
    runningEntries = nextRunning
  }

  function activate(entry) {
    if (entry.windows && entry.windows.length > 0 && typeof entry.windows[0].activate === "function")
      entry.windows[0].activate()
    else launch(entry)
  }

  function launch(entry) {
    var id = normalize(entry.desktopId)
    if (id) Util.execDetached("uwsm-app -- gtk-launch " + Util.shellQuote(id + ".desktop"))
  }

  function magnifyFor(index, item) {
    if (!magnification || pointerPosition.x < -1000 || !item) return 1
    var center = item.x + item.width / 2
    var distance = Math.abs(pointerPosition.x - center)
    var spread = iconSize * 1.35
    return 1 + 0.55 * Math.exp(-Math.pow(distance / spread, 2))
  }

  implicitWidth: dockRow.implicitWidth + 16
  implicitHeight: iconSize * (magnification ? 1.55 : 1) + 28
  radius: Math.min(18, implicitHeight / 3)
  color: Color.bar.background
  border.color: Color.bar.text
  border.width: 1

  onPinnedChanged: rebuild()
  onRunningChanged: rebuild()
  Component.onCompleted: rebuild()
  Connections { target: DesktopEntries.applications; function onValuesChanged() { root.rebuild() } }

  Row {
    id: dockRow
    anchors.centerIn: parent
    spacing: 3

    Repeater {
      model: root.pinnedEntries
      DockIcon {
        required property var modelData
        required property int index
        entry: modelData
        dockSurface: root
        appLibrary: root.service && root.service.shell ? root.service.shell.appLibrary : null
        iconSize: root.iconSize
        magnifyScale: root.magnifyFor(index, this)
        indicatorStyle: root.runningIndicator
        pinned: modelData.pinned
        onActivated: root.activate(entry)
        onContextRequested: function(entry, position) { root.contextRequested(entry, position) }
      }
    }

    DockSeparator {
      vertical: true
      visible: root.pinnedEntries.length > 0 && root.runningEntries.length > 0
      anchors.verticalCenter: parent.verticalCenter
    }

    Repeater {
      model: root.runningEntries
      DockIcon {
        required property var modelData
        required property int index
        entry: modelData
        dockSurface: root
        appLibrary: root.service && root.service.shell ? root.service.shell.appLibrary : null
        iconSize: root.iconSize
        magnifyScale: root.magnifyFor(root.pinnedEntries.length + index, this)
        indicatorStyle: root.runningIndicator
        pinned: false
        onActivated: root.activate(entry)
        onContextRequested: function(entry, position) { root.contextRequested(entry, position) }
      }
    }
  }
}
