import QtQuick

// A status icon inside a bar capsule.
Text {
    property string glyph
    property color tone: Theme.text
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    text: glyph
    color: tone
    font { family: Theme.iconFont; pixelSize: 16 }
}
