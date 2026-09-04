import QtQuick
import QtQuick.Controls
import qs.Commons

Rectangle {
  id: root
  property alias text: input.text
  property string style: "grid"
  signal moveRequested(int delta)
  signal horizontalRequested(int delta)
  signal launchRequested()
  signal dismissRequested()

  function focusInput() { input.forceActiveFocus() }

  implicitHeight: style === "spotlight" ? 72 : 52
  radius: style === "grid" ? implicitHeight / 2 : Math.max(4, style === "kickoff" ? 6 : 10)
  color: Color.menu.selectedBackground
  border.color: input.activeFocus ? Color.accent : Color.menu.border
  border.width: input.activeFocus ? 2 : 1

  Text {
    anchors.left: parent.left
    anchors.leftMargin: 18
    anchors.verticalCenter: parent.verticalCenter
    text: "⌕"
    color: Color.menu.text
    font.pixelSize: root.style === "spotlight" ? 28 : 22
  }

  TextInput {
    id: input
    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 54; rightMargin: 18 }
    color: Color.menu.text
    selectionColor: Color.accent
    selectedTextColor: Color.background
    font.family: Style.font.family
    font.pixelSize: root.style === "spotlight" ? 28 : Style.font.title
    clip: true
    activeFocusOnTab: true
    Accessible.name: "Search applications"

    Text {
      visible: input.text.length === 0
      anchors.fill: parent
      verticalAlignment: Text.AlignVCenter
      text: "Search"
      color: Color.muted
      font: input.font
    }

    Keys.onPressed: function(event) {
      if (event.key === Qt.Key_Escape) root.dismissRequested()
      else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.launchRequested()
      else if (event.key === Qt.Key_Down) root.moveRequested(1)
      else if (event.key === Qt.Key_Up) root.moveRequested(-1)
      else if (event.key === Qt.Key_Left && input.cursorPosition === 0) root.horizontalRequested(-1)
      else if (event.key === Qt.Key_Right && input.cursorPosition === input.length) root.horizontalRequested(1)
      else return
      event.accepted = true
    }
  }
}
