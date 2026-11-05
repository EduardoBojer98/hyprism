import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Lock Screen: the theme's design (hypr/lockscreens/<theme.lock>.conf) and your background: the desktop wallpaper
// or any picture from the wallpaper folders, with blur and brightness. Saved in Config.lockscreen;
// ThemeSync writes hypr/settings/hyprlock-theme.conf, read the next time the screen locks.
// The clock follows the menu bar's 24-hour setting; fonts and colours come from the theme.
ColumnLayout {
    id: page
    spacing: 20

    readonly property var l: Config.lockscreen
    readonly property string picture: l.wallpaper || Wallpapers.current

    // ---- preview ------------------------------------------------------------------------------
    Rectangle {
        Layout.fillWidth: true
        Layout.maximumWidth: 760
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredHeight: width * 10 / 16
        radius: Theme.radius
        color: "transparent"
        border { color: Theme.stroke; width: 1 }
        clip: true
        LockPreview {
            anchors { fill: parent; margins: 1 }
            source: page.picture
            blur: page.l.blur
            brightness: page.l.brightness
        }
    }
    // No "try it" button: hyprlock quit without a password (grace period, SIGUSR1) counts as a failed
    // login, and three of those lock the account for 10 minutes (pam_faillock, seen 2026-11-01).
    Text {
        Layout.fillWidth: true
        text: "Live preview. The real lock screen follows it the next time the screen locks (Super+L)."
        wrapMode: Text.Wrap
        color: Theme.subtext
        font { family: Theme.font; pixelSize: Theme.fontLabel }
    }

    // ---- layout -------------------------------------------------------------------------------
    SettingGroup {
        title: "Layout"
        SettingRow {
            label: "Clock"
            hint: "The " + Theme.current.name + " theme's is " + Theme.current.lock.clock
            ConfigChoice { section: "lockscreen"; key: "clock"; values: ["theme", "big", "stacked", "terminal", "readout", "small"]
                           labels: ["Default", "Big", "Stacked", "Terminal", "Readout", "Small"] }
        }
        SettingRow {
            label: "Position"
            ConfigChoice { section: "lockscreen"; key: "position"; values: ["theme", "center", "top", "bottom", "left"]
                           labels: ["Default", "Centre", "Top", "Bottom", "Left"] }
        }
        SettingRow {
            label: "Date"
            ConfigToggle { section: "lockscreen"; key: "date" }
        }
        SettingRow {
            label: "Greeting"
            hint: "\"" + LockScreen.greetingText() + "\" above the clock"
            ConfigToggle { section: "lockscreen"; key: "greeting" }
        }
        SettingRow {
            label: "Your picture"
            hint: page.l.avatar !== "" ? page.l.avatar.split("/").pop() : "A round picture above the clock"
            Row {
                spacing: 8
                PillButton { text: page.l.avatar !== "" ? "Change…" : "Choose…"; onClicked: avatarPick.running = true }
                PillButton { visible: page.l.avatar !== ""; text: "Remove"; onClicked: Config.set("lockscreen", "avatar", "") }
            }
            // KDE's file dialog, like the theme pickers (ThemeAdder); only a plain path is saved
            Process {
                id: avatarPick
                command: ["kdialog", "--title", "Your picture", "--getopenfilename", Quickshell.env("HOME") + "/Pictures", "*.png *.jpg *.jpeg *.webp|Pictures"]
                stdout: StdioCollector { onStreamFinished: { const f = text.trim(); if (f && /^[^\n#]+$/.test(f)) Config.set("lockscreen", "avatar", f) } }
            }
        }
        Repeater {
            model: [
                { id: "battery", name: "Battery", hint: "At the bottom edge, on machines with a battery" },
                { id: "layout", name: "Keyboard layout", hint: "In the password field, when you use more than one layout" },
                { id: "media", name: "Now playing", hint: "Title and artist at the bottom edge (playerctl)" }
            ]
            SettingRow {
                required property var modelData
                label: modelData.name
                hint: modelData.hint
                Toggle {
                    checked: page.l.widgets.includes(modelData.id)
                    onToggled: on => Config.set("lockscreen", "widgets", on ? Array.from(page.l.widgets).concat([modelData.id])
                                                                          : page.l.widgets.filter(w => w !== modelData.id))
                }
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
                    model: Wallpapers.images
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
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Config.set("lockscreen", "wallpaper", pic.modelData) }
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
    }

    ResetGroup { sections: ["lockscreen"] }

    Text {
        Layout.fillWidth: true
        text: "The clock follows the menu bar's 24-hour setting; fonts and colours come from the theme."
        color: Theme.subtext
        wrapMode: Text.Wrap
        font { family: Theme.font; pixelSize: Theme.fontCaption }
    }
}
