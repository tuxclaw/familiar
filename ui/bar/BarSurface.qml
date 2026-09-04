import QtQuick
import qs.Commons

Rectangle {
  property string mode: "solid"

  color: mode === "transparent" ? "transparent" : Color.bar.background
}
