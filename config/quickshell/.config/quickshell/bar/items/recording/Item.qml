import QtQuick
import Quickshell
import qs

// A pulsing red dot while the screen is being recorded; hidden otherwise. Click stops the recording.
BarItem {
    required property var bar
    actions: bar.cfg
    shown: Sys.recording
    vertical: bar.vertical
    tip: "Recording: click to stop"
    onPressed: Quickshell.execDetached(["record", "stop"])
    Rectangle {
        width: 10; height: 10; radius: 5
        color: Theme.error
        // a slow pulse while recording (still with reduced motion: it is the state)
        SequentialAnimation on opacity { running: Sys.recording && Theme.animate; loops: Animation.Infinite
            NumberAnimation { to: 0.35; duration: 700 } NumberAnimation { to: 1; duration: 700 } }
    }
    Text { visible: !bar.vertical; text: bar.say("rec"); color: Theme.error; font { family: bar.family; pixelSize: Theme.fontLabel; weight: Font.DemiBold } }
}
