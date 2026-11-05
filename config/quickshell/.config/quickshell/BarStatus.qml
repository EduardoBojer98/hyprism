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
        MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["record", "stop"]) }
    }
    Text { visible: Notifications.dnd; text: "\u{F009B}"; color: Theme.subtext; font { family: Theme.iconFont; pixelSize: st.glyphSize - 1 } }
    Text { visible: Caffeine.active; text: "\u{F0176}"; color: Theme.subtext; font { family: Theme.iconFont; pixelSize: st.glyphSize - 1 } }

    // ---- words ----
    Repeater {
        model: st.words ? [st.netText, Sys.btOn ? (Sys.btLinked ? st.say("bt on") : st.say("bt")) : "", st.volText, Sys.hasBattery ? st.batText : ""].filter(x => x) : []
        Text {
            required property string modelData
            text: modelData
            color: modelData.indexOf("%") > 0 && Sys.batteryLow ? Theme.error : st.tone
            font { family: st.family; pixelSize: Theme.fontLabel; letterSpacing: st.caps ? 1 : 0; features: { "tnum": 1 } }
        }
    }

    // ---- icons ----
    Text { visible: !st.words; text: Sys.networkGlyph; color: Sys.signal < 0 && !Sys.wired ? Theme.muted : st.tone; font { family: Theme.iconFont; pixelSize: st.glyphSize } }
    Num { visible: st.mixed && !st.vertical && !Sys.wired && Sys.signal >= 0; text: Sys.signal }
    Text { visible: !st.words && Sys.btOn; leftPadding: st.mixed && !st.vertical ? 8 : 0; text: Sys.btLinked ? "\u{F00B1}" : "\u{F00AF}"; color: Sys.btLinked ? st.tone : Theme.subtext; font { family: Theme.iconFont; pixelSize: st.glyphSize } }
    Text { visible: !st.words; leftPadding: st.mixed && !st.vertical ? 8 : 0; text: Sys.volumeGlyph; color: Sys.muted ? Theme.subtext : st.tone; font { family: Theme.iconFont; pixelSize: st.glyphSize } }
    Num { visible: st.mixed && !st.vertical && !Sys.muted; text: Math.round(Sys.volume * 100) }
    Item {   // battery cell (a gap before it in mixed mode): outline, fill to the charge, nub; ok colour while charging, error when low
        visible: !st.words && Sys.hasBattery
        readonly property int gap: st.mixed && !st.vertical ? 8 : 0
        implicitWidth: 24 + gap; implicitHeight: 12
        readonly property color fillTone: Sys.batteryLow ? Theme.error : Sys.charging ? Theme.success : st.tone
        Rectangle {
            id: cellBody
            x: parent.gap
            width: 21; height: 12; radius: Math.min(3.5, Theme.radiusSmall)
            color: "transparent"
            border { color: Qt.alpha(st.tone, 0.5); width: 1 }
            Rectangle {
                x: 2; y: 2
                width: Math.max(2, (parent.width - 4) * Math.min(1, Sys.batteryPct / 100)); height: parent.height - 4
                radius: Math.max(0, parent.radius - 1.5)
                color: parent.parent.fillTone
            }
        }
        Rectangle { anchors { left: cellBody.right; leftMargin: 1; verticalCenter: cellBody.verticalCenter } width: 2; height: 4; radius: 1; color: Qt.alpha(st.tone, 0.5) }
    }
    Num { visible: st.mixed && !st.vertical && Sys.hasBattery; text: Sys.batteryPct + "%"; color: Sys.batteryLow ? Theme.error : st.tone }

    component Num: Text {   // a number beside its glyph (mixed mode)
        color: st.tone
        font { family: st.family; pixelSize: Theme.fontLabel; features: { "tnum": 1 } }
    }
}
