import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Lock Screen: a live preview (with the password field's states), its position and clock picked from pictures
// of the real layout (LockScreen.layout), what it shows as chips, and your background: the desktop wallpaper
// or any picture from the wallpaper folders, with blur and brightness. Saved in Config.lockscreen;
// ThemeSync writes hypr/settings/hyprlock-theme.conf, read the next time the screen locks.
// The 24-hour setting is shared with the menu bar's clock; fonts and colours come from the theme.
ColumnLayout {
    id: page
    spacing: 20

    readonly property var l: Config.lockscreen
    readonly property string picture: l.wallpaper || Wallpapers.still(Wallpapers.current)
    readonly property var def: Theme.current.lock
    readonly property var positions: [
        { id: "theme",  name: "Theme's own", align: def.align },
        { id: "split",  name: "Split",       align: "split",  hint: "The clock up top, your name and the password field low down" },
        { id: "center", name: "Centre",      align: "center", hint: "Everything in one column in the middle" },
        { id: "top",    name: "Top",         align: "top",    hint: "One column from the top, the picture free below" },
        { id: "bottom", name: "Bottom",      align: "bottom", hint: "One column along the bottom, the picture free above" },
        { id: "left",   name: "Left",        align: "left",   hint: "One column on the left, the picture free on the right" },
    ]
    readonly property var clocks: [
        { id: "theme",    name: "Theme's own", clock: def.clock },
        { id: "big",      name: "Big",         clock: "big" },
        { id: "small",    name: "Small",       clock: "small" },
        { id: "stacked",  name: "Stacked",     clock: "stacked" },
        { id: "terminal", name: "Terminal",    clock: "terminal" },
        { id: "readout",  name: "Readout",     clock: "readout" },
    ]
    // what the lock screen shows: on/off settings and the widgets list, as one row of chips
    readonly property var parts: [
        { key: "date",     name: "Date",            icon: "\u{F00ED}" },
        { key: "greeting", name: "Greeting",        icon: "\u{F1821}" },
        { key: "user",     name: "Your name",       icon: "\u{F0004}" },
        { widget: "battery", name: "Battery",       icon: "\u{F0079}" },
        { widget: "layout",  name: "Keyboard layout", icon: "\u{F030C}" },
        { widget: "media",   name: "Now playing",   icon: "\u{F075A}" },
    ]
    function isOn(p) { return p.key ? page.l[p.key] : page.l.widgets.includes(p.widget) }
    function flip(p) {
        if (p.key) Config.set("lockscreen", p.key, !page.l[p.key])
        else Config.set("lockscreen", "widgets", isOn(p) ? page.l.widgets.filter(w => w !== p.widget) : Array.from(page.l.widgets).concat([p.widget]))
    }
    property string field: "idle"   // the big preview's password field state (preview only)

    // one choice drawn as the lock screen it gives
    component Thumb: Item {
        id: th
        property string name
        property bool chosen
        property string clock: LockScreen.clock
        property string align: LockScreen.align
        signal picked()
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignTop
        implicitHeight: pic.height + Theme.spaceXl + 2
        activeFocusOnTab: true
        Keys.onReturnPressed: picked()
        Keys.onSpacePressed: picked()
        Accessible.role: Accessible.RadioButton
        Accessible.name: name
        Accessible.checked: chosen
        Accessible.onPressAction: picked()
        Rectangle {
            id: pic
            width: parent.width
            height: Math.round(width * 10 / 16)
            radius: Theme.radiusSmall + 2
            color: "transparent"
            border { color: th.chosen ? Theme.accent : area.containsMouse ? Theme.strokeStrong : Theme.stroke; width: th.chosen ? 2 : 1 }
            clip: true
            LockPreview {
                anchors { fill: parent; margins: th.chosen ? 2 : 1 }
                z: -1
                source: page.picture
                blur: page.l.blur
                brightness: page.l.brightness
                live: false
                clock: th.clock
                align: th.align
            }
        }
        MouseArea { id: area; anchors.fill: pic; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: th.picked() }
        Text {
            anchors { left: parent.left; top: pic.bottom; topMargin: Theme.spaceS - 2 }
            text: th.name
            color: th.chosen ? Theme.accent : Theme.text
            font { family: Theme.font; pixelSize: Theme.fontLabel; weight: th.chosen ? Font.DemiBold : Font.Normal }
        }
        FocusRing {}
    }

    // ---- preview ------------------------------------------------------------------------------
    Rectangle {
        Layout.fillWidth: true
        Layout.maximumWidth: 860
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredHeight: width * 10 / 16
        radius: Theme.radiusLarge
        color: "transparent"
        border { color: Theme.stroke; width: 1 }
        clip: true
        LockPreview {
            anchors { fill: parent; margins: 1 }
            z: -1
            source: page.picture
            blur: page.l.blur
            brightness: page.l.brightness
            field: page.field
        }
    }
    // No "try it" button: hyprlock quit without a password (grace period, SIGUSR1) counts as a failed
    // login, and three of those lock the account for 10 minutes (pam_faillock, seen 2026-11-01).
    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spaceM
        Text {
            Layout.fillWidth: true
            text: "Live preview. The real lock screen follows it the next time the screen locks (Super+L)."
            wrapMode: Text.Wrap
            color: Theme.subtext
            font { family: Theme.font; pixelSize: Theme.fontLabel }
        }
        Choice {   // how the password field looks as you use it
            accessibleName: "Show the password field"
            options: ["Waiting", "Typing", "Wrong", "Caps Lock"]
            index: ["idle", "typing", "wrong", "caps"].indexOf(page.field)
            onPicked: i => page.field = ["idle", "typing", "wrong", "caps"][i]
        }
    }

    // ---- layout -------------------------------------------------------------------------------
    SettingGroup {
        title: "Layout"
        SettingRow {
            label: "Position"
            hint: Config.lockscreen.position === "theme" ? "The " + Theme.current.name + " theme's: " + (page.positions.find(p => p.id === page.def.align)?.name ?? page.def.align)
                : page.positions.find(p => p.id === Config.lockscreen.position)?.hint ?? ""
        }
        GridLayout {
            Layout.fillWidth: true
            Layout.margins: Theme.spaceM
            Layout.topMargin: 0
            columns: page.width >= 720 ? 3 : 2
            columnSpacing: Theme.spaceM
            rowSpacing: Theme.spaceM
            Repeater {
                model: page.positions
                Thumb {
                    required property var modelData
                    name: modelData.name
                    align: modelData.align
                    chosen: Config.lockscreen.position === modelData.id
                    onPicked: Config.set("lockscreen", "position", modelData.id)
                }
            }
        }
        SettingRow {
            label: "Clock"
            hint: "The " + Theme.current.name + " theme's is " + page.def.clock
        }
        GridLayout {
            Layout.fillWidth: true
            Layout.margins: Theme.spaceM
            Layout.topMargin: 0
            columns: page.width >= 720 ? 3 : 2
            columnSpacing: Theme.spaceM
            rowSpacing: Theme.spaceM
            Repeater {
                model: page.clocks
                Thumb {
                    required property var modelData
                    name: modelData.name
                    clock: modelData.clock
                    chosen: Config.lockscreen.clock === modelData.id
                    onPicked: Config.set("lockscreen", "clock", modelData.id)
                }
            }
        }
    }

    // ---- what it shows ------------------------------------------------------------------------
    SettingGroup {
        title: "On the lock screen"
        SettingRow {
            label: "Shown"
            hint: "Click to turn one on or off. Caps Lock always warns under the password field"
        }
        Flow {
            Layout.fillWidth: true
            Layout.margins: Theme.spaceM
            Layout.topMargin: 0
            spacing: Theme.spaceS - 2
            Repeater {
                model: page.parts
                Rectangle {
                    id: chip
                    required property var modelData
                    readonly property bool on: page.isOn(modelData)
                    width: chipRow.implicitWidth + Theme.spaceL + 2
                    height: Math.max(Theme.hit, chipRow.implicitHeight + Theme.spaceM)
                    radius: Theme.radius === 0 ? 0 : height / 2
                    color: chipArea.containsMouse ? Theme.fillHover : on ? Theme.fill : "transparent"
                    border { color: on ? Theme.accent : chipArea.containsMouse ? Theme.strokeStrong : Theme.stroke; width: 1 }
                    activeFocusOnTab: true
                    Keys.onReturnPressed: page.flip(modelData)
                    Keys.onSpacePressed: page.flip(modelData)
                    Accessible.role: Accessible.CheckBox
                    Accessible.name: modelData.name
                    Accessible.checked: on
                    Accessible.onPressAction: page.flip(modelData)
                    Row {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: Theme.spaceS - 2
                        Text { anchors.verticalCenter: parent.verticalCenter; text: chip.on ? chip.modelData.icon : "\u{F0415}"
                               color: chip.on ? Theme.accent : Theme.muted; font { family: Theme.iconFont; pixelSize: Theme.glyphS } }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: chip.modelData.name; color: chip.on ? Theme.text : Theme.subtext
                               font { family: Theme.font; pixelSize: Theme.fontLabel } }
                    }
                    MouseArea { id: chipArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.flip(chip.modelData) }
                    FocusRing {}
                }
            }
        }
        SettingRow {
            label: "Your picture"
            hint: page.l.avatar !== "" ? page.l.avatar.split("/").pop() : page.l.user ? "None: your initial on a disc" : "A round picture over the password field"
            Row {
                spacing: Theme.spaceS
                PillButton { text: page.l.avatar !== "" ? "Change…" : "Choose…"; onClicked: avatarPick.running = true }
                PillButton { visible: page.l.avatar !== ""; text: "Remove"; onClicked: Config.set("lockscreen", "avatar", "") }
            }
            // GTK file dialog (zenity), like the theme pickers (ThemeAdder); only a plain path is saved
            Process {
                id: avatarPick
                command: ["zenity", "--file-selection", "--title=Your picture", "--filename=" + Quickshell.env("HOME") + "/Pictures/", "--file-filter=Pictures | *.png *.jpg *.jpeg *.webp"]
                stdout: StdioCollector { onStreamFinished: { const f = text.trim(); if (f && /^[^\n#]+$/.test(f)) Config.set("lockscreen", "avatar", f) } }
            }
        }
    }

    // ---- background ---------------------------------------------------------------------------
    SettingGroup {
        title: "Background"
        SettingRow {
            label: "Picture"
            hint: page.l.wallpaper ? page.l.wallpaper.split("/").pop() : "Changes along with the desktop wallpaper"
            Choice {
                options: ["Desktop wallpaper", "Choose a picture"]
                index: page.l.wallpaper || chooser.open ? 1 : 0
                onPicked: i => { chooser.open = i === 1; if (i === 0) Config.set("lockscreen", "wallpaper", "") }
            }
        }
        Item {
            id: chooser
            property bool open: false
            visible: open || page.l.wallpaper !== ""
            Layout.fillWidth: true
            implicitHeight: pics.implicitHeight + 28
            Text {
                visible: Wallpapers.images.length === 0
                anchors { left: parent.left; right: parent.right; margins: 16; verticalCenter: parent.verticalCenter }
                text: "No pictures yet. Add a folder in Appearance > Wallpaper."
                color: Theme.muted
                font { family: Theme.font; pixelSize: Theme.fontLabel }
            }
            Flow {
                id: pics
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                spacing: 8
                Repeater {
                    model: Wallpapers.images.filter(p => !Wallpapers.isVideo(p))   // hyprlock shows pictures only
                    Rectangle {
                        id: pic
                        required property string modelData
                        readonly property bool current: page.l.wallpaper === modelData
                        width: 120; height: 75
                        radius: Theme.radiusSmall
                        color: Theme.fill
                        border { color: current ? Theme.accent : "transparent"; width: 2 }
                        Image {
                            anchors { fill: parent; margins: 2 }
                            source: "file://" + pic.modelData
                            sourceSize.width: 240
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Config.set("lockscreen", "wallpaper", pic.modelData); Accessible.role: Accessible.Button; Accessible.name: "Lock screen wallpaper"; Accessible.onPressAction: Config.set("lockscreen", "wallpaper", pic.modelData) }
                    }
                }
            }
        }
        SettingRow {
            label: "Blur"
            ConfigSlider { section: "lockscreen"; key: "blur"; from: 0; to: 6; step: 1; format: v => v === 0 ? "Off" : ["", "Light", "Light", "Medium", "Strong", "Strong", "Frosted"][v] }
        }
        SettingRow {
            label: "Brightness"
            hint: "Darker keeps the clock easy to read on bright pictures"
            ConfigSlider { section: "lockscreen"; key: "brightness"; from: 0.3; to: 1; step: 0.02; format: v => Math.round(v * 100) + "%" }
        }
        SettingRow {
            label: "Colours from its picture"
            hint: !Config.lockscreen.wallpaperColours ? "Off: the desktop's accent colours"
                : WallpaperColours.lockAccent ? "The clock and password field take their accents from the picture behind them"
                : "Nothing colourful in this picture: the desktop's accents stay"
            ConfigToggle { section: "lockscreen"; key: "wallpaperColours" }
        }
        SettingRow {   // the same setting as the bar clock's, here too so it is reachable with no clock on the bar
            label: "24-hour time"
            hint: (Config.bar.clock24 ? "14:40" : "2:40 PM") + ". Bar clocks follow it unless set otherwise in their own settings"
            ConfigToggle { section: "bar"; key: "clock24" }
        }
    }

    ResetGroup { sections: ["lockscreen"] }

    Text {
        Layout.fillWidth: true
        text: "Fonts and colours come from the theme (accents from the picture with Colours from its picture on)."
        color: Theme.subtext
        wrapMode: Text.Wrap
        font { family: Theme.font; pixelSize: Theme.fontCaption }
    }
}
