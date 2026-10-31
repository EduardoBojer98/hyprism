import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// About: this machine and the setup that built it.
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
        SettingRow { label: "NVIDIA GPU"; hint: "Switch it in ROG Control Center"; Value { text: page.info.nvidia === "1" ? "Off (saves battery)" : "On" } }
    }

    SettingGroup {
        title: "Software"
        SettingRow { label: "System"; Value { text: page.info.os ?? "" } }
        SettingRow { label: "Kernel"; Value { text: page.info.kernel ?? "" } }
        SettingRow { label: "Hyprland"; Value { text: page.info.hypr ?? "" } }
        SettingRow { label: "Quickshell"; Value { text: page.info.qs ?? "" } }
        SettingRow {
            label: "linux-setup"
            hint: "github.com/EduardoBojer98/linux-setup"
            Value { text: page.info.setup ?? "" }
            PillButton { text: "Open folder"; onClicked: Quickshell.execDetached(["xdg-open", page.info.repo ?? ""]) }   // wherever the repo was cloned
        }
    }

    // Both run in a terminal so you see what happens (and git or sudo can ask questions)
    SettingGroup {
        title: "Update"
        SettingRow {
            label: "Update everything"
            hint: "Pulls the latest setup, updates the system (snapshot first on Arch), relinks the configs and runs the doctor"
            PillButton { enabled: !!page.info.repo; text: "Update"; onClicked: page.inTerminal("./install.sh update") }
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
    function inTerminal(cmd) {
        Quickshell.execDetached(["ghostty", "+new-window", "-e", "sh", "-c", "cd \"$1\" && " + cmd + "; echo; read -p 'Press Enter to close' _", "sh", page.info.repo])
    }

    component Value: Text {
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        color: Theme.subtext
        font { family: Theme.font; pixelSize: 13 }
    }
}
