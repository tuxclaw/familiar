import QtQuick
import qs.Commons

Rectangle {
  property string mode: "solid"
  property bool lightTheme: false

  color: mode === "transparent" ? "transparent"
    : mode === "blur" && lightTheme ? Util.alpha(Color.bar.background, 0.9)
    : Color.bar.background
}
