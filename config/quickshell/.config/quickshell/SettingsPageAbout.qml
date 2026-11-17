import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// About: this machine, the setup that built it, and restore points for your settings (settings-snapshot).
ColumnLayout {
    id: page
    spacing: 20

    property var info: ({})

    Process {
        running: true
        command: ["sh", "-c",
            "echo \"host=$(cat /etc/hostname)\"; echo \"model=$(cat /sys/class/dmi/id/product_name)\"; "
            + "echo \"os=$(. /etc/os-release; echo $PRETTY_NAME)\"; echo \"kernel=$(uname -r)\"; "
            + "echo \"cpu=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //')\"; "
            + "echo \"ram=$(free -h | awk '/Mem:/{print $2}')\"; "
            + "echo \"disk=$(df -h / | awk 'NR==2{print $3\" of \"$2\" used\"}')\"; "
            + "echo \"nvidia=$(cat /sys/class/firmware-attributes/asus-armoury/attributes/dgpu_disable/current_value 2>/dev/null)\"; "
            + "echo \"hypr=$(hyprctl version -j | grep -oP '\\\"tag\\\":\\s*\\\"\\K[^\\\"]+')\"; "
            + "echo \"qs=$(qs --version 2>/dev/null | head -1)\"; "
            + "echo \"setup=$(git -C \"$(dirname \"$(readlink -f \"$HOME/.config/quickshell/shell.qml\")\")\" describe --tags --always 2>/dev/null)\"; "
            + "echo \"repo=$(git -C \"$(dirname \"$(readlink -f \"$HOME/.config/quickshell/shell.qml\")\")\" rev-parse --show-toplevel 2>/dev/null)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const o = {}
                for (const l of text.trim().split("\n")) { const i = l.indexOf("="); o[l.slice(0, i)] = l.slice(i + 1) }
                page.info = o
            }
        }
    }

    SettingGroup {
        title: "This computer"
        SettingRow { label: "Name"; Value { text: page.info.host ?? "" } }
        SettingRow { label: "Model"; Value { text: page.info.model ?? "" } }
        SettingRow { label: "Processor"; Value { text: page.info.cpu ?? "" } }
        SettingRow { label: "Memory"; Value { text: page.info.ram ?? "" } }
        SettingRow { label: "Storage"; Value { text: page.info.disk ?? "" } }
        SettingRow { visible: Machine.asus && Machine.nvidia; label: "NVIDIA GPU"; hint: "Switch it in ROG Control Center"; Value { text: page.info.nvidia === "1" ? "Off (saves battery)" : "On" } }
    }

    SettingGroup {
        title: "Software"
        SettingRow { label: "System"; Value { text: page.info.os ?? "" } }
        SettingRow { label: "Kernel"; Value { text: page.info.kernel ?? "" } }
        SettingRow { label: "Hyprland"; Value { text: page.info.hypr ?? "" } }
        SettingRow { label: "Quickshell"; Value { text: page.info.qs ?? "" } }
        SettingRow {
            label: "Hyprism"
            hint: "github.com/EduardoBojer98/hyprism"
            Value { text: page.info.setup ?? "" }
            PillButton { text: "Open folder"; onClicked: Quickshell.execDetached(["xdg-open", page.info.repo ?? ""]) }   // wherever the repo was cloned
        }
    }

    Component.onCompleted: Updates.refresh(false)
    // what Updates found, in words: the first line is the row's label, the rest its hint
    readonly property var updateText: {
        const u = Updates, notes = []
        if (u.dirty) notes.push("The repo has local edits: Update won't pull until you commit or stash them")
        if (u.ahead > 0) notes.push(u.ahead + " local commit(s) aren't on the channel: Update can't pull")
        if (u.error !== "") return ["Hyprism updates", [u.error].concat(notes).join(". ")]
        if (u.checked === 0) return ["Looking for Hyprism updates…", notes.join(". ")]
        if (u.count === 0) return ["Hyprism is up to date", ["Checked at " + Qt.formatTime(new Date(u.checked), "HH:mm")].concat(notes).join(". ")]
        const more = u.count > 3 ? " · and " + (u.count - 3) + " more" : ""
        return [u.count + (u.count === 1 ? " new change" : " new changes") + " for Hyprism", [u.changes.slice(0, 3).join(" · ") + more].concat(notes).join(". ")]
    }

    // Switching and updating run in a terminal so you see what happens (and git or sudo can ask questions)
    SettingGroup {
        title: "Update"
        SettingRow {
            label: "Channel"
            hint: "Stable gets tested releases. Dev gets the newest work first and can break; you can switch back any time"
            Choice {
                accessibleName: "Update channel"
                enabled: !!page.info.repo
                options: ["Stable", "Dev"]
                index: Updates.channel === "dev" ? 1 : 0
                extra: Updates.channel === "" && Updates.branch !== "" ? Updates.branch : ""   // another branch: shown, not a choice
                onPicked: i => { const c = ["stable", "dev"][i]; if (c && c !== Updates.channel) page.inTerminal("./install.sh channel " + c) }
            }
        }
        SettingRow {
            label: page.updateText[0]
            hint: page.updateText[1]
            Value { visible: Updates.count > 0; text: Updates.count + " new"; color: Theme.accent; font.weight: Font.DemiBold }
            PillButton { enabled: !Updates.checking; text: Updates.checking ? "Checking…" : "Check now"; onClicked: Updates.refresh(true) }
        }
        SettingRow {
            label: "Update everything"
            hint: (Updates.system > 0 ? Updates.summary + " waiting. " : "")
                + "Pulls the latest setup, updates the system and Flatpak apps (snapshot first on Arch), relinks the configs and runs the doctor"
            PillButton { enabled: !!page.info.repo; text: "Update"; onClicked: Updates.install() }
        }
        SettingRow {
            label: "Re-run the full install"
            hint: "Packages and system settings too; asks before each change and for your password"
            PillButton { enabled: !!page.info.repo; text: "Run"; onClicked: page.inTerminal("./install.sh") }
        }
        SettingRow {
            label: "Check this computer"
            hint: "Lists missing packages, unlinked or changed configs and services that are off; changes nothing"
            PillButton { enabled: !!page.info.repo; text: "Run doctor"; onClicked: page.inTerminal("./install.sh doctor") }
        }
    }
    // ---- restore points: copies of settings.json (the newest 10), one per shell start when something changed
    property var points: []
    property string backupNote: ""
    Process {
        id: pointsRead
        running: true
        command: ["settings-snapshot", "list"]
        stdout: StdioCollector { onStreamFinished: { try { page.points = JSON.parse(text) } catch (e) { page.points = [] } } }
    }
    Process {   // one change at a time; the list and a short note follow its result
        id: backup
        property string done: ""
        stderr: StdioCollector { id: backupErr }
        onExited: code => { page.backupNote = code === 0 ? done : backupErr.text.trim().replace(/^settings-snapshot: /, ""); pointsRead.running = true }
    }
    function snapshot(args, done) { backup.done = done; backup.command = ["settings-snapshot"].concat(args); backup.running = true }
    readonly property string exportPath: Quickshell.env("HOME") + "/hyprism-settings.json"
    readonly property var reasons: ({ start: "Desktop start", manual: "Made by you", "before-restore": "Before a restore",
                                      "before-import": "Before an import", displays: "Before a display change", keybinds: "Before a shortcut change",
                                      actions: "Before an action change" })

    SettingGroup {
        title: "Backups"
        SettingRow {
            label: "Restore points"
            hint: page.backupNote !== "" ? page.backupNote
                : "Your settings are copied when the desktop starts and before big changes; the newest 10 are kept"
            PillButton { enabled: !backup.running; text: "Make one now"; onClicked: page.snapshot(["take", "manual"], "Restore point made") }
        }
        Repeater {
            model: page.points
            SettingRow {
                required property var modelData
                label: modelData.time
                hint: page.reasons[modelData.reason] ?? modelData.reason
                PillButton { enabled: !backup.running; text: "Restore"; onClicked: page.snapshot(["restore", modelData.id], "Settings from " + modelData.time + " are back") }
            }
        }
        SettingRow {
            label: "Export"
            hint: "Saves your settings to " + page.exportPath.replace(Quickshell.env("HOME"), "~") + ", to keep or to use on another computer"
            PillButton { enabled: !backup.running; text: "Export"; onClicked: page.snapshot(["export", page.exportPath], "Saved to " + page.exportPath.replace(Quickshell.env("HOME"), "~")) }
        }
        SettingRow {
            label: "Import"
            hint: "Uses the settings in a file you exported; your current ones become a restore point first"
            TextField { id: importPath; width: 220; placeholder: "~/hyprism-settings.json"; accessibleName: "Settings file to import" }
            PillButton {
                enabled: !backup.running && importPath.text.trim() !== ""
                text: "Import"
                onClicked: page.snapshot(["import", importPath.text.trim().replace(/^~/, Quickshell.env("HOME"))], "Imported")
            }
        }
    }

    function inTerminal(cmd) {
        Quickshell.execDetached(["ghostty", "+new-window", "-e", "sh", "-c", "cd \"$1\" && " + cmd + "; echo; read -p 'Press Enter to close' _", "sh", page.info.repo])
    }

    component Value: Text {
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        color: Theme.subtext
        font { family: Theme.font; pixelSize: Theme.fontSize }
    }
}
