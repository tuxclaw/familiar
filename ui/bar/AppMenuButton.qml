import QtQuick
import qs.Commons
import qs.Ui

WidgetButton {
  id: root
  property string profileId: ""
  text: root.profileId === "macos" ? "●" : "Applications"
  fontFamily: bar ? bar.fontFamily : Style.font.family
  fontSize: Style.font.body
  foreground: Color.bar.text
  onPressed: function() {
    if (!root.bar || !root.bar.shell || typeof root.bar.shell.summon !== "function") return
    if (root.profileId === "macos") root.bar.shell.summon("omarchy.menu", "{}")
    else if (root.bar.manifest) root.bar.shell.summon(root.bar.manifest.id, '{"surface":"launcher"}')
  }
}
