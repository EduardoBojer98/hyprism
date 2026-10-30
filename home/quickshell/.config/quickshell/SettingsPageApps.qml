import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Default Apps: which app opens web links, folders, PDFs and text files (xdg-mime).
ColumnLayout {
    id: page
    spacing: 20

    // role -> mime types it covers and how to recognise candidate apps by desktop category
    readonly property var roles: [
        { name: "Web browser",  mimes: ["x-scheme-handler/http", "x-scheme-handler/https", "text/html"], category: "WebBrowser" },
        { name: "Files",        mimes: ["inode/directory"], category: "FileManager" },
        { name: "PDF documents", mimes: ["application/pdf"], ids: ["org.kde.okular", "org.gnome.Papers", "firefox", "google-chrome"] },
        { name: "Text files",   mimes: ["text/plain"], category: "TextEditor", ids: ["com.microsoft.VSCode", "org.kde.kate"] },
        { name: "Images",       mimes: ["image/png", "image/jpeg", "image/webp"], category: "Viewer" },
    ]
    property var current: ({})   // mime -> desktop id

    Process {
        running: true
        command: ["sh", "-c", "for m in x-scheme-handler/http inode/directory application/pdf text/plain image/png; do echo \"$m $(xdg-mime query default $m)\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const c = {}
                for (const line of text.trim().split("\n")) { const [m, d] = line.split(" "); c[m] = (d ?? "").replace(/\.desktop$/, "") }
                page.current = c
            }
        }
    }

    function candidates(role) {
        return DesktopEntries.applications.values.filter(e => !e.noDisplay &&
            ((role.category && e.categories.includes(role.category)) || (role.ids ?? []).includes(e.id)))
    }

    SettingGroup {
        Repeater {
            model: page.roles
            SettingRow {
                required property var modelData
                readonly property var apps: page.candidates(modelData)
                label: modelData.name
                Dropdown {
                    width: 240
                    options: apps.map(e => e.name)
                    current: DesktopEntries.byId(page.current[modelData.mimes[0]] ?? "")?.name ?? (page.current[modelData.mimes[0]] || "Not set")
                    onPicked: v => {
                        const app = apps.find(e => e.name === v)
                        if (!app) return
                        Quickshell.execDetached(["xdg-mime", "default", app.id + ".desktop", ...modelData.mimes])
                        const c = Object.assign({}, page.current); c[modelData.mimes[0]] = app.id; page.current = c
                    }
                }
            }
        }
    }

    Text {
        Layout.fillWidth: true
        text: "Saved in ~/.config/mimeapps.list, which KDE Plasma also uses."
        color: Theme.muted
        font { family: Theme.font; pixelSize: 12 }
    }
}
