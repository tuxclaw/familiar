import QtQuick
import qs.Commons
import qs.Ui

WidgetButton {
  id: root
  keepSpace: true
  labelVisible: false
  text: " "
  fixedWidth: 27
  tooltipText: "Activities"
  foreground: Color.bar.text
  Rectangle {
    anchors.fill: parent
    z: -1
    radius: height / 2
    color: activityHover.hovered && root.bar ? root.bar.familiarHover : "transparent"
    Behavior on color { ColorAnimation { duration: root.bar ? root.bar.hoverDuration : 100; easing.type: root.bar ? root.bar.motionCurve : Easing.OutCubic } }
  }
  Image {
    z: -1
    anchors.centerIn: parent
    width: 18
    height: 18
    source: Qt.resolvedUrl("../../assets/omarchy-logo.svg")
    sourceSize.width: 18
    sourceSize.height: 18
    fillMode: Image.PreserveAspectFit
    onStatusChanged: if (status === Image.Error)
      source = Qt.resolvedUrl("../../assets/omarchy-logo.png")
  }
  HoverHandler { id: activityHover }
  onPressed: function() {
    if (!root.bar || !root.bar.shell || !root.bar.manifest
        || typeof root.bar.shell.summon !== "function") return
    root.bar.shell.summon(root.bar.manifest.id, '{"surface":"overview"}')
  }
}
