import QtQuick
import Quickshell
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

  function notificationService() {
    var shell = bar && bar.shell
    if (!shell) return null
    if (typeof shell.firstPartyServiceFor === "function") {
      var firstParty = shell.firstPartyServiceFor("omarchy.notifications")
      if (firstParty) return firstParty
    }
    if (typeof shell.serviceFor === "function") {
      var service = shell.serviceFor("omarchy.notifications")
      if (service) return service
    }
    if ("notifications" in shell && shell.notifications) return shell.notifications
    if ("notificationService" in shell && shell.notificationService) return shell.notificationService
    return null
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      var service = root.notificationService()
      if (service && typeof service.showRecentHistory === "function")
        service.showRecentHistory()
      else if (service && typeof service.showHistory === "function")
        service.showHistory()
      else
        Quickshell.execDetached(["omarchy-shell", "notifications", "showHistory"])
    }
  }
}
