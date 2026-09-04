import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import qs.Commons

Text {
  id: root
  property var bar: null
  readonly property var activeToplevel: ToplevelManager.activeToplevel

  text: activeToplevel ? String(activeToplevel.title || activeToplevel.appId || "") : ""
  visible: text.length > 0
  color: Color.bar.text
  font.family: bar ? bar.fontFamily : Style.font.family
  font.pixelSize: Style.font.body
  font.weight: Font.DemiBold
  elide: Text.ElideRight
  Layout.maximumWidth: 280
  verticalAlignment: Text.AlignVCenter
}
