import QtQuick
import "../../lib/Input.js" as Input
import QtQuick.Controls
import Quickshell
import qs.Commons

Item {
  id: root
  required property var entry
  required property var dockSurface
  property var appLibrary: null
  property int iconSize: 48
  property real magnifyScale: 1
  property string indicatorStyle: "dot"
  property bool pinned: false
  property bool fallbackActive: false
  property bool showRunningIndicator: true
  property bool contextMenuEnabled: true
  property string tooltipText: Input.boundedText(entry.name)
  property string profileId: "gnome"
  property real motionScale: 1

  readonly property string executableIcon: Quickshell.iconPath("application-x-executable", "application-x-executable")
  readonly property string primaryIconSource: iconSource(entry.icon)

  signal activated(var entry)
  signal contextRequested(var entry, point position)

  function iconSource(iconName) {
    var value = String(iconName || "")
    if (value.length === 0) return executableIcon
    if (appLibrary && typeof appLibrary.iconSource === "function")
      return appLibrary.iconSource(value) || executableIcon
    if (value.indexOf("file://") === 0 || value.indexOf("image://") === 0) return value
    if (value.charAt(0) === "/") return Util.fileUrl(value)
    return Quickshell.iconPath(value, "application-x-executable")
  }

  onPrimaryIconSourceChanged: fallbackActive = false

  implicitWidth: iconSize * magnifyScale + 8
  implicitHeight: iconSize * magnifyScale + 12

  Image {
    id: icon
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    width: root.iconSize * root.magnifyScale
    height: width
    fillMode: Image.PreserveAspectFit
    sourceSize.width: width * Screen.devicePixelRatio
    sourceSize.height: height * Screen.devicePixelRatio
    source: root.fallbackActive ? root.executableIcon : root.primaryIconSource
    asynchronous: true
    onStatusChanged: if (status === Image.Error && !root.fallbackActive) root.fallbackActive = true
    Behavior on width { NumberAnimation { duration: Math.round(100 * root.motionScale); easing.type: Easing.OutQuad } }
    transform: Translate { y: launchBounce.running ? launchBounceOffset : 0 }
  }

  property real launchBounceOffset: 0
  SequentialAnimation {
    id: launchBounce
    loops: 2
    NumberAnimation { target: root; property: "launchBounceOffset"; from: 0; to: -12; duration: Math.round(160 * root.motionScale); easing.type: Easing.OutQuad }
    NumberAnimation { target: root; property: "launchBounceOffset"; from: -12; to: 0; duration: Math.round(160 * root.motionScale); easing.type: Easing.InQuad }
  }

  RunningIndicator {
    visible: root.showRunningIndicator
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    style: root.indicatorStyle
    count: Number(root.entry.windowCount || 0)
  }

  MouseArea {
    id: iconMouse
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onPositionChanged: function(mouse) { root.dockSurface.pointerPosition = mapToItem(root.dockSurface, mouse.x, mouse.y) }
    onExited: root.dockSurface.pointerPosition = Qt.point(-10000, -10000)
    onClicked: function(mouse) {
      if (mouse.button === Qt.RightButton && root.contextMenuEnabled)
        root.contextRequested(root.entry, mapToItem(root.parent, mouse.x, mouse.y))
      else if (mouse.button === Qt.LeftButton)
        if (root.profileId === "macos" && root.motionScale > 0) launchBounce.restart()
      if (mouse.button === Qt.LeftButton)
        root.activated(root.entry)
    }
  }

  ToolTip {
    id: tooltip
    visible: iconMouse.containsMouse && text.length > 0
    text: Input.boundedText(root.tooltipText)
    delay: 500
    contentItem: Text {
      text: Input.boundedText(tooltip.text)
      textFormat: Text.PlainText
      color: Color.menu.text
      font.family: Style.font.family
      font.pixelSize: Style.font.body
    }
  }
}
