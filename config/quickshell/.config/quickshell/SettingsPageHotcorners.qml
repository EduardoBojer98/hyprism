import QtQuick
import QtQuick.Layouts

// Hot Corners: what pushing the pointer into each screen corner does (Config.hotCorners).
ColumnLayout {
    id: page
    spacing: 20

    readonly property var names: HotCornerActions.list.map(a => a.name)

    SettingGroup {
        title: "Push the pointer into a corner to…"
        Repeater {
            model: [["topLeft", "Top left"], ["topRight", "Top right"], ["bottomLeft", "Bottom left"], ["bottomRight", "Bottom right"]]
            SettingRow {
                required property var modelData
                label: modelData[1]
                Dropdown {
                    width: 200
                    options: page.names
                    current: HotCornerActions.name(Config.hotCorners[modelData[0]])
                    onPicked: v => Config.set("hotCorners", modelData[0], HotCornerActions.list[page.names.indexOf(v)].id)
                }
            }
        }
    }

    Text {
        Layout.fillWidth: true
        text: "Works on every screen. Corners next to another screen only fire where the pointer can stop."
        color: Theme.subtext
        wrapMode: Text.Wrap
        font { family: Theme.font; pixelSize: Theme.fontCaption }
    }

    ResetGroup { sections: ["hotCorners"] }
}
