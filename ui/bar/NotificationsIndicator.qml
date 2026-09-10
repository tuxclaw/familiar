import QtQuick
import qs.Commons
import qs.Ui

WidgetButton {
  id: root

  text: "󰂛"
  foreground: Color.bar.text
  Rectangle {
    anchors.fill: parent
    z: -1
    radius: height / 2
    color: notificationHover.hovered && root.bar ? root.bar.familiarHover : "transparent"
    Behavior on color { ColorAnimation { duration: root.bar ? root.bar.hoverDuration : 100; easing.type: root.bar ? root.bar.motionCurve : Easing.OutCubic } }
  }
  HoverHandler { id: notificationHover }
  onPressed: function() {
    if (!root.bar || typeof root.bar.run !== "function") return
    // Third-party bars get a notifications proxy with DND only — no showRecentHistory.
    root.bar.run("omarchy-shell notifications showHistory")
  }
}
