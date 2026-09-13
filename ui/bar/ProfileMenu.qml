import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.Commons

PopupWindow {
  id: root
  required property Item anchorItem
  required property var bar
  readonly property var service: bar ? bar.service : null
  readonly property string currentProfile: service ? service.getProfile() : ""
  readonly property bool bottomBar: bar && bar.position === "bottom"

  visible: false
  implicitWidth: 176
  implicitHeight: menuColumn.implicitHeight + 12
  color: "transparent"

  function open() {
    if (!service) return
    bar.requestPopout(root)
    visible = true
  }

  function close() {
    visible = false
    if (bar) bar.releasePopout(root)
  }

  function pick(profileId) {
    // Switching profiles can destroy the button and this popup immediately.
    var targetService = service
    close()
    if (targetService) targetService.setProfile(profileId)
  }

  Component.onDestruction: if (bar) bar.releasePopout(root)

  anchor.item: anchorItem
  anchor.edges: (bottomBar ? Edges.Top : Edges.Bottom) | Edges.Left
  anchor.gravity: (bottomBar ? Edges.Top : Edges.Bottom) | Edges.Right
  anchor.adjustment: PopupAdjustment.Slide

  HyprlandFocusGrab {
    active: root.visible
    // Include only the popup so clicks anywhere else, including the bar, dismiss.
    windows: [root]
    onCleared: root.close()
  }

  Rectangle {
    anchors.fill: parent
    radius: 10
    color: Color.menu.background
    border.color: Color.menu.border
    border.width: 1
    focus: true
    Keys.onEscapePressed: root.close()

    Column {
      id: menuColumn
      anchors { left: parent.left; right: parent.right; top: parent.top; margins: 6 }

      Repeater {
        model: [
          { label: "GNOME", profileId: "gnome" },
          { label: "Plasma", profileId: "plasma" },
          { label: "Mac", profileId: "macos" }
        ]

        Rectangle {
          required property var modelData
          width: menuColumn.width
          height: 34
          radius: 6
          color: actionMouse.containsMouse ? Color.menu.selectedBackground : "transparent"

          Text {
            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
            text: root.currentProfile === modelData.profileId ? "✓" : ""
            color: Color.menu.text
            font.family: Style.font.family
          }

          Text {
            anchors { left: parent.left; leftMargin: 34; verticalCenter: parent.verticalCenter }
            text: modelData.label
            color: Color.menu.text
            font.family: Style.font.family
          }

          MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.pick(modelData.profileId)
          }
        }
      }
    }
  }
}
