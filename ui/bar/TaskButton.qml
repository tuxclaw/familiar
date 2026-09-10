import QtQuick
import "../../lib/Input.js" as Input
import qs.Commons

Item {
  id: root
  required property var toplevel
  property var bar: null
  implicitWidth: Math.min(180, Math.max(72, label.implicitWidth + Style.spacing.lg * 2))
  implicitHeight: Math.max(label.implicitHeight, 28)

  Rectangle {
    anchors.fill: parent
    radius: 4
    color: taskHover.containsMouse && root.bar ? root.bar.familiarHover : "transparent"
    Behavior on color { ColorAnimation { duration: root.bar ? root.bar.hoverDuration : 80; easing.type: root.bar ? root.bar.motionCurve : Easing.OutQuad } }
  }

  Text {
    id: label
    anchors.fill: parent
    anchors.leftMargin: Style.spacing.md
    anchors.rightMargin: Style.spacing.md
    text: Input.boundedText(String(root.toplevel.title || root.toplevel.appId || "Application"))
    textFormat: Text.PlainText
    color: Color.bar.text
    font.family: root.bar ? root.bar.fontFamily : Style.font.family
    font.pixelSize: Style.font.body
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
  }

  MouseArea {
    id: taskHover
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: if (root.toplevel && typeof root.toplevel.activate === "function") root.toplevel.activate()
  }
}
