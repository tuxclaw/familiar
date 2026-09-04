import QtQuick
import qs.Commons

Text {
  id: root

  property var bar: null
  readonly property int unreadCount: 0
  text: unreadCount > 0 ? "Notifications " + unreadCount : "Notifications"
  color: Color.bar.text
  font.family: bar ? bar.fontFamily : Style.font.family
  font.pixelSize: Style.font.body
  verticalAlignment: Text.AlignVCenter

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      var shell = root.bar && root.bar.shell
      if (!shell || typeof shell.firstPartyServiceFor !== "function") return
      var service = shell.firstPartyServiceFor("omarchy.notifications")
      if (service && typeof service.showRecentHistory === "function")
        service.showRecentHistory()
    }
  }
}
