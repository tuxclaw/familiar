import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../../lib/Apps.js" as Apps
import "../.."

Item {
  id: root
  property string style: "grid"
  property var service: null
  property var entries: []
  property var commands: []
  property var defaultCommands: []
  property var userCommands: []
  property var results: []
  property var frecency: ({})
  property int selectedIndex: 0
  property string category: "All"
  readonly property var appLibrary: service && service.shell ? service.shell.appLibrary : null
  readonly property int columns: 6
  signal dismiss()

  Familiar {
    id: familiar
    profile: root.service ? root.service.currentProfile : ({})
  }

  function desktopEntry(rawId) {
    var id = Apps.normalizeId(rawId)
    return DesktopEntries.byId(rawId) || DesktopEntries.byId(id)
      || DesktopEntries.heuristicLookup(rawId) || DesktopEntries.heuristicLookup(id)
  }

  function rebuildEntries() {
    var values = DesktopEntries.applications.values || []
    var next = []
    for (var i = 0; i < values.length; i++) {
      var desktop = root.desktopEntry(values[i].id) || values[i]
      var id = Apps.normalizeId(desktop.id)
      if (!id) continue
      next.push({ kind: "app", id: id, name: String(desktop.name || id),
        description: String(desktop.comment || desktop.genericName || "Application"),
        categories: String(desktop.categories || ""), icon: String(desktop.icon || "") })
    }
    entries = next
    updateResults()
  }

  function updateResults() {
    var source = entries
    if (style === "kickoff" && category !== "All") source = source.filter(function(entry) {
      return String(entry.categories).toLowerCase().indexOf(category.toLowerCase()) >= 0
    })
    var ranked = Apps.rank(source, search.text, frecency)
    if (search.text.trim().length >= 2) ranked = ranked.concat(Apps.rank(commands, search.text, frecency))
    results = ranked
    selectedIndex = results.length ? Math.max(0, Math.min(selectedIndex, results.length - 1)) : -1
  }

  function mergeCommands() {
    var byAction = ({})
    var merged = []
    var sources = defaultCommands.concat(userCommands)
    for (var i = 0; i < sources.length; i++) {
      if (byAction[sources[i].action]) continue
      byAction[sources[i].action] = true
      merged.push(sources[i])
    }
    commands = merged
    updateResults()
  }

  function open(payload) {
    search.text = payload && payload.query ? String(payload.query) : ""
    selectedIndex = 0
    updateResults()
    search.focusInput()
  }

  function move(delta) {
    if (!results.length) return
    selectedIndex = (selectedIndex + delta + results.length) % results.length
    if (style === "grid") grid.positionViewAtIndex(selectedIndex, GridView.Contain)
    else list.positionViewAtIndex(selectedIndex, ListView.Contain)
  }

  function activate(index) {
    var entry = results[index]
    if (!entry) return
    if (entry.kind === "command") Util.execDetached(entry.action)
    else {
      var desktop = desktopEntry(entry.id)
      var launchId = desktop ? Apps.normalizeId(desktop.id) : entry.id
      if (!launchId) return
      Util.execDetached("uwsm-app -- gtk-launch " + Util.shellQuote(launchId + ".desktop"))
    }
    frecency[entry.id] = Number(frecency[entry.id] || 0) + 1
    frecency = Object.assign({}, frecency)
    persistProcess.command = ["bash", "-c", "mkdir -p -- \"$HOME/.local/state/familiar\"; printf '%s\\n' \"$1\" > \"$HOME/.local/state/familiar/frecency.json\"", "familiar-frecency", JSON.stringify(frecency)]
    persistProcess.running = true
    dismiss()
  }

  Rectangle {
    id: panel
    anchors.centerIn: parent
    width: root.style === "grid" ? Math.min(parent.width * 0.8, 1120) : root.style === "kickoff" ? Math.min(560, parent.width - 48) : Math.min(680, parent.width - 48)
    height: root.style === "grid" ? Math.min(parent.height - 64, 690) : Math.min(parent.height - 96, root.style === "spotlight" ? 560 : 620)
    radius: root.style === "grid" ? 24 : root.style === "kickoff" ? 12 : 14
    color: root.style === "grid" ? Color.background : Color.menu.background
    opacity: root.style === "spotlight" ? Math.max(0, 0.94 + familiar.blurAlphaAdjustment) : 0.98
    border.color: Color.menu.border
    border.width: 1

    MouseArea { anchors.fill: parent; onClicked: function(mouse) { mouse.accepted = true } }

    SearchField {
      id: search
      anchors { top: parent.top; left: parent.left; right: parent.right; margins: root.style === "grid" ? 28 : 18 }
      style: root.style
      onTextChanged: { root.selectedIndex = 0; root.updateResults() }
      onMoveRequested: function(delta) { root.move(root.style === "grid" ? delta * root.columns : delta) }
      onHorizontalRequested: function(delta) { root.move(delta) }
      onLaunchRequested: root.activate(root.selectedIndex)
      onDismissRequested: root.dismiss()
    }

    Row {
      visible: root.style === "kickoff"
      anchors { top: search.bottom; bottom: parent.bottom; left: parent.left; right: parent.right; margins: 18; topMargin: 14 }
      spacing: 12
      Column {
        width: 120
        spacing: 4
        Repeater {
          model: ["All", "Utility", "Development", "Graphics", "Network", "Office", "System"]
          Rectangle {
            required property string modelData
            width: 120; height: 38; radius: 5
            color: root.category === modelData ? Color.menu.selectedBackground : "transparent"
            Text {
              anchors { fill: parent; margins: 10 }
              verticalAlignment: Text.AlignVCenter
              text: modelData
              color: root.category === modelData ? Color.menu.selectedText : Color.menu.text
              elide: Text.ElideRight
              font.family: Style.font.family
              font.pixelSize: Style.font.body
            }
            TapHandler { onTapped: { root.category = modelData; root.selectedIndex = 0; root.updateResults(); search.focusInput() } }
          }
        }
      }
      Rectangle { width: 1; height: parent.height; color: Color.menu.border }
    }

    AppGrid {
      id: grid
      visible: root.style === "grid"
      anchors { top: search.bottom; bottom: parent.bottom; left: parent.left; right: parent.right; margins: 24; topMargin: 20 }
      entries: root.results
      selectedIndex: root.selectedIndex
      appLibrary: root.appLibrary
      onActivated: function(index) { root.activate(index) }
    }

    ListView {
      id: list
      visible: root.style !== "grid"
      anchors { top: search.bottom; bottom: parent.bottom; right: parent.right; margins: 18; topMargin: 14; left: parent.left; leftMargin: root.style === "kickoff" ? 170 : 18 }
      model: root.results
      spacing: 3
      clip: true
      reuseItems: true
      pixelAligned: false
      cacheBuffer: 480
      flickDeceleration: 1800
      maximumFlickVelocity: 3500
      boundsBehavior: Flickable.StopAtBounds
      flickableDirection: Flickable.VerticalFlick
      delegate: Column {
        required property var modelData
        required property int index
        width: list.width
        property bool showSection: index === 0 || modelData.kind !== root.results[index - 1].kind
        Text { visible: parent.showSection; width: parent.width; height: visible ? 26 : 0; text: parent.modelData.kind === "command" ? "Commands" : "Applications"; color: Color.muted; font.family: Style.font.family; font.pixelSize: Math.max(12, Style.font.caption); verticalAlignment: Text.AlignVCenter }
        ResultRow { width: parent.width; entry: parent.modelData; selected: parent.index === root.selectedIndex; appLibrary: root.appLibrary; onActivated: root.activate(parent.index) }
      }
      Text { anchors.centerIn: parent; visible: root.results.length === 0; text: "No results"; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.body }
    }
  }

  Process { id: persistProcess }
  FileView {
    path: Quickshell.env("HOME") + "/.local/state/familiar/frecency.json"
    printErrors: false
    onLoaded: { try { root.frecency = JSON.parse(text() || "{}") } catch (error) { root.frecency = ({}) }; root.updateResults() }
    onLoadFailed: root.frecency = ({})
  }
  FileView {
    path: "/usr/share/omarchy/default/omarchy/omarchy-menu.jsonc"
    watchChanges: true
    printErrors: false
    onLoaded: { root.defaultCommands = Apps.menuCommands(text()); root.mergeCommands() }
    onLoadFailed: { root.defaultCommands = []; root.mergeCommands() }
    onFileChanged: reload()
  }
  FileView {
    path: Quickshell.env("HOME") + "/.config/omarchy/extensions/omarchy-menu.jsonc"
    watchChanges: true
    printErrors: false
    onLoaded: { root.userCommands = Apps.menuCommands(text()); root.mergeCommands() }
    onLoadFailed: { root.userCommands = []; root.mergeCommands() }
    onFileChanged: reload()
  }
  Connections { target: DesktopEntries.applications; function onValuesChanged() { root.rebuildEntries() } }
  Component.onCompleted: root.rebuildEntries()
}
