import QtQuick
import qs.Commons

Rectangle {
  property bool vertical: false
  implicitWidth: vertical ? 1 : 12
  implicitHeight: vertical ? 12 : 1
  color: Color.bar.text
  opacity: 0.25
}
