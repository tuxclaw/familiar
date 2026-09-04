import QtQuick
import qs.Commons

Item {
  id: root
  property string style: "dot"
  property int count: 0

  implicitWidth: style === "pill" ? 18 : 16
  implicitHeight: 5
  visible: count > 0

  Row {
    anchors.centerIn: parent
    spacing: 2

    Repeater {
      model: root.style === "pill" ? 1 : Math.min(3, root.count)
      Rectangle {
        width: root.style === "line" ? 14 : root.style === "pill" ? 18 : 4
        height: root.style === "line" ? 2 : root.style === "pill" ? 3 : 4
        radius: height / 2
        color: Color.accent
      }
    }
  }
}
