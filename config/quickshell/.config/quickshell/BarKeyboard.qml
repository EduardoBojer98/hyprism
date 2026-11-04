import QtQuick

// Keyboard layout: a small keycap (or plain text in word themes); click lists the layouts, scroll switches.
BarItem {
    id: kb
    property bool plain: false
    property color tone: Theme.text
    property string family: Theme.font
    shown: Keyboard.layouts.length > 1
    active: Keyboard.open
    onPressed: Keyboard.toggle()
    onScrolled: d => Keyboard.use((Keyboard.active + (d > 0 ? 1 : Keyboard.layouts.length - 1)) % Keyboard.layouts.length)
    Text {
        visible: kb.plain
        text: Keyboard.short.toLowerCase()
        color: kb.tone
        font { family: kb.family; pixelSize: Theme.fontLabel }
    }
    Rectangle {
        visible: !kb.plain
        width: Math.max(22, cap.implicitWidth + 8); height: 15
        radius: Math.min(4, Theme.radiusSmall)
        color: "transparent"
        border { color: Qt.alpha(kb.tone, 0.5); width: 1 }
        Text {
            id: cap
            anchors.centerIn: parent
            text: Keyboard.short
            color: kb.tone
            font { family: Theme.font; pixelSize: 9; weight: Font.Bold; letterSpacing: 0.3 }
        }
    }
}
