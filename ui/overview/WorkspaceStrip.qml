import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.Commons

Item {
  id: root
  property bool vertical: false
  readonly property var workspaceValues: Hyprland.workspaces.values || []
  readonly property var workspaceIds: {
    var ids = [1, 2, 3, 4, 5]
    for (var i = 0; i < workspaceValues.length; i++) {
      var id = Number(workspaceValues[i].id)
      if (id > 0 && id <= 10 && ids.indexOf(id) < 0) ids.push(id)
    }
    ids.sort(function(a, b) { return a - b })
    return ids
  }

  implicitWidth: vertical ? 142 : strip.implicitWidth
  implicitHeight: vertical ? strip.implicitHeight : 92

  function workspaceFor(id) {
    for (var i = 0; i < workspaceValues.length; i++)
      if (Number(workspaceValues[i].id) === Number(id)) return workspaceValues[i]
    return null
  }

  Grid {
    id: strip
    columns: root.vertical ? 1 : root.workspaceIds.length
    rows: root.vertical ? root.workspaceIds.length : 1
    spacing: 10
    Repeater {
      model: root.workspaceIds
      Rectangle {
        id: card
        required property var modelData
        readonly property int workspaceId: Number(modelData)
        readonly property var workspace: root.workspaceFor(workspaceId)
        readonly property var windows: workspace ? (workspace.toplevels.values || []) : []
        readonly property bool focused: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === workspaceId
        width: root.vertical ? 132 : 148
        height: 82
        radius: 9
        color: cardMouse.containsMouse ? Color.menu.selectedBackground : Color.menu.background
        border.color: focused ? Color.accent : Color.menu.border
        border.width: focused ? 2 : 1

        Text {
          anchors { top: parent.top; left: parent.left; margins: 7 }
          text: card.workspaceId
          color: Color.menu.text
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
        Row {
          anchors.centerIn: parent
          spacing: 4
          Repeater {
            model: card.windows.slice(0, 4)
            Image {
              required property var modelData
              readonly property var wayland: modelData ? modelData.wayland : null
              readonly property var desktop: DesktopEntries.byId(String(wayland ? wayland.appId : "")) || DesktopEntries.heuristicLookup(String(wayland ? wayland.appId : ""))
              width: 24; height: 24
              source: Quickshell.iconPath(desktop ? desktop.icon : "application-x-executable", "application-x-executable")
              fillMode: Image.PreserveAspectFit
            }
          }
        }
        MouseArea {
          id: cardMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: Util.execDetached("hyprctl dispatch " + Util.shellQuote('hl.dsp.focus({ workspace = "' + card.workspaceId + '" })'))
        }
      }
    }
  }
}
