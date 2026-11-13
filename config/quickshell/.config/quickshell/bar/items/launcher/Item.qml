import QtQuick
import qs

// The apps button: opens the launcher.
BarItem {
    required property var bar
    actions: bar.cfg
    vertical: bar.vertical
    tip: "Apps"
    panel: "launcher"
    active: Launcher.open
    onPressed: Launcher.toggle()
    Text { text: "\u{F003B}"; color: Theme.accent; font { family: Theme.iconFont; pixelSize: 18 } }
}
