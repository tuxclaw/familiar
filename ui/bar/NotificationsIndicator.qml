import QtQuick
import qs.Commons

Text {
  property var bar: null
  readonly property int unreadCount: 0
  text: unreadCount > 0 ? "Notifications " + unreadCount : "Notifications"
  color: Color.bar.text
  font.family: bar ? bar.fontFamily : Style.font.family
  font.pixelSize: Style.font.body
  verticalAlignment: Text.AlignVCenter
}
