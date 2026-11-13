import QtQuick
import qs

// The quick-settings button: opens the Control Center (Wi-Fi, Bluetooth, sound, display, power, tools) beside it.
BarItem {
    required property var bar
    actions: bar.cfg
    vertical: bar.vertical
    tip: "Quick settings"
    active: ControlCenter.open
    onPressed: ControlCenter.toggle()
    Text { text: "\u{F062E}"; color: Theme.accent; font { family: Theme.iconFont; pixelSize: 18 } }
}
