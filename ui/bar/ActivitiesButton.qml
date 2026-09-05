import QtQuick
import qs.Commons
import qs.Ui

WidgetButton {
  id: root
  text: "Activities"
  fontFamily: bar ? bar.fontFamily : Style.font.family
  fontSize: Style.font.body
  foreground: Color.bar.text
  Rectangle {
    anchors.fill: parent
    z: -1
    radius: height / 2
    color: activityHover.hovered && root.bar ? root.bar.familiarHover : "transparent"
    Behavior on color { ColorAnimation { duration: root.bar ? root.bar.hoverDuration : 100; easing.type: root.bar ? root.bar.motionCurve : Easing.OutCubic } }
  }
  HoverHandler { id: activityHover }
  onPressed: function() {
    if (!root.bar || !root.bar.shell || !root.bar.manifest
        || typeof root.bar.shell.summon !== "function") return
    root.bar.shell.summon(root.bar.manifest.id, '{"surface":"overview"}')
  }
}
