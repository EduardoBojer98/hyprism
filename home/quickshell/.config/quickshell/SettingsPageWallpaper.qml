import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Wallpaper: pick any image in ~/Pictures/Wallpapers. Applied live (hyprpaper IPC) and saved
// in hyprpaper.conf and the lock screen.
ColumnLayout {
    id: page
    spacing: 16

    property var images: []
    property string current: ""
    readonly property string dir: Quickshell.env("HOME") + "/Pictures/Wallpapers"

    Process {
        running: true
        command: ["sh", "-c", "ls -1 \"$HOME/Pictures/Wallpapers\" | grep -iE '\\.(png|jpe?g|webp)$'; echo '--'; grep -oP 'path\\s*=\\s*\\K.*' \"$HOME/.config/hypr/hyprpaper.conf\" | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const [list, cur] = text.split("--\n")
                page.images = list.trim().split("\n").filter(x => x)
                page.current = (cur ?? "").trim().split("/").pop()
            }
        }
    }

    function pick(file) {
        current = file
        const path = dir + "/" + file
        Quickshell.execDetached(["hyprctl", "hyprpaper", "wallpaper", "," + path])
        Quickshell.execDetached(["sh", "-c",
            "sed -i 's|^\\(\\s*path\\s*=\\s*\\).*Wallpapers/.*|\\1~/Pictures/Wallpapers/" + file.replace(/[|'\\]/g, "") + "|' \"$HOME/.config/hypr/hyprpaper.conf\" \"$HOME/.config/hypr/hyprlock.conf\""])
    }

    Text {
        Layout.fillWidth: true
        text: "Add your own images to ~/Pictures/Wallpapers (that folder lives in the linux-setup repo)."
        color: Theme.muted
        wrapMode: Text.Wrap
        font { family: Theme.font; pixelSize: 12 }
    }

    Flow {
        Layout.fillWidth: true
        spacing: 14
        Repeater {
            model: page.images
            Column {
                required property string modelData
                spacing: 6
                Rectangle {
                    width: 220; height: 124; radius: 12
                    color: Theme.fill
                    border { color: modelData === page.current ? Theme.accent : Theme.stroke; width: modelData === page.current ? 2 : 1 }
                    clip: true
                    Image {
                        anchors { fill: parent; margins: 2 }
                        source: "file://" + page.dir + "/" + modelData
                        sourceSize: Qt.size(440, 248)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: page.pick(modelData) }
                }
                Text {
                    width: 220
                    text: modelData
                    elide: Text.ElideMiddle
                    color: modelData === page.current ? Theme.text : Theme.subtext
                    font { family: Theme.font; pixelSize: 11 }
                }
            }
        }
    }
}
