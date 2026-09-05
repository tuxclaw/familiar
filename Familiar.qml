import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

QtObject {
  id: root

  property var profile: ({})
  property real motionScale: 1
  readonly property string profileId: String(profile.id || "gnome")
  readonly property bool isLight: {
    var c = Color.background
    var red = linearChannel(c.r)
    var green = linearChannel(c.g)
    var blue = linearChannel(c.b)
    var luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue
    return luminance > 0.5
  }
  readonly property int motionFast: Math.round((profileId === "plasma" ? 80 : profileId === "macos" ? 150 : 100) * motionScale)
  readonly property int motionBase: Math.round((profileId === "plasma" ? 120 : profileId === "macos" ? 260 : 180) * motionScale)
  readonly property int motionSlow: Math.round((profileId === "plasma" ? 200 : profileId === "macos" ? 380 : 260) * motionScale)
  readonly property int motionCurve: profileId === "plasma" ? Easing.OutQuad : profileId === "macos" ? Easing.OutBack : Easing.OutCubic
  readonly property color barHover: isLight ? Util.alpha(Color.foreground, 0.06) : Style.hoverFillFor(Color.bar.text, Color.accent, Color.urgent)
  readonly property color barActive: isLight ? Util.alpha(Color.foreground, 0.12) : Style.selectedFillFor(Color.bar.text, Color.accent, Color.urgent)
  readonly property real blurAlphaAdjustment: isLight ? -0.1 : 0

  readonly property var tokens: ({
    "background": Color.bar.background,
    "foreground": Color.bar.text,
    "fontFamily": Style.font.family,
    "radius": profile.tokens && profile.tokens.radius !== undefined ? profile.tokens.radius : 8,
    "density": profile.tokens && profile.tokens.density !== undefined ? profile.tokens.density : 1.0,
    "motionFast": root.motionFast,
    "motionBase": root.motionBase,
    "motionSlow": root.motionSlow,
    "motionCurve": root.motionCurve,
    "motionScale": root.motionScale,
    "barHover": root.barHover,
    "barActive": root.barActive,
    "isLight": root.isLight,
    "blurAlphaAdjustment": root.blurAlphaAdjustment
  })

  function validate(candidate) {
    return candidate && typeof candidate.id === "string" && candidate.bar && candidate.keymap
  }

  function linearChannel(value) {
    return value <= 0.04045 ? value / 12.92 : Math.pow((value + 0.055) / 1.055, 2.4)
  }

  function px(value) {
    return Math.round(value * tokens.density)
  }

  property Process animationQuery: Process {
    id: animationQuery
    command: ["hyprctl", "-j", "getoption", "animations:enabled"]
    running: true
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var value = JSON.parse(text || "{}")
          var enabled = value.int !== undefined ? Number(value.int) : Number(value.value)
          root.motionScale = enabled === 0 ? 0 : 1
        } catch (error) {
          root.motionScale = 1
        }
      }
    }
  }
}
