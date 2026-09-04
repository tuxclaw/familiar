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

  function iconSource(iconName) {
    var value = String(iconName || "")
    if (value.length === 0) return Quickshell.iconPath("application-x-executable", true)
    if (value.indexOf("file://") === 0 || value.indexOf("image://") === 0) return value
    if (value.charAt(0) === "/") return Util.fileUrl(value)
    var themed = Quickshell.iconPath(value, true)
    return themed.length > 0 ? themed : Quickshell.iconPath("application-x-executable", true)
  }

  implicitWidth: iconSize * magnifyScale + 8
  implicitHeight: iconSize * magnifyScale + 12

  Image {
    id: icon
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    width: root.iconSize * root.magnifyScale
    height: width
    fillMode: Image.PreserveAspectFit
    source: root.iconSource(root.entry.icon)
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
