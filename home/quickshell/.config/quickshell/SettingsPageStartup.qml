import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// Startup Apps: apps opened when you log in to Hyprland (not KDE). Saved as desktop entry ids in
// settings.json (startup.apps); ~/.local/bin/startup-apps opens them from Hyprland's autostart.
ColumnLayout {
    id: page
    spacing: 20

    property string query: ""
    readonly property var chosen: Config.startup.apps
    readonly property var matches: {
        const q = query.trim().toLowerCase()
        if (!q) return []
        return DesktopEntries.applications.values
            .filter(e => !e.noDisplay && !chosen.includes(e.id) && (e.name.toLowerCase().includes(q) || e.id.toLowerCase().includes(q)))
            .sort((a, b) => a.name.localeCompare(b.name))
            .slice(0, 8)
    }
    function add(id) { Config.set("startup", "apps", chosen.concat([id])); query = ""; search.text = "" }
    function remove(id) { Config.set("startup", "apps", chosen.filter(x => x !== id)) }

    SettingGroup {
        title: "Open at login"
        Text {
            visible: page.chosen.length === 0
            Layout.fillWidth: true
            Layout.margins: 16
            text: "No apps yet. Search below to add one."
            color: Theme.muted
            font { family: Theme.font; pixelSize: Theme.fontLabel }
        }
        Repeater {
            model: page.chosen
            AppRow {
                required property string modelData
                required property int index
                entry: DesktopEntries.byId(modelData)
                fallback: modelData
                first: index === 0
                action: "Remove"
                onTriggered: page.remove(modelData)
            }
        }
    }

    SettingGroup {
        title: "Add an app"
        SettingRow {
            label: "Search"
            hint: "Type part of the app's name"
            TextField {
                id: search
                width: 220
                placeholder: "e.g. Discord"
                onTextChanged: page.query = text
                onAccepted: if (page.matches.length) page.add(page.matches[0].id)
            }
        }
        Repeater {
            model: page.matches
            AppRow {
                required property var modelData
                entry: modelData
                action: "Add"
                onTriggered: page.add(modelData.id)
            }
        }
    }

    Text {
        Layout.fillWidth: true
        text: "Apps open in this order a few seconds after login. KDE Plasma keeps its own startup list."
        color: Theme.muted
        wrapMode: Text.Wrap
        font { family: Theme.font; pixelSize: Theme.fontCaption }
    }

    ResetGroup { sections: ["startup"] }

    // icon, name, and a button on the right; a hairline above every row but the first
    component AppRow: Item {
        id: row
        property var entry: null
        property string fallback: ""
        property bool first: false
        property string action
        signal triggered()
        Layout.fillWidth: true
        implicitHeight: 46
        Rectangle { visible: !row.first; anchors { left: parent.left; right: parent.right; leftMargin: 16 } height: 1; color: Theme.stroke }
        IconImage {
            id: icon
            anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
            implicitSize: 24
            source: Quickshell.iconPath(row.entry?.icon ?? "", "application-x-executable")
        }
        Text {
            anchors { left: icon.right; leftMargin: 12; right: btn.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
            text: row.entry?.name ?? (row.fallback + " (not installed)")
            elide: Text.ElideRight
            color: row.entry ? Theme.text : Theme.muted
            font { family: Theme.font; pixelSize: Theme.fontSize }
        }
        PillButton {
            id: btn
            anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
            text: row.action
            primary: row.action === "Add"
            onClicked: row.triggered()
        }
    }
}
