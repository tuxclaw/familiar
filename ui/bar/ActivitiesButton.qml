import QtQuick
import qs.Commons
import qs.Ui

WidgetButton {
  id: root
  readonly property string style: bar && bar.profile && bar.profile.overview ? bar.profile.overview.style : "gnome"
  keepSpace: true
  labelVisible: false
  text: " "
  fixedWidth: root.style === "gnome" ? 44 : 27
  tooltipText: "Activities"
  foreground: Color.bar.text
  Rectangle {
    anchors.fill: parent
    anchors.margins: root.style === "gnome" ? 3 : 0
    z: -1
    radius: height / 2
    color: activityHover.hovered && root.bar ? root.bar.familiarHover : "transparent"
    Behavior on color { ColorAnimation { duration: root.bar ? root.bar.hoverDuration : 100; easing.type: root.bar ? root.bar.motionCurve : Easing.OutCubic } }
  }
  Image {
    z: -1
    anchors.centerIn: parent
    width: root.style === "gnome" ? 20 : 18
    height: width
    source: Qt.resolvedUrl("../../assets/omarchy-logo.svg")
    sourceSize.width: 40
    sourceSize.height: 40
    fillMode: Image.PreserveAspectFit
    onStatusChanged: if (status === Image.Error)
      source = Qt.resolvedUrl("../../assets/omarchy-logo.png")
  }
  HoverHandler { id: activityHover }
  SequentialAnimation {
    id: pressFeedback
    NumberAnimation { target: root; property: "scale"; to: 0.94; duration: root.bar ? root.bar.hoverDuration : 100 }
    NumberAnimation { target: root; property: "scale"; to: 1; duration: root.bar ? root.bar.hoverDuration : 100 }
  }
  ProfileMenu { id: profileMenu; anchorItem: root; bar: root.bar }
  onPressed: function(button) {
    if (button === Qt.RightButton) {
      profileMenu.open()
      return
    }
    if (button !== Qt.LeftButton) return
    if (root.style === "gnome") pressFeedback.restart()
    if (!root.bar || !root.bar.shell || !root.bar.manifest
        || typeof root.bar.shell.summon !== "function") return
    root.bar.shell.summon(root.bar.manifest.id, '{"surface":"overview"}')
  }
}
