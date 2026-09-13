import QtQuick
import qs.Commons
import "../../lib/DockPins.js" as DockPins

Rectangle {
  id: root
  required property var dockSurface
  readonly property var service: dockSurface.service
  property var labels: ["Weather", "Audio", "Microphone", "Bluetooth", "Network", "Power", "Clock", "Monitor", "Tailscale"]
  width: 230
  height: column.implicitHeight + 16
  radius: 12
  color: Color.menu.background
  border.color: Color.menu.border

  function pick(id) {
    if (!service) return
    var base = service.pendingPinned || service.writingDock || { widgets: service.storedWidgets, widgetSide: service.widgetSide }
    var widgets = base.widgets.slice()
    var index = widgets.indexOf(id)
    if (index < 0) widgets.push(id)
    else widgets.splice(index, 1)
    service.persistWidgets(widgets, base.widgetSide)
  }

  Column {
    id: column
    anchors { top: parent.top; left: parent.left; right: parent.right; margins: 8 }
    spacing: 2
    Text { text: "Dock widgets"; color: Color.menu.text; height: 28 }
    Repeater {
      model: DockPins.widgetIds
      Rectangle {
        required property string modelData
        required property int index
        width: column.width
        height: 28
        radius: 5
        color: pointer.containsMouse ? Color.menu.selectedBackground : "transparent"
        Text {
          anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
          text: (root.service && root.service.storedWidgets.indexOf(parent.modelData) >= 0 ? "✓  " : "+  ") + root.labels[parent.index]
          color: Color.menu.text
        }
        MouseArea { id: pointer; anchors.fill: parent; hoverEnabled: true; onClicked: root.pick(parent.modelData) }
      }
    }
    Row {
      spacing: 6
      Repeater {
        model: ["left", "right"]
        Rectangle {
          required property string modelData
          width: 104
          height: 30
          radius: 5
          color: root.service && root.service.widgetSide === modelData ? Color.menu.selectedBackground : "transparent"
          Text { anchors.centerIn: parent; text: parent.modelData === "left" ? "Left of apps" : "Right of apps"; color: Color.menu.text }
          MouseArea {
            anchors.fill: parent
            onClicked: {
              if (!root.service) return
              var base = root.service.pendingPinned || root.service.writingDock || { widgets: root.service.storedWidgets }
              root.service.persistWidgets(base.widgets, parent.modelData)
            }
          }
        }
      }
    }
  }
}
