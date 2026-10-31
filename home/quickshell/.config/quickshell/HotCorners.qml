import Quickshell
import Quickshell.Wayland
import QtQuick

// Hot corners: push the pointer into a screen corner to run an action (Config.hotCorners, set in
// Settings > Desktop > Hot Corners). Each corner is a tiny invisible window on top of everything;
// it fires once per visit, after a short pause so passing through doesn't trigger it.
Scope {
    id: root

    required property ShellScreen screen

    Variants {
        model: ["topLeft", "topRight", "bottomLeft", "bottomRight"].filter(c => Config.hotCorners[c] !== "")

        PanelWindow {
            id: corner
            required property string modelData
            screen: root.screen
            anchors {
                top: modelData.startsWith("top"); bottom: modelData.startsWith("bottom")
                left: modelData.endsWith("Left"); right: modelData.endsWith("Right")
            }
            implicitWidth: 2
            implicitHeight: 2
            exclusionMode: ExclusionMode.Ignore   // the real corner, not below the bar
            color: "transparent"
            WlrLayershell.namespace: "qs-hotcorner"
            WlrLayershell.layer: WlrLayer.Overlay

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onContainsMouseChanged: if (containsMouse) dwell.restart(); else dwell.stop()
                Timer { id: dwell; interval: 150; onTriggered: HotCornerActions.run(Config.hotCorners[corner.modelData]) }
            }
        }
    }
}
