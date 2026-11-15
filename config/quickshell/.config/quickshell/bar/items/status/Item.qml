import QtQuick
import qs

// Network, Bluetooth, sound and battery in one item; a click opens the flyout of the icon clicked. Scroll: volume.
BarStatus {
    required property var bar
    actions: bar.cfg
    vertical: bar.vertical; mode: bar.voice; tone: bar.tone; family: bar.family
    tip: "Quick settings"
}
