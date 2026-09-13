import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.Commons

Item {
  id: root
  property string style: ""
  property real availableWidth: 1000
  readonly property real previewWidth: Math.max(24, Math.min(164, (availableWidth - 10 * (workspaceIds.length - 1)) / workspaceIds.length))
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
  implicitHeight: root.style === "gnome" ? strip.implicitHeight + 18 : vertical ? strip.implicitHeight : 92

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
        width: root.style === "gnome" ? root.previewWidth : root.vertical ? 132 : 148
        height: root.style === "gnome" ? width * 0.5625 : 82
        radius: root.style === "gnome" ? 12 : 9
        color: cardMouse.containsMouse ? Color.menu.selectedBackground : Color.menu.background
        scale: root.style === "gnome" && cardMouse.containsMouse ? 1.025 : 1
        border.color: focused ? Color.accent : Color.menu.border
        border.width: focused ? 2 : 1

        Text {
          visible: root.style !== "gnome"
          anchors { top: parent.top; left: parent.left; margins: 7 }
          text: card.workspaceId
          color: Color.menu.text
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
        Row {
          visible: root.style !== "gnome"
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
        // Desktop miniatures use no additional screencopy streams.
        Item {
          visible: root.style === "gnome"
          anchors { fill: parent; margins: 8 }
          Rectangle {
            width: parent.width; height: 3; radius: 1.5
            color: Color.muted
            opacity: 0.25
          }
          Grid {
            id: miniatureGrid
            anchors { fill: parent; topMargin: 9; bottomMargin: 4 }
            columns: card.windows.length === 1 ? 1 : 2
            spacing: 4
            Repeater {
              model: card.windows.slice(0, 4)
              Rectangle {
                required property var modelData
                readonly property var wayland: modelData ? modelData.wayland : null
                readonly property var desktop: DesktopEntries.byId(String(wayland ? wayland.appId : "")) || DesktopEntries.heuristicLookup(String(wayland ? wayland.appId : ""))
                width: (miniatureGrid.width - (miniatureGrid.columns - 1) * 4) / miniatureGrid.columns
                height: (miniatureGrid.height - (card.windows.length > 2 ? 4 : 0)) / (card.windows.length > 2 ? 2 : 1)
                radius: 4
                color: Color.background
                border.color: Color.menu.border
                Image {
                  anchors.centerIn: parent
                  width: Math.max(0, Math.min(20, parent.width - 4, parent.height - 4)); height: width
                  source: Quickshell.iconPath(parent.desktop ? parent.desktop.icon : "application-x-executable", "application-x-executable")
                  fillMode: Image.PreserveAspectFit
                }
              }
            }
          }
        }
        Rectangle {
          visible: root.style === "gnome"
          anchors { horizontalCenter: parent.horizontalCenter; top: parent.bottom; topMargin: 8 }
          width: card.focused ? 20 : 5; height: 4; radius: 2
          color: card.focused ? Color.accent : Color.muted
          opacity: card.focused ? 1 : 0.45
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
