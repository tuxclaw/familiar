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
    visible: root.style !== "gnome"
    anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: 28 }
    text: root.style === "presentWindows" ? "Present Windows" : root.style === "missionControl" ? "Mission Control" : "Activities"
    color: Color.menu.text
    font.family: Style.font.family
    font.pixelSize: 26
    font.bold: true
  }

  Row {
    visible: root.style === "gnome"
    anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: 28 }
    spacing: 12
    Text {
      text: "Activities"
      color: Color.menu.text
      font.family: Style.font.family
      font.pixelSize: Style.font.body
      font.weight: Font.DemiBold
    }
    Text {
      text: root.windows.length === 1 ? "1 open window" : root.windows.length + " open windows"
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.body
    }
  }

  WorkspaceStrip {
    id: workspaces
    style: root.style
    availableWidth: Math.max(0, root.width - 64)
    vertical: root.style === "presentWindows"
    anchors {
      top: parent.top
      topMargin: root.style === "gnome" ? 66 : root.style === "presentWindows" ? 70 : 74
      right: root.style === "gnome" ? undefined : parent.right
      rightMargin: 24
      horizontalCenter: root.style === "presentWindows" ? undefined : parent.horizontalCenter
    }
  }

  Text {
    visible: root.style === "gnome"
    anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 30 }
    text: "Select a window to resume  ·  Esc to return"
    color: Color.muted
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
  }

  GridView {
    id: grid
    anchors {
      top: parent.top
      bottom: parent.bottom
      left: parent.left
      right: parent.right
      topMargin: root.style === "gnome" ? workspaces.y + workspaces.height + 28 : root.style === "presentWindows" ? 74 : 182
      bottomMargin: root.style === "gnome" ? 78 : 42
      leftMargin: root.style === "gnome" ? Math.max(24, (root.width - (grid.count === 1 ? 900 : 1440)) / 2) : 42
      rightMargin: root.style === "gnome" ? Math.max(24, (root.width - (grid.count === 1 ? 900 : 1440)) / 2) : root.style === "presentWindows" ? 190 : 42
    }
    clip: true
    model: root.windows
    readonly property int columnCount: Math.max(1, Math.min(root.style === "gnome" ? Math.max(1, Math.floor(width / 320)) : 4, 4, Math.ceil(Math.sqrt(count))))
    cellWidth: width / columnCount
    cellHeight: root.style === "gnome" ? Math.min(cellWidth * 0.7, Math.max(180, height / Math.max(1, Math.ceil(count / columnCount)))) : Math.min(230, Math.max(150, height / Math.max(1, Math.ceil(count / columnCount))))
    topMargin: root.style === "gnome" ? Math.max(0, (height - Math.ceil(count / columnCount) * cellHeight) / 2) : 0
    delegate: Item {
      required property var modelData
      required property int index
      width: grid.cellWidth
      height: grid.cellHeight
      WindowThumb {
        anchors.fill: parent
        anchors.margins: root.style === "gnome" ? 16 : 10
        style: root.style
        motionDuration: familiar.motionFast
        toplevel: parent.modelData
        service: root.service
        livePreview: parent.index < 12
        cornerRadius: root.style === "presentWindows" ? 6 : root.style === "missionControl" ? 10 : 16
        onActivated: root.dismiss()
      }
    }
    Text { anchors.centerIn: parent; visible: grid.count === 0; text: "No open windows"; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.body }
  }
}
