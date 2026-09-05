import QtQuick

GridView {
  id: root
  property var entries: []
  property int selectedIndex: 0
  property var appLibrary: null
  signal activated(int index)

  model: entries
  cellWidth: Math.max(112, Math.floor(width / 6))
  cellHeight: 144
  clip: true
  interactive: true
  reuseItems: true
  pixelAligned: false
  cacheBuffer: cellHeight * 8
  displayMarginBeginning: cellHeight
  displayMarginEnd: cellHeight
  flickDeceleration: 1800
  maximumFlickVelocity: 3500
  boundsBehavior: Flickable.StopAtBounds
  flickableDirection: Flickable.VerticalFlick
  highlightFollowsCurrentItem: false

  WheelHandler {
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    onWheel: function(event) {
      var dy = event.pixelDelta.y !== 0 ? event.pixelDelta.y : event.angleDelta.y * 0.5
      var maxY = Math.max(0, root.contentHeight - root.height)
      root.contentY = Math.max(0, Math.min(maxY, root.contentY - dy))
      event.accepted = true
    }
  }

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
