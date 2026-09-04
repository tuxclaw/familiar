import QtQuick

GridView {
  id: root
  property var entries: []
  property int selectedIndex: 0
  property var appLibrary: null
  signal activated(int index)

  model: entries
  cellWidth: Math.max(112, width / 6)
  cellHeight: 144
  clip: true
  interactive: true

  delegate: AppGridCell {
    required property var modelData
    required property int index
    width: root.cellWidth
    height: root.cellHeight
    entry: modelData
    selected: index === root.selectedIndex
    appLibrary: root.appLibrary
    onActivated: root.activated(index)
  }
}
