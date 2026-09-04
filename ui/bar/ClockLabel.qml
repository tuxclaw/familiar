import QtQuick
import Quickshell
import qs.Commons

Text {
  id: root

  property var bar: null
  property string format: "ddd HH:mm"
  property string fontFamily: Style.font.family
  property date displayDate: clock.date

  text: Qt.formatDateTime(displayDate, format)
  color: Color.bar.text
  font.family: fontFamily
  font.pixelSize: 14
  font.weight: Font.DemiBold

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      if (root.bar && typeof root.bar.summonBarWidget === "function") {
        try {
          if (root.bar.summonBarWidget("omarchy.clock") !== false)
            return
        } catch (error) {
          console.warn("Could not summon clock bar widget:", error)
        }
      }

      if (root.bar && typeof root.bar.hostedBarWidget === "function") {
        var hostedItem = root.bar.hostedBarWidget("omarchy.clock", "togglePanel", false)
        if (hostedItem) {
          hostedItem.togglePanel()
          return
        }
      }

      if (root.bar && root.bar.shell && typeof root.bar.shell.summon === "function")
        root.bar.shell.summon("omarchy.clock")
    }
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
    onDateChanged: root.displayDate = date
  }
}
