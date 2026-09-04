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
  implicitHeight: row.implicitHeight

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
    for (var r = 0; layout && r < roles.length; r++) {
      var entries = Array.isArray(layout[roles[r]]) ? layout[roles[r]] : []
      for (var i = 0; i < entries.length; i++) {
        if (itemId(entries[i]) === "omarchy.clock") return entries[i]
      }
    }
    return ({ id: "omarchy.clock" })
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

      Loader {
        id: familiarLoader
        required property var modelData
        readonly property string itemName: root.itemId(modelData)
        readonly property var stockClockComponent: {
          var revision = root.bar.barWidgetRegistry.revision
          return itemName === "clock" ? root.registryComponent("omarchy.clock") : null
        }
        readonly property bool hostsStockClock: itemName === "clock" && stockClockComponent !== null
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
          case "spacer": return spacerComponent
          case "omarchyWidgets": return stockWidgetsComponent
          default: return null
          }
        }

        active: componentForItem !== null
        sourceComponent: componentForItem
        implicitWidth: item && item.visible ? item.implicitWidth : 0
        implicitHeight: item && item.visible ? item.implicitHeight : 0
        Layout.fillHeight: true
        Layout.preferredWidth: implicitWidth
        Layout.fillWidth: itemName === "spacer"

        onLoaded: {
          if (!item) return
          if ("bar" in item) item.bar = root.bar
          if ("settings" in item) item.settings = hostsStockClock
            ? root.clockSettings() : root.itemSettings(modelData)
          if ("profileId" in item) item.profileId = String((root.bar.profile && root.bar.profile.id) || "")
          if ("format" in item) item.format = root.bar.clockFormat
          if ("fontFamily" in item) item.fontFamily = root.bar.fontFamily
          if (hostsStockClock) root.bar.registerHostedItem(item)
        }

        Component.onDestruction: if (hostsStockClock && item) root.bar.unregisterHostedItem(item)
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

        Loader {
          id: stockLoader
          required property var modelData
          readonly property string widgetId: typeof modelData === "string"
            ? modelData : String((modelData && modelData.id) || "")
          readonly property var settingsValue: modelData
          readonly property var comp: {
            var revision = root.bar.barWidgetRegistry.revision
            var w = root.bar.barWidgetRegistry.widgets
            return w[widgetId] ? w[widgetId].component : null
          }

          active: comp !== null
          sourceComponent: comp
          implicitWidth: item && item.visible ? item.implicitWidth : 0
          implicitHeight: item && item.visible ? item.implicitHeight : 0
          Layout.fillHeight: true
          Layout.preferredWidth: implicitWidth

          onLoaded: {
            if (!item) return
            if ("bar" in item) item.bar = root.bar
            if ("settings" in item) item.settings = settingsValue
            root.bar.registerHostedItem(item)
          }

          Component.onDestruction: if (item) root.bar.unregisterHostedItem(item)
        }
      }
    }
  }
}
