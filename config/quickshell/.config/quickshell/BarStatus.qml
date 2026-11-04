import QtQuick

// Network, Bluetooth, sound and battery in one item that opens the Control Center (scroll: volume).
//   mode "icons"  drawn glyphs; the battery as a small drawn cell (most rices)
//   mode "text"   lowercase words and numbers: "wifi 82  vol 45  bat 72%" (Monolith, Mist)
//   mode "caps"   upper-case readout: "NET 82  VOL 45  BAT 72" (Console, Noir)
BarItem {
    id: st
    property string mode: "icons"
    property color tone: Theme.text
    property int glyphSize: 15
    property string family: Theme.font
    active: ControlCenter.open
    onPressed: ControlCenter.toggle()
    onScrolled: d => Sys.nudgeVolume(d)
    spacing: mode === "icons" ? (vertical ? 10 : 12) : (vertical ? 4 : 16)

    readonly property bool words: mode !== "icons"
    readonly property bool caps: mode === "caps"
    function w(s) { return caps ? s.toUpperCase() : s }
    readonly property string netText: Sys.wired ? w("eth") : !Sys.wifiOn ? w("wifi off") : Sys.signal < 0 ? w("offline") : w("wifi ") + Sys.signal
    readonly property string volText: Sys.muted ? w("muted") : w("vol ") + Math.round(Sys.volume * 100)
    readonly property string batText: w("bat ") + Sys.batteryPct + "%" + (Sys.charging ? "+" : "")

    // ---- words ----
    Repeater {
        model: st.words ? [st.netText, Sys.btOn ? (Sys.btLinked ? st.w("bt on") : st.w("bt")) : "", st.volText, Sys.hasBattery ? st.batText : ""].filter(x => x) : []
        Text {
            required property string modelData
            text: modelData
            color: modelData.indexOf("%") > 0 && Sys.batteryLow ? Theme.error : st.tone
            font { family: st.family; pixelSize: Theme.fontLabel; letterSpacing: st.caps ? 1 : 0; features: { "tnum": 1 } }
        }
    }

    // ---- icons ----
    Text { visible: !st.words; text: Sys.networkGlyph; color: Sys.signal < 0 && !Sys.wired ? Theme.muted : st.tone; font { family: Theme.iconFont; pixelSize: st.glyphSize } }
    Text { visible: !st.words && Sys.btOn; text: Sys.btLinked ? "\u{F00B1}" : "\u{F00AF}"; color: Sys.btLinked ? st.tone : Theme.subtext; font { family: Theme.iconFont; pixelSize: st.glyphSize } }
    Text { visible: !st.words; text: Sys.volumeGlyph; color: Sys.muted ? Theme.subtext : st.tone; font { family: Theme.iconFont; pixelSize: st.glyphSize } }
    Item {   // battery cell: outline, fill to the charge, nub; ok colour while charging, error when low
        visible: !st.words && Sys.hasBattery
        implicitWidth: 24; implicitHeight: 12
        readonly property color fillTone: Sys.batteryLow ? Theme.error : Sys.charging ? Theme.success : st.tone
        Rectangle {
            id: cellBody
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
}
