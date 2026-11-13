import QtQuick
import qs

// The battery: a gauge (words in word themes); hidden without a battery. Click opens Settings > Power.
BarItem {
    required property var bar
    actions: bar.cfg
    shown: Sys.hasBattery
    vertical: bar.vertical
    tip: "Battery " + Sys.batteryPct + "%" + (Sys.charging ? ", charging" : "")
    onPressed: SettingsApp.show("power")
    BarBattery { visible: !bar.words; tone: bar.tone; family: bar.family; vertical: bar.vertical }
    Text {
        visible: bar.words
        text: bar.say("bat" + (Config.bar.batteryPercent === "off" ? "" : (bar.vertical ? "\n" : " ") + Sys.batteryPct + "%" + (Sys.charging ? "+" : "")))
        horizontalAlignment: Text.AlignHCenter
        color: Sys.batteryLow ? Theme.error : bar.tone
        font { family: bar.family; pixelSize: Theme.fontLabel; letterSpacing: bar.voice === "caps" ? 1 : 0; features: { "tnum": 1 } }
    }
}
