import QtQuick

// Settings > Lock & Sleep: what happens while you're away, as a timeline per power source (the same steps
// SettingsSync writes to hypridle.conf): awake, dimmed for the last 30 s, locked with the screens off, asleep.
Item {
    id: pv

    readonly property int lockMin: Config.idle.lockMin
    readonly property var lanes: Sys.hasBattery ? [["Plugged in", Config.idle.sleepOnPowerMin], ["On battery", Config.idle.sleepMin]]
                                                : [["When idle", Config.idle.sleepOnPowerMin]]
    // the scale: a little past the last step, at least 10 minutes
    readonly property real span: Math.max(10, lockMin, ...lanes.map(l => l[1])) * 1.15
    function label(m) { return m < 1 ? Math.round(m * 60) + " s" : (Number.isInteger(m) ? m : m.toFixed(1)) + " min" }

    implicitHeight: col.implicitHeight + Theme.spaceM * 2
    Accessible.role: Accessible.Graphic
    Accessible.name: "Timeline: " + (lockMin > 0 ? "locks after " + label(lockMin) : "never locks")
        + lanes.map(l => ", " + l[0].toLowerCase() + (l[1] > 0 ? " sleeps after " + label(l[1]) : " never sleeps")).join("")

    Column {
        id: col
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 16; rightMargin: 16 }
        spacing: Theme.spaceM

        Repeater {
            model: pv.lanes
            Item {
                id: lane
                required property var modelData
                readonly property int sleepAt: modelData[1]
                readonly property real end: sleepAt > 0 ? sleepAt : pv.span
                // [from, to, kind] in minutes; sleeping first means the lock never comes
                readonly property var parts: {
                    const p = [], lock = pv.lockMin > 0 && pv.lockMin < end ? pv.lockMin : 0
                    const dim = lock > 1 ? lock - 0.5 : lock
                    p.push([0, lock || end, "awake"])
                    if (lock) { if (dim < lock) p.push([dim, lock, "dim"]); p.push([lock, end, "locked"]) }
                    if (sleepAt > 0) p.push([sleepAt, pv.span, "asleep"])
                    return p
                }
                width: col.width
                height: name.implicitHeight + 4 + bar.height + 4 + marks.height

                Text {
                    id: name
                    text: lane.modelData[0]
                    color: Theme.subtext
                    font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
                }
                Item {
                    id: bar
                    y: name.implicitHeight + 4
                    width: parent.width; height: 10
                    Rectangle { anchors.fill: parent; radius: height / 2; color: Theme.fill; border { color: Theme.stroke; width: 1 } }
                    Repeater {
                        model: lane.parts
                        Rectangle {
                            required property var modelData
                            x: bar.width * modelData[0] / pv.span
                            width: Math.max(2, bar.width * (modelData[1] - modelData[0]) / pv.span)
                            height: bar.height
                            radius: height / 2
                            color: ({ awake: Theme.accent, dim: Qt.alpha(Theme.accent, 0.45), locked: Qt.alpha(Theme.text, 0.35), asleep: "transparent" })[modelData[2]]
                            Behavior on x { NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
                            Behavior on width { NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
                        }
                    }
                }
                Item {   // what happens when, under the bar
                    id: marks
                    y: bar.y + bar.height + 4
                    width: parent.width; height: lockMark.implicitHeight
                    Text {
                        id: lockMark
                        visible: pv.lockMin > 0 && pv.lockMin < lane.end
                        x: Math.min(parent.width - width, Math.max(0, parent.width * pv.lockMin / pv.span - width / 2))
                        text: "Locks " + pv.label(pv.lockMin)
                        color: Theme.text
                        font { family: Theme.font; pixelSize: Theme.fontCaption }
                    }
                    Text {
                        visible: lane.sleepAt > 0
                        x: Math.min(parent.width - width, Math.max(lockMark.visible ? lockMark.x + lockMark.width + 8 : 0, parent.width * lane.sleepAt / pv.span - width / 2))
                        text: "Sleeps " + pv.label(lane.sleepAt)
                        color: Theme.text
                        font { family: Theme.font; pixelSize: Theme.fontCaption }
                    }
                    Text {
                        visible: lane.sleepAt === 0
                        anchors.right: parent.right
                        text: "never sleeps"
                        color: Theme.subtext
                        font { family: Theme.font; pixelSize: Theme.fontCaption }
                    }
                }
            }
        }
        Row {   // the key
            spacing: Theme.spaceM
            Repeater {
                model: [["Awake", Theme.accent], ["Dims", Qt.alpha(Theme.accent, 0.45)], ["Locked, screens off", Qt.alpha(Theme.text, 0.35)]]
                Row {
                    required property var modelData
                    spacing: 5
                    Rectangle { width: 10; height: 10; radius: 5; color: modelData[1]; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: modelData[0]; color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption } }
                }
            }
        }
    }
}
