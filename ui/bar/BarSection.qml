import QtQuick
import QtQuick.Layouts
import qs.Commons

Item {
  id: root

  required property var bar
  required property string role
  property var items: []
  property int alignment: Qt.AlignLeft

  implicitWidth: row.implicitWidth

  function itemId(entry) {
    return typeof entry === "string" ? entry : String((entry && entry.id) || "")
  }

  function itemSettings(entry) {
    return typeof entry === "object" && entry !== null ? entry : ({})
  }

  function registryComponent(widgetId) {
    var registry = bar && bar.barWidgetRegistry
    var widgets = registry && registry.widgets
    return widgets && widgets[widgetId] ? widgets[widgetId].component : null
  }

  function clockSettings() {
    var layout = bar && bar.barConfig && bar.barConfig.layout
    var roles = ["left", "center", "right"]
    var found = ({ id: "omarchy.clock" })
    for (var r = 0; layout && r < roles.length; r++) {
      var entries = Array.isArray(layout[roles[r]]) ? layout[roles[r]] : []
      for (var i = 0; i < entries.length; i++) {
        if (itemId(entries[i]) === "omarchy.clock") {
          found = entries[i]
          break
        }
      }
    }
    var copy = ({ id: "omarchy.clock" })
    if (found && typeof found === "object") {
      for (var key in found) copy[key] = found[key]
    }
    if (bar && bar.clockFormat && bar.clockFormat !== "auto")
      copy.format = bar.clockFormat
    return copy
  }

  function weatherSettings() {
    var layout = bar && bar.barConfig && bar.barConfig.layout
    var roles = ["left", "center", "right"]
    for (var r = 0; layout && r < roles.length; r++) {
      var entries = Array.isArray(layout[roles[r]]) ? layout[roles[r]] : []
      for (var i = 0; i < entries.length; i++) {
        if (itemId(entries[i]) === "omarchy.weather") return entries[i]
      }
    }
    return ({ id: "omarchy.weather" })
  }

  RowLayout {
    id: row
    anchors.fill: parent
    spacing: Style.spacing.sm

    Item {
      Layout.fillWidth: root.alignment !== Qt.AlignLeft
      visible: Layout.fillWidth
    }

    Repeater {
      model: root.items || []

      Item {
        id: familiarSlot
        required property var modelData
        readonly property string itemName: root.itemId(modelData)
        readonly property var stockClockComponent: {
          var revision = root.bar.barWidgetRegistry.revision
          return itemName === "clock" ? root.registryComponent("omarchy.clock") : null
        }
        readonly property bool hostsStockClock: itemName === "clock" && stockClockComponent !== null
        readonly property var stockWeatherComponent: {
          var revision = root.bar.barWidgetRegistry.revision
          return itemName === "weather" ? root.registryComponent("omarchy.weather") : null
        }
        readonly property bool hostsStockWeather: itemName === "weather" && stockWeatherComponent !== null
        readonly property bool hostsStockWidget: hostsStockClock || hostsStockWeather
        readonly property var componentForItem: {
          switch (itemName) {
          case "activities": return activitiesComponent
          case "appMenu": return appMenuComponent
          case "activeApp": return activeAppComponent
          case "tasks": return tasksComponent
          case "tray": return trayComponent
          case "workspaces": return workspacesComponent
          case "notifications": return notificationsComponent
          case "clock": return stockClockComponent
          case "weather": return stockWeatherComponent
          case "spacer": return spacerComponent
          case "omarchyWidgets": return stockWidgetsComponent
          default: return null
          }
        }

        readonly property var activeItem: familiarLoader.item

        function enforceClockFormat() {
          var item = familiarLoader.item
          if (!hostsStockClock || !item || !root.bar) return
          var wanted = root.bar.clockFormat
          if (!wanted || wanted === "auto") return
          if (item.settings && item.settings.format === wanted) return
          item.settings = root.clockSettings()
        }

        width: activeItem && activeItem.visible ? activeItem.implicitWidth : 0
        height: root.bar.barSize
        Layout.fillHeight: true
        Layout.preferredWidth: width
        Layout.fillWidth: itemName === "spacer"

        Loader {
          id: familiarLoader
          active: familiarSlot.componentForItem !== null
          sourceComponent: familiarSlot.componentForItem
          anchors.fill: parent

          onLoaded: {
            if (!item) return
            if ("bar" in item) item.bar = root.bar
            if ("settings" in item) item.settings = familiarSlot.hostsStockClock
              ? root.clockSettings() : familiarSlot.hostsStockWeather
              ? root.weatherSettings() : root.itemSettings(familiarSlot.modelData)
            if ("profileId" in item) item.profileId = String((root.bar.profile && root.bar.profile.id) || "")
            if ("format" in item) item.format = root.bar.clockFormat
            if ("fontFamily" in item) item.fontFamily = root.bar.fontFamily
            if (familiarSlot.hostsStockWidget) root.bar.registerHostedItem(item)
            familiarSlot.enforceClockFormat()
          }
        }

        Connections {
          target: familiarLoader.item
          enabled: familiarSlot.hostsStockClock && familiarLoader.item !== null
          function onSettingsChanged() { familiarSlot.enforceClockFormat() }
        }
        Connections {
          target: root.bar
          enabled: familiarSlot.hostsStockClock
          function onClockFormatChanged() { familiarSlot.enforceClockFormat() }
        }

        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.AllButtons
          propagateComposedEvents: true
          onClicked: function(mouse) {
            // Stock clock right-click walks into 24-hour presets; keep profile format.
            if (familiarSlot.hostsStockClock && mouse.button === Qt.RightButton) return
            if (!root.bar.pressModuleClickTarget(familiarSlot, mouse.button, mouse.x, mouse.y)) mouse.accepted = false
          }
        }

        Component.onDestruction: if (hostsStockWidget && activeItem) root.bar.unregisterHostedItem(activeItem)
      }
    }

    Item {
      Layout.fillWidth: root.alignment !== Qt.AlignRight
      visible: Layout.fillWidth
    }
  }

  Component { id: activitiesComponent; ActivitiesButton {} }
  Component { id: appMenuComponent; AppMenuButton {} }
  Component { id: activeAppComponent; ActiveAppLabel {} }
  Component { id: tasksComponent; TaskList {} }
  Component { id: trayComponent; TrayArea {} }
  Component { id: workspacesComponent; WorkspacePips {} }
  Component { id: notificationsComponent; NotificationsIndicator {} }
  Component { id: spacerComponent; Item { Layout.fillWidth: true } }

  Component {
    id: stockWidgetsComponent

    RowLayout {
      id: stockRow
      spacing: 0
      readonly property var entries: {
        var layout = root.bar.barConfig && root.bar.barConfig.layout
        var sectionEntries = layout ? layout[root.role] : null
        return Array.isArray(sectionEntries) ? sectionEntries : []
      }

      Repeater {
        model: stockRow.entries

        Item {
          id: stockSlot
          required property var modelData
          readonly property string widgetId: typeof modelData === "string"
            ? modelData : String((modelData && modelData.id) || "")
          readonly property var settingsValue: modelData
          readonly property var comp: {
            var revision = root.bar.barWidgetRegistry.revision
            var w = root.bar.barWidgetRegistry.widgets
            return w[widgetId] ? w[widgetId].component : null
          }

          readonly property var activeItem: stockLoader.item

          width: activeItem && activeItem.visible ? activeItem.implicitWidth : 0
          height: root.bar.barSize
          Layout.fillHeight: true
          Layout.preferredWidth: width

          Loader {
            id: stockLoader
            active: stockSlot.comp !== null
            sourceComponent: stockSlot.comp
            anchors.fill: parent

            onLoaded: {
              if (!item) return
              if ("bar" in item) item.bar = root.bar
              if ("settings" in item) item.settings = stockSlot.settingsValue
              root.bar.registerHostedItem(item)
            }
          }

          MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            propagateComposedEvents: true
            onClicked: function(mouse) {
              if (!root.bar.pressModuleClickTarget(stockSlot, mouse.button, mouse.x, mouse.y)) mouse.accepted = false
            }
          }

          Component.onDestruction: if (activeItem) root.bar.unregisterHostedItem(activeItem)
        }
      }
    }
  }
}
