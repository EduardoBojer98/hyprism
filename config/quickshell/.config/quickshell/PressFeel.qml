import QtQuick

// A button's press, the theme's way (Theme.pressStyle): "shadow" (Poster) sets a hard block in the second accent
// under the control, and a press pushes the control into it; "sink" (Pebble) drops it 1 px and springs it back on
// release; "scale" does nothing here (the control's own Theme.pressScale). Put one in a control, then move it:
//   PressFeel { id: feel; pressed: area.pressed }   transform: Translate { x: feel.shift; y: feel.shift + feel.drop }
Rectangle {
    id: feel
    property bool pressed: false
    readonly property bool shadow: Theme.pressStyle === "shadow" && parent.enabled
    readonly property int lift: 3
    // bindings, not readonly: a Behavior animates them
    property real shift: shadow && pressed ? lift : 0
    property real drop: Theme.pressStyle === "sink" && pressed ? 1 : 0
    Behavior on shift { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easing } }
    Behavior on drop { NumberAnimation { duration: Theme.animFast; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve } }

    z: -1   // under the control
    visible: shadow
    width: parent.width; height: parent.height
    radius: parent.radius ?? 0
    x: lift - shift; y: lift - shift   // still on screen while the control moves onto it
    color: Theme.accent2
    Rectangle {   // the panel's surface under the control, so a see-through fill doesn't show the block through it
        x: feel.shift - feel.lift; y: x
        width: parent.width; height: parent.height; radius: parent.radius
        color: Theme.surfaceColor
    }
}
