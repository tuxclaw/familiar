import QtQuick
import "../../lib/DockPins.js" as DockPins
import "../../lib/Input.js" as Input
import Quickshell
import qs.Commons
import qs.Ui

Item {
  id: root
  required property var entry
  required property var dockSurface
  property var appLibrary: null
  property int iconSize: 48
  property real magnifyScale: 1
  property string indicatorStyle: "dot"
  property bool pinned: false
  property bool fallbackActive: false
  property bool showRunningIndicator: true
  property bool contextMenuEnabled: entry.type !== "folder"
  readonly property bool editable: entry.type === "folder" || !!entry.desktopId
  readonly property bool editing: editable && dockSurface.editMode
  property string tooltipText: Input.boundedText(entry.name)
  property string profileId: "gnome"
  property real motionScale: 1

  readonly property string executableIcon: Quickshell.iconPath("application-x-executable", "application-x-executable")
  readonly property string primaryIconSource: iconSource(entry.icon)

  signal reorderDropped(var entry, point position)
  signal activated(var entry)

  function iconSource(iconName) {
    var value = String(iconName || "")
    if (value.length === 0) return executableIcon
    if (value.indexOf("file://") === 0 || value.indexOf("image://") === 0) return value
    if (value.charAt(0) === "/") return Util.fileUrl(value)
    return Quickshell.iconPath(value, "application-x-executable")
  }

  onPrimaryIconSourceChanged: fallbackActive = false
  Component.onDestruction: if (iconMouse.reorderGesture) root.dockSurface.draggingPinned = false

  z: iconMouse.reorderGesture ? 1 : 0
  rotation: editing && motionScale > 0 ? wiggleAngle : 0
  property real wiggleAngle: 0
  SequentialAnimation on wiggleAngle {
    running: root.editing && root.motionScale > 0
    loops: Animation.Infinite
    NumberAnimation { to: 2; duration: 130 }
    NumberAnimation { to: -2; duration: 130 }
  }

  implicitWidth: iconSize + 8
  // Keep the glyph baseline and indicator fixed while the image grows upward.
  implicitHeight: iconSize + 12

  Image {
    id: icon
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    // Reserve the indicator slot even when Applications hides its indicator.
    anchors.bottomMargin: 12
    width: root.iconSize * root.magnifyScale
    height: width
    fillMode: Image.PreserveAspectFit
    // Decode once at maximum magnification, not on every pointer movement.
    sourceSize.width: Math.ceil(root.iconSize * 1.55 * Screen.devicePixelRatio)
    sourceSize.height: sourceSize.width
    source: root.fallbackActive ? root.executableIcon : root.primaryIconSource
    asynchronous: true
    onStatusChanged: if (status === Image.Error && !root.fallbackActive) root.fallbackActive = true
    opacity: iconMouse.reorderGesture ? 0.2 : 1
    transform: Translate { y: launchBounce.running ? launchBounceOffset : 0 }
  }

  Rectangle {
    anchors.fill: parent
    color: "transparent"
    radius: 10
    border.width: 2
    border.color: Color.menu.text
    visible: root.dockSurface.dragPlan !== null && root.dockSurface.dragPlan.kind === "merge"
      && root.dockSurface.dragPlan.target === root.dockSurface.entryKey(root.entry)
  }

  property real launchBounceOffset: 0
  SequentialAnimation {
    id: launchBounce
    loops: 2
    NumberAnimation { target: root; property: "launchBounceOffset"; from: 0; to: -12; duration: Math.round(160 * root.motionScale); easing.type: Easing.OutQuad }
    NumberAnimation { target: root; property: "launchBounceOffset"; from: -12; to: 0; duration: Math.round(160 * root.motionScale); easing.type: Easing.InQuad }
  }

  RunningIndicator {
    visible: root.showRunningIndicator && count > 0
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    style: root.indicatorStyle
    count: Number(root.entry.windowCount || 0)
  }

  MouseArea {
    id: iconMouse
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: true
    property point pressPosition
    property bool reorderGesture: false
    property bool held: false
    property bool moved: false
    property double pressTime: 0
    preventStealing: true
    cursorShape: reorderGesture ? Qt.ClosedHandCursor : Qt.PointingHandCursor
    onPressed: function(mouse) {
      reorderGesture = false
      held = false
      moved = false
      pressTime = Date.now()
      pressPosition = mapToGlobal(mouse.x, mouse.y)
      if (mouse.button === Qt.LeftButton && (root.editable || !root.contextMenuEnabled)) holdTimer.restart()
    }
    onPositionChanged: function(mouse) {
      var point = mapToItem(root.dockSurface, mouse.x, mouse.y)
      var globalPoint = mapToGlobal(mouse.x, mouse.y)
      if (pressed && (pressedButtons & Qt.LeftButton)
          && DockPins.isDrag(globalPoint.x - pressPosition.x, globalPoint.y - pressPosition.y, Qt.styleHints.startDragDistance)) {
        moved = true
        holdTimer.stop()
      }
      if (root.pinned && pressed && (pressedButtons & Qt.LeftButton) && moved) {
        if (!reorderGesture) {
          reorderGesture = true
          root.dockSurface.beginDrag(root.entry)
        }
        root.dockSurface.updateDrag(root.entry, point)
      }
    }
    onReleased: function(mouse) {
      holdTimer.stop()
      if (reorderGesture && mouse.button === Qt.LeftButton) {
        var entry = root.entry
        var position = mapToItem(root.dockSurface, mouse.x, mouse.y)
        // Defer model replacement until this MouseArea finishes its release/click.
        Qt.callLater(function() {
          iconMouse.reorderGesture = false
          root.reorderDropped(entry, position)
        })
      }
    }
    onCanceled: {
      holdTimer.stop()
      reorderGesture = false
      held = false
      root.dockSurface.cancelDrag()
    }
    onClicked: function(mouse) {
      if (reorderGesture) return
      if (held || moved) return
      if (mouse.button !== Qt.LeftButton) return
      if (root.profileId === "macos" && root.motionScale > 0) launchBounce.restart()
      root.activated(root.entry)
    }
  }

  Timer {
    id: holdTimer
    interval: 450
    onTriggered: {
      if (iconMouse.pressed && !iconMouse.moved && !iconMouse.reorderGesture
          && DockPins.isLongPress(Date.now() - iconMouse.pressTime, 0, 0, Qt.styleHints.startDragDistance)) {
        iconMouse.held = true
        root.dockSurface.editMode = true
        if (!root.contextMenuEnabled) root.dockSurface.widgetPickerOpen = true
      }
    }
  }

  Rectangle {
    visible: root.editing
    anchors.top: parent.top
    anchors.right: parent.right
    width: 22; height: 22
    radius: 11
    color: Color.menu.selectedBackground
    z: 5
    Text { anchors.centerIn: parent; text: root.entry.type === "folder" ? "×" : (root.pinned ? "−" : "+"); color: Color.menu.text }
    MouseArea {
      anchors.fill: parent
      onClicked: {
        if (root.entry.type === "folder") root.dockSurface.dissolveFolder(root.entry.id)
        else root.dockSurface.togglePin(root.entry)
      }
    }
  }

  PanelToolTip {
    id: tooltip
    visible: iconMouse.containsMouse && !iconMouse.reorderGesture && text.length > 0
    text: Input.boundedText(root.tooltipText)
    delay: 500
  }
}
