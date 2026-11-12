import QtQuick

// One clickable bar item in any theme: its content in a row (or a column on a vertical bar), a
// hover highlight in the theme's corner radius, brighter while its panel is open, a small press.
// A click records where it happened (Anchor), so the panel it opens appears beside it.
Rectangle {
    id: item
    default property alias content: grid.data
    property alias spacing: grid.spacing
    property bool vertical: false
    property bool active: false
    property bool interactive: true
    property bool shown: true          // false: nothing to show, the bar leaves no gap
    readonly property bool hovered: area.containsMouse
    property int pad: vertical ? 6 : 8
    property color hover: Qt.alpha(Theme.barInk, Theme.light ? 0.10 : 0.11)
    property color pressedColor: Qt.alpha(Theme.barInk, Theme.light ? 0.16 : 0.17)
    property alias acceptedButtons: area.acceptedButtons
    property string edge: Theme.barEdge     // the screen edge this item sits on (the dock sets its own)
    property var origin: undefined          // its window's top-left on the screen, when not at the edge (Anchor)
    property string opens: ""               // the panel it opens (CursorPopup name): from a shortcut it opens here too
    Component.onCompleted: if (opens !== "") Anchor.register(opens, item)
    Component.onDestruction: if (opens !== "") Anchor.unregister(item)
    property var actions: null              // your settings for this item (BarItems.settings): click, rightClick, scroll, tooltip
    property string tip: ""                 // one line shown on hover
    signal pressed(int button)
    signal scrolled(int delta)
    property string accessibleName: ""      // for a screen reader, when the tip is empty

    // what a click does, from the mouse or the keyboard
    function activate(button) {
        Anchor.take(item, item.edge, item.origin)
        const mine = button === Qt.RightButton ? item.actions?.rightClick : item.actions?.click
        if (!BarActions.run(mine)) item.pressed(button)
    }

    // keyboard (BarFocus): Tab or arrows along the bar, Enter / Space activates, Escape leaves
    activeFocusOnTab: interactive && shown
    function go(forward) { item.nextItemInFocusChain(forward).forceActiveFocus() }
    Keys.onPressed: e => {
        const next = item.vertical ? Qt.Key_Down : Qt.Key_Right, prev = item.vertical ? Qt.Key_Up : Qt.Key_Left
        if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) { item.activate(Qt.LeftButton); BarFocus.leave() }
        else if (e.key === Qt.Key_Escape) BarFocus.leave()
        else if (e.key === next) item.go(true)
        else if (e.key === prev) item.go(false)
        else return
        e.accepted = true
    }
    FocusRing {}
    Accessible.role: Accessible.Button
    Accessible.name: item.accessibleName !== "" ? item.accessibleName : item.tip
    Accessible.focusable: true
    Accessible.onPressAction: item.activate(Qt.LeftButton)

    visible: shown
    implicitWidth: vertical ? Math.max(grid.implicitWidth + pad * 2, 28) : grid.implicitWidth + pad * 2
    property real minHeight: 0          // e.g. a block that fills the bar's height
    implicitHeight: vertical ? grid.implicitHeight + pad * 2 : Math.max(grid.implicitHeight + 6, 24, minHeight)
    radius: Theme.radiusSmall
    color: active ? pressedColor : interactive && area.containsMouse ? hover : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    scale: area.pressed ? Theme.pressScale : 1
    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }

    Grid {
        id: grid
        anchors.centerIn: parent
        // one row or one column: only `columns` is set (setting rows too adds spacing for empty rows)
        columns: item.vertical ? 1 : Math.max(1, visibleChildren.filter(c => c.width > 0).length)   // a Repeater is a visible child too: it must not add an empty column
        spacing: 6
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter
    }
    MouseArea {
        id: area
        anchors.fill: parent
        z: -1
        enabled: item.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: typeof item.actions?.rightClick === "string" ? Qt.LeftButton | Qt.RightButton : Qt.LeftButton
        // your own action for this item wins (BarActions); otherwise the item does its own thing
        onClicked: mouse => item.activate(mouse.button)
        onWheel: wheel => {
            const d = wheel.angleDelta.y > 0 ? 1 : -1
            if (!BarActions.run(item.actions?.scroll, d)) item.scrolled(d)
        }
    }
    // the hint exists only while the pointer rests on the item (no window per item otherwise)
    Loader {
        anchors.fill: parent
        active: item.hovered && item.tip !== "" && (item.actions?.tooltip ?? true) !== false
        sourceComponent: ToolTipText { shown: true; text: item.tip }
    }
}
