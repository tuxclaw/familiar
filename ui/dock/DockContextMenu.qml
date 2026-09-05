import QtQuick
import qs.Commons

Rectangle {
  id: root
  property var entry: null
  property bool pinned: false
  signal pinRequested(string desktopId, bool pin)
  signal newWindowRequested(var entry)
  signal quitRequested(var entry)

  visible: entry !== null
  width: 176
  height: menuColumn.implicitHeight + 12
  radius: 10
  color: Color.menu.background
  border.color: Color.menu.border
  border.width: 1
  z: 20

  function openFor(candidate, isPinned, xPosition) {
    entry = candidate
    pinned = isPinned
    x = Math.max(0, Math.min(parent.width - width, xPosition - width / 2))
  }
  function close() { entry = null }

  Column {
    id: menuColumn
    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 6 }

    Repeater {
      model: [root.pinned ? "Unpin" : "Pin", "New window", "Quit"]
      Rectangle {
        required property string modelData
        width: menuColumn.width
        height: 34
        radius: 6
        color: actionMouse.containsMouse ? Color.menu.selectedBackground : "transparent"
        Text {
          anchors.fill: parent
          anchors.leftMargin: 10
          verticalAlignment: Text.AlignVCenter
          text: modelData
          color: Color.menu.text
          font.family: Style.font.family
        }
        MouseArea {
          id: actionMouse
          anchors.fill: parent
          hoverEnabled: true
          onClicked: {
            if (modelData === "Pin" || modelData === "Unpin") {
              var pinId = root.pinned ? String(root.entry.pinId || root.entry.desktopId) : String(root.entry.desktopId)
              root.pinRequested(pinId, !root.pinned)
            }
            else if (modelData === "New window") root.newWindowRequested(root.entry)
            else root.quitRequested(root.entry)
            root.close()
          }
        }
      }
    }
  }
}
