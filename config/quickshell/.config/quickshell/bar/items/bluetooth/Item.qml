import QtQuick
import qs

// Bluetooth state; hidden without an adapter. Click opens the Bluetooth section of the Control Center.
BarIndicator {
    shown: Sys.adapter !== null
    glyph: !Sys.btOn ? "\u{F00B2}" : Sys.btLinked ? "\u{F00B1}" : "\u{F00AF}"
    word: Sys.btOn ? (Sys.btLinked ? "bt on" : "bt") : "bt off"
    ink: Sys.btOn ? bar.tone : bar.dim
    tip: !Sys.btOn ? "Bluetooth is off" : Sys.btLinked ? "Bluetooth: a device is connected" : "Bluetooth is on"
    panel: "controlcenter"
    active: ControlCenter.open && ControlCenter.expanded === "bt"
    onPressed: ControlCenter.showSection("bt")
}
