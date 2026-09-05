import QtQuick
import Quickshell.Wayland
import qs.Commons
import "."
import "../.."

Item {
  id: root
  property string style: "gnome"
  property var service: null
  readonly property var windows: ToplevelManager.toplevels.values || []
  signal dismiss()

  Familiar {
    id: familiar
    profile: root.service ? root.service.currentProfile : ({})
  }

  function open(payload) {
    root.opacity = 0
    root.scale = root.style === "presentWindows" ? 1 : root.style === "missionControl" ? 0.92 : 0.96
    enterOpacity.restart()
    enterScale.restart()
  }

  opacity: 0
  scale: 1
  readonly property int enterDuration: familiar.profileId === "macos" ? Math.round(300 * familiar.motionScale) : familiar.motionSlow
  NumberAnimation { id: enterOpacity; target: root; property: "opacity"; to: 1; duration: root.enterDuration; easing.type: familiar.motionCurve; easing.overshoot: familiar.profileId === "macos" ? 1.2 : 0 }
  NumberAnimation { id: enterScale; target: root; property: "scale"; to: 1; duration: root.enterDuration; easing.type: familiar.motionCurve; easing.overshoot: familiar.profileId === "macos" ? 1.2 : 0 }

  MouseArea { anchors.fill: parent; onClicked: root.dismiss() }

  Text {
    anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: 28 }
    text: root.style === "presentWindows" ? "Present Windows" : root.style === "missionControl" ? "Mission Control" : "Activities"
    color: Color.menu.text
    font.family: Style.font.family
    font.pixelSize: 26
    font.bold: true
  }

  WorkspaceStrip {
    id: workspaces
    vertical: root.style === "presentWindows"
    anchors {
      top: parent.top
      topMargin: root.style === "presentWindows" ? 70 : 74
      right: parent.right
      rightMargin: 24
      horizontalCenter: root.style === "presentWindows" ? undefined : parent.horizontalCenter
    }
  }

  GridView {
    id: grid
    anchors {
      top: parent.top
      bottom: parent.bottom
      left: parent.left
      right: parent.right
      topMargin: root.style === "presentWindows" ? 74 : 182
      bottomMargin: 42
      leftMargin: 42
      rightMargin: root.style === "presentWindows" ? 190 : 42
    }
    clip: true
    model: root.windows
    readonly property int columnCount: Math.max(1, Math.min(4, Math.ceil(Math.sqrt(count))))
    cellWidth: width / columnCount
    cellHeight: Math.min(230, Math.max(150, height / Math.max(1, Math.ceil(count / columnCount))))
    delegate: Item {
      required property var modelData
      required property int index
      width: grid.cellWidth
      height: grid.cellHeight
      WindowThumb {
        anchors.fill: parent
        anchors.margins: 10
        toplevel: parent.modelData
        service: root.service
        livePreview: parent.index < 12
        cornerRadius: root.style === "presentWindows" ? 6 : root.style === "missionControl" ? 10 : 12
        onActivated: root.dismiss()
      }
    }
    Text { anchors.centerIn: parent; visible: grid.count === 0; text: "No open windows"; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.body }
  }
}
