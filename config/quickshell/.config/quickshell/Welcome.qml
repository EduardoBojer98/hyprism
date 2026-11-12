pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

// First-run welcome: opens once on the first login (when the settings and the themes are loaded and
// system.welcomed is still false), centred like the power menu. The three keys a newcomer needs, a look
// to pick (theme, light or dark, bar layout), the keyboard layouts, and what was found on this computer.
// Everything it changes goes through Config.set, so it is all in Settings later. `welcomed` is saved when
// it is closed (Done, Esc, a click outside), so a crash before that shows it again.
// `qs ipc call welcome open` shows it again; so does the "Welcome" action in the menu.
Singleton {
    id: root

    property bool open: false
    property string computer: ""      // one line from ~/.config/hyprism/hardware.toml, "" when there is none
    property bool asked: false        // the first-run check runs once

    readonly property bool due: Config.loaded && Themes.ready && !Config.system.welcomed
    onDueChanged: check()
    Component.onCompleted: check()
    function check() { if (due && !asked) { asked = true; show() } }

    function show() { reader.running = false; reader.running = true; Quickshell.execDetached(["theme-wallpaper", "--all"]); open = true }
    function hide() { if (!open) return; open = false; Config.set("system", "welcomed", true) }
    function toggle() { if (open) hide(); else show() }

    IpcHandler {
        target: "welcome"
        function open(): void { root.show() }
        function close(): void { root.hide() }
    }

    // "Laptop · Intel and NVIDIA graphics · battery · touch screen" from hardware.toml (read as text, never run)
    Process {
        id: reader
        command: ["sh", "-c", "cat \"${XDG_CONFIG_HOME:-$HOME/.config}/hyprism/hardware.toml\" 2>/dev/null; true"]
        stdout: StdioCollector {
            onStreamFinished: {
                const pick = re => (text.match(re) ?? [])[1] ?? ""
                const form = ({ laptop: "Laptop", desktop: "Desktop computer", vm: "Virtual machine" })[pick(/^form\s*=\s*"([^"]*)"/m)] ?? ""
                const names = ({ amd: "AMD", intel: "Intel", nvidia: "NVIDIA" })
                const gpus = pick(/^vendors\s*=\s*\[([^\]]*)\]/m).split(",").map(v => v.replace(/["\s]/g, "")).filter(v => v && v !== "virtual")
                    .map(v => names[v] ?? v).filter((v, i, a) => a.indexOf(v) === i)
                const parts = [form]
                if (gpus.length) parts.push(gpus.join(" and ") + " graphics")
                if (pick(/^battery\s*=\s*"([^"]*)"/m)) parts.push("battery")
                if (/^touchscreen\s*=\s*true/m.test(text)) parts.push("touch screen")
                root.computer = text.trim() ? parts.filter(p => p).join(" · ") : ""
            }
        }
    }

    PanelWindow {
        id: win
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        visible: root.open || stage.opacity > 0
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "qs-welcome"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        Item {
            id: stage
            anchors.fill: parent
            opacity: root.open ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
            focus: root.open

            // Tab walks the controls (they take focus themselves); what they leave unhandled lands here
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) root.hide()
                else return
                event.accepted = true
            }

            Rectangle { anchors.fill: parent; color: Theme.backdrop }
            MouseArea { anchors.fill: parent; onClicked: root.hide() }

            Glass {
                id: card
                readonly property int margin: Math.max(Theme.spaceL, Math.min(win.width, win.height) * 0.04)
                readonly property int pad: Theme.spaceXl
                width: Math.min(1100, win.width - margin * 2)
                height: Math.min(content.implicitHeight + buttons.height + Theme.spaceM + pad * 2, win.height - margin * 2)
                anchors.centerIn: parent
                strong: true
                radius: Theme.radiusPanel
                scale: root.open ? 1 : 0.97
                Behavior on scale { NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
                MouseArea { anchors.fill: parent }   // clicks on the card don't close it

                Flickable {   // scrolls on short screens
                    anchors { fill: parent; margins: card.pad; bottomMargin: card.pad + buttons.height + Theme.spaceM }
                    contentHeight: content.implicitHeight
                    clip: contentHeight > height
                    interactive: contentHeight > height
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: content
                        width: parent.width
                        spacing: Theme.spaceM

                        Text { text: "Welcome"; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontHeading; weight: Font.Bold } }
                        Text {
                            Layout.fillWidth: true
                            text: "Super is the Windows key. Tap it or press Super+Space to search for anything: apps, files, settings, actions.\n"
                                + "Super+I opens Settings. Super+/ lists every shortcut."
                            color: Theme.subtext
                            wrapMode: Text.Wrap
                            lineHeight: 1.15
                            font { family: Theme.font; pixelSize: Theme.fontSize }
                        }

                        Label { text: "Pick a look"; Layout.topMargin: Theme.spaceS }
                        GridLayout {
                            id: gallery
                            Layout.fillWidth: true
                            columns: Math.min(Themes.list.length, Math.max(2, Math.floor((width + columnSpacing) / (100 + columnSpacing))))   // all in one row where they fit
                            columnSpacing: Theme.spaceS
                            rowSpacing: Theme.spaceM
                            Repeater {
                                model: Themes.list
                                ThemePreview {
                                    required property var modelData
                                    theme: Themes.resolve(modelData.id, {}, Config.appearance.mode)   // in the light or dark half picked below
                                    chosen: Config.appearance.theme === modelData.id
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignTop
                                    onPicked: Config.set("appearance", "theme", modelData.id)
                                    activeFocusOnTab: true
                                    Keys.onReturnPressed: picked()
                                    Keys.onSpacePressed: picked()
                                    Accessible.name: "Theme " + modelData.name
                                    Accessible.role: Accessible.Button
                                    FocusRing {}
                                }
                            }
                        }
                        RowLayout {
                            spacing: Theme.spaceM
                            Text { text: "Light or dark"; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontSize } }
                            ConfigChoice {
                                section: "appearance"; key: "mode"
                                values: ["light", "dark", "theme"]; labels: ["Light", "Dark", "Theme's choice"]
                                Accessible.name: "Light or dark"
                                Accessible.role: Accessible.ComboBox
                            }
                        }

                        Label { text: "Bar layout"; Layout.topMargin: Theme.spaceS }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spaceM
                            ConfigChoice {
                                section: "bar"; key: "preset"
                                values: ["theme", "minimal", "full", "laptop", "external"]
                                labels: ["Theme's own", "Minimal", "Full", "Laptop", "External"]
                                Accessible.name: "Bar layout"
                                Accessible.role: Accessible.ComboBox
                            }
                            Text {
                                Layout.fillWidth: true
                                visible: Sys.hasBattery
                                text: "This computer has a battery: Laptop fits it."
                                color: Theme.subtext
                                elide: Text.ElideRight
                                font { family: Theme.font; pixelSize: Theme.fontLabel }
                            }
                        }

                        Label { text: "Keyboard layouts"; Layout.topMargin: Theme.spaceS }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spaceM
                            PillButton {
                                text: "Choose layouts…"
                                Accessible.name: "Choose keyboard layouts"
                                Accessible.role: Accessible.Button
                                onClicked: { root.hide(); SettingsApp.show("input") }
                            }
                            Text { Layout.fillWidth: true; text: "Add a second language, or switch with a key."; color: Theme.subtext; elide: Text.ElideRight; font { family: Theme.font; pixelSize: Theme.fontLabel } }
                        }

                        Label { text: "This computer"; visible: root.computer !== ""; Layout.topMargin: Theme.spaceS }
                        Text {
                            Layout.fillWidth: true
                            visible: root.computer !== ""
                            text: root.computer + ". Optional parts: run ./install.sh modules to list them."
                            color: Theme.text
                            wrapMode: Text.Wrap
                            font { family: Theme.font; pixelSize: Theme.fontSize }
                        }
                    }
                }

                // outside the scrolling part, so they are always in view
                RowLayout {
                    id: buttons
                    anchors { right: parent.right; bottom: parent.bottom; margins: card.pad }
                    spacing: Theme.spaceS
                    PillButton {
                        text: "Show all shortcuts"
                        Accessible.name: "Show all shortcuts"
                        Accessible.role: Accessible.Button
                        onClicked: { root.hide(); Cheatsheet.show() }
                    }
                    PillButton {
                        text: "Done"
                        primary: true
                        Accessible.name: "Done"
                        Accessible.role: Accessible.Button
                        onClicked: root.hide()
                    }
                }
            }
        }
    }

    component Label: Text {
        color: Theme.accent
        font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.Bold; letterSpacing: 1.2; capitalization: Font.AllUppercase }
    }
}
