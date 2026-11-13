import QtQuick
import qs

// The quick-tools button: opens the utility menu beside it (screenshot an area, text from screen, colour picker,
// clipboard, emoji, settings, power).
BarItem {
    required property var bar
    actions: bar.cfg
    vertical: bar.vertical
    tip: "Quick tools"
    panel: "utilitymenu"
    active: UtilityMenu.open
    onPressed: UtilityMenu.toggle()
    Text { text: "\u{F062E}"; color: Theme.accent; font { family: Theme.iconFont; pixelSize: 18 } }
}
