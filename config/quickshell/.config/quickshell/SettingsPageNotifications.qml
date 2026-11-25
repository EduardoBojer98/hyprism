import QtQuick
import QtQuick.Layouts

// Notifications: a live preview drawn with the real card (it replays its entrance as you change things), the popup
// style from samples of every look, density, width, text size and effect as chips and sliders, where they appear,
// a test through the shell's own server, how long each urgency stays and how it sounds, Do Not Disturb with a daily
// schedule, apps kept quiet, the notification centre, and the on-screen display with samples of its looks.
ColumnLayout {
    id: page
    spacing: Theme.spaceXl

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
        compact: { name: "One line", about: "One slim row: the title and a line of text" },
        pill: { name: "Pill", about: "The slim row in a round capsule" },
        minimal: { name: "Minimal", about: "Title and text only, no icon or edge" }
    })
    readonly property var styleIds: ["theme", "card", "bubble", "line", "block", "tag", "compact", "pill", "minimal"]
    // what the samples show: plain records, like notifications kept from an earlier session
    readonly property var sample: ({ id: "sample", appName: "Mail", appIcon: "internet-mail", image: "", desktopEntry: "",
                                     summary: "Lunch at one?", body: "Booked a table by the window. Bring the slides if you can.",
                                     urgency: 1, actions: [], hints: ({}) })
    readonly property var sampleWithButtons: Object.assign({}, sample, { id: "sample-buttons",
        actions: [{ identifier: "reply", text: "Reply", invoke: () => {} }, { identifier: "later", text: "Later", invoke: () => {} }] })
    readonly property var sampleMusic: ({ id: "sample-music", appName: "Music", appIcon: "multimedia-audio-player", image: "", desktopEntry: "",
                                          summary: "Now playing", body: "Slow Morning — The Quiet Hours", urgency: 1, actions: [], hints: ({}) })
    readonly property var places: [["top-left", "Top left"], ["top", "Top"], ["top-right", "Top right"],
                                   ["bottom-left", "Bottom left"], ["bottom", "Bottom"], ["bottom-right", "Bottom right"]]
    readonly property string placeNow: Notifications.corner

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
    // a picture to choose: a patch of desktop with `content` on it, a name and a line under it (style samples)
    component Pick: Rectangle {
        id: pick
        property bool chosen
        property string name
        property string about
        default property alias content: patch.data
        property real patchHeight: 0
        signal picked()
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignTop
        implicitHeight: pickCol.implicitHeight + Theme.spaceM * 2
        radius: Theme.radius
        color: chosen ? Theme.accentWash : pickArea.containsMouse ? Theme.fillHover : "transparent"
        border { color: chosen ? Theme.accent : Theme.stroke; width: chosen ? 2 : 1 }
        activeFocusOnTab: true
        Keys.onSpacePressed: picked()
        Keys.onReturnPressed: picked()
        FocusRing {}
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        Column {
            id: pickCol
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceM }
            spacing: Theme.spaceS
            Rectangle { id: patch; width: parent.width; height: pick.patchHeight; radius: Theme.radiusSmall; color: Theme.base; clip: true }
            Text {
                width: parent.width
                text: (pick.chosen ? "\u{F012C}  " : "") + pick.name
                elide: Text.ElideRight
                color: pick.chosen ? Theme.accent : Theme.text
                font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.DemiBold }
            }
            Text {
                width: parent.width
                visible: text !== ""
                text: pick.about
                wrapMode: Text.Wrap
                color: Theme.subtext
                font { family: Theme.font; pixelSize: Theme.fontCaption }
            }
        }
        MouseArea {
            id: pickArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            Accessible.role: Accessible.RadioButton
            Accessible.name: pick.name
            Accessible.checked: pick.chosen
            Accessible.onPressAction: pick.picked()
            onClicked: pick.picked()
        }
    }

    // ---- preview: the real card with your settings, at its real size where it fits -----------------------
    SettingGroup {
        title: "Preview"
        Rectangle {
            id: stage
            Layout.fillWidth: true
            Layout.margins: Theme.spaceM
            implicitHeight: stack.height * stack.scale + Theme.spaceL * 2 + (page.c.groupByApp ? Theme.spaceM : 0)   // room for the folded stack
            radius: Theme.radiusSmall
            color: Theme.base
            border { color: Theme.stroke; width: 1 }
            clip: true
            // the entrance, replayed when the look changes: t goes 0 -> 1 the way Notifications.effect brings a popup in
            property real t: 1
            readonly property string fx: Notifications.effect
            readonly property real side: page.placeNow.endsWith("left") ? -1 : 1
            function replay() { if (fx !== "none") { replayAnim.restart() } }
            NumberAnimation { id: replayAnim; target: stage; property: "t"; from: 0; to: 1; duration: Math.max(Theme.enter, Theme.anim)
                              easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve }
            Connections {
                target: Notifications
                function onKindChanged() { stage.replay() }
                function onEffectChanged() { stage.replay() }
                function onDensityChanged() { stage.replay() }
                function onCornerChanged() { stage.replay() }
            }
            Column {
                id: stack
                readonly property real room: stage.width - Theme.spaceL * 2
                scale: Math.min(1, room / Notifications.cardWidth)
                transformOrigin: page.placeNow.endsWith("left") ? Item.TopLeft : page.placeNow.endsWith("right") ? Item.TopRight : Item.Top
                width: Notifications.cardWidth
                y: Theme.spaceL
                x: page.placeNow.endsWith("left") ? Theme.spaceL : page.placeNow.endsWith("right") ? stage.width - width - Theme.spaceL : (stage.width - width) / 2
                spacing: page.c.groupByApp && Notifications.kind !== "line" ? Notifications.gap + Theme.spaceS : Notifications.gap
                Repeater {
                    model: [page.sampleWithButtons, page.sampleMusic]
                    Item {
                        id: slot
                        required property var modelData
                        required property int index
                        width: stack.width
                        height: shot.height
                        NotificationCard {
                            id: shot
                            width: parent.width
                            banner: true
                            enabled: false
                            kindOverride: Notifications.kind
                            notification: slot.modelData
                            stacked: slot.index === 1 && page.c.groupByApp ? 2 : 0   // grouped: the second app's folded stack
                            opacity: stage.fx === "none" ? 1 : stage.t
                            x: stage.fx === "slide" && Theme.moves ? stage.side * (1 - stage.t) * stack.width : 0
                            y: stage.fx === "drop" ? (page.placeNow.startsWith("bottom") ? 1 : -1) * (1 - stage.t) * Theme.travel : 0
                            scale: stage.fx === "scale" && Theme.moves ? 0.85 + 0.15 * stage.t : 1
                        }
                    }
                }
            }
        }
        SettingRow {
            label: "Send a test notification"
            hint: Notifications.dnd ? "Do Not Disturb is on: only a critical one pops up" : "A real one, through the shell's own notification server"
            Row {
                spacing: Theme.spaceXs + 2
                PillButton { text: "Normal"; primary: true; onClicked: Notifications.test("normal") }
                PillButton { text: "Low"; onClicked: Notifications.test("low") }
                PillButton { text: "Critical"; onClicked: Notifications.test("critical") }
                PillButton { text: "Replay"; onClicked: stage.replay() }
            }
        }
    }

    // ---- look -------------------------------------------------------------------------------------------
    SettingGroup {
        title: "Look"
        GridLayout {
            Layout.fillWidth: true
            Layout.margins: Theme.spaceM
            columns: Math.min(4, Math.max(2, Math.floor((width + columnSpacing) / (230 + columnSpacing))))   // samples big enough to read
            columnSpacing: Theme.spaceM
            rowSpacing: Theme.spaceM
            Repeater {
                model: page.styleIds
                Pick {
                    id: opt
                    required property string modelData
                    readonly property string kind: modelData === "theme" ? Theme.current.notify.kind : modelData
                    chosen: page.c.style === modelData
                    name: modelData === "theme" ? "The theme's (" + (page.styles[kind]?.name ?? kind) + ")" : page.styles[modelData].name
                    about: modelData === "theme" ? "Changes with the theme" : page.styles[modelData].about
                    patchHeight: sampleCard.height * sampleCard.scale + Theme.spaceM * 2
                    onPicked: Config.set("notifications", "style", modelData)
                    NotificationCard {   // the sample, the size it has on screen, scaled
                        id: sampleCard
                        x: Theme.spaceM; y: Theme.spaceM
                        width: Notifications.cardWidth
                        scale: (opt.width - Theme.spaceM * 4) / Notifications.cardWidth
                        transformOrigin: Item.TopLeft
                        banner: true
                        enabled: false
                        kindOverride: opt.kind
                        notification: page.sample
                    }
                }
            }
        }
        SettingRow {
            label: "Density"
            hint: ({ compact: "Tight padding, small icons, two lines of text", regular: "More room, three lines of text",
                     roomy: "Big icons and type, four lines of text" })[page.c.density] ?? ""
            ConfigChoice { section: "notifications"; key: "density"; values: ["compact", "regular", "roomy"]; labels: ["Compact", "Regular", "Roomy"] }
        }
        SettingRow {
            label: "Width"
            hint: "Popups and the notification centre"
            ConfigSlider { section: "notifications"; key: "width"; from: 280; to: 560; step: 20; format: v => v + " px" }
        }
        SettingRow {
            label: "Text size"
            hint: "Text and icons, on top of the density"
            ConfigSlider { section: "notifications"; key: "size"; from: 80; to: 150; step: 10; format: v => v + "%" }
        }
        SettingRow {
            label: "Coming and going"
            hint: page.c.effect === "theme" ? "The style's own: " + ({ drop: "a short drop with a fade", slide: "a slide from the side", fade: "a fade" })[Notifications.effect]
                : Theme.moves ? "" : "Animations are reduced (Settings > Appearance): only the fade shows"
            ConfigChoice { section: "notifications"; key: "effect"; values: ["theme", "slide", "fade", "scale", "none"]; labels: ["Style's own", "Slide", "Fade", "Scale", "None"] }
        }
        SettingRow {
            label: "App icons and pictures"
            hint: "Off: text only, in popups and the notification centre"
            ConfigToggle { section: "notifications"; key: "showIcons" }
        }
        SettingRow {
            label: "App buttons"
            hint: "Reply, Mark as read and the like. Off: click the notification to open it"
            ConfigToggle { section: "notifications"; key: "showActions" }
        }
    }

    // ---- place ------------------------------------------------------------------------------------------
    SettingGroup {
        title: "Where and how many"
        SettingRow {
            label: "Position"
            hint: page.c.position === "theme" ? "The theme's place. Click a spot on the screen to choose your own." : "Click a spot on the screen to move them."
            Column {
                spacing: Theme.spaceS
                Rectangle {   // the screen, its bar, and the six places a popup can go
                    id: screen
                    width: 216; height: 135
                    radius: Theme.radiusSmall
                    color: Theme.base
                    border { color: Theme.stroke; width: 1 }
                    readonly property real inset: Theme.spaceS
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
            label: "On screen at once"
            hint: "More wait their turn; all of them are in the notification centre"
            ConfigSlider { section: "notifications"; key: "maxVisible"; from: 1; to: 8; step: 1; format: v => v === 1 ? "1 popup" : v + " popups" }
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
            label: "Group by app"
            hint: "One popup per app with a count of the rest, and the notification centre folded by app"
            ConfigToggle { section: "notifications"; key: "groupByApp" }
        }
        SettingRow {
            label: "Keep in history"
            ConfigChoice { section: "notifications"; key: "historyMax"; values: [50, 100, 300]; labels: ["50", "100", "300"] }
        }
        SettingRow {
            label: "Clear history"
            hint: Notifications.history.length + " notifications"
            PillButton { text: "Clear all"; enabled: Notifications.history.length > 0; onClicked: Notifications.clearAll() }
        }
        SettingRow {
            label: "Keep dismissed ones"
            hint: "Listed under Earlier in the notification centre, so you can find one you dismissed or missed"
            ConfigChoice { section: "notifications"; key: "keepDays"; values: [0, 1, 7, 30]; labels: ["Off", "1 day", "7 days", "30 days"] }
        }
        SettingRow {
            label: "Clear dismissed ones"
            hint: Notifications.earlier.length + " under Earlier"
            PillButton { text: "Clear history"; enabled: Notifications.earlier.length > 0; onClicked: Notifications.clearEarlier() }
        }
    }

    SettingGroup {
        title: "On-screen display"
        DesktopPreview { show: "osd"; Layout.fillWidth: true; Layout.topMargin: 4 }
        GridLayout {   // each look drawn with the real card at your size
            Layout.fillWidth: true
            Layout.margins: Theme.spaceM
            columns: page.width >= 1100 ? 4 : 2   // samples big enough to read
            columnSpacing: Theme.spaceM
            rowSpacing: Theme.spaceM
            Repeater {
                model: ["theme", "bar", "numeral", "ascii"]
                Pick {
                    id: osdPick
                    required property string modelData
                    readonly property string themeLook: Theme.current.osd?.style ?? "bar"
                    readonly property string shown: modelData === "theme" ? themeLook : modelData
                    readonly property var names: ({ bar: "Bar", numeral: "Numeral", ascii: "Meter" })
                    chosen: Config.osd.style === modelData
                    name: modelData === "theme" ? "The theme's (" + names[themeLook] + ")" : names[modelData]
                    about: ({ theme: "Changes with the theme", bar: "A thin level bar and the number", numeral: "A big number over ten blocks",
                              ascii: "A terminal meter in the mono font" })[modelData]
                    patchHeight: osdSample.height * osdSample.scale + Theme.spaceM * 2
                    onPicked: Config.set("osd", "style", modelData)
                    OsdCard {
                        id: osdSample
                        anchors.centerIn: parent
                        width: implicitWidth; height: implicitHeight
                        scale: Math.min(1, (osdPick.width - Theme.spaceM * 4) / implicitWidth)
                        icon: "\u{F057E}"
                        level: 0.6
                        look: osdPick.shown
                        size: Config.osd.size
                    }
                }
            }
        }
        SettingRow {
            label: "Size"
            ConfigChoice { section: "osd"; key: "size"; values: ["compact", "regular", "large"]; labels: ["Compact", "Regular", "Large"] }
        }
        SettingRow {
            label: "Position"
            ConfigChoice { section: "osd"; key: "position"; values: ["bottom", "top", "center"]; labels: ["Bottom", "Top", "Centre"] }
        }
        SettingRow {
            label: "Screen"
            hint: Config.osd.screen === "cursor" ? "The screen with the pointer, where you're working" : "The main screen (Settings > Displays), else the one you're working on"
            ConfigChoice { section: "osd"; key: "screen"; values: ["main", "cursor"]; labels: ["Main display", "Pointer's display"] }
        }
        SettingRow {
            label: "Stays for"
            ConfigSlider { section: "osd"; key: "timeoutMs"; from: 600; to: 5000; step: 100; format: v => (v / 1000).toFixed(1) + " s" }
        }
        SettingRow {
            label: "Show a sample"
            hint: "The real one, on screen, with these settings"
            PillButton { text: "Show"; primary: true; onClicked: SettingsApp.osdDemo() }
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
