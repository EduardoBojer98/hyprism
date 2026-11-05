import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import QtQuick

// One bar item, by id. The bar lays these out in its three sections (Theme.barLayout); every item
// works across a horizontal bar and down a vertical one, and speaks the theme's voice:
//   icons  glyphs (Material Design Icons from the Nerd Font) with numbers where they help
//   mixed  a glyph and its value on every item ("<glyph> 45"), in the bar's face (Monolith, Console)
//   words  lowercase words and numbers ("vol 45"), caps: the same in capitals ("VOL 45")
// Adding an item: a Component below, an entry in Themes.barItems (name + glyph for Settings), done.
Loader {
    id: w
    required property string kind
    required property var monitor
    property bool vertical: false
    property color tone: Theme.text          // ink on this bar's ground
    property color dim: Theme.subtext
    property string voice: "icons"
    property string family: Theme.font
    property int thickness: Theme.barSize
    property bool separated: false           // a thin rule before this item (Bar's sep)


    readonly property bool words: voice === "words" || voice === "caps"
    readonly property bool mixed: voice === "mixed"
    function say(s) { return voice === "caps" || Theme.barStyle.caps === true ? s.toUpperCase() : s }
    sourceComponent: ({ apps: appsC, launcher: launcherC, workspaces: wsC, window: windowC, clock: clockC, date: dateC, media: mediaC, tray: trayC,
                        keyboard: keyboardC, notifications: bellC, status: statusC, network: networkC, bluetooth: btC, volume: volumeC,
                        brightness: brightnessC, battery: batteryC, "power-profile": profileC, cpu: cpuC, memory: memC, gpu: gpuC,
                        recording: recC, power: powerC })[kind] ?? null
    // the separator sits in the gap before the item, outside it (the grid's spacing holds it)
    Rectangle {
        visible: w.separated && w.visible
        color: Qt.alpha(w.tone, 0.28)
        width: w.vertical ? Math.min(14, w.thickness * 0.45) : 1
        height: w.vertical ? 1 : Math.min(14, w.thickness * 0.45)
        x: w.vertical ? (w.width - width) / 2 : -8
        y: w.vertical ? -8 : (w.height - height) / 2
    }
    // an item with nothing to show takes no space (e.g. media with no player). Items say so with
    // `shown` (not `visible`, which follows this Loader and would never come back)
    visible: item ? (item.shown ?? true) : false

    // a glyph and/or a value, in the bar's voice; vertical bars stack them
    component Indicator: BarItem {
        id: ind
        property string glyph: ""
        property string word: ""          // words/caps voice: "vol"
        property string value: ""         // "45", "72%"
        property bool showValue: false    // icons voice: the value beside the glyph
        property bool textual: false      // a readout: in the mixed voice it reads as words ("cpu 5%"), no glyph
        readonly property bool asWords: w.words || (w.mixed && textual && !w.vertical)
        property color ink: w.tone
        vertical: w.vertical
        spacing: 4
        Text {
            visible: !ind.asWords && ind.glyph !== ""
            text: ind.glyph
            color: ind.ink
            font { family: Theme.iconFont; pixelSize: 16 }
        }
        Text {
            visible: ind.asWords || ((ind.showValue || w.mixed) && ind.value !== "" && !(w.mixed && w.vertical))
            text: ind.asWords ? w.say(ind.word + (ind.value !== "" ? (w.vertical ? "\n" : " ") + ind.value : "")) : ind.value
            horizontalAlignment: Text.AlignHCenter
            color: ind.ink
            font { family: w.family; pixelSize: Theme.fontLabel; letterSpacing: w.voice === "caps" ? 1 : 0; features: { "tnum": 1 } }
        }
    }

    // the dock inside the bar: pinned apps, then other running ones; a mark under each open app,
    // the accent under the focused one. Click: bring it up (again: its next window) or start it;
    // middle-click: a new window.
    Component {
        id: appsC
        Item {
            id: apps
            readonly property int count: DesktopEntries.applications.values.length   // lookups re-run once apps have loaded
            function entryFor(appId) { return count ? DesktopEntries.heuristicLookup(appId) : null }
            readonly property var running: Hyprland.toplevels.values.filter(t => t.wayland && t.workspace?.monitor === w.monitor)
            readonly property var entries: {
                const out = count ? Array.from(Config.dock.pinned).map(id => DesktopEntries.byId(id)).filter(e => e) : []
                for (const t of running) { const e = entryFor(t.wayland.appId); if (e && !out.some(x => x.id === e.id)) out.push(e) }
                return out
            }
            readonly property int icon: Math.max(16, Math.min(Math.round(w.thickness * 0.62), 30))
            implicitWidth: grid.implicitWidth
            implicitHeight: grid.implicitHeight
            Grid {
                id: grid
                columns: w.vertical ? 1 : Math.max(1, visibleChildren.filter(c => c.width > 0).length)
                spacing: 2
                Repeater {
                    model: apps.entries
                    BarItem {
                        id: app
                        required property var modelData
                        required property int index
                        readonly property var wins: apps.running.filter(t => apps.entryFor(t.wayland.appId)?.id === modelData.id)
                        vertical: w.vertical
                        pad: 4
                        active: wins.some(t => t.activated)
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        onPressed: button => {
                            if (button === Qt.MiddleButton || wins.length === 0) { modelData.execute(); return }
                            const i = wins.findIndex(t => t.activated)
                            wins[(i + 1) % wins.length].wayland.activate()
                        }
                        // words voices (terminal themes) name the apps instead, like tmux's window list
                        readonly property bool asText: w.words && !w.vertical
                        color: asText && active ? Theme.accent : active ? pressedColor : hovered ? hover : "transparent"
                        radius: asText ? 0 : Theme.radiusSmall
                        IconImage { visible: !app.asText; implicitSize: apps.icon; source: Quickshell.iconPath(app.modelData?.icon ?? "", "application-x-executable") }
                        Text {
                            visible: app.asText
                            text: w.say((app.index + 1) + " " + (app.modelData?.name ?? "").toLowerCase().split(/[ .]/)[0] + (app.wins.length > 1 ? "·" + app.wins.length : ""))
                            color: app.active ? Theme.accentText : app.wins.length ? w.tone : w.dim
                            font { family: w.family; pixelSize: Theme.fontLabel; weight: app.active ? Font.Bold : Font.Normal }
                        }
                        Rectangle {   // open / focused mark, on the screen-edge side (icons only)
                            parent: app
                            visible: app.wins.length > 0 && !app.asText
                            readonly property bool far: Theme.barEdge === "top" || Theme.barEdge === "left"
                            width: w.vertical ? 3 : (app.active ? 14 : 5)
                            height: w.vertical ? (app.active ? 14 : 5) : 3
                            radius: Theme.radius === 0 ? 0 : 1.5
                            x: w.vertical ? (far ? 0 : parent.width - width) : (parent.width - width) / 2
                            y: w.vertical ? (parent.height - height) / 2 : (far ? 0 : parent.height - height)
                            color: app.active ? Theme.accent : Qt.alpha(w.tone, 0.6)
                        }
                    }
                }
            }
        }
    }
    Component {
        id: launcherC
        BarItem {
            vertical: w.vertical
            active: Launcher.open
            onPressed: Launcher.toggle()
            Text { text: "\u{F003B}"; color: Theme.accent; font { family: Theme.iconFont; pixelSize: 18 } }
        }
    }
    Component {
        id: wsC
        BarWs { monitor: w.monitor; vertical: w.vertical; thickness: w.thickness; tone: w.tone; dim: w.dim }
    }
    Component {
        id: windowC
        Item {
            property bool shown: Sys.appClass !== ""
            visible: shown
            implicitWidth: w.vertical ? icon.implicitWidth : app.implicitWidth
            implicitHeight: w.vertical ? icon.implicitHeight : app.implicitHeight
            BarApp {
                id: app
                visible: !w.vertical
                anchors.verticalCenter: parent.verticalCenter
                tone: w.tone; family: w.family; lower: w.voice === "words"
                weight: Theme.barStyle.ws === "blocks" ? Font.ExtraBold : Font.DemiBold
                size: Theme.barStyle.ws === "blocks" ? Theme.fontTitle + 2 : Theme.fontSize
            }
            IconImage {   // a vertical bar has no room for words: the app's icon
                id: icon
                visible: w.vertical
                anchors.horizontalCenter: parent.horizontalCenter
                implicitSize: 22
                source: Quickshell.iconPath(Sys.appEntry?.icon ?? "", "application-x-executable")
            }
        }
    }
    Component {
        id: clockC
        BarItem {
            id: clock
            readonly property string style: Theme.barStyle.clock      // plain | accent | display | block
            readonly property bool block: style === "block"
            vertical: w.vertical
            // block: an inverse accent segment the bar's full height, like tmux's status-right
            minHeight: block && !w.vertical ? w.thickness - 1 : 0
            radius: block ? 0 : Theme.radiusSmall
            pad: block ? 12 : 8
            color: block ? (active ? Qt.darker(Theme.accent, 1.15) : Theme.accent) : active ? pressedColor : hovered ? hover : "transparent"
            active: Calendar.open === true
            onPressed: Calendar.toggle()
            Text {
                text: w.vertical ? Sys.hours() + "\n" + Sys.minutes() : clock.style === "display" ? Sys.time() : Sys.clockText
                horizontalAlignment: Text.AlignHCenter
                lineHeight: w.vertical ? 0.85 : 1
                color: clock.block ? Theme.accentText : clock.style === "accent" ? Theme.accent : w.tone
                font {
                    family: clock.style === "display" ? Theme.displayFont : w.family
                    pixelSize: clock.style === "display" ? Math.round(Math.min(w.thickness * (w.vertical ? 0.42 : 0.62), 34)) : Theme.fontLabel + (w.words ? 0 : 1)
                    weight: clock.style === "display" ? Theme.displayWeight : clock.block ? Font.Bold : Font.Medium
                    letterSpacing: clock.style === "display" ? -1 : 0
                    features: { "tnum": 1 }
                }
            }
        }
    }
    Component {
        id: dateC
        BarItem {
            vertical: w.vertical
            active: Calendar.open === true
            onPressed: Calendar.toggle()
            Item {
                implicitWidth: w.vertical ? label.implicitHeight : label.implicitWidth
                implicitHeight: w.vertical ? label.implicitWidth : label.implicitHeight
                Text {
                    id: label
                    anchors.centerIn: parent
                    rotation: w.vertical ? 90 : 0
                    text: w.say(Qt.formatDateTime(Sys.now, w.vertical ? "dddd d MMMM" : "ddd d MMM"))
                    color: w.tone
                    font { family: w.family; pixelSize: Theme.fontLabel; weight: Font.DemiBold }
                }
            }
        }
    }
    Component {
        id: mediaC
        Indicator {
            shown: Sys.player !== null && Sys.track !== ""
            glyph: Sys.player?.isPlaying ? "\u{F03E4}" : "\u{F040A}"
            word: Sys.player?.isPlaying ? "play" : "paused"
            value: w.vertical ? "" : Sys.track.length > 38 ? Sys.track.slice(0, 37) + "…" : Sys.track
            showValue: !w.vertical
            onPressed: Sys.player?.togglePlaying()
            onScrolled: d => d > 0 ? Sys.player?.previous() : Sys.player?.next()
        }
    }
    Component {
        id: trayC
        BarTray { vertical: w.vertical; iconSize: w.words ? 14 : 16; tone: w.tone }
    }
    Component {
        id: keyboardC
        BarKeyboard { vertical: w.vertical; plain: w.words; tone: w.tone; family: w.family }
    }
    Component {
        id: bellC
        BarBell { vertical: w.vertical; tone: w.tone }
    }
    Component {
        id: statusC
        BarStatus { vertical: w.vertical; mode: w.voice; tone: w.tone; family: w.family }
    }
    Component {
        id: networkC
        Indicator {
            glyph: Sys.networkGlyph
            word: Sys.wired ? "eth" : !Sys.wifiOn ? "wifi off" : Sys.signal < 0 ? "offline" : "wifi"
            value: Sys.wired || Sys.signal < 0 ? "" : String(Sys.signal)
            ink: Sys.signal < 0 && !Sys.wired ? w.dim : w.tone
            active: ControlCenter.open && ControlCenter.expanded === "wifi"
            onPressed: ControlCenter.showSection("wifi")
        }
    }
    Component {
        id: btC
        Indicator {
            shown: Sys.adapter !== null
            glyph: !Sys.btOn ? "\u{F00B2}" : Sys.btLinked ? "\u{F00B1}" : "\u{F00AF}"
            word: Sys.btOn ? (Sys.btLinked ? "bt on" : "bt") : "bt off"
            ink: Sys.btOn ? w.tone : w.dim
            active: ControlCenter.open && ControlCenter.expanded === "bt"
            onPressed: ControlCenter.showSection("bt")
        }
    }
    Component {
        id: volumeC
        Indicator {
            glyph: Sys.volumeGlyph
            word: Sys.muted ? "muted" : "vol"
            value: Sys.muted ? "" : String(Math.round(Sys.volume * 100))
            ink: Sys.muted ? w.dim : w.tone
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            onPressed: button => button === Qt.MiddleButton ? Sys.toggleMute() : ControlCenter.showSection("out")
            onScrolled: d => Sys.nudgeVolume(d)
        }
    }
    Component {
        id: brightnessC
        Indicator {
            shown: Sys.brightness >= 0
            glyph: "\u{F00DF}"
            word: "lux"
            value: String(Sys.brightness)
            onPressed: ControlCenter.toggle()
            onScrolled: d => Sys.nudgeBrightness(d)
        }
    }
    Component {
        id: batteryC
        Indicator {
            shown: Sys.hasBattery
            glyph: Sys.batteryGlyph
            word: "bat"
            value: Sys.batteryPct + "%" + (Sys.charging ? "+" : "")
            showValue: true
            ink: Sys.batteryLow ? Theme.error : w.tone
            onPressed: SettingsApp.show("power")
        }
    }
    Component {
        id: profileC
        Indicator {
            readonly property int p: PowerMode.profile
            glyph: ["\u{F032A}", "\u{F0E0E}", "\u{F0E0F}"][p] ?? "\u{F0E0E}"
            word: ["quiet", "balanced", "perf"][p] ?? ""
            onPressed: PowerMode.set((p + 1) % 3)
        }
    }
    Component {
        id: cpuC
        Indicator {
            Component.onCompleted: BarStats.users++
            Component.onDestruction: BarStats.users--
            textual: true; glyph: "\u{F0EE0}"; word: "cpu"; value: Math.round(BarStats.cpu * 100) + "%"; showValue: true
            active: Sensors.open
            onPressed: Sensors.toggle()
        }
    }
    Component {
        id: memC
        Indicator {
            Component.onCompleted: BarStats.users++
            Component.onDestruction: BarStats.users--
            textual: true; glyph: "\u{F035B}"; word: "mem"; value: BarStats.memUsed.toFixed(1) + "G"; showValue: true
            active: Sensors.open
            onPressed: Sensors.toggle()
        }
    }
    Component {
        id: gpuC
        Indicator {
            Component.onCompleted: BarStats.users++
            Component.onDestruction: BarStats.users--
            shown: BarStats.gpu >= 0
            textual: true; glyph: "\u{F08AE}"; word: "gpu"; value: BarStats.gpu + "%"; showValue: true
            active: Sensors.open
            onPressed: Sensors.toggle()
        }
    }
    Component {
        id: recC
        BarItem {
            shown: Sys.recording
            vertical: w.vertical
            onPressed: Quickshell.execDetached(["record", "stop"])
            Rectangle {
                width: 10; height: 10; radius: 5
                color: Theme.error
                // a slow pulse while recording (still with reduced motion: it is the state)
                SequentialAnimation on opacity { running: Sys.recording && Theme.animate; loops: Animation.Infinite
                    NumberAnimation { to: 0.35; duration: 700 } NumberAnimation { to: 1; duration: 700 } }
            }
            Text { visible: !w.vertical; text: w.say("rec"); color: Theme.error; font { family: w.family; pixelSize: Theme.fontLabel; weight: Font.DemiBold } }
        }
    }
    Component {
        id: powerC
        Indicator {
            glyph: "\u{F0425}"
            word: "power"
            active: PowerMenu.open
            onPressed: PowerMenu.toggle()
        }
    }
}
