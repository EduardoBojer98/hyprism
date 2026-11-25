import QtQuick
import QtQuick.Layouts

// "Keep these display settings?" after a change made away from Settings > Displays (the switcher, Super+P, a
// preset from the keyboard): without it the countdown ran unseen and the old layout came back after 15 s.
// Enter keeps, Esc or a click outside goes back, and doing nothing goes back too (a mode the screen can't show).
// Settings > Displays shows its own banner, so this stays closed while Settings is open.
Overlay {
    id: confirm
    name: "display-confirm"
    dim: false
    cardWidth: 460
    cardHeight: col.implicitHeight + Theme.spaceL * 2
    open: Displays.counting && !SettingsApp.open
    onDismissed: Displays.revert()

    onKeyPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) Displays.keep()
        else return
        event.accepted = true
    }

    ColumnLayout {
        id: col
        anchors { fill: parent; margins: Theme.spaceL }
        spacing: Theme.spaceM

        Text { text: "Keep these display settings?"; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontHeading; weight: Font.DemiBold } }
        Text {
            Layout.fillWidth: true
            text: `Going back to the previous ones in ${Displays.left} s`
            wrapMode: Text.Wrap
            color: Theme.subtext
            font { family: Theme.font; pixelSize: Theme.fontSize }
        }
        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: Theme.spaceS
            PillButton { text: "Go back"; onClicked: Displays.revert() }
            PillButton { text: "Keep"; primary: true; onClicked: Displays.keep() }
        }
    }
}
