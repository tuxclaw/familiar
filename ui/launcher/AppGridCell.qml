import QtQuick
import Quickshell
import qs.Commons

Item {
  id: root
  required property var entry
  property bool selected: false
  property var appLibrary: null
  signal activated()

  function iconSource(value) {
    var icon = String(value || "")
    if (appLibrary && typeof appLibrary.iconSource === "function") return appLibrary.iconSource(icon)
    if (icon.indexOf("file://") === 0 || icon.indexOf("image://") === 0) return icon
    if (icon.charAt(0) === "/") return Util.fileUrl(icon)
    return Quickshell.iconPath(icon || "application-x-executable", "application-x-executable")
  }

  implicitWidth: 128
  implicitHeight: 136

  Rectangle {
    anchors.fill: parent
    radius: 12
    color: root.selected || hover.hovered ? Color.menu.selectedBackground : "transparent"
    border.color: root.selected ? Color.accent : "transparent"
    border.width: root.selected ? 2 : 0
  }
  Image {
    anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: 12 }
    width: 82; height: 82
    source: root.iconSource(root.entry.icon)
    sourceSize.width: width * Screen.devicePixelRatio
    sourceSize.height: height * Screen.devicePixelRatio
    fillMode: Image.PreserveAspectFit
    asynchronous: true
    cache: true
    smooth: true
  }
  Text {
    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 8 }
    text: root.entry.name
    color: Color.menu.text
    horizontalAlignment: Text.AlignHCenter
    elide: Text.ElideRight
    maximumLineCount: 2
    wrapMode: Text.Wrap
    font.family: Style.font.family
    font.pixelSize: Style.font.body
  }
  HoverHandler { id: hover }
  TapHandler { onTapped: root.activated() }
}
