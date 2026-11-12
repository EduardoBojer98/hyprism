import QtQuick
import qs

// Today's date; opens the calendar.
BarItem {
    required property var bar
    actions: bar.cfg
    vertical: bar.vertical
    tip: "Today: " + Qt.formatDateTime(Sys.now, "dddd d MMMM yyyy")
    active: Calendar.open === true
    opens: "calendar"
    onPressed: Calendar.toggle()
    Item {
        implicitWidth: bar.vertical ? label.implicitHeight : label.implicitWidth
        implicitHeight: bar.vertical ? label.implicitWidth : label.implicitHeight
        Text {
            id: label
            anchors.centerIn: parent
            rotation: bar.vertical ? 90 : 0
            text: bar.say(Qt.formatDateTime(Sys.now, bar.vertical ? "dddd d MMMM" : "ddd d MMM"))
            color: bar.tone
            font { family: bar.family; pixelSize: Theme.fontLabel; weight: Font.DemiBold }
        }
    }
}
