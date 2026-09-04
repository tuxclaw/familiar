import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import qs.Commons

RowLayout {
  id: root
  property var bar: null
  spacing: Style.spacing.xs
  visible: !bar || !bar.barConfig || bar.barConfig.trayVisible !== false

  Repeater {
    model: SystemTray.items

    Item {
      id: trayButton
      required property var modelData
      implicitWidth: 24
      implicitHeight: 24

      Image {
        anchors.centerIn: parent
        width: 18
        height: 18
        source: String(trayButton.modelData.icon || "")
        fillMode: Image.PreserveAspectFit
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          if (trayButton.modelData && typeof trayButton.modelData.activate === "function")
            trayButton.modelData.activate()
        }
      }
    }
  }
}
