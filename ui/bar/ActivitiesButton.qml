import QtQuick
import qs.Commons

Item {
  id: root
  property var bar: null
  implicitWidth: label.implicitWidth + Style.spacing.lg * 2
  implicitHeight: Math.max(label.implicitHeight, 24)

  function openOverview() {
    if (!root.bar || !root.bar.shell || !root.bar.manifest) return
    var shell = root.bar.shell
    var payload = '{"surface":"overview"}'
    if (typeof shell.summon === "function") {
      shell.summon(root.bar.manifest.id, payload)
      return
    }

    var loader = shell.panelLoaders ? shell.panelLoaders[root.bar.manifest.id] : null
    var overlay = loader ? loader.item : null
    if (!overlay) return
    if (typeof overlay.open === "function") overlay.open(payload)
    else {
      overlay.surface = "overview"
      overlay.opened = true
    }
  }

  Text {
    id: label
    anchors.centerIn: parent
    text: "Activities"
    color: Color.bar.text
    font.family: root.bar ? root.bar.fontFamily : Style.font.family
    font.pixelSize: Style.font.body
    font.weight: Font.DemiBold
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.openOverview()
  }
}
