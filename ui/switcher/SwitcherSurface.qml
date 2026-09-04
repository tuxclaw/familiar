import QtQuick
import Quickshell.Wayland
import qs.Commons
import "."

Item {
  id: root
  property string style: "iconRow"
  property var service: null
  property string scope: "app"
  property var entries: []
  property int selectedIndex: -1
  signal dismiss()

  function rebuild() {
    var windows = ToplevelManager.toplevels.values || []
    if (scope === "window") { entries = windows.slice(); return }
    var seen = ({})
    var grouped = []
    for (var i = 0; i < windows.length; i++) {
      var id = String(windows[i].appId || windows[i].title || i)
      if (seen[id]) continue
      seen[id] = true
      grouped.push(windows[i])
    }
    entries = grouped
  }

  function open(payload) {
    scope = payload && payload.scope ? String(payload.scope) : "app"
    rebuild()
    selectedIndex = entries.length > 1 ? 1 : entries.length ? 0 : -1
    fallback.restart()
  }

  function advance(payload) {
    if (payload && payload.scope && String(payload.scope) !== scope) {
      scope = String(payload.scope)
      rebuild()
    }
    if (entries.length) selectedIndex = (selectedIndex + 1) % entries.length
    fallback.restart()
  }

  function commit() {
    fallback.stop()
    var entry = entries[selectedIndex]
    if (entry && typeof entry.activate === "function") entry.activate()
  }

  Timer { id: fallback; interval: 1200; onTriggered: { root.commit(); root.dismiss() } }

  Rectangle {
    anchors.centerIn: parent
    width: root.style === "thumbnailList" ? 400 : Math.min(parent.width - 64, Math.max(148, cells.contentWidth + 28))
    height: root.style === "thumbnailList" ? Math.min(parent.height - 80, Math.max(110, cells.contentHeight + 28)) : 146
    radius: 14
    color: Color.menu.background
    border.color: Color.menu.border
    border.width: 1
    ListView {
      id: cells
      anchors { fill: parent; margins: 14 }
      model: root.entries
      orientation: root.style === "thumbnailList" ? ListView.Vertical : ListView.Horizontal
      spacing: 8
      clip: true
      delegate: SwitcherCell {
        required property var modelData
        required property int index
        entry: modelData
        selected: index === root.selectedIndex
        thumbnail: root.style === "thumbnailList"
      }
      onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
      currentIndex: root.selectedIndex
    }
  }
}
