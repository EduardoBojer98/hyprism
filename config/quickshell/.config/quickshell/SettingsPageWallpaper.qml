import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Wallpaper: image folders, an optional slideshow, and a grid of every image in those folders and every theme's own.
// Click an image to use it now (the lock screen follows). With the slideshow on "Selected
// images", the round badge on each image adds it to or removes it from the rotation.
ColumnLayout {
    id: page
    spacing: 20

    readonly property var c: Config.wallpaper
    readonly property bool picking: c.slideshow && c.source === "selected"
    property string folderError: ""

    function addFolder(path) {
        path = path.trim().replace(/\/+$/, "")
        if (!path) return
        if (c.folders.includes(path)) { folderError = "Already in the list"; return }
        check.path = path
        check.running = true
    }
    function toggleSelected(path) {
        const s = c.selected
        Config.set("wallpaper", "selected", s.includes(path) ? s.filter(p => p !== path) : s.concat([path]))
    }

    // the folder has to exist before it goes in the list
    Process {
        id: check
        property string path
        command: ["sh", "-c", "[ -d \"$1\" ]", "sh", Wallpapers.expand(path)]
        onExited: code => {
            if (code === 0) { Config.set("wallpaper", "folders", page.c.folders.concat([path])); folderInput.text = ""; page.folderError = "" }
            else page.folderError = "No such folder"
        }
    }
    // folder picker (KDE's dialog, works outside Plasma too)
    Process {
        id: browse
        command: ["kdialog", "--getexistingdirectory", Quickshell.env("HOME") + "/Pictures"]
        stdout: StdioCollector { onStreamFinished: if (text.trim()) page.addFolder(text.trim()) }
    }

    SettingGroup {
        title: "Folders"
        Repeater {
            model: page.c.folders
            SettingRow {
                required property string modelData
                label: modelData
                PillButton { text: "Remove"; enabled: page.c.folders.length > 1; onClicked: Config.set("wallpaper", "folders", page.c.folders.filter(f => f !== modelData)) }
            }
        }
        SettingRow {
            label: "Add a folder"
            hint: page.folderError !== "" ? page.folderError : "Type a path (~ works) or browse. Subfolders one level down are included."
            TextField { id: folderInput; width: 200; placeholder: "~/Pictures/Backgrounds"; invalid: page.folderError !== ""; onAccepted: page.addFolder(text) }
            PillButton { text: "Add"; onClicked: page.addFolder(folderInput.text) }
            PillButton { text: "Browse…"; onClicked: browse.running = true }
        }
    }

    SettingGroup {
        title: "Look"
        SettingRow {
            label: "Blur"
            hint: "The desktop only; the lock screen has its own blur in Lock Screen"
            ConfigSlider { section: "wallpaper"; key: "blur"; from: 0; to: 30; step: 1; format: v => v === 0 ? "Off" : String(v) }
        }
    }

    SettingGroup {
        title: "Colours"
        SettingRow {
            label: "Colours from the wallpaper"
            hint: "The accent colours follow your picture. Off: the theme's own colours."
            ConfigToggle { section: "appearance"; key: "wallpaperColours" }
        }
    }

    SettingGroup {
        title: "Slideshow"
        SettingRow {
            label: "Change the wallpaper automatically"
            ConfigToggle { section: "wallpaper"; key: "slideshow" }
        }
        SettingRow {
            visible: page.c.slideshow
            label: "Every"
            ConfigChoice { section: "wallpaper"; key: "interval"; values: [5, 15, 30, 60, 180, 1440]; labels: ["5 min", "15 min", "30 min", "1 h", "3 h", "Day"] }
        }
        SettingRow {
            visible: page.c.slideshow
            label: "Use"
            hint: page.c.source === "selected" ? `${Wallpapers.pool.length} picked: click the round badge on an image to add or remove it` : `All ${Wallpapers.images.length} images in the folders`
            ConfigChoice { section: "wallpaper"; key: "source"; values: ["all", "selected"]; labels: ["All images", "Selected images"] }
        }
        SettingRow {
            visible: page.c.slideshow
            label: "Order"
            ConfigChoice { section: "wallpaper"; key: "order"; values: ["shuffle", "name"]; labels: ["Shuffle", "By name"] }
            PillButton { text: "Next now"; enabled: Wallpapers.pool.length > 1; onClicked: Wallpapers.next() }
        }
    }

    Text {
        Layout.fillWidth: true
        visible: Wallpapers.images.length === 0
        text: "No images found. Add .png, .jpg or .webp files to one of the folders above."
        color: Theme.subtext
        wrapMode: Text.Wrap
        font { family: Theme.font; pixelSize: Theme.fontLabel }
    }

    Flow {
        Layout.fillWidth: true
        spacing: 14
        Repeater {
            model: Wallpapers.images
            Column {
                id: tile
                required property string modelData
                readonly property bool isCurrent: modelData === Wallpapers.current
                readonly property bool inRotation: page.c.selected.includes(modelData)
                spacing: 6
                Rectangle {
                    width: 200; height: 112; radius: Theme.radius
                    color: Theme.fill
                    border { color: tile.isCurrent ? Theme.accent : Theme.stroke; width: tile.isCurrent ? 2 : 1 }
                    clip: true
                    Image {
                        anchors { fill: parent; margins: 2 }
                        source: "file://" + tile.modelData
                        sourceSize: Qt.size(400, 224)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Wallpapers.pick(tile.modelData)
                        Accessible.role: Accessible.Button
                        Accessible.name: "Use " + tile.modelData.split("/").pop() + " as the wallpaper"
                        Accessible.onPressAction: Wallpapers.pick(tile.modelData)
                    }
                    Rectangle {   // slideshow badge
                        visible: page.picking
                        anchors { right: parent.right; top: parent.top; margins: 8 }
                        width: 24; height: 24; radius: 12
                        color: tile.inRotation ? Theme.accent : Qt.rgba(0, 0, 0, 0.45)
                        border { color: Qt.rgba(1, 1, 1, 0.7); width: tile.inRotation ? 0 : 1.5 }
                        Text { anchors.centerIn: parent; visible: tile.inRotation; text: "\u{F012C}"; color: Theme.accentText; font { family: Theme.iconFont; pixelSize: Theme.iconSmall } }
                        MouseArea { anchors { fill: parent; margins: -4 } cursorShape: Qt.PointingHandCursor; onClicked: page.toggleSelected(tile.modelData); Accessible.role: Accessible.CheckBox; Accessible.name: "In the slideshow: " + tile.modelData.split("/").pop(); Accessible.checked: tile.inRotation }
                    }
                }
                Text {
                    width: 200
                    text: tile.modelData.split("/").pop()
                    elide: Text.ElideMiddle
                    color: tile.isCurrent ? Theme.text : Theme.subtext
                    font { family: Theme.font; pixelSize: Theme.fontCaption }
                }
            }
        }
    }

    ResetGroup { sections: ["wallpaper"] }
}
