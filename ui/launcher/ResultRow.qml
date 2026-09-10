import QtQuick
import "../../lib/Input.js" as Input
import Quickshell
import qs.Commons

Rectangle {
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

  implicitHeight: 62
  radius: 7
  color: selected || hover.hovered ? Color.menu.selectedBackground : "transparent"
  border.color: selected ? Color.accent : "transparent"
  border.width: selected ? 2 : 0

  Image {
    id: icon
    anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 10 }
    width: 42; height: 42
    source: root.iconSource(root.entry.icon)
    sourceSize.width: width * Screen.devicePixelRatio
    sourceSize.height: height * Screen.devicePixelRatio
    fillMode: Image.PreserveAspectFit
    asynchronous: true
  }
  Column {
    anchors { left: icon.right; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 12; rightMargin: 12 }
    spacing: 2
    Text { width: parent.width; text: Input.boundedText(root.entry.name); textFormat: Text.PlainText; color: Color.menu.text; elide: Text.ElideRight; font.family: Style.font.family; font.pixelSize: Style.font.body; font.bold: root.selected }
    Text { width: parent.width; text: Input.boundedText(root.entry.description || (root.entry.kind === "command" ? "Omarchy command" : root.entry.categories || "Application")); textFormat: Text.PlainText; color: Color.muted; elide: Text.ElideRight; font.family: Style.font.family; font.pixelSize: Math.max(12, Style.font.caption) }
  }
  HoverHandler { id: hover }
  TapHandler { onTapped: root.activated() }
}
