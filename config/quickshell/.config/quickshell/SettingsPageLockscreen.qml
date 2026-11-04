import Quickshell
import QtQuick
import QtQuick.Layouts

// Lock Screen: pick a design (hypr/lockscreens/*.conf) and the background: the desktop wallpaper
// or any picture from the wallpaper folders, with blur and brightness. Saved in Config.lockscreen;
// ThemeSync writes hypr/settings/hyprlock-theme.conf, read the next time the screen locks.
// The clock follows the menu bar's 24-hour setting, the font Appearance > Text.
ColumnLayout {
    id: page
    spacing: 20

    readonly property var l: Config.lockscreen
    readonly property string picture: l.wallpaper || Wallpapers.current
    readonly property var designs: [
        { id: "glass",    name: "Glass",    about: "Clock at the top, password at the bottom" },
        { id: "center",   name: "Centre",   about: "Everything in the middle" },
        { id: "minimal",  name: "Minimal",  about: "A small corner clock, the picture left free" },
        { id: "sidebar",  name: "Sidebar",  about: "A frosted panel down the left side" },
        { id: "stacked",  name: "Stacked",  about: "Big bold hours over minutes" },
        { id: "terminal", name: "Terminal", about: "A shell prompt asking for your password" },
        { id: "neon",     name: "Neon",     about: "A glowing accent clock and a gradient password field" },
    ]

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
            design: page.l.design
            source: page.picture
            blur: page.l.blur
            brightness: page.l.brightness
        }
    }
    // No "try it" button: hyprlock quit without a password (grace period, SIGUSR1) counts as a failed
    // login, and three of those lock the account for 10 minutes (pam_faillock, seen 2026-11-01).
    Text {
        Layout.fillWidth: true
        text: (page.designs.find(d => d.id === page.l.design)?.about ?? "") + ". Applies the next time the screen locks (Super+L)."
        wrapMode: Text.Wrap
        color: Theme.muted
        font { family: Theme.font; pixelSize: Theme.fontLabel }
    }

    // ---- designs ------------------------------------------------------------------------------
    SettingGroup {
        title: "Design"
        GridLayout {
            id: grid
            Layout.fillWidth: true
            Layout.margins: 14
            columns: width > 600 ? 3 : 2
            columnSpacing: 12
            rowSpacing: 12
            Repeater {
                model: page.designs
                ColumnLayout {
                    id: card
                    required property var modelData
                    readonly property bool current: page.l.design === modelData.id
                    Layout.fillWidth: true
                    spacing: 6
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: width * 10 / 16
                        radius: Theme.radiusSmall
                        color: "transparent"
                        border { color: card.current ? Theme.accent : cardArea.containsMouse ? Theme.text : Theme.stroke; width: card.current ? 2 : 1 }
                        clip: true
                        LockPreview {
                            anchors { fill: parent; margins: card.current ? 2 : 1 }
                            design: card.modelData.id
                            source: page.picture
                            blur: page.l.blur
                            brightness: page.l.brightness
                            live: false
                        }
                        MouseArea { id: cardArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Config.set("lockscreen", "design", card.modelData.id) }
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: card.modelData.name
                        color: card.current ? Theme.text : Theme.subtext
                        font { family: Theme.font; pixelSize: Theme.fontLabel; weight: card.current ? Font.DemiBold : Font.Normal }
                    }
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
            ConfigSlider { section: "lockscreen"; key: "blur"; from: 0; to: 6; step: 1; format: v => v === 0 ? "Sharp" : ["", "Light", "Light", "Medium", "Strong", "Strong", "Frosted"][v] }
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
        text: "The clock follows the menu bar's 24-hour setting and the font from Appearance."
        color: Theme.muted
        wrapMode: Text.Wrap
        font { family: Theme.font; pixelSize: Theme.fontCaption }
    }
}
