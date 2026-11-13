import QtQuick
import qs

// The keyboard layout; hidden with a single layout. Click lists the layouts, scroll switches (BarKeyboard).
BarKeyboard {
    required property var bar
    actions: bar.cfg
    vertical: bar.vertical; plain: bar.words; tone: bar.tone; family: bar.family
    tip: "Keyboard layout"
}
