import QtQuick
import "../../lib/DockPins.js" as DockPins
import Quickshell
import Quickshell.Wayland
import qs.Commons
import "../.."
import "../../lib/PwaMatcher.js" as PwaMatcher

Rectangle {
  id: root
  property var service: null
  property var widgetBar: null
  property bool widgetPickerOpen: false
  readonly property real widgetWidth: widgetCluster.width > 0 ? widgetCluster.width + 8 : 0
  readonly property bool widgetsLeft: service && service.widgetSide === "left"
  property var pinned: []
  property var running: []
  property int iconSize: 48
  property bool magnification: false
  property bool showRunning: true
  property string runningIndicator: "dot"
  property point pointerPosition: Qt.point(-10000, -10000)
  property bool draggingPinned: false
  readonly property real animationScale: familiar.motionScale
  property bool editMode: false
  property string openFolderId: ""
  property var dragEntry: null
  property var dragPlan: null
  property var railKeys: []
  property var dragSlots: []
  property real dragRailWidth: 0
  readonly property int cellWidth: iconSize + 11
  readonly property int cellHeight: iconSize + 20
  readonly property bool folderOpen: openFolderId !== ""
  property var folderEntries: []
  property string folderName: ""
  property var pinnedEntries: []
  property var runningEntries: []
  readonly property var launcherEntry: ({
    desktopId: "",
    pinId: "",
    name: "Applications",
    icon: Qt.resolvedUrl("applications-256.png"),
    windows: [],
    windowCount: 0,
    pinned: false
  })

  Familiar {
    id: familiar
    profile: root.service ? root.service.currentProfile : ({})
  }

  signal showLauncher()

  function normalize(id) {
    var value = String(id || "").trim()
    return value.slice(-8) === ".desktop" ? value.slice(0, -8) : value
  }

  function desktopEntry(id) {
    var rawTarget = String(id || "").trim()
    var target = normalize(rawTarget)
    if (!target) return null
    // Browser heuristics can return the browser itself for a PWA WM class.
    if (PwaMatcher.parse(target))
      return PwaMatcher.matchEntry(target, DesktopEntries.applications.values || [])
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

  function entryIcon(desktop, fallback) {
    return desktop && desktop.icon ? desktop.icon : PwaMatcher.fallbackIcon(fallback)
  }

  function rebuild() {
    if (draggingPinned) return // Keep the pointer grab alive until release.
    var windows = running || []
    var byId = Object.create(null)
    var desktops = Object.create(null)
    for (var i = 0; i < windows.length; i++) {
      var appId = normalize(windows[i].appId)
      if (!appId) continue
      var windowDesktop = desktopEntry(appId)
      var desktopId = entryId(windowDesktop, appId)
      if (!Object.prototype.hasOwnProperty.call(byId, desktopId)) byId[desktopId] = []
      byId[desktopId].push(windows[i])
      if (windowDesktop) desktops[desktopId] = windowDesktop
    }
    var nextPinned = []
    var nextRunning = []
    var included = Object.create(null)
    for (var p = 0; p < pinned.length; p++) {
      if (typeof pinned[p] !== "string") {
        var folder = pinned[p]
        var children = []
        for (var f = 0; f < folder.items.length; f++) {
          var childId = normalize(folder.items[f])
          var childDesktop = desktopEntry(childId)
          var childCanonical = entryId(childDesktop, childId)
          var childWindows = byId[childCanonical] || []
          children.push({ desktopId: childCanonical, pinId: childId, folderId: folder.id,
            name: childDesktop ? (childDesktop.name || childCanonical) : childCanonical,
            icon: entryIcon(childDesktop, childId), windows: childWindows,
            windowCount: childWindows.length, pinned: true })
          included[childCanonical] = true
        }
        nextPinned.push({ type: "folder", id: folder.id, pinId: folder.id, name: folder.name,
          icon: "folder", items: children, pinned: true, windowCount: 0 })
        continue
      }
      var pinnedId = normalize(pinned[p])
      var desktop = desktopEntry(pinnedId)
      var canonicalId = entryId(desktop, pinnedId)
      if (!canonicalId || Object.prototype.hasOwnProperty.call(included, canonicalId)) continue
      var pinnedWindows = byId[canonicalId] || []
      nextPinned.push({ desktopId: canonicalId, pinId: pinnedId, name: desktop ? (desktop.name || canonicalId) : canonicalId, icon: entryIcon(desktop, pinnedId), windows: pinnedWindows, windowCount: pinnedWindows.length, pinned: true })
      included[canonicalId] = true
    }
    if (showRunning) Object.keys(byId).forEach(function(desktopId) {
      if (Object.prototype.hasOwnProperty.call(included, desktopId)) return
      var desktop = desktops[desktopId] || root.desktopEntry(desktopId)
      nextRunning.push({ desktopId: root.entryId(desktop, desktopId), pinId: "", name: desktop ? (desktop.name || desktopId) : desktopId, icon: root.entryIcon(desktop, desktopId), windows: byId[desktopId], windowCount: byId[desktopId].length, pinned: false })
    })
    pinnedEntries = nextPinned
    runningEntries = nextRunning
    refreshFolder()
  }

  function refreshFolder() {
    var folder = pinnedEntries.filter(function(entry) { return entry.type === "folder" && entry.id === root.openFolderId })[0]
    folderEntries = folder ? folder.items : []
    folderName = folder ? folder.name : ""
    if (!folder) openFolderId = ""
  }

  function entryKey(entry) {
    return entry.type === "folder" ? "folder:" + entry.id : "app:" + normalize(entry.pinId || entry.desktopId)
  }

  function beginDrag(entry) {
    var slots = []
    for (var i = 0; i < pinnedRepeater.count; i++) {
      var tile = pinnedRepeater.itemAt(i)
      slots.push({ key: entryKey(tile.entry), x: tile.x, width: tile.width + 3 })
    }
    dragSlots = slots
    dragRailWidth = pinnedRail.width
    draggingPinned = true
    dragEntry = entry
    railKeys = pinnedEntries.map(entryKey)
  }

  function updateDrag(entry, position) {
    if (!draggingPinned) return
    var point = folderPopup.mapFromItem(root, position.x, position.y)
    if (entry.folderId === openFolderId && folderOpen && point.x >= 0 && point.x < folderPopup.width
        && point.y >= folderPopup.gridTop && point.y < folderPopup.height) {
      var gridIndex = DockPins.railIndex(point.x - 12, point.y - folderPopup.gridTop,
        folderEntries.length - 1, folderPopup.columns, cellWidth, cellHeight)
      dragPlan = { kind: "grid", index: gridIndex }
      railKeys = pinnedEntries.map(entryKey)
      return
    }
    if (position.y < 0 || position.y > height || position.x < 0 || position.x > width) {
      dragPlan = null
      railKeys = pinnedEntries.map(entryKey)
      return
    }
    var local = pinnedRail.mapFromItem(root, position.x, position.y)
    var keys = pinnedEntries.map(entryKey)
    var source = entry.folderId ? "app:" + entry.pinId : entryKey(entry)
    var remaining = keys.filter(function(key) { return key !== source })
    var index = remaining.length
    var target = null
    var centerDistance = 1
    for (var i = 0; i < dragSlots.length; i++) {
      var slot = dragSlots[i]
      if (slot.key !== source && local.x < slot.x + slot.width / 2 && index === remaining.length)
        index = remaining.indexOf(slot.key)
      if (local.x >= slot.x && local.x < slot.x + slot.width) {
        target = pinnedEntries[i]
        centerDistance = Math.abs((local.x - slot.x) / slot.width - 0.5)
      }
    }
    // Hit-test captured slots, not animated delegates, to avoid oscillating targets.
    if (target && entry.type !== "folder" && entryKey(target) !== source
        && (!entry.folderId || target.id !== entry.folderId) && centerDistance < 0.18) {
      dragPlan = { kind: "merge", target: entryKey(target) }
      railKeys = keys
    } else {
      dragPlan = { kind: "rail", index: index }
      railKeys = DockPins.insert(remaining, source, index)
    }
  }

  function railSlot(entry, index) {
    var slot = draggingPinned ? railKeys.indexOf(entryKey(entry)) : index
    return slot < 0 ? index : slot
  }

  function finishDrag(entry, position) {
    updateDrag(entry, position)
    var plan = dragPlan
    var next = null
    if (plan && service) {
      var source = entry.folderId ? entry.pinId : entryKey(entry)
      if (plan.kind === "merge") next = DockPins.merge(pinned, source, entry.folderId, plan.target,
        "folder-" + Date.now().toString(36) + "-" + Math.random().toString(36).slice(2, 8))
      else if (plan.kind === "grid") next = DockPins.reorderFolder(pinned, entry.folderId, entry.pinId, plan.index)
      else next = DockPins.move(pinned, source, entry.folderId, plan.index)
    }
    cancelDrag()
    if (next && JSON.stringify(next) !== JSON.stringify(pinned)) {
      service.persistPinned(next)
      if (openFolderId && !next.some(function(pin) { return pin.type === "folder" && pin.id === root.openFolderId }))
        openFolderId = ""
    }
  }

  function cancelDrag() {
    draggingPinned = false
    dragEntry = null
    dragSlots = []
    dragPlan = null
    railKeys = []
    rebuild()
  }

  function togglePin(entry) {
    if (service) service.persistPinned(DockPins.toggle(pinned, entry.pinId || entry.desktopId, !entry.pinned))
  }

  function dissolveFolder(id) {
    if (service) service.persistPinned(DockPins.dissolve(pinned, id))
    openFolderId = ""
  }

  function activate(entry) {
    if (entry.type === "folder") {
      openFolderId = openFolderId === entry.id ? "" : entry.id
      return
    }
    if (editMode) return
    if (entry.windows && entry.windows.length > 0 && typeof entry.windows[0].activate === "function")
      entry.windows[0].activate()
    else launch(entry)
  }

  function launch(entry) {
    var id = normalize(entry.desktopId)
    if (id) Util.execDetached("uwsm-app -- gtk-launch " + Util.shellQuote(id + ".desktop"))
  }

  function pinnedX(entry, index) {
    var offset = 0
    if (draggingPinned) {
      var slot = railSlot(entry, index)
      for (var i = 0; i < slot; i++) {
        var key = railKeys[i]
        var original = dragSlots.filter(function(item) { return item.key === key })[0]
        offset += original ? original.width : cellWidth
      }
    } else {
      for (var i = 0; i < index; i++) {
        var tile = pinnedRepeater.itemAt(i)
        offset += tile ? tile.width + 3 : cellWidth
      }
    }
    return offset
  }

  function pinnedWidth() {
    if (draggingPinned) return dragRailWidth + (dragEntry.folderId && dragPlan && dragPlan.kind === "rail" ? cellWidth : 0)
    var total = 0
    for (var i = 0; i < pinnedRepeater.count; i++) {
      var tile = pinnedRepeater.itemAt(i)
      total += tile ? tile.width + 3 : cellWidth
    }
    return total
  }

  function magnifyFor(index, item) {
    if (draggingPinned || !magnification || pointerPosition.x < -1000 || !item) return 1
    var center = item.mapToItem(root, item.width / 2, item.height / 2).x
    var distance = Math.abs(pointerPosition.x - center)
    var spread = iconSize * 1.35
    return 1 + 0.55 * Math.exp(-Math.pow(distance / spread, 2))
  }

  implicitWidth: dockRow.implicitWidth + widgetWidth + 16
  readonly property int chromeHeight: iconSize + 12 + 8 // Indicator slot plus padding.
  // Fixed headroom for maximum magnification and launch bounce; never hover-driven.
  readonly property int magnifyOverflow: magnification ? Math.ceil(iconSize * 0.55) + 12 : 0
  implicitHeight: chromeHeight
  radius: Math.min(18, implicitHeight / 3)
  color: Color.menu.background
  border.color: Color.menu.border
  border.width: 1

  onOpenFolderIdChanged: {
    if (folderOpen) widgetPickerOpen = false
    refreshFolder()
  }
  onWidgetPickerOpenChanged: if (widgetPickerOpen) openFolderId = ""
  onEditModeChanged: if (!editMode) widgetPickerOpen = false
  onPinnedChanged: rebuild()
  onRunningChanged: rebuild()
  Component.onCompleted: rebuild()
  Connections { target: DesktopEntries.applications; function onValuesChanged() { root.rebuild() } }

  PopupWindow {
    visible: root.folderOpen
    anchor.item: root
    anchor.rect.x: (root.width - folderPopup.width) / 2
    anchor.rect.y: -8
    anchor.edges: Edges.Top | Edges.Left
    anchor.gravity: Edges.Top | Edges.Right
    anchor.adjustment: PopupAdjustment.Slide
    implicitWidth: folderPopup.width
    implicitHeight: folderPopup.height
    color: "transparent"

    DockFolderPopup {
      id: folderPopup
      dockSurface: root
    }
  }

  DockWidgetCluster {
    id: widgetCluster
    bar: root.widgetBar
    dockSurface: root
    widgets: root.service ? root.service.storedWidgets : []
    x: root.widgetsLeft ? 8 : dockRow.x + dockRow.width + 8
    anchors.verticalCenter: parent.verticalCenter
  }

  // The ghost is independent of the original delegate and can cross the popup boundary.
  Image {
    visible: root.draggingPinned && root.dragEntry !== null
    source: root.dragEntry ? Quickshell.iconPath(root.dragEntry.icon || "folder", "application-x-executable") : ""
    x: root.pointerPosition.x - width / 2
    y: root.pointerPosition.y - height / 2
    width: root.iconSize
    height: width
    opacity: 0.85
    z: 30
  }

  Row {
    id: dockRow
    x: 8 + (root.widgetsLeft ? root.widgetWidth : 0)
    anchors.verticalCenter: parent.verticalCenter
    spacing: 3

    Item {
      id: pinnedRail
      width: root.pinnedWidth()
      height: root.cellHeight
      Repeater {
        id: pinnedRepeater
        model: root.pinnedEntries
        DockIcon {
          required property var modelData
          required property int index
          entry: modelData
          x: root.pinnedX(entry, index)
          y: (pinnedRail.height - height) / 2
          Behavior on x {
            enabled: root.draggingPinned
            NumberAnimation { duration: Math.round(150 * familiar.motionScale); easing.type: Easing.OutCubic }
          }
          dockSurface: root
          appLibrary: root.service && root.service.shell ? root.service.shell.appLibrary : null
          iconSize: root.iconSize
          magnifyScale: root.draggingPinned && root.dragSlots[index] ? (root.dragSlots[index].width - 11) / root.iconSize : root.magnifyFor(index, this)
          indicatorStyle: root.runningIndicator
          pinned: modelData.pinned
          onReorderDropped: function(entry, position) { root.finishDrag(entry, position) }
          profileId: familiar.profileId
          motionScale: familiar.motionScale
          onActivated: root.activate(entry)
        }
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
        anchors.verticalCenter: parent.verticalCenter
        required property var modelData
        required property int index
        entry: modelData
        dockSurface: root
        appLibrary: root.service && root.service.shell ? root.service.shell.appLibrary : null
        iconSize: root.iconSize
        magnifyScale: root.magnifyFor(root.pinnedEntries.length + index, this)
        indicatorStyle: root.runningIndicator
        pinned: false
        profileId: familiar.profileId
        motionScale: familiar.motionScale
        onActivated: root.activate(entry)
      }
    }

    DockSeparator {
      vertical: true
      visible: root.pinnedEntries.length + root.runningEntries.length > 0
      anchors.verticalCenter: parent.verticalCenter
    }

    DockIcon {
      entry: root.launcherEntry
      anchors.verticalCenter: parent.verticalCenter
      dockSurface: root
      appLibrary: root.service && root.service.shell ? root.service.shell.appLibrary : null
      iconSize: root.iconSize
      magnifyScale: root.magnifyFor(root.pinnedEntries.length + root.runningEntries.length, this)
      indicatorStyle: root.runningIndicator
      pinned: false
      profileId: familiar.profileId
      motionScale: familiar.motionScale
      showRunningIndicator: false
      contextMenuEnabled: false
      tooltipText: "Applications"
      onActivated: root.showLauncher()
    }
    Rectangle {
      visible: root.editMode
      width: 70
      height: root.cellHeight
      radius: 8
      color: Color.menu.selectedBackground
      Text { anchors.centerIn: parent; text: "Widgets"; color: Color.menu.text }
      MouseArea { anchors.fill: parent; onClicked: root.widgetPickerOpen = !root.widgetPickerOpen }
    }

    Rectangle {
      visible: root.editMode
      width: 48
      height: root.cellHeight
      radius: 8
      color: Color.menu.selectedBackground
      Text { anchors.centerIn: parent; text: "Done"; color: Color.menu.text }
      MouseArea { anchors.fill: parent; onClicked: { root.editMode = false; root.openFolderId = "" } }
    }
  }
}
