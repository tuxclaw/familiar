import QtQuick
import qs.Commons

Item {
  id: root
  property var bar: null
  property string profileId: ""
  implicitWidth: label.implicitWidth + Style.spacing.lg * 2
  implicitHeight: Math.max(label.implicitHeight, 24)

  Text {
    id: label
    anchors.centerIn: parent
    text: root.profileId === "macos" ? "●" : "Applications"
    color: Color.bar.text
    font.family: root.bar ? root.bar.fontFamily : Style.font.family
    font.pixelSize: Style.font.body
    font.weight: Font.DemiBold
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      if (!root.bar || !root.bar.shell || typeof root.bar.shell.summon !== "function") return
      if (root.profileId === "macos") root.bar.shell.summon("omarchy.menu", "{}")
      else if (root.bar.manifest) root.bar.shell.summon(root.bar.manifest.id, '{"surface":"launcher"}')
    }
  }
}
