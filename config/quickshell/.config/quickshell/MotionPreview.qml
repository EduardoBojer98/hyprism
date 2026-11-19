import QtQuick

// A live drawing of one motion look for Settings > Themes > Motion: a window opening the way Hyprland will open it,
// a panel dropping out of the bar on the look's panel tokens (as CursorPopup moves), and a toggle inside it pressed and
// flipped (as Toggle moves). Pointing at the card plays it on a loop: close, open, press. It stands still otherwise
// (and while Animations isn't Full), so a closed or idle Settings costs nothing. Click to pick it.
Item {
    id: card
    required property var spec           // Theme.look(id): enter, exit, curve, travel, scale, press, hypr
    property string label
    property string about
    property bool chosen: false
    signal picked()

    readonly property real s: width / 200                  // drawing scale
    readonly property real k: 0.5                          // travel is drawn at half size: the panel is a tenth of a real one
    // Hyprland's windowsIn / windowsOut per preset (modules/animations.lua): ms (speed x 100), curve, start / end scale,
    // or a slide in from the nearest edge. Springs as the bezier closest to them: "easy" damped, "bouncy" ~10 % over.
    readonly property var windows: ({
        instant: { inMs: 120, outMs: 100, curve: [0.15, 0, 0.1, 1],     from: 0.98, to: 0.98 },
        crisp:   { inMs: 200, outMs: 140, curve: [0.15, 0, 0.1, 1],     from: 0.96, to: 0.96 },
        snappy:  { inMs: 260, outMs: 160, curve: [0.23, 1, 0.32, 1],    from: 1,    to: 0.95, slide: true },
        slam:    { inMs: 240, outMs: 140, curve: [0.16, 1, 0.3, 1],     from: 1.08, to: 0.92 },
        ease:    { inMs: 410, outMs: 160, curve: [0.22, 1, 0.36, 1],    from: 0.92, to: 0.94 },
        spring:  { inMs: 440, outMs: 180, curve: [0.34, 1.56, 0.64, 1], from: 0.86, to: 0.9 },
        minimal: { inMs: 150, outMs: 120, curve: [0.23, 1, 0.32, 1],    from: 1,    to: 1 },
        fade:    { inMs: 600, outMs: 400, curve: [0.23, 1, 0.32, 1],    from: 0.99, to: 0.99 },
    })
    readonly property var win: windows[spec.hypr] ?? windows.ease
    readonly property var curve: spec.curve.concat([1, 1])
    readonly property var easeOut: [0.23, 1, 0.32, 1, 1, 1]
    readonly property int anim: Math.min(220, spec.enter)                       // Theme.anim / animFast for this look
    readonly property int animFast: Math.min(120, Math.max(60, spec.enter / 2))

    // the still picture is the open state; playing steps these
    property bool winOn: true
    property bool panelOn: true
    property bool toggleOn: true
    property bool pressing: false
    readonly property bool playing: area.containsMouse && Theme.moves

    implicitHeight: shot.height + text.implicitHeight + Theme.spaceS

    SequentialAnimation {
        running: card.playing
        loops: Animation.Infinite
        onRunningChanged: if (!running) { card.pressing = false; card.winOn = true; card.panelOn = true; card.toggleOn = true }
        // everything leaves at once (exits are simultaneous), then the window, the panel it carries, and the press
        PropertyAction { target: card; property: "winOn"; value: false }
        PropertyAction { target: card; property: "panelOn"; value: false }
        PauseAnimation { duration: Math.max(card.win.outMs, card.spec.exit) + 220 }
        PropertyAction { target: card; property: "toggleOn"; value: false }
        PropertyAction { target: card; property: "winOn"; value: true }
        PauseAnimation { duration: 180 }
        PropertyAction { target: card; property: "panelOn"; value: true }
        PauseAnimation { duration: card.spec.enter + 160 }
        PropertyAction { target: card; property: "pressing"; value: true }
        PauseAnimation { duration: card.animFast + 40 }
        PropertyAction { target: card; property: "pressing"; value: false }
        PropertyAction { target: card; property: "toggleOn"; value: true }
        PauseAnimation { duration: 1300 }
    }

    Rectangle {
        id: shot
        width: parent.width
        height: Math.round(width * 0.62)
        radius: Theme.radiusSmall
        color: Theme.base
        clip: true

        Rectangle {   // the bar
            id: bar
            width: parent.width
            height: 9 * card.s
            topLeftRadius: shot.radius
            topRightRadius: shot.radius
            color: Theme.glass
        }

        Rectangle {   // a window, opened the way Hyprland opens it
            id: window
            x: 10 * card.s
            y: bar.height + 10 * card.s
            width: 104 * card.s
            height: parent.height - y - 10 * card.s
            radius: Math.min(Theme.radius, 6) * card.s
            color: Theme.surfaceColor
            border { color: Theme.accent; width: 1 }
            property real w: card.winOn ? 1 : 0
            Behavior on w { NumberAnimation { duration: card.winOn ? card.win.inMs : card.win.outMs
                                              easing.type: Easing.BezierSpline; easing.bezierCurve: card.winOn ? card.win.curve.concat([1, 1]) : card.easeOut } }
            opacity: card.winOn ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: card.winOn ? 173 : 146 } }   // fadeIn / fadeOut
            readonly property real sc: (card.winOn ? card.win.from : card.win.to) + (1 - (card.winOn ? card.win.from : card.win.to)) * w
            transform: [
                Scale { origin.x: window.width / 2; origin.y: window.height / 2; xScale: card.win.slide && card.winOn ? 1 : window.sc; yScale: xScale },
                Translate { y: card.win.slide && card.winOn ? (1 - window.w) * (shot.height - window.y) : 0 }
            ]
            Rectangle { x: 6 * card.s; y: 6 * card.s; width: parent.width * 0.4; height: 3 * card.s; radius: height / 2; color: Theme.muted }
            Rectangle { x: 6 * card.s; y: 14 * card.s; width: parent.width * 0.7; height: 3 * card.s; radius: height / 2; color: Theme.fill }
            Rectangle { x: 6 * card.s; y: 21 * card.s; width: parent.width * 0.55; height: 3 * card.s; radius: height / 2; color: Theme.fill }
        }

        Rectangle {   // a panel out of the bar: CursorPopup's travel, start scale and fade on this look's curve
            id: panel
            x: parent.width - width - 8 * card.s
            y: bar.height + 3 * card.s
            width: 72 * card.s
            height: 58 * card.s
            radius: Math.min(Theme.radiusPanel, 8) * card.s
            color: Theme.menu
            border { color: Theme.stroke; width: 1 }
            property real t: card.panelOn ? 1 : 0
            Behavior on t { NumberAnimation { duration: card.panelOn ? card.spec.enter : card.spec.exit
                                              easing.type: card.panelOn ? Easing.BezierSpline : Theme.easing; easing.bezierCurve: card.curve } }
            opacity: Math.min(1, t * 1.6)
            readonly property real sc: card.spec.scale + (1 - card.spec.scale) * t
            transform: [
                Scale { origin.x: panel.width / 2; origin.y: 0; xScale: panel.sc; yScale: panel.sc },
                Translate { y: -(1 - panel.t) * card.spec.travel * card.k }
            ]
            Rectangle { x: 7 * card.s; y: 8 * card.s; width: parent.width * 0.5; height: 3 * card.s; radius: height / 2; color: Theme.muted }
            Rectangle { x: 7 * card.s; y: 16 * card.s; width: parent.width * 0.34; height: 3 * card.s; radius: height / 2; color: Theme.fill }

            Rectangle {   // the toggle: pressed (the look's press scale), then the thumb crosses on its curve
                id: toggle
                x: 7 * card.s
                y: parent.height - height - 9 * card.s
                width: 26 * card.s
                height: 14 * card.s
                radius: Theme.radius === 0 ? 0 : height / 2
                color: card.toggleOn ? Theme.accent : Theme.fillActive
                Behavior on color { ColorAnimation { duration: card.anim } }
                scale: card.pressing ? card.spec.press : 1
                Behavior on scale { NumberAnimation { duration: card.animFast; easing.type: Theme.easing } }
                Rectangle {
                    width: parent.height - 4 * card.s
                    height: width
                    radius: Theme.radius === 0 ? 0 : width / 2
                    y: 2 * card.s
                    x: card.toggleOn ? parent.width - width - 2 * card.s : 2 * card.s
                    color: Theme.selectInverse ? Theme.text : Theme.thumb
                    Behavior on x { NumberAnimation { duration: card.anim; easing.type: Easing.BezierSpline; easing.bezierCurve: card.curve } }
                }
            }
        }

        Rectangle {   // the frame, over everything that moves
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border { color: card.chosen ? Theme.accent : area.containsMouse ? Theme.strokeStrong : Theme.stroke; width: card.chosen ? 2 : 1 }
        }
    }

    Column {
        id: text
        anchors { top: shot.bottom; topMargin: Theme.spaceS; left: parent.left; right: parent.right }
        Text {
            width: parent.width
            text: (card.chosen ? "\u{F012C}  " : "") + card.label
            elide: Text.ElideRight
            color: card.chosen ? Theme.accent : Theme.text
            font { family: Theme.font; pixelSize: Theme.fontSize; weight: Font.DemiBold }
        }
        Text {
            width: parent.width
            text: card.about
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            color: Theme.subtext
            font { family: Theme.font; pixelSize: Theme.fontCaption }
        }
        Text {   // the numbers behind it, for the curious
            width: parent.width
            text: card.spec.enter + " / " + card.spec.exit + " ms · " + card.spec.travel + " px · windows: " + card.spec.hypr
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            color: Theme.subtext
            font { family: Theme.font; pixelSize: Theme.fontCaption; features: { "tnum": 1 } }
        }
    }

    MouseArea {
        id: area
        Accessible.role: Accessible.RadioButton
        Accessible.name: "Motion look " + card.label
        Accessible.description: card.about
        Accessible.checkable: true
        Accessible.checked: card.chosen
        Accessible.onPressAction: card.picked()
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: card.picked()
    }
}
