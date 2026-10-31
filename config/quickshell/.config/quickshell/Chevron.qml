import QtQuick

// Dropdown indicator: points down when closed, turns up (in the accent) when open
Text {
    property bool open: false
    property int size: 16
    text: "\u{F0140}"
    color: open ? Theme.accent : Theme.subtext
    rotation: open ? 180 : 0
    font { family: Theme.iconFont; pixelSize: size }
    Behavior on rotation { NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
}
