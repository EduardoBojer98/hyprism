pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

// The Settings app: one glass window with a sidebar of sections, like macOS System Settings.
// Open with Super+I, the Control Center's gear, the launcher ("Settings"), or
// `qs ipc call settings open [group or page]`.
Singleton {
    id: root

    property bool open: false
    property string section: "appearance"   // the group shown
    property string focusPage: ""           // page to scroll to inside it (from show())

    // The sidebar: groups like a normal desktop's settings, each showing one or more pages below.
    // Page ids still work everywhere (show("sound"), `qs ipc call settings open bluetooth`).
    readonly property var allGroups: [
        { id: "display",    name: "Display",              glyph: "\u{F0379}", pages: ["displays", "monitor"] },
        { id: "appearance", name: "Appearance",           glyph: "\u{F03D8}", pages: ["appearance", "wallpaper", "icons"] },
        { id: "desktop",    name: "Desktop",              glyph: "\u{F0349}", pages: ["dock", "launcher", "controlcenter", "notifications", "clipboard", "weather", "calendar"] },
        { id: "input",      name: "Input",                glyph: "\u{F030C}", pages: ["input"] },
        { id: "sound",      name: "Sound",                glyph: "\u{F057E}", pages: ["sound"] },
        { id: "network",    name: "Network & Bluetooth",  glyph: "\u{F05A9}", pages: ["network", "bluetooth"] },
        { id: "power",      name: "Power & Battery",      glyph: "\u{F0079}", pages: ["power", "idle", "asus"] },
        { id: "keybinds",   name: "Keyboard Shortcuts",   glyph: "\u{F0313}", pages: ["keybinds"] },
        { id: "apps",       name: "Default Apps",         glyph: "\u{F003B}", pages: ["apps"] },
        { id: "startup",    name: "Startup Apps",         glyph: "\u{F040A}", pages: ["startup"] },
        { id: "system",     name: "System",               glyph: "\u{F02FD}", pages: ["about", "language"] },
    ]
    // ASUS Hardware only on machines with asusctl
    readonly property var sections: allGroups.map(g => Object.assign({}, g, { pages: g.pages.filter(p => p !== "asus" || Machine.asus) }))
    readonly property var currentGroup: sections.find(g => g.id === section) ?? sections[0]
    function pageName(id) { return allSections.find(p => p.id === id)?.name ?? "" }

    // Pages: what each SettingsPage<Id>.qml is called (Spotlight searches these too)
    readonly property var allSections: [
        { id: "appearance",    name: "Appearance & Themes", glyph: "\u{F03D8}" },
        { id: "icons",         name: "Icons",               glyph: "\u{F0BC1}" },
        { id: "dock",          name: "Desktop & Dock",      glyph: "\u{F0379}" },
        { id: "launcher",      name: "Search & Launcher",   glyph: "\u{F0349}" },
        { id: "clipboard",     name: "Clipboard",           glyph: "\u{F014C}" },
        { id: "controlcenter", name: "Control Center",      glyph: "\u{F0493}" },
        { id: "notifications", name: "Notifications",       glyph: "\u{F009A}" },
        { id: "displays",      name: "Displays",            glyph: "\u{F0379}" },
        { id: "monitor",       name: "Shared Monitor",      glyph: "\u{F0E58}" },
        { id: "sound",         name: "Sound",               glyph: "\u{F057E}" },
        { id: "network",       name: "Wi-Fi & Network",     glyph: "\u{F05A9}" },
        { id: "bluetooth",     name: "Bluetooth",           glyph: "\u{F00AF}" },
        { id: "input",         name: "Keyboard & Touchpad", glyph: "\u{F030C}" },
        { id: "language",      name: "Language & Region",   glyph: "\u{F05CA}" },
        { id: "keybinds",      name: "Keyboard Shortcuts",  glyph: "\u{F0313}" },
        { id: "power",         name: "Battery & Power",     glyph: "\u{F0079}" },
        { id: "asus",          name: "ASUS Hardware",       glyph: "\u{F061A}" },
        { id: "wallpaper",     name: "Wallpaper",           glyph: "\u{F02E9}" },
        { id: "weather",       name: "Weather",             glyph: "\u{F0595}" },
        { id: "calendar",      name: "Calendar",            glyph: "\u{F00ED}" },
        { id: "idle",          name: "Lock & Sleep",        glyph: "\u{F033E}" },
        { id: "apps",          name: "Default Applications", glyph: "\u{F003B}" },
        { id: "startup",       name: "Startup Apps",        glyph: "\u{F040A}" },
        { id: "about",         name: "About",               glyph: "\u{F02FD}" },
    ]

    // s: a group id, a page id (opens its group scrolled to that page), or "" (last group)
    function show(s) {
        const g = sections.find(x => x.id === s) ?? sections.find(x => x.pages.includes(s))
        if (g) { section = g.id; focusPage = g.id === s ? "" : s }
        open = true
    }

    IpcHandler {
        target: "settings"
        function open(section: string): void { root.show(section) }
        function toggle(): void { root.open = !root.open }
    }

    // Lua table literal from a plain JS object (strings, numbers, booleans, nested objects)
    function lua(value, indent) {
        indent = indent || ""
        if (typeof value === "string") return JSON.stringify(value)
        if (typeof value === "number" || typeof value === "boolean") return String(value)
        const inner = indent + "    "
        return "{\n" + Object.keys(value).map(k =>
            inner + "[" + JSON.stringify(k) + "] = " + lua(value[k], inner) + ",").join("\n") + "\n" + indent + "}"
    }

    // Write a text file in the Hyprland config (the repo, through the stow link)
    function writeHyprFile(rel, text) {
        // mkdir: settings/ isn't in git (your own choices), so a fresh install has to create it
        Quickshell.execDetached(["sh", "-c", "f=\"$HOME/.config/hypr/" + rel + "\"; mkdir -p \"$(dirname \"$f\")\"; cat > \"$f\" <<'QS_EOF'\n" + text + "\nQS_EOF"])
    }

    FloatingWindow {
        id: win
        // Narrow window: the sidebar shrinks to icons and the page margins tighten; rows put their
        // control under the label when both don't fit (SettingRow). Anything still too big scrolls.
        readonly property bool compact: width < 780
        readonly property int pad: width < 640 ? Theme.spaceL : 28
        // filling (almost) the whole screen means Hyprland has it maximised
        readonly property bool maximised: screen ? width >= screen.width - 80 && height >= screen.height - 120 : false

        visible: root.open
        title: "Settings"
        color: "transparent"
        implicitWidth: 1020
        implicitHeight: 700
        minimumSize: Qt.size(460, 360)
        onVisibleChanged: if (!visible) root.open = false

        Glass {
            anchors.fill: parent
            strong: true
            radius: 0
            border.width: 0

            // ---- sidebar ---------------------------------------------------------------------
            Rectangle {
                id: sidebar
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                width: win.compact ? 64 : 240
                color: Theme.sidebar
                Behavior on width { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easing } }

                Flickable {
                    id: nav
                    anchors.fill: parent
                    contentHeight: navColumn.implicitHeight + 30
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: GlassScrollBar {}

                    Column {
                        id: navColumn
                        x: 12; y: 18
                        width: sidebar.width - 24
                        spacing: 2

                        Text {
                            visible: !win.compact
                            text: "Settings"
                            leftPadding: 10
                            bottomPadding: 12
                            color: Theme.text
                            font { family: Theme.font; pixelSize: 20; weight: Font.Bold }
                        }

                        Repeater {
                            model: root.sections
                            Rectangle {
                                required property var modelData
                                readonly property bool current: root.section === modelData.id
                                width: parent.width
                                height: 34
                                radius: Theme.radiusSmall
                                color: current ? Theme.fillActive : navArea.containsMouse ? Theme.fillHover : "transparent"
                                border { color: current ? Theme.stroke : "transparent"; width: 1 }
                                Row {
                                    anchors { left: parent.left; leftMargin: win.compact ? (parent.width - 24) / 2 : 10; verticalCenter: parent.verticalCenter }
                                    spacing: 10
                                    Rectangle {
                                        width: 24; height: 24; radius: 7
                                        color: current ? Theme.accent : Theme.fill
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.glyph
                                            color: current ? Theme.accentText : Theme.text
                                            font { family: Theme.iconFont; pixelSize: 14 }
                                        }
                                    }
                                    Text {
                                        visible: !win.compact
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: sidebar.width - 24 - 54
                                        elide: Text.ElideRight
                                        text: modelData.name
                                        color: Theme.text
                                        font { family: Theme.font; pixelSize: 13; weight: current ? Font.DemiBold : Font.Normal }
                                    }
                                }
                                MouseArea { id: navArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.show(modelData.id) }
                            }
                        }
                    }
                }
            }

            Rectangle { // divider
                anchors { left: sidebar.right; top: parent.top; bottom: parent.bottom }
                width: 1
                color: Theme.stroke
            }

            // ---- page ------------------------------------------------------------------------
            Flickable {
                id: page
                anchors { left: sidebar.right; leftMargin: 1; right: parent.right; top: parent.top; bottom: parent.bottom }
                contentHeight: pageColumn.implicitHeight + win.pad * 2
                contentWidth: pageColumn.width + win.pad * 2     // wider than the window only below ~340 px of page
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: GlassScrollBar {}
                ScrollBar.horizontal: GlassScrollBar {}

                Connections { target: root; function onSectionChanged() { page.contentY = 0; page.contentX = 0 } }

                ColumnLayout {
                    id: pageColumn
                    x: win.pad; y: win.pad
                    width: Math.max(page.width - win.pad * 2, 340)
                    spacing: 20

                    Text {
                        Layout.fillWidth: true
                        text: root.currentGroup.name
                        elide: Text.ElideRight
                        color: Theme.text
                        font { family: Theme.font; pixelSize: 22; weight: Font.Bold }
                    }

                    // the group's pages one below the other, each under its own heading
                    Repeater {
                        model: root.currentGroup.pages
                        ColumnLayout {
                            id: part
                            required property string modelData
                            required property int index
                            Layout.fillWidth: true
                            Layout.topMargin: index > 0 ? 16 : 0
                            spacing: 12

                            Text {
                                visible: root.currentGroup.pages.length > 1
                                text: root.pageName(part.modelData)
                                color: Theme.text
                                font { family: Theme.font; pixelSize: 17; weight: Font.DemiBold }
                            }
                            Loader {
                                Layout.fillWidth: true
                                active: root.open
                                source: "SettingsPage" + part.modelData.charAt(0).toUpperCase() + part.modelData.slice(1) + ".qml"
                            }
                            // show("bluetooth") lands on Bluetooth inside Network & Bluetooth, once the layout has placed it
                            Timer {
                                running: root.open && root.focusPage === part.modelData
                                interval: 80
                                onTriggered: {
                                    page.contentY = Math.max(0, Math.min(part.y + win.pad, page.contentHeight - page.height))
                                    root.focusPage = ""
                                }
                            }
                        }
                    }
                }
            }

            // ---- window buttons: minimise, maximise, close (the shell draws its own, like a GTK app) ----
            Row {
                anchors { top: parent.top; right: parent.right; margins: 12 }
                spacing: 8
                Repeater {
                    model: [
                        { glyph: "\u{F05B0}", tip: "Minimise", act: () => Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.window.move({ workspace = \"special:minimized\", follow = false })"]) },
                        { glyph: win.maximised ? "\u{F05B2}" : "\u{F05AF}", tip: win.maximised ? "Restore" : "Maximise", act: () => Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.window.fullscreen({ action = \"toggle\", mode = \"maximized\" })"]) },
                        { glyph: "\u{F05AD}", tip: "Close", act: () => root.open = false }
                    ]
                    Rectangle {
                        required property var modelData
                        width: 24; height: 24; radius: 12
                        color: btnArea.pressed ? Theme.fillActive : btnArea.containsMouse ? Theme.fillHover : Theme.fill
                        border { color: Theme.stroke; width: 1 }
                        Text {
                            anchors.centerIn: parent
                            text: modelData.glyph
                            color: Theme.text
                            font { family: Theme.iconFont; pixelSize: 13 }
                        }
                        MouseArea { id: btnArea; anchors.fill: parent; hoverEnabled: true; onClicked: modelData.act() }
                        ToolTipText { shown: btnArea.containsMouse; text: modelData.tip }
                    }
                }
            }
        }
    }
}
