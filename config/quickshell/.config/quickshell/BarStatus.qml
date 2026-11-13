import Quickshell
import QtQuick

// Network, Bluetooth, sound and battery in one item that opens the Control Center (scroll: volume).
//   mode "icons"  drawn glyphs; the battery as a small drawn cell (most themes)
//   mode "words"  lowercase words and numbers: "wifi 82  vol 45  bat 72%" (Monolith)
//   mode "caps"   upper-case readout: "NET 82  VOL 45  BAT 72"
//   mode "mixed"  glyphs, each with its number: "<wifi> 82  <vol> 45  <bat> 72%" (Monolith, Console)
BarItem {
    id: st
    property string mode: "icons"
    property color tone: Theme.text
    property int glyphSize: 15
    property string family: Theme.font
    active: ControlCenter.open
    opens: "controlcenter"
    onPressed: ControlCenter.toggle()
    onScrolled: d => Sys.nudgeVolume(d)
    // mixed: a number sits close to its glyph; the next glyph keeps its distance (leftPadding)
    spacing: mode === "icons" ? (vertical ? 10 : 12) : mode === "mixed" ? (vertical ? 10 : 4) : (vertical ? 4 : 16)

    readonly property bool words: mode === "words" || mode === "caps"
    readonly property bool mixed: mode === "mixed"
    readonly property bool caps: mode === "caps"
    function say(s) { return caps ? s.toUpperCase() : s }
    readonly property string netText: Sys.wired ? say("eth") : !Sys.wifiOn ? say("wifi off") : Sys.signal < 0 ? say("offline") : say("wifi ") + Sys.signal
    readonly property string volText: Sys.muted ? say("muted") : say("vol ") + Math.round(Sys.volume * 100)
    readonly property string batText: say("bat ") + Sys.batteryPct + "%" + (Sys.charging ? "+" : "")

    // ---- modes that are on: recording (click the dot to stop), Do Not Disturb, Caffeine ----
    Rectangle {
        visible: Sys.recording
        width: 10; height: 10; radius: 5
        color: Theme.error
        SequentialAnimation on opacity { running: Sys.recording && Theme.animate; loops: Animation.Infinite; NumberAnimation { to: 0.35; duration: 700 } NumberAnimation { to: 1; duration: 700 } }
        MouseArea { anchors.fill: parent; anchors.margins: -6; Accessible.role: Accessible.Button; Accessible.name: "Stop recording"; Accessible.onPressAction: Quickshell.execDetached(["record", "stop"]); cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["record", "stop"]) }
    }
    Text { visible: Notifications.dnd; text: "\u{F009B}"; color: Theme.barDim; font { family: Theme.iconFont; pixelSize: st.glyphSize - 1 } }
    Text { visible: Caffeine.active; text: "\u{F0176}"; color: Theme.barDim; font { family: Theme.iconFont; pixelSize: st.glyphSize - 1 } }

    // ---- words ----
    Repeater {
        model: st.words ? [st.netText, Sys.btOn ? (Sys.btLinked ? st.say("bt on") : st.say("bt")) : "", st.volText, Sys.hasBattery && Config.bar.batteryPercent !== "off" ? st.batText : ""].filter(x => x) : []
        Text {
            required property string modelData
            text: modelData
            color: modelData.indexOf("%") > 0 && Sys.batteryLow ? Theme.error : st.tone
            font { family: st.family; pixelSize: Theme.fontLabel; letterSpacing: st.caps ? 1 : 0; features: { "tnum": 1 } }
        }
    }

    // ---- icons ----
    Text { visible: !st.words; text: Sys.networkGlyph; color: Sys.signal < 0 && !Sys.wired ? Theme.barDim : st.tone; font { family: Theme.iconFont; pixelSize: st.glyphSize } }
    Num { visible: st.mixed && !st.vertical && !Sys.wired && Sys.signal >= 0; text: Sys.signal }
    Text { visible: !st.words && Sys.btOn; leftPadding: st.mixed && !st.vertical ? 8 : 0; text: Sys.btLinked ? "\u{F00B1}" : "\u{F00AF}"; color: Sys.btLinked ? st.tone : Theme.barDim; font { family: Theme.iconFont; pixelSize: st.glyphSize } }
    Text { visible: !st.words; leftPadding: st.mixed && !st.vertical ? 8 : 0; text: Sys.volumeGlyph; color: Sys.muted ? Theme.barDim : st.tone; font { family: Theme.iconFont; pixelSize: st.glyphSize } }
    Num { visible: st.mixed && !st.vertical && !Sys.muted; text: Math.round(Sys.volume * 100) }
    BarBattery {   // a gap before it in mixed mode, like the other glyph + value pairs
        visible: !st.words && Sys.hasBattery
        leftPadding: st.mixed && !st.vertical ? 8 : 0
        tone: st.tone; family: st.family; vertical: st.vertical
    }

    component Num: Text {   // a number beside its glyph (mixed mode)
        color: st.tone
        font { family: st.family; pixelSize: Theme.fontLabel; features: { "tnum": 1 } }
    }
}
