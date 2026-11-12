import QtQuick
import qs

// The system tray icons; hidden when no app has one.
BarTray {
    required property var bar
    vertical: bar.vertical; iconSize: bar.words ? 14 : 16; tone: bar.tone
}
