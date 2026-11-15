import Quickshell
import QtQuick
import QtQuick.Layouts

// A bar item's own small panel: one Control Center section (or a few) in the panel frame, beside the item.
// It has its own PanelState, so folding a list or closing it never touches the Control Center.
//   Flyout { id: f; name: "volume"; ControlCenterSliders { host: f.host; parts: ["sound", "mic"] } }
Scope {
    id: flyout
    property string name                         // CursorPopup name: the bar item's `opens`
    property string fixed: ""                    // the one list always folded out ("wifi", "bt")
    default property alias content: body.data
    readonly property PanelState host: PanelState { popup: popup; fixed: flyout.fixed }
    readonly property bool open: popup.open
    signal opened()
    signal closed()
    function toggle() { popup.toggle() }
    function hide() { popup.hide() }

    CursorPopup {
        id: popup
        name: flyout.name
        placement: "topRight"
        boxWidth: ControlCenter.customWidth
        boxHeight: body.implicitHeight + ControlCenter.pad * 2
        onOpened: { flyout.host.reset(); flyout.opened() }
        onClosed: flyout.closed()

        Glass {
            anchors.fill: parent
            strong: true
            radius: Theme.radiusPanel
            ColumnLayout {
                id: body
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: ControlCenter.pad }
                spacing: ControlCenter.gap
            }
        }
    }
}
