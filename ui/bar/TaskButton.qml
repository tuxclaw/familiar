import QtQuick
import qs.Commons

Item {
  id: root
  required property var toplevel
  property var bar: null
  implicitWidth: Math.min(180, Math.max(72, label.implicitWidth + Style.spacing.lg * 2))
  implicitHeight: Math.max(label.implicitHeight, 28)

  Text {
    id: label
    anchors.fill: parent
    anchors.leftMargin: Style.spacing.md
    anchors.rightMargin: Style.spacing.md
    text: String(root.toplevel.title || root.toplevel.appId || "Application")
    color: Color.bar.text
    font.family: root.bar ? root.bar.fontFamily : Style.font.family
    font.pixelSize: Style.font.body
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: if (root.toplevel && typeof root.toplevel.activate === "function") root.toplevel.activate()
  }
}
