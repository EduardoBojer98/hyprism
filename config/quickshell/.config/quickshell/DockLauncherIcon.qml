import QtQuick

// The glyph inside the dock's launcher button, in one of several designs (Config.dock.launcherIcon).
// `lit` (hovered or the launcher open) plays the design's animation; reduced motion shows the lit state
// without movement. Used by DockLauncher.qml and the picker in Settings > Dock.
Item {
    id: icon
    property string style: "grid"
    property real size: 44
    property bool lit: false
    property color ink: Theme.text
    readonly property bool moves: Theme.moves
    readonly property real u: size / 44   // drawn at 44 px, scaled
    // the designs, in picker order: id, name
    readonly property var styles: [["grid", "Grid"], ["orbit", "Orbit"], ["bloom", "Bloom"], ["search", "Lens"], ["stack", "Stack"], ["pulse", "Pulse"]]
    width: size; height: size

    // grid: 2 x 2 squares; lit turns a quarter and one square becomes an accent dot
    Grid {
        id: dots
        visible: icon.style === "grid"
        readonly property real cell: icon.size * 0.2
        anchors.centerIn: parent
        columns: 2
        spacing: icon.size * 0.09
        rotation: icon.lit && icon.moves ? 45 : 0
        Behavior on rotation { NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
        Repeater {
            model: 4
            Rectangle {
                required property int index
                readonly property bool dot: index === 1 && icon.lit
                width: dots.cell; height: dots.cell
                radius: dot ? dots.cell / 2 : dots.cell * 0.3
                color: index === 1 ? Theme.accent : icon.ink
                opacity: index === 1 ? 1 : 0.88
                Behavior on radius { NumberAnimation { duration: Theme.anim } }
            }
        }
    }

    // orbit: a planet on a thin ring with an accent moon; lit sets the moon circling and the planet swelling
    Item {
        visible: icon.style === "orbit"
        anchors.fill: parent
        Rectangle {
            anchors.centerIn: parent
            width: 24 * icon.u; height: width; radius: width / 2
            color: "transparent"
            border { color: Qt.alpha(icon.ink, icon.lit ? 0.55 : 0.35); width: Math.max(1, 1.5 * icon.u) }
            Behavior on border.color { ColorAnimation { duration: Theme.anim } }
        }
        Rectangle {
            anchors.centerIn: parent
            width: (icon.lit ? 11 : 9) * icon.u; height: width; radius: width / 2
            color: icon.ink
            Behavior on width { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutBack } }
        }
        Item {
            id: moonArm
            anchors.fill: parent
            rotation: -45
            Rectangle {
                x: parent.width / 2 - width / 2; y: parent.height / 2 - 12 * icon.u - height / 2
                width: 7 * icon.u; height: width; radius: width / 2
                color: Theme.accent
            }
            RotationAnimation on rotation {
                running: icon.lit && icon.moves && icon.style === "orbit"
                from: moonArm.rotation; to: moonArm.rotation + 360
                duration: Theme.pulse * 2; loops: Animation.Infinite
            }
        }
        Connections {   // back to rest when the pointer leaves
            target: icon
            function onLitChanged() { if (!icon.lit) settle.start() }
        }
        NumberAnimation { id: settle; target: moonArm; property: "rotation"; to: -45; duration: Theme.anim; easing.type: Theme.easing }
    }

    // bloom: 3 x 3 dots; lit spreads them into a flower, the corners fade and the heart turns accent
    Item {
        visible: icon.style === "bloom"
        anchors.fill: parent
        Repeater {
            model: 9
            Rectangle {
                required property int index
                readonly property int col: index % 3 - 1
                readonly property int row: Math.floor(index / 3) - 1
                readonly property bool corner: col !== 0 && row !== 0
                readonly property bool heart: col === 0 && row === 0
                property real gap: (icon.lit && icon.moves ? 11 : 8.5) * icon.u
                width: (heart && icon.lit ? 8 : corner && icon.lit ? 3.5 : 6) * icon.u; height: width; radius: width / 2
                x: icon.width / 2 + col * gap - width / 2
                y: icon.height / 2 + row * gap - height / 2
                color: heart ? Theme.accent : icon.ink
                opacity: corner && icon.lit ? 0.45 : 0.9
                Behavior on gap { NumberAnimation { duration: Theme.anim + (Math.abs(col) + Math.abs(row)) * 40; easing.type: Easing.OutBack } }
                Behavior on width { NumberAnimation { duration: Theme.anim } }
                Behavior on opacity { NumberAnimation { duration: Theme.anim } }
            }
        }
    }

    // search (Lens): a magnifying glass; lit tilts it and fills the lens with accent and a passing glint
    Item {
        visible: icon.style === "search"
        anchors.fill: parent
        rotation: icon.lit && icon.moves ? -14 : 0
        scale: icon.lit && icon.moves ? 1.06 : 1
        Behavior on rotation { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutBack } }
        Behavior on scale { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutBack } }
        Rectangle {   // handle
            x: icon.width / 2 + 3 * icon.u; y: icon.height / 2 + 3 * icon.u
            width: 4.5 * icon.u; height: 12 * icon.u; radius: width / 2
            rotation: -45; transformOrigin: Item.Top
            color: icon.ink
        }
        Rectangle {   // lens
            id: lens
            x: icon.width / 2 - 13 * icon.u; y: icon.height / 2 - 13 * icon.u
            width: 20 * icon.u; height: width; radius: width / 2
            color: icon.lit ? Qt.alpha(Theme.accent, 0.85) : "transparent"
            border { color: icon.lit ? Theme.accent : icon.ink; width: 3 * icon.u }
            clip: true
            Behavior on color { ColorAnimation { duration: Theme.anim } }
            Rectangle {   // glint; hidden at rest (lens clip is square, it would show in a corner)
                visible: icon.lit
                width: 4 * icon.u; height: lens.height * 0.7; radius: width / 2   // short, so it stays inside the round lens
                rotation: 35
                y: lens.height * 0.15
                x: icon.lit && icon.moves ? lens.width : -width * 2
                color: Qt.rgba(1, 1, 1, 0.7)
                Behavior on x { enabled: icon.lit; NumberAnimation { duration: Theme.pulse; easing.type: Easing.InOutQuad } }
            }
        }
    }

    // stack: three cards, the top one accent; lit fans them out like a hand
    Item {
        visible: icon.style === "stack"
        anchors.fill: parent
        Repeater {
            model: 3
            Rectangle {
                required property int index   // 0: back, 2: front
                readonly property real fan: icon.lit && icon.moves ? (index - 1) * 16 : 0
                x: icon.width / 2 - width / 2 + (icon.lit && icon.moves ? 0 : (index - 1) * 2.5 * icon.u)
                y: icon.height / 2 - height / 2 + (icon.lit && icon.moves ? 0 : (1 - index) * 3 * icon.u)
                width: 15 * icon.u; height: 21 * icon.u; radius: 3.5 * icon.u
                transformOrigin: Item.Bottom
                rotation: fan
                color: index === 2 ? Theme.accent : icon.ink
                opacity: index === 2 ? 1 : 0.35 + index * 0.25
                border { color: Qt.alpha(Theme.surfaceColor, 0.5); width: 1 }
                Behavior on rotation { NumberAnimation { duration: Theme.anim + index * 50; easing.type: Easing.OutBack } }
                Behavior on x { NumberAnimation { duration: Theme.anim } }
                Behavior on y { NumberAnimation { duration: Theme.anim } }
            }
        }
    }

    // pulse: an accent core in a ring; lit sends ripples out from it
    Item {
        visible: icon.style === "pulse"
        anchors.fill: parent
        Repeater {
            model: 2
            Rectangle {
                id: ripple
                required property int index
                anchors.centerIn: parent
                width: 12 * icon.u; height: width; radius: width / 2
                color: "transparent"
                border { color: Theme.accent; width: Math.max(1, 2 * icon.u) }
                opacity: 0
                SequentialAnimation {
                    running: icon.lit && icon.moves && icon.style === "pulse"
                    loops: Animation.Infinite
                    onRunningChanged: if (!running) { ripple.opacity = 0; ripple.width = 12 * icon.u }
                    PauseAnimation { duration: ripple.index * Theme.pulse }
                    ParallelAnimation {
                        NumberAnimation { target: ripple; property: "width"; from: 12 * icon.u; to: 34 * icon.u; duration: Theme.pulse * 2; easing.type: Theme.easing }
                        NumberAnimation { target: ripple; property: "opacity"; from: 0.9; to: 0; duration: Theme.pulse * 2; easing.type: Theme.easing }
                    }
                    PauseAnimation { duration: (1 - ripple.index) * Theme.pulse }
                }
            }
        }
        Rectangle {
            anchors.centerIn: parent
            width: 24 * icon.u; height: width; radius: width / 2
            color: "transparent"
            border { color: Qt.alpha(icon.ink, icon.lit ? 0.2 : 0.45); width: Math.max(1, 1.5 * icon.u) }
            Behavior on border.color { ColorAnimation { duration: Theme.anim } }
        }
        Rectangle {
            anchors.centerIn: parent
            width: (icon.lit ? 14 : 11) * icon.u; height: width; radius: width / 2
            color: Theme.accent
            Behavior on width { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutBack } }
        }
    }
}
