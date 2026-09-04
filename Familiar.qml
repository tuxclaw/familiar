import QtQuick
import qs.Commons

QtObject {
  id: root

  property var profile: ({})

  readonly property var tokens: ({
    "background": Color.bar.background,
    "foreground": Color.bar.text,
    "fontFamily": Style.font.family,
    "radius": profile.tokens && profile.tokens.radius !== undefined ? profile.tokens.radius : 8,
    "density": profile.tokens && profile.tokens.density !== undefined ? profile.tokens.density : 1.0
  })

  function validate(candidate) {
    return candidate && typeof candidate.id === "string" && candidate.bar && candidate.keymap
  }

  function px(value) {
    return Math.round(value * tokens.density)
  }
}
