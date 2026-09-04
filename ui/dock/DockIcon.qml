import QtQuick
import Quickshell
import qs.Commons

Item {
  id: root
  required property var entry
  property int iconSize: 48
  property real magnifyScale: 1
  property string indicatorStyle: "dot"
  property bool pinned: false

  signal activated(var entry)
  signal contextRequested(var entry, point position)

  implicitWidth: iconSize * magnifyScale + 8
  implicitHeight: iconSize * magnifyScale + 12

  Image {
    id: icon
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    width: root.iconSize * root.magnifyScale
    height: width
    fillMode: Image.PreserveAspectFit
    source: {
      var value = String(root.entry.icon || "")
      return value.length > 0 ? Quickshell.iconPath(value, true)
        : Quickshell.iconPath("application-x-executable", true)
    }
    Behavior on width { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
  }

  RunningIndicator {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    style: root.indicatorStyle
    count: Number(root.entry.windowCount || 0)
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onPositionChanged: function(mouse) { root.parent.pointerPosition = mapToItem(root.parent, mouse.x, mouse.y) }
    onExited: root.parent.pointerPosition = Qt.point(-10000, -10000)
    onClicked: function(mouse) {
      if (mouse.button === Qt.RightButton)
        root.contextRequested(root.entry, mapToItem(root.parent, mouse.x, mouse.y))
      else
        root.activated(root.entry)
    }
  }
}
