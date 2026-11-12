import QtQuick
import qs

// Network, Bluetooth, sound and battery in one item that opens the Control Center. Scroll changes the volume.
BarStatus {
    required property var bar
    actions: bar.cfg
    vertical: bar.vertical; mode: bar.voice; tone: bar.tone; family: bar.family
    tip: "Quick settings"
}
