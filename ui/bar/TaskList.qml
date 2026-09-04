import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import qs.Commons

RowLayout {
  id: root
  property var bar: null
  spacing: Style.spacing.xs

  function groupedToplevels() {
    var values = ToplevelManager.toplevels.values || []
    var seen = ({})
    var result = []
    for (var i = 0; i < values.length; i++) {
      var item = values[i]
      var appId = "$" + String(item.appId || item.title || i)
      if (seen[appId]) continue
      seen[appId] = true
      result.push(item)
    }
    return result
  }

  Repeater {
    model: root.groupedToplevels()
    TaskButton {
      required property var modelData
      toplevel: modelData
      bar: root.bar
    }
  }
}
