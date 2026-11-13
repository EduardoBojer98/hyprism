import Quickshell
import Quickshell.Widgets
import QtQuick

// Launcher part: a small section heading on the home view.
Text {
    topPadding: Theme.spaceXs
    leftPadding: Theme.spaceXs
    color: Theme.subtext
    font { family: Launcher.rowFont; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
}
