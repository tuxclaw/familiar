import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.Commons

RowLayout {
  id: root
  property var bar: null
  spacing: Style.spacing.sm
  readonly property var workspaceValues: Hyprland.workspaces.values || []
  readonly property var displayedWorkspaces: workspaceValues.length > 0 ? workspaceValues : [null, null, null]

  Repeater {
    model: root.displayedWorkspaces

    Rectangle {
      id: pip
      required property var modelData
      required property int index
      readonly property bool focused: modelData
        ? Hyprland.focusedWorkspace === modelData
        : index === 0
      width: focused ? 18 : 8
      height: 8
      radius: height / 2
      color: focused ? Color.bar.active : Color.bar.text
      opacity: focused ? 1 : 0.55

      MouseArea {
        anchors.fill: parent
        cursorShape: pip.modelData ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (pip.modelData && typeof pip.modelData.activate === "function") pip.modelData.activate()
      }
    }
  }
}
