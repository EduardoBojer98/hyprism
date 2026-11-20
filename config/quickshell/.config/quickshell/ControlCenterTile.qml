import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Control Center building block (used by ControlCenter.qml and its parts).
// A grouping tile on the panel, the layout's way: a soft rounded card (cards), a block with a hard shadow (bento),
// or no fill at all (hud: the panel's own brackets frame it). The "borderless" style keeps it flat.
Rectangle {
    readonly property bool flat: ControlCenter.style === "borderless"
    radius: flat ? Theme.radiusSmall : ControlCenter.cards ? Theme.radiusLarge : Theme.radius
    color: flat || ControlCenter.hud ? "transparent" : Theme.fill
    PressFeel { visible: ControlCenter.bento && !parent.flat }   // a hard block under the card; cards don't press
}
