import QtQuick
import qs

// The bell: opens the notification centre, with a dot for unread ones (BarBell).
BarBell {
    required property var bar
    actions: bar.cfg
    vertical: bar.vertical; tone: bar.tone
    tip: "Notifications"
}
