import QtQuick
import "../../lib/Input.js" as Input
import Quickshell
import Quickshell.Wayland
import qs.Commons

Rectangle {
  id: root
  required property var toplevel
  property string style: ""
  property int motionDuration: 100
  property bool livePreview: false
  property var service: null
  property int cornerRadius: 10
  readonly property var desktop: DesktopEntries.byId(String(toplevel.appId || ""))
    || DesktopEntries.heuristicLookup(String(toplevel.appId || ""))
  readonly property string iconName: desktop ? String(desktop.icon || "") : "application-x-executable"
  signal activated()

  radius: cornerRadius
  color: Color.menu.background
  border.color: root.style === "gnome" && pointer.hovered ? Color.accent : toplevel && toplevel.activated ? Color.accent : Color.menu.border
  border.width: toplevel && toplevel.activated ? 3 : 1
  clip: root.style !== "gnome"
  scale: root.style === "gnome" && pointer.hovered ? 1.025 : 1
  Behavior on scale { enabled: root.style === "gnome"; NumberAnimation { duration: root.motionDuration; easing.type: Easing.OutCubic } }

  Repeater {
    model: root.style === "gnome" ? 3 : 0
    Rectangle {
      required property int index
      z: -1
      x: -2 - index * 3; y: 4 + index
      width: root.width + 4 + index * 6; height: root.height + 4 + index * 3
      radius: root.cornerRadius + index * 3
      color: Color.background
      opacity: 0.16 / (index + 1)
    }
  }

  ScreencopyView {
    id: preview
    anchors.fill: parent
    anchors.margins: root.style === "gnome" ? 8 : root.border.width
    anchors.bottomMargin: root.style === "gnome" ? 44 : root.border.width
    captureSource: root.livePreview ? root.toplevel : null
    live: false
    paintCursor: false
    visible: hasContent
  }

  Timer {
    interval: 67
    repeat: true
    running: root.visible && root.livePreview
    onTriggered: preview.captureFrame()
  }

  Rectangle {
    anchors.fill: parent
    anchors.margins: root.style === "gnome" ? 8 : root.border.width
    anchors.bottomMargin: root.style === "gnome" ? 44 : root.border.width
    visible: !preview.hasContent
    color: Color.background
    Image {
      anchors.centerIn: parent
      width: Math.min(72, parent.width * 0.3)
      height: width
      source: Quickshell.iconPath(root.iconName, "application-x-executable")
      sourceSize.width: width * Screen.devicePixelRatio
      sourceSize.height: height * Screen.devicePixelRatio
      fillMode: Image.PreserveAspectFit
    }
  }

  Rectangle {
    visible: root.style === "gnome" || pointer.hovered
    anchors { left: parent.left; right: root.style === "gnome" ? parent.right : closeButton.left; bottom: parent.bottom; margins: 10; rightMargin: 6 }
    height: root.style === "gnome" ? 28 : titleText.implicitHeight + 12
    radius: 6
    color: Color.menu.background
    opacity: 0.94
    Text {
      id: titleText
      anchors { fill: parent; margins: 6; leftMargin: 9; rightMargin: 9 }
      text: Input.boundedText(String(root.toplevel.title || root.toplevel.appId || "Untitled window"))
      textFormat: Text.PlainText
      color: Color.menu.text
      elide: Text.ElideRight
      verticalAlignment: Text.AlignVCenter
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }
  }

  Rectangle {
    id: closeButton
    visible: pointer.hovered || closeTap.hovered
    anchors { top: parent.top; right: parent.right; margins: 10 }
    width: 30; height: 30; radius: 15
    color: closeTap.hovered ? Color.accent : Color.menu.background
    Text { anchors.centerIn: parent; text: "×"; color: Color.menu.text; font.pixelSize: 20 }
    HoverHandler { id: closeTap }
    TapHandler {
      onTapped: if (root.toplevel && typeof root.toplevel.close === "function") root.toplevel.close()
    }
  }

  HoverHandler { id: pointer }
  TapHandler {
    onTapped: {
      if (root.toplevel && typeof root.toplevel.activate === "function") root.toplevel.activate()
      root.activated()
    }
  }
}
