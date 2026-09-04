import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.Commons

RowLayout {
  id: root
  property var bar: null
  spacing: Style.spacing.sm
  readonly property var workspaceValues: Hyprland.workspaces.values || []
  readonly property var displayedWorkspaces: {
    var ids = [1, 2, 3, 4, 5]
    for (var i = 0; i < workspaceValues.length; i++) {
      var id = workspaceValues[i] && workspaceValues[i].id
      if (id > 0 && id <= 10 && ids.indexOf(id) === -1) ids.push(id)
    }
    ids.sort(function(a, b) { return a - b })
    return ids
  }

  Repeater {
    model: root.displayedWorkspaces

    Rectangle {
      id: pip
      required property var modelData
      required property int index
      readonly property int workspaceId: Number(modelData)
      readonly property bool focused: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === workspaceId
      width: focused ? 18 : 16
      height: 16
      radius: height / 2
      color: focused ? Color.bar.active : Color.bar.text
      opacity: focused ? 1 : 0.55

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          if (!root.bar || typeof root.bar.run !== "function")
            return
          root.bar.run("hyprctl dispatch " + Util.shellQuote('hl.dsp.focus({ workspace = "' + pip.workspaceId + '" })'))
        }
      }
    }
  }
}
