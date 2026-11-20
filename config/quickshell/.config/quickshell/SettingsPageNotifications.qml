import QtQuick
import QtQuick.Layouts

// Notifications: how popups look and where they appear (each style drawn with a sample), a test notification
// through the shell's own server, how long each urgency stays and how it sounds, Do Not Disturb with a daily
// schedule, apps kept quiet, the notification centre's history and the on-screen display.
ColumnLayout {
    id: page
    spacing: 20

    readonly property var c: Config.notifications
    readonly property var soundIds: [""].concat(Object.keys(Notifications.sounds))
    // apps that have sent something (still in the history), plus any muted earlier
    readonly property var apps: [...new Set(Notifications.history.map(n => n.appName || "Other").concat(c.mutedApps))].sort((a, b) => a.localeCompare(b))
    readonly property var styles: ({
        card: { name: "Card", about: "Icon, app and time, title and text" },
        bubble: { name: "Bubble", about: "Round, a lifted tone, no edge" },
        line: { name: "Line", about: "A log line in mono; it types in" },
        block: { name: "Block", about: "An accent bar, a bold title, a hard shadow" },
        tag: { name: "Tag", about: "The app's name on an accent tag" },
        compact: { name: "Compact", about: "One slim row: the title and a line of text" }
    })
    readonly property var styleIds: ["theme", "card", "bubble", "line", "block", "tag", "compact"]
    // what the style samples show: a plain record, like a notification kept from an earlier session
    readonly property var sample: ({ id: "sample", appName: "Mail", appIcon: "internet-mail", image: "", desktopEntry: "",
                                     summary: "Lunch at one?", body: "Booked a table by the window. Bring the slides if you can.",
                                     urgency: 1, actions: [], hints: ({}) })
    readonly property var places: [["top-left", "Top left"], ["top", "Top"], ["top-right", "Top right"],
                                   ["bottom-left", "Bottom left"], ["bottom", "Bottom"], ["bottom-right", "Bottom right"]]
    readonly property string placeNow: c.position === "theme" ? Theme.current.notify.corner : c.position

    // a sound for one urgency: picking one plays it
    component SoundRow: SettingRow {
        id: sr
        property string key
        Dropdown {
            width: 160
            accessibleName: sr.label
            options: page.soundIds.map(id => id ? Notifications.sounds[id] : "None")
            current: page.c[sr.key] ? (Notifications.sounds[page.c[sr.key]] ?? page.c[sr.key]) : "None"
            onPicked: v => {
                const id = page.soundIds[options.indexOf(v)]
                Config.set("notifications", sr.key, id)
                Notifications.lastSound = 0
                Notifications.playSound(id)
            }
        }
    }

    // ---- look and place ---------------------------------------------------------------------------
    SettingGroup {
        title: "Popups"

        Text {
            Layout.fillWidth: true
            Layout.margins: 16
            Layout.bottomMargin: 0
            text: "Style"
            color: Theme.text
            font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.Medium }
        }
        GridLayout {
            id: styleGrid
            Layout.fillWidth: true
            Layout.margins: 12
            Layout.topMargin: 8
            columns: Math.min(4, Math.max(2, Math.floor((width + columnSpacing) / (230 + columnSpacing))))   // samples big enough to read
            columnSpacing: 12
            rowSpacing: 12
            Repeater {
                model: page.styleIds
                Rectangle {
                    id: opt
                    required property string modelData
                    readonly property string kind: modelData === "theme" ? Theme.current.notify.kind : modelData
                    readonly property bool chosen: page.c.style === modelData
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    implicitHeight: optCol.implicitHeight + 20
                    radius: Theme.radius
                    color: chosen ? Theme.accentWash : optArea.containsMouse ? Theme.fillHover : "transparent"
                    border { color: chosen ? Theme.accent : Theme.stroke; width: chosen ? 2 : 1 }
                    activeFocusOnTab: true
                    Keys.onSpacePressed: Config.set("notifications", "style", modelData)
                    Keys.onReturnPressed: Config.set("notifications", "style", modelData)
                    FocusRing {}
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Column {
                        id: optCol
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                        spacing: 8
                        Rectangle {   // a patch of desktop with the sample on it, the size it has on screen, scaled
                            width: parent.width
                            height: sampleCard.height * sampleCard.scale + 20
                            radius: Theme.radiusSmall
                            color: Theme.base
                            clip: true
                            NotificationCard {
                                id: sampleCard
                                x: 10; y: 10
                                width: 344
                                scale: (parent.width - 20) / 344
                                transformOrigin: Item.TopLeft
                                banner: true
                                enabled: false
                                kindOverride: opt.kind
                                notification: page.sample
                            }
                        }
                        Text {
                            width: parent.width
                            text: (opt.chosen ? "\u{F012C}  " : "") + (opt.modelData === "theme" ? "The theme's (" + (page.styles[opt.kind]?.name ?? opt.kind) + ")" : page.styles[opt.modelData].name)
                            elide: Text.ElideRight
                            color: opt.chosen ? Theme.accent : Theme.text
                            font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.DemiBold }
                        }
                        Text {
                            width: parent.width
                            text: opt.modelData === "theme" ? "Changes with the theme" : page.styles[opt.modelData].about
                            wrapMode: Text.Wrap
                            color: Theme.subtext
                            font { family: Theme.font; pixelSize: Theme.fontCaption }
                        }
                    }
                    MouseArea {
                        id: optArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        Accessible.role: Accessible.RadioButton
                        Accessible.name: (opt.modelData === "theme" ? "The theme's style" : page.styles[opt.modelData].name) + " popup style"
                        Accessible.checked: opt.chosen
                        Accessible.onPressAction: Config.set("notifications", "style", opt.modelData)
                        onClicked: Config.set("notifications", "style", opt.modelData)
                    }
                }
            }
        }

        SettingRow {
            label: "Position"
            hint: page.c.position === "theme" ? "The theme's place. Click a spot on the screen to choose your own." : "Click a spot on the screen to move them."
            Column {
                spacing: 8
                Rectangle {   // the screen, its bar, and the six places a popup can go
                    id: screen
                    width: 216; height: 135
                    radius: Theme.radiusSmall
                    color: Theme.base
                    border { color: Theme.stroke; width: 1 }
                    readonly property real inset: 8
                    Rectangle {   // the bar, at its edge
                        readonly property string edge: Theme.barEdge
                        x: edge === "right" ? parent.width - width - 3 : 3
                        y: edge === "bottom" ? parent.height - height - 3 : 3
                        width: edge === "left" || edge === "right" ? 6 : parent.width - 6
                        height: edge === "left" || edge === "right" ? parent.height - 6 : 6
                        radius: 2
                        color: Theme.fillActive
                    }
                    Repeater {
                        model: page.places
                        Rectangle {
                            id: spot
                            required property var modelData
                            readonly property string where: modelData[0]
                            readonly property bool chosen: page.placeNow === where
                            width: 64; height: 24
                            radius: Math.min(Theme.radiusSmall, 5)
                            x: where.endsWith("left") ? screen.inset + (Theme.barEdge === "left" ? 8 : 0)
                             : where.endsWith("right") ? screen.width - width - screen.inset - (Theme.barEdge === "right" ? 8 : 0)
                             : (screen.width - width) / 2
                            y: where.startsWith("top") ? screen.inset + (Theme.barEdge === "top" ? 8 : 0)
                                                       : screen.height - height - screen.inset - (Theme.barEdge === "bottom" ? 8 : 0)
                            color: chosen ? Theme.accent : spotArea.containsMouse ? Theme.fillActive : Theme.fill
                            border { color: chosen ? Theme.accent : Theme.stroke; width: 1 }
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            Column {   // a title and a line of text, as a popup would read
                                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 6 }
                                spacing: 3
                                Rectangle { width: parent.width * 0.6; height: 3; radius: 1.5; color: spot.chosen ? Theme.accentText : Theme.subtext }
                                Rectangle { width: parent.width * 0.85; height: 3; radius: 1.5; color: spot.chosen ? Qt.alpha(Theme.accentText, 0.6) : Theme.muted }
                            }
                            MouseArea {
                                id: spotArea
                                anchors { fill: parent; margins: -4 }
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                Accessible.role: Accessible.RadioButton
                                Accessible.name: "Popups at the " + spot.modelData[1].toLowerCase()
                                Accessible.checked: spot.chosen
                                Accessible.onPressAction: Config.set("notifications", "position", spot.where)
                                onClicked: Config.set("notifications", "position", spot.where)
                            }
                        }
                    }
                }
                PillButton {
                    visible: page.c.position !== "theme"
                    text: "Use the theme's place"
                    onClicked: Config.set("notifications", "position", "theme")
                }
            }
        }

        SettingRow {
            label: "Send a test notification"
            hint: Notifications.dnd ? "Do Not Disturb is on: only a critical one pops up" : "Through the shell's own notification server, like an app's"
            Row {
                spacing: 6
                PillButton { text: "Normal"; primary: true; onClicked: Notifications.test("normal") }
                PillButton { text: "Low"; onClicked: Notifications.test("low") }
                PillButton { text: "Critical"; onClicked: Notifications.test("critical") }
            }
        }
    }

    // ---- behaviour --------------------------------------------------------------------------------
    SettingGroup {
        title: "Behaviour"
        SettingRow {
            label: "On screen at once"
            hint: "More wait their turn; all of them are in the notification centre"
            ConfigSlider { section: "notifications"; key: "maxVisible"; from: 1; to: 8; step: 1; format: v => v === 1 ? "1 popup" : v + " popups" }
        }
        SettingRow {
            label: "Group by app"
            hint: "One popup per app with a count of the rest, and the history grouped by app"
            ConfigToggle { section: "notifications"; key: "groupByApp" }
        }
        SettingRow {
            label: "App icons and pictures"
            hint: "Off: text only, in popups and the notification centre"
            ConfigToggle { section: "notifications"; key: "showIcons" }
        }
    }

    SettingGroup {
        title: "How long popups stay"
        SettingRow {
            label: "Low priority"
            ConfigChoice { section: "notifications"; key: "timeoutLowSec"; values: [2, 4, 6, 10]; labels: ["2 s", "4 s", "6 s", "10 s"] }
        }
        SettingRow {
            label: "Normal"
            hint: "An app can ask for its own time"
            ConfigChoice { section: "notifications"; key: "timeoutSec"; values: [4, 6, 10, 15]; labels: ["4 s", "6 s", "10 s", "15 s"] }
        }
        SettingRow {
            label: "Critical"
            hint: "Low battery, failed backups: these keep this time whatever the app asks"
            ConfigChoice { section: "notifications"; key: "timeoutCriticalSec"; values: [0, 10, 30, 60]; labels: ["Until dismissed", "10 s", "30 s", "60 s"] }
        }
    }

    // ---- quiet ------------------------------------------------------------------------------------
    SettingGroup {
        title: "Do Not Disturb"
        SettingRow {
            label: "Do Not Disturb"
            hint: Notifications.scheduled ? "On by the schedule until " + page.c.dndTo + ". Focus in the Control Center ends it early."
                                          : "No popups or sound except critical ones; everything still lands in the notification centre"
            ConfigToggle { section: "notifications"; key: "dnd" }
        }
        SettingRow {
            label: "Every day on a schedule"
            ConfigToggle { section: "notifications"; key: "dndSchedule" }
        }
        SettingRow {
            visible: page.c.dndSchedule
            label: "From – to"
            hint: "24-hour time, e.g. 22:00 – 07:00"
            RowLayout {
                spacing: Theme.spaceS
                Repeater {
                    model: ["dndFrom", "dndTo"]
                    TextField {
                        required property string modelData
                        Layout.preferredWidth: 72
                        accessibleName: modelData === "dndFrom" ? "Do Not Disturb from" : "Do Not Disturb until"
                        text: page.c[modelData]
                        invalid: !/^([01]?\d|2[0-3]):[0-5]\d$/.test(text)
                        onAccepted: if (!invalid) Config.set("notifications", modelData, text.length === 4 ? "0" + text : text)
                        // typing breaks the text binding: show the saved value again after any change
                        Connections {
                            target: Config
                            function onNotificationsChanged() { parent.text = page.c[parent.modelData] }
                        }
                    }
                }
            }
        }
    }

    SettingGroup {
        title: "Sound"
        SoundRow { label: "Low priority"; key: "soundLow" }
        SoundRow { label: "Normal"; key: "sound"; hint: "Not during Do Not Disturb" }
        SoundRow { label: "Critical"; key: "soundCritical"; hint: "Plays during Do Not Disturb too" }
        SettingRow {
            label: "Volume"
            hint: "Relative to the system volume"
            Row {
                spacing: 8
                ConfigSlider { section: "notifications"; key: "volume"; from: 0; to: 100; step: 5; format: v => v + "%" }
                PillButton { text: "Play"; enabled: page.c.sound !== ""; onClicked: { Notifications.lastSound = 0; Notifications.playSound(page.c.sound) } }
            }
        }
    }

    SettingGroup {
        title: "Apps"
        Text {
            visible: page.apps.length === 0
            Layout.fillWidth: true
            Layout.margins: 16
            text: "Apps show up here once they've sent a notification."
            color: Theme.muted
            font { family: Theme.font; pixelSize: Theme.fontLabel }
        }
        Repeater {
            model: page.apps
            SettingRow {
                id: appRow
                required property string modelData
                readonly property bool muted: page.c.mutedApps.includes(modelData)
                label: modelData
                hint: muted ? "Only in the notification centre: no popup or sound" : "Popups and sound"
                Toggle {
                    checked: !appRow.muted
                    onToggled: on => Config.set("notifications", "mutedApps",
                        on ? page.c.mutedApps.filter(a => a !== modelData) : page.c.mutedApps.concat([modelData]))
                }
            }
        }
    }

    SettingGroup {
        title: "Notification centre"
        SettingRow {
            label: "Keep in history"
            ConfigChoice { section: "notifications"; key: "historyMax"; values: [50, 100, 300]; labels: ["50", "100", "300"] }
        }
        SettingRow {
            label: "Clear history"
            hint: Notifications.history.length + " notifications"
            PillButton { text: "Clear all"; enabled: Notifications.history.length > 0; onClicked: Notifications.clearAll() }
        }
    }

    SettingGroup {
        title: "On-screen display"
        DesktopPreview { show: "osd"; Layout.fillWidth: true; Layout.topMargin: 4 }
        SettingRow {
            label: "Position"
            ConfigChoice { section: "osd"; key: "position"; values: ["bottom", "top", "center"]; labels: ["Bottom", "Top", "Centre"] }
        }
        SettingRow {
            label: "Stays for"
            ConfigSlider { section: "osd"; key: "timeoutMs"; from: 600; to: 5000; step: 100; format: v => (v / 1000).toFixed(1) + " s" }
        }
        SettingRow { label: "Volume"; hint: "A pop-up when the volume or mute changes"; ConfigToggle { section: "osd"; key: "volume" } }
        SettingRow { label: "Brightness"; ConfigToggle { section: "osd"; key: "brightness" } }
        SettingRow { label: "Microphone mute"; ConfigToggle { section: "osd"; key: "micMute" } }
        SettingRow { label: "Keyboard layout"; ConfigToggle { section: "osd"; key: "layout" } }
        SettingRow {
            label: "Caps Lock"
            hint: "Shown when you press Caps Lock, if the keyboard has a Caps Lock light"
            ConfigToggle { section: "osd"; key: "capsLock" }
        }
    }

    ResetGroup { sections: ["notifications", "osd"] }
}
