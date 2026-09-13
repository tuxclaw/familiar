import QtQuick
import "../../lib/DockPins.js" as DockPins
import qs.Commons

Rectangle {
  id: root
  required property var dockSurface
  readonly property int columns: Math.min(4, Math.max(1, dockSurface.folderEntries.length))
  readonly property int gridTop: 48
  readonly property var order: {
    var ids = dockSurface.folderEntries.map(function(entry) { return entry.pinId })
    var plan = dockSurface.dragPlan
    if (dockSurface.draggingPinned && plan && plan.kind === "grid")
      return DockPins.insert(ids, dockSurface.dragEntry.pinId, plan.index)
    return ids
  }
  width: columns * dockSurface.cellWidth + 24
  height: gridTop + Math.max(1, Math.ceil(order.length / columns)) * dockSurface.cellHeight + 12
  color: Color.menu.background
  border.color: Color.menu.border
  radius: 14

  Text {
    x: 12; y: 12
    width: parent.width - 48
    text: root.dockSurface.folderName
    textFormat: Text.PlainText
    elide: Text.ElideRight
    color: Color.menu.text
  }
  Text {
    anchors.right: parent.right
    anchors.rightMargin: 12
    y: 12
    text: "×"
    color: Color.menu.text
    MouseArea { anchors.fill: parent; anchors.margins: -8; onClicked: root.dockSurface.openFolderId = "" }
  }
  Repeater {
    model: root.dockSurface.folderEntries
    DockIcon {
      required property var modelData
      required property int index
      readonly property int slot: root.order.indexOf(modelData.pinId)
      entry: modelData
      dockSurface: root.dockSurface
      pinned: true
      iconSize: dockSurface.iconSize
      motionScale: dockSurface.animationScale
      x: 12 + (slot % root.columns) * dockSurface.cellWidth
      y: root.gridTop + Math.floor(slot / root.columns) * dockSurface.cellHeight
      Behavior on x { NumberAnimation { duration: Math.round(150 * root.dockSurface.animationScale); easing.type: Easing.OutCubic } }
      Behavior on y { NumberAnimation { duration: Math.round(150 * root.dockSurface.animationScale); easing.type: Easing.OutCubic } }
      onActivated: function(entry) { dockSurface.activate(entry) }
      onContextRequested: function(entry, position) { dockSurface.contextRequested(entry, position) }
      onReorderDropped: function(entry, position) { dockSurface.finishDrag(entry, position) }
    }
  }
}
