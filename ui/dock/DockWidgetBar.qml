import QtQuick
import Quickshell
import qs.Commons

Item {
  id: root
  property var hostShell: null
  readonly property var shell: shellFacade
  // Stock inline preferences apply for this host session; never write bar.layout.
  QtObject {
    id: shellFacade
    function summon(id, payload) {
      return root.hostShell && typeof root.hostShell.summon === "function"
        ? root.hostShell.summon(id, payload) : false
    }
    function updateEntryInline(id, settings) {
      var items = root.moduleWidgets(id)
      for (var i = 0; i < items.length; i++) items[i].settings = Object.assign({}, settings)
    }
  }
  property var pluginRegistry: null
  property var barConfig: ({})
  property var barWidgetRegistry: null
  property string position: "bottom"
  property bool vertical: false
  property int barSize: 48
  property string fontFamily: Style.font.family
  property color foreground: Color.bar.text
  property color barForeground: Color.bar.text
  property color urgent: Color.urgent
  property bool foregroundAnimationEnabled: true
  property real iconSlot: Style.bar.iconSlot
  property bool centerHoverRevealSuppressed: false

  function setCenterHoverRevealSuppressed(suppressed) {
    centerHoverRevealSuppressed = suppressed
  }

  function moduleWidgets(id) {
    return hostedStockItems.filter(function(item) { return item && item.moduleName === id })
  }

  function targetBelongsToWindow(target, window) {
    return !!target && !!window && target.QsWindow && target.QsWindow.window === window
  }
  property var activePopout: null
  property var clickTargets: []
  property var hostedStockItems: []
  function registerHostedItem(item) {
    if (!item || hostedStockItems.indexOf(item) !== -1) return
    var next = hostedStockItems.slice()
    next.push(item)
    hostedStockItems = next
  }

  function unregisterHostedItem(item) {
    if (item && typeof item.close === "function") item.close()
    releasePopout(item)
    hostedStockItems = hostedStockItems.filter(function(candidate) { return candidate !== item })
  }

  function registerClickTarget(target) {
    if (!target || clickTargets.indexOf(target) !== -1) return
    var next = clickTargets.slice()
    next.push(target)
    clickTargets = next
  }

  function unregisterClickTarget(target) {
    clickTargets = clickTargets.filter(function(item) { return item !== target })
  }

  function moduleTargetClickable(target) {
    return target
      && target.visible !== false
      && target.opacity !== 0
      && target.interactive !== false
      && target.pressable !== false
      && target.concealed !== true
      && typeof target.triggerPress === "function"
  }

  function moduleClickTargetAt(slot, localX, localY) {
    for (var i = clickTargets.length - 1; i >= 0; i--) {
      var target = clickTargets[i]
      if (!moduleTargetClickable(target)) continue

      var targetPoint = { x: localX, y: localY }
      try {
        targetPoint = slot.mapToItem(target, localX, localY)
      } catch (e) {
        continue
      }

      if (targetPoint.x >= 0 && targetPoint.x <= target.width &&
          targetPoint.y >= 0 && targetPoint.y <= target.height) {
        return target
      }
    }

    if (moduleTargetClickable(slot.activeItem)) return slot.activeItem
    return null
  }

  function pressModuleClickTarget(slot, button, localX, localY) {
    var target = moduleClickTargetAt(slot, localX, localY)
    if (!target) return false

    target.triggerPress(button)
    return true
  }

  function run(command) {
    if (!command) return
    Util.execDetached(command)
  }

  function hostedBarWidget(pluginId, methodName, openedOnly) {
    var id = String(pluginId || "")
    for (var i = 0; i < hostedStockItems.length; i++) {
      var item = hostedStockItems[i]
      if (!item || String(item.moduleName || "") !== id) continue
      if (openedOnly && item.opened !== true) continue
      if (!methodName || typeof item[methodName] === "function") return item
    }
    return null
  }

  function summonBarWidget(pluginId) {
    var item = hostedBarWidget(pluginId, "open", false)
    if (!item) return false
    item.open()
    return true
  }

  function hideBarWidget(pluginId) {
    var item = hostedBarWidget(pluginId, "close", true)
      || hostedBarWidget(pluginId, "close", false)
    if (!item) return false
    item.close()
    return true
  }

  function isBarWidgetOpen(pluginId) {
    return hostedBarWidget(pluginId, "", true) !== null
  }

  function switchPanelFrom(owner, direction) {
    var current = hostedStockItems.indexOf(owner)
    if (current < 0 || hostedStockItems.length < 2) return false
    var step = direction < 0 ? -1 : 1
    for (var offset = 1; offset < hostedStockItems.length; offset++) {
      var candidate = hostedStockItems[(current + step * offset + hostedStockItems.length) % hostedStockItems.length]
      if (!candidate || candidate === owner) continue
      if (typeof candidate.open === "function") {
        candidate.open()
        return true
      }
      if (typeof candidate.toggle === "function") {
        candidate.toggle()
        return true
      }
    }
    return false
  }

  function requestPopout(owner) {
    if (activePopout === owner) return
    if (activePopout) {
      if ("closeForPopoutSwitch" in activePopout) activePopout.closeForPopoutSwitch()
      else if ("close" in activePopout) activePopout.close()
    }
    activePopout = owner
  }

  function releasePopout(owner) {
    if (activePopout === owner) activePopout = null
  }
  function showTooltip(owner, text) {}
  function hideTooltip(owner) {}

}
