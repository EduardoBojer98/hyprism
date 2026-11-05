import QtQuick

// "More below": the bottom edge of a scrolling list fades into its ground, shown only while there is more.
//   MoreBelow { flick: page; ground: Theme.glassStrong }   (a sibling over the Flickable, anchored to its bottom)
Rectangle {
    required property Flickable flick
    property color ground: Theme.glassStrong
    height: 32
    visible: flick.contentY < flick.contentHeight - flick.height - 1
    gradient: Gradient {
        GradientStop { position: 0; color: Qt.alpha(ground, 0) }
        GradientStop { position: 1; color: ground }
    }
}
