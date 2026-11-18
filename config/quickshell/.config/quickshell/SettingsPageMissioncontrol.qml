import QtQuick
import QtQuick.Layouts

// Mission Control: the overview of open windows with the workspaces along the top (Config.missionControl).
ColumnLayout {
    id: page
    spacing: 20

    SettingGroup {
        title: "Workspaces along the top"
        SettingRow {
            label: "Screens"
            hint: Config.missionControl.screens === "this" ? "Only the workspaces of the screen it opens on"
                                                           : "Every screen's workspaces, side by side, each under its screen's name"
            ConfigChoice { section: "missionControl"; key: "screens"; values: ["all", "this"]; labels: ["Every screen", "This screen"] }
        }
        SettingRow {
            label: "Click a workspace to"
            hint: Config.missionControl.click === "browse" ? "Show its windows; a second click, or a click on a window, goes there"
                                                          : "Go to it and close Mission Control"
            ConfigChoice { section: "missionControl"; key: "click"; values: ["switch", "browse"]; labels: ["Go there", "See its windows"] }
        }
        SettingRow {
            label: "New workspace tile"
            hint: "An empty workspace at the end of the row: click it to start one, or drop a window on it"
            ConfigToggle { section: "missionControl"; key: "newTile" }
        }
        SettingRow {
            label: "Picture size"
            hint: "Smaller when there are too many to fit"
            ConfigChoice { section: "missionControl"; key: "size"; values: ["small", "medium", "large"]; labels: ["Small", "Medium", "Large"] }
        }
    }

    Text {
        Layout.fillWidth: true
        text: "Open it with Super+W, a three-finger swipe up, or a hot corner. Keys: arrows pick a window, Enter goes to it, 1–9 go to a workspace, Escape closes."
        color: Theme.subtext
        wrapMode: Text.Wrap
        font { family: Theme.font; pixelSize: Theme.fontCaption }
    }

    ResetGroup { sections: ["missionControl"] }
}
