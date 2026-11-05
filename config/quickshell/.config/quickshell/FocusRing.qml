import QtQuick

// The keyboard focus mark for a control: an accent ring just outside it, shown only while it has focus
// (Tab moves between controls). Put one inside any focusable control: FocusRing {}
Rectangle {
    anchors { fill: parent; margins: -3 }
    visible: parent.activeFocus
    radius: (parent.radius ?? 0) > 0 ? parent.radius + 3 : 0
    color: "transparent"
    border { color: Theme.accent; width: 2 }
}
