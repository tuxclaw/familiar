import QtQuick
import qs.Commons

Item {
  id: root
  property var bar: null
  implicitWidth: label.implicitWidth + Style.spacing.lg * 2
  implicitHeight: Math.max(label.implicitHeight, 24)

  Text {
    id: label
    anchors.centerIn: parent
    text: "Activities"
    color: Color.bar.text
    font.family: root.bar ? root.bar.fontFamily : Style.font.family
    font.pixelSize: Style.font.body
    font.weight: Font.DemiBold
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      if (root.bar && root.bar.shell && root.bar.manifest && typeof root.bar.shell.summon === "function")
        root.bar.shell.summon(root.bar.manifest.id, '{"surface":"overview"}')
    }
  }
}
