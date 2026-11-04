import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Startup Apps: what really starts at login, straight from ~/.config/autostart (the XDG autostart
// folder that apps' own "start at login" options and KDE Plasma use too). ~/.local/bin/startup-apps
// reads and edits it and starts the entries from Hyprland's autostart.
ColumnLayout {
    id: page
    spacing: 20

    property var entries: []
    property string query: ""
    readonly property var matches: {
        const q = query.trim().toLowerCase()
        if (!q) return []
        const have = entries.map(e => e.id)
        return DesktopEntries.applications.values
            .filter(e => !e.noDisplay && !have.includes(e.id) && (e.name.toLowerCase().includes(q) || e.id.toLowerCase().includes(q)))
            .sort((a, b) => a.name.localeCompare(b.name))
            .slice(0, 8)
    }

    function refresh() { lister.running = true }
    // actions wait their turn: a running Process can't take a second command
    property var queue: []
    function next() {
        if (editor.running) return
        if (!queue.length) { refresh(); return }
        editor.command = ["startup-apps"].concat(queue[0])
        queue = queue.slice(1)
        editor.running = true
    }
    function run(args) { queue = queue.concat([args]); next() }
    function add(id) { run(["add", id]); query = ""; search.text = "" }

    Process {
        id: lister
        running: true
        command: ["startup-apps", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { page.entries = JSON.parse(text) } catch (e) { page.entries = [] }
                // the old list in settings.json was copied into the folder by startup-apps
                if (Config.startup.apps.length) Config.set("startup", "apps", [])
            }
        }
    }
    Process { id: editor; onExited: page.next() }
    // Running state changes on its own; look again every few seconds while the page is open
    Timer { interval: 4000; repeat: true; running: page.visible; onTriggered: page.refresh() }

    SettingGroup {
        title: "Open at login"
        Text {
            visible: page.entries.length === 0
            Layout.fillWidth: true
            Layout.margins: 16
            text: "Nothing starts at login yet. Search below to add an app."
            color: Theme.muted
            font { family: Theme.font; pixelSize: Theme.fontLabel }
        }
        Repeater {
            model: page.entries
            SettingRow {
                required property var modelData
                label: modelData.name || modelData.id
                hint: !modelData.here ? "Only starts in " + modelData.only.replace(/;$/, "").replace(/;/g, ", ")
                    : modelData.running === true ? "Running now"
                    : modelData.running === false ? (modelData.on ? "Not running" : "Off")
                    : (modelData.on ? "On" : "Off")
                Toggle {
                    anchors.verticalCenter: parent.verticalCenter
                    checked: modelData.on
                    onToggled: c => page.run([c ? "on" : "off", modelData.file])
                }
                PillButton { text: "Remove"; onClicked: page.run(["remove", modelData.file]) }
            }
        }
    }

    SettingGroup {
        title: "Add an app"
        SettingRow {
            label: "Search"
            hint: "Type part of the app's name"
            TextField {
                id: search
                width: 220
                placeholder: "e.g. Discord"
                onTextChanged: page.query = text
                onAccepted: if (page.matches.length) page.add(page.matches[0].id)
            }
        }
        Repeater {
            model: page.matches
            AppRow {
                required property var modelData
                entry: modelData
                action: "Add"
                onTriggered: page.add(modelData.id)
            }
        }
    }

    Text {
        Layout.fillWidth: true
        text: "This is the same list KDE Plasma uses, so changes here apply there too. Turning an app off keeps it in the list. "
            + "The desktop's own parts (bar, wallpaper, lock, clipboard) always start and aren't listed."
        color: Theme.muted
        wrapMode: Text.Wrap
        font { family: Theme.font; pixelSize: Theme.fontCaption }
    }
}
