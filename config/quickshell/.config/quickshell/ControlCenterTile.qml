import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Control Center building block (used by ControlCenter.qml and its parts).
// A grouping tile on the panel: a slightly lighter rounded area, no border
Rectangle {
    radius: ControlCenter.style === "borderless" ? Theme.radiusSmall : Theme.radius
    color: ControlCenter.style === "borderless" ? "transparent" : Theme.fill
    border { color: ControlCenter.style === "borderless" ? Theme.stroke : "transparent"; width: ControlCenter.style === "borderless" ? 0 : 0 }
}
