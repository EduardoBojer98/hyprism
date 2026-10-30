import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Networking
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

// macOS-style Control Center under the bar's status pill:
// battery · Wi-Fi / Bluetooth / keyboard / Acer tiles (chevron expands lists) · power mode ·
// brightness · output volume + device · microphone + device.
PopupWindow {
    id: cc

    required property Item anchorItem
    property string expanded: ""     // "", "wifi", "bt", "out", "in"
    property var passwordFor: null   // Wi-Fi network waiting for a password
    property real brightness: 0

    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var battery: UPower.displayDevice

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.top: 12
    grabFocus: true
    implicitWidth: 380
    implicitHeight: content.implicitHeight + 28
    color: "transparent"

    PwObjectTracker { objects: [cc.sink, cc.source] }

    onVisibleChanged: {
        if (wifi) wifi.scannerEnabled = visible
        if (visible) brightnessRead.running = true
        else { expanded = ""; passwordFor = null }
    }

    Process {
        id: brightnessRead
        command: ["brightnessctl", "-m"]   // amdgpu_bl1,backlight,123,48%,255
        stdout: StdioCollector { onStreamFinished: cc.brightness = parseInt(text.split(",")[3]) / 100 }
    }

    function nodeName(n) { return n?.description || n?.nickname || n?.name || "" }
    function toggleExpanded(name) { expanded = expanded === name ? "" : name; passwordFor = null }

    Glass {
        anchors.fill: parent
        strong: true
        radius: Theme.radiusLarge

        ColumnLayout {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
            spacing: 12

            // ---- battery header ------------------------------------------------------------
            RowLayout {
                Layout.fillWidth: true
                readonly property int pct: Math.round((cc.battery?.percentage ?? 0) * 100)
                readonly property bool charging: cc.battery?.state === UPowerDeviceState.Charging
                readonly property real secs: charging ? (cc.battery?.timeToFull ?? 0) : (cc.battery?.timeToEmpty ?? 0)

                Text {
                    text: parent.charging ? "\u{F0084}" : "\u{F0079}"
                    color: parent.charging ? Theme.green : Theme.text
                    font { family: Theme.iconFont; pixelSize: 22 }
                }
                Column {
                    Layout.fillWidth: true
                    Text {
                        text: parent.parent.pct + "%"
                        color: Theme.text
                        font { family: Theme.font; pixelSize: 15; weight: Font.DemiBold }
                    }
                    Text {
                        readonly property var row: parent.parent
                        text: !UPower.onBattery && !row.charging ? "Plugged in · held at the 80 % limit"
                            : row.secs > 0 ? (row.charging ? "Full in " : "") + Math.floor(row.secs / 3600) + " h " + Math.round(row.secs % 3600 / 60) + " min" + (row.charging ? "" : " left")
                            : row.charging ? "Charging" : "On battery"
                        color: Theme.muted
                        font { family: Theme.font; pixelSize: 11 }
                    }
                }
                RoundButton {
                    glyph: "\u{F0493}"
                    hint: "ROG Control Center"
                    onClicked: { cc.visible = false; Quickshell.execDetached(["rog-control-center"]) }
                }
            }

            // ---- tiles ---------------------------------------------------------------------
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 10
                rowSpacing: 10

                Tile {
                    glyph: Networking.wifiEnabled ? "\u{F05A9}" : "\u{F05AA}"
                    title: "Wi-Fi"
                    subtitle: !Networking.wifiEnabled ? "Off" : (cc.wifi?.networks.values.find(n => n.connected)?.name ?? "Not connected")
                    active: Networking.wifiEnabled
                    expandable: true
                    isExpanded: cc.expanded === "wifi"
                    onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                    onExpand: cc.toggleExpanded("wifi")
                }
                Tile {
                    readonly property var connectedDevices: cc.adapter ? cc.adapter.devices.values.filter(d => d.connected) : []
                    glyph: cc.adapter?.enabled ? "\u{F00AF}" : "\u{F00B2}"
                    title: "Bluetooth"
                    subtitle: !cc.adapter ? "No adapter" : !cc.adapter.enabled ? "Off"
                            : connectedDevices.length ? connectedDevices.map(d => d.name).join(", ") : "On"
                    active: cc.adapter?.enabled ?? false
                    expandable: true
                    isExpanded: cc.expanded === "bt"
                    onToggled: if (cc.adapter) cc.adapter.enabled = !cc.adapter.enabled
                    onExpand: cc.toggleExpanded("bt")
                }
                Tile {
                    glyph: "\u{F11C}"
                    title: "Keyboard"
                    subtitle: Osk.visible ? "On screen" : "Hidden"
                    active: Osk.visible
                    onToggled: Osk.toggle()
                }
                Tile {
                    readonly property bool ours: Hyprland.monitors.values.some(m => m.name === "HDMI-A-1")
                    glyph: "\u{F0379}"
                    title: "Acer monitor"
                    subtitle: ours ? "This laptop" : "Work PC"
                    active: ours
                    onToggled: Quickshell.execDetached(["monswitch", "toggle"])
                }
            }

            // ---- Wi-Fi networks ------------------------------------------------------------
            ExpandList {
                shown: cc.expanded === "wifi"
                model: (cc.wifi?.networks.values ?? []).filter(n => n.name)
                    .sort((a, b) => b.connected - a.connected || b.signalStrength - a.signalStrength)
                    .slice(0, 8)
                delegate: ListRow {
                    required property var modelData
                    glyph: modelData.signalStrength > 0.66 ? "\u{F0928}" : modelData.signalStrength > 0.33 ? "\u{F0925}" : "\u{F091F}"
                    title: modelData.name
                    trailing: modelData.connected ? "\u{F012C}" : (modelData.security !== WifiSecurityType.Open && !modelData.known) ? "\u{F033E}" : ""
                    selected: modelData.connected
                    onClicked: {
                        if (modelData.connected) modelData.disconnect()
                        else if (modelData.known || modelData.security === WifiSecurityType.Open) modelData.connect()
                        else cc.passwordFor = modelData
                    }
                }
            }

            // Password prompt for a new secured network
            Rectangle {
                visible: cc.expanded === "wifi" && cc.passwordFor !== null
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                radius: 12
                color: Theme.fill
                border { color: Theme.stroke; width: 1 }

                TextInput {
                    id: psk
                    anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    color: Theme.text
                    font { family: Theme.font; pixelSize: 13 }
                    focus: parent.visible
                    onAccepted: { cc.passwordFor.connectWithPsk(text); text = ""; cc.passwordFor = null }
                    Keys.onEscapePressed: cc.passwordFor = null
                    Text {
                        visible: !psk.text
                        text: "Password for " + (cc.passwordFor?.name ?? "") + " — Enter to join"
                        color: Theme.muted
                        font: psk.font
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // ---- Bluetooth devices -----------------------------------------------------------
            ExpandList {
                shown: cc.expanded === "bt"
                model: (cc.adapter?.devices.values ?? []).filter(d => d.paired || d.connected)
                    .sort((a, b) => b.connected - a.connected)
                delegate: ListRow {
                    required property var modelData
                    glyph: "\u{F00AF}"
                    title: modelData.name + (modelData.batteryAvailable ? "  ·  " + Math.round(modelData.battery * 100) + "%" : "")
                    trailing: modelData.connected ? "\u{F012C}" : ""
                    selected: modelData.connected
                    onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
                }
                emptyText: "No paired devices — pair new ones in ROG/KDE settings or bluetoothctl"
            }

            // ---- power mode ------------------------------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                radius: height / 2
                color: Theme.fill

                Rectangle {
                    width: (parent.width - 8) / 3
                    height: parent.height - 8
                    y: 4
                    x: 4 + PowerProfiles.profile * width
                    radius: height / 2
                    color: Theme.fillActive
                    border { color: Theme.stroke; width: 1 }
                    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                }
                Row {
                    anchors { fill: parent; margins: 4 }
                    Repeater {
                        model: [["\u{F032A}", "Quiet", Theme.green], ["\u{F05D1}", "Balanced", Theme.accent], ["\u{F04C5}", "Performance", Theme.peach]]
                        Item {
                            required property var modelData
                            required property int index
                            width: parent.width / 3
                            height: parent.height
                            Row {
                                anchors.centerIn: parent
                                spacing: 6
                                Text {
                                    text: modelData[0]
                                    color: PowerProfiles.profile === index ? modelData[2] : Theme.subtext
                                    font { family: Theme.iconFont; pixelSize: 14 }
                                }
                                Text {
                                    text: modelData[1]
                                    color: PowerProfiles.profile === index ? Theme.text : Theme.subtext
                                    font { family: Theme.font; pixelSize: 12; weight: Font.Medium }
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: PowerProfiles.profile = index
                            }
                        }
                    }
                }
            }

            // ---- sliders ---------------------------------------------------------------------
            SectionLabel { text: "Display" }
            Slider {
                Layout.fillWidth: true
                icon: "\u{F00DF}"
                value: cc.brightness
                onMoved: v => {
                    cc.brightness = Math.max(0.05, v)
                    Quickshell.execDetached(["brightnessctl", "-q", "set", Math.round(cc.brightness * 100) + "%"])
                }
            }

            SectionLabel { text: "Sound"; chevron: true; isExpanded: cc.expanded === "out"; onExpand: cc.toggleExpanded("out"); detail: cc.nodeName(cc.sink) }
            Slider {
                Layout.fillWidth: true
                icon: cc.sink?.audio?.muted ? "\u{F075F}" : "\u{F057E}"
                value: cc.sink?.audio?.muted ? 0 : (cc.sink?.audio?.volume ?? 0)
                onMoved: v => { if (cc.sink?.audio) { cc.sink.audio.muted = false; cc.sink.audio.volume = v } }
                onIconClicked: if (cc.sink?.audio) cc.sink.audio.muted = !cc.sink.audio.muted
            }
            ExpandList {
                shown: cc.expanded === "out"
                model: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioSink)
                delegate: ListRow {
                    required property var modelData
                    glyph: "\u{F04C3}"
                    title: cc.nodeName(modelData)
                    selected: modelData === cc.sink
                    trailing: selected ? "\u{F012C}" : ""
                    onClicked: Pipewire.preferredDefaultAudioSink = modelData
                }
            }

            SectionLabel { text: "Microphone"; chevron: true; isExpanded: cc.expanded === "in"; onExpand: cc.toggleExpanded("in"); detail: cc.nodeName(cc.source) }
            Slider {
                Layout.fillWidth: true
                icon: cc.source?.audio?.muted ? "\u{F036D}" : "\u{F036C}"
                value: cc.source?.audio?.muted ? 0 : (cc.source?.audio?.volume ?? 0)
                onMoved: v => { if (cc.source?.audio) { cc.source.audio.muted = false; cc.source.audio.volume = v } }
                onIconClicked: if (cc.source?.audio) cc.source.audio.muted = !cc.source.audio.muted
            }
            ExpandList {
                shown: cc.expanded === "in"
                model: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioSource)
                delegate: ListRow {
                    required property var modelData
                    glyph: "\u{F036C}"
                    title: cc.nodeName(modelData)
                    selected: modelData === cc.source
                    trailing: selected ? "\u{F012C}" : ""
                    onClicked: Pipewire.preferredDefaultAudioSource = modelData
                }
            }

            Item { Layout.preferredHeight: 2 }
        }
    }

    // ---- building blocks ---------------------------------------------------------------------

    // Big toggle tile: tap toggles, chevron (if expandable) opens the list below
    component Tile: Rectangle {
        id: tile
        property string glyph
        property string title
        property string subtitle
        property bool active: false
        property bool expandable: false
        property bool isExpanded: false
        signal toggled()
        signal expand()

        Layout.fillWidth: true
        Layout.preferredHeight: 58
        radius: 16
        color: tileArea.containsMouse ? Theme.fillHover : Theme.fill
        border { color: isExpanded ? Theme.accent : Theme.stroke; width: 1 }
        Behavior on color { ColorAnimation { duration: Theme.anim } }

        Rectangle {
            id: bubble
            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
            width: 34; height: 34; radius: 17
            color: tile.active ? Theme.accent : Theme.fillActive
            Behavior on color { ColorAnimation { duration: Theme.anim } }
            Text {
                anchors.centerIn: parent
                text: tile.glyph
                color: tile.active ? Theme.accentText : Theme.text
                font { family: Theme.iconFont; pixelSize: 16 }
            }
        }
        Column {
            anchors { left: bubble.right; leftMargin: 10; right: chevron.left; rightMargin: 4; verticalCenter: parent.verticalCenter }
            Text { width: parent.width; text: tile.title; color: Theme.text; elide: Text.ElideRight; font { family: Theme.font; pixelSize: 13; weight: Font.DemiBold } }
            Text { width: parent.width; text: tile.subtitle; color: Theme.muted; elide: Text.ElideRight; font { family: Theme.font; pixelSize: 11 } }
        }
        MouseArea {
            id: tileArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.toggled()
        }
        Text {
            id: chevron
            visible: tile.expandable
            width: visible ? 26 : 0
            anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
            horizontalAlignment: Text.AlignHCenter
            text: tile.isExpanded ? "\u{F0143}" : "\u{F0140}"
            color: Theme.subtext
            font { family: Theme.iconFont; pixelSize: 16 }
            MouseArea { anchors { fill: parent; margins: -10 } cursorShape: Qt.PointingHandCursor; onClicked: tile.expand() }
        }
    }

    // Small label above a slider, optionally with the current device and a chevron
    component SectionLabel: Item {
        id: label
        property string text
        property string detail
        property bool chevron: false
        property bool isExpanded: false
        signal expand()
        Layout.fillWidth: true
        Layout.preferredHeight: 18
        Layout.topMargin: 2
        Text {
            anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
            text: label.text
            color: Theme.subtext
            font { family: Theme.font; pixelSize: 12; weight: Font.DemiBold }
        }
        Row {
            visible: label.chevron
            anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
            spacing: 4
            Text {
                text: label.detail
                width: Math.min(implicitWidth, 220)
                elide: Text.ElideRight
                color: Theme.muted
                font { family: Theme.font; pixelSize: 11 }
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: label.isExpanded ? "\u{F0143}" : "\u{F0140}"
                color: Theme.subtext
                font { family: Theme.iconFont; pixelSize: 14 }
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        MouseArea {
            visible: label.chevron
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: label.expand()
        }
    }

    // A collapsible list of rows (networks, devices, audio outputs)
    component ExpandList: Rectangle {
        id: list
        property bool shown: false
        property var model: []
        property Component delegate
        property string emptyText: "Nothing found"
        visible: shown
        Layout.fillWidth: true
        Layout.preferredHeight: shown ? rows.implicitHeight + 8 : 0
        radius: 14
        color: Qt.rgba(0, 0, 0, 0.18)
        border { color: Theme.stroke; width: 1 }

        Column {
            id: rows
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 4 }
            Repeater { model: list.model; delegate: list.delegate }
            Text {
                visible: list.model.length === 0
                width: parent.width
                padding: 10
                wrapMode: Text.Wrap
                text: list.emptyText
                color: Theme.muted
                font { family: Theme.font; pixelSize: 12 }
            }
        }
    }

    component ListRow: Rectangle {
        id: row
        property string glyph
        property string title
        property string trailing
        property bool selected: false
        signal clicked()
        width: parent ? parent.width : 0
        height: 36
        radius: 10
        color: rowArea.containsMouse ? Theme.fillHover : "transparent"
        Text {
            id: rowGlyph
            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
            text: row.glyph
            color: row.selected ? Theme.accent : Theme.subtext
            font { family: Theme.iconFont; pixelSize: 15 }
        }
        Text {
            anchors { left: rowGlyph.right; leftMargin: 10; right: trailingText.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
            text: row.title
            elide: Text.ElideRight
            color: Theme.text
            font { family: Theme.font; pixelSize: 13; weight: row.selected ? Font.DemiBold : Font.Normal }
        }
        Text {
            id: trailingText
            anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
            text: row.trailing
            color: row.selected ? Theme.accent : Theme.muted
            font { family: Theme.iconFont; pixelSize: 14 }
        }
        MouseArea {
            id: rowArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.clicked()
        }
    }

    component RoundButton: Rectangle {
        id: btn
        property string glyph
        property string hint
        signal clicked()
        width: 34; height: 34; radius: 17
        color: btnArea.containsMouse ? Theme.fillHover : Theme.fill
        border { color: Theme.stroke; width: 1 }
        Text {
            anchors.centerIn: parent
            text: btn.glyph
            color: Theme.text
            font { family: Theme.iconFont; pixelSize: 16 }
        }
        MouseArea {
            id: btnArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }
}
