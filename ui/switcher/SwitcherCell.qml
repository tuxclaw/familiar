import QtQuick
import Quickshell
import qs.Commons

Rectangle {
  id: root
  required property var entry
  property bool selected: false
  property bool thumbnail: false
  property var appLibrary: null
  readonly property var desktop: DesktopEntries.byId(String(entry.appId || "")) || DesktopEntries.heuristicLookup(String(entry.appId || ""))
  width: thumbnail ? 360 : 112
  height: thumbnail ? 82 : 118
  radius: 10
  color: "transparent"
  border.color: selected ? Color.accent : "transparent"
  border.width: selected ? 2 : 0

  Image {
    width: root.thumbnail ? 52 : 64; height: width
    anchors { left: parent.left; leftMargin: root.thumbnail ? 14 : (parent.width - width) / 2; verticalCenter: parent.verticalCenter }
    source: Quickshell.iconPath(root.desktop ? root.desktop.icon : "application-x-executable", "application-x-executable")
    fillMode: Image.PreserveAspectFit
  }
  Text {
    anchors { left: root.thumbnail ? parent.left : undefined; leftMargin: root.thumbnail ? 82 : 0; right: root.thumbnail ? parent.right : undefined; bottom: root.thumbnail ? undefined : parent.bottom; bottomMargin: 8; verticalCenter: root.thumbnail ? parent.verticalCenter : undefined; horizontalCenter: root.thumbnail ? undefined : parent.horizontalCenter }
    width: root.thumbnail ? undefined : parent.width - 10
    text: String(root.entry.title || root.entry.appId || "Window")
    color: Color.menu.text
    elide: Text.ElideRight
    horizontalAlignment: root.thumbnail ? Text.AlignLeft : Text.AlignHCenter
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
  }
}
