import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Control Center building block (used by ControlCenter.qml and its parts).
// Small heading inside a dropdown ("Known networks", "Apps"): in capitals in the bento layout, lower-case mono in hud
Text {
    Layout.fillWidth: true
    Layout.leftMargin: 6
    Layout.topMargin: 6
    Layout.bottomMargin: 2
    color: ControlCenter.hud ? Theme.accent2 : Theme.muted
    font { family: ControlCenter.hud ? Theme.monoFont : Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold
           capitalization: ControlCenter.bento ? Font.AllUppercase : ControlCenter.hud ? Font.AllLowercase : Font.MixedCase }
}
