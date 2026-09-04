import QtQuick
import Quickshell
import qs.Commons

Text {
  id: root

  property var bar: null
  property string format: "ddd HH:mm"
  property string fontFamily: Style.font.family
  property date displayDate: clock.date

  text: Qt.formatDateTime(displayDate, format)
  color: Color.bar.text
  font.family: fontFamily
  font.pixelSize: 14
  font.weight: Font.DemiBold

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      if (root.bar && root.bar.shell && typeof root.bar.shell.summon === "function")
        root.bar.shell.summon("omarchy.clock")
    }
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
    onDateChanged: root.displayDate = date
  }
}
