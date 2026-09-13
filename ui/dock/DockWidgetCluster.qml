import QtQuick
import "../../lib/DockPins.js" as DockPins

Row {
  id: root
  required property var bar
  required property var dockSurface
  property var widgets: []
  spacing: 4

  function widgetComponent(id) {
    if (DockPins.widgetIds.indexOf(id) < 0) return null
    var registry = bar ? bar.barWidgetRegistry : null
    var revision = registry ? registry.revision : 0
    var entry = registry && registry.widgets ? registry.widgets[id] : null
    return entry ? entry.component : null
  }

  function widgetUrl(id) {
    if (DockPins.widgetIds.indexOf(id) < 0 || !bar || widgetComponent(id)) return ""
    var registry = bar.hostShell && bar.hostShell.pluginRegistry
      ? bar.hostShell.pluginRegistry : (bar.shell ? bar.shell.pluginRegistry : null)
    var manifest = registry && registry.installedPlugins ? registry.installedPlugins[id] : null
    if (manifest && typeof registry.entryPointUrl === "function") {
      var source = registry.entryPointUrl(manifest, "barWidget")
      if (source) return source
    }
    // Fixed stock paths only; microphone requires a registered widget.
    var fallback = {
      "omarchy.weather": "file:///usr/share/omarchy/shell/plugins/panels/weather/BarWidget.qml",
      "omarchy.clock": "file:///usr/share/omarchy/shell/plugins/panels/clock/BarWidget.qml",
      "omarchy.audio": "file:///usr/share/omarchy/shell/plugins/panels/audio/Panel.qml",
      "omarchy.bluetooth": "file:///usr/share/omarchy/shell/plugins/panels/bluetooth/Panel.qml",
      "omarchy.network": "file:///usr/share/omarchy/shell/plugins/panels/network/Panel.qml",
      "omarchy.power": "file:///usr/share/omarchy/shell/plugins/panels/power/Panel.qml",
      "omarchy.monitor": "file:///usr/share/omarchy/shell/plugins/panels/monitor/Panel.qml",
      "omarchy.tailscale": "file:///usr/share/omarchy/shell/plugins/panels/tailscale/Panel.qml"
    }
    return fallback[id] || ""
  }

  function widgetSettings(id) {
    var layout = bar.barConfig && bar.barConfig.layout
    var roles = ["left", "center", "right"]
    var result = { id: id }
    for (var r = 0; layout && r < roles.length; r++) {
      var entries = layout[roles[r]] || []
      for (var i = 0; i < entries.length; i++) {
        var entry = entries[i]
        if (entry && typeof entry === "object" && entry.id === id)
          return Object.assign({}, entry)
      }
    }
    return result
  }

  Repeater {
    model: root.widgets
    Item {
      id: slot
      required property string modelData
      readonly property var activeItem: widgetLoader.item
      readonly property var component: root.widgetComponent(modelData)
      readonly property string widgetSource: root.widgetUrl(modelData)
      property var registeredItem: null
      function loadWidget() {
        unregister()
        if (component) widgetLoader.sourceComponent = component
        else widgetLoader.source = widgetSource
      }
      onComponentChanged: Qt.callLater(slot.loadWidget)
      onWidgetSourceChanged: Qt.callLater(slot.loadWidget)
      Component.onCompleted: loadWidget()
      width: activeItem && activeItem.visible ? activeItem.implicitWidth : 0
      height: root.bar.barSize

      function unregister() {
        if (registeredItem) root.bar.unregisterHostedItem(registeredItem)
        registeredItem = null
      }

      Loader {
        id: widgetLoader
        anchors.fill: parent

        onLoaded: {
          slot.unregister()
          if (!item) return
          if ("bar" in item) item.bar = root.bar
          if ("settings" in item) item.settings = root.widgetSettings(slot.modelData)
          root.bar.registerHostedItem(item)
          slot.registeredItem = item
        }
      }

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        propagateComposedEvents: true
        pressAndHoldInterval: 450
        property bool held: false
        onPressed: held = false
        onPressAndHold: function(mouse) {
          if (mouse.button !== Qt.LeftButton) return
          held = true
          root.dockSurface.editMode = true
          root.dockSurface.widgetPickerOpen = true
        }
        onClicked: function(mouse) {
          if (held) return
          if (root.dockSurface.editMode) {
            root.dockSurface.widgetPickerOpen = true
            return
          }
          if (!root.bar.pressModuleClickTarget(slot, mouse.button, mouse.x, mouse.y)) mouse.accepted = false
        }
      }
      Component.onDestruction: unregister()
    }
  }
}
