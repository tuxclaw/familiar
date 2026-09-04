import QtQuick
import Quickshell
import qs.Commons

Text {
  id: root

  property string format: "ddd HH:mm"
  property string fontFamily: Style.font.family
  property date displayDate: clock.date

  text: Qt.formatDateTime(displayDate, format)
  color: Color.bar.text
  font.family: fontFamily
  font.pixelSize: 14
  font.weight: Font.DemiBold

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
    onDateChanged: root.displayDate = date
  }
}
