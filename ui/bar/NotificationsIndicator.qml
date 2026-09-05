import QtQuick
import qs.Commons
import qs.Ui

WidgetButton {
  id: root

  readonly property int unreadCount: 0
  text: unreadCount > 0 ? "Notifications " + unreadCount : "Notifications"
  fontFamily: bar ? bar.fontFamily : Style.font.family
  fontSize: Style.font.body
  foreground: Color.bar.text
  Rectangle {
    anchors.fill: parent
    z: -1
    radius: height / 2
    color: notificationHover.hovered && root.bar ? root.bar.familiarHover : "transparent"
    Behavior on color { ColorAnimation { duration: root.bar ? root.bar.hoverDuration : 100; easing.type: root.bar ? root.bar.motionCurve : Easing.OutCubic } }
  }
  HoverHandler { id: notificationHover }
  onPressed: function() {
    var shell = root.bar && root.bar.shell
    if (!shell || typeof shell.firstPartyServiceFor !== "function") return
    var service = shell.firstPartyServiceFor("omarchy.notifications")
    if (service && typeof service.showRecentHistory === "function")
      service.showRecentHistory()
  }
}
