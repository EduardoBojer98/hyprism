import QtQuick
import QtQuick.Layouts

// Window Behaviour: how Hyprland lays out new windows, which window gets focus, and moving and
// resizing (Config.windows; ThemeSync applies it live and saves
// hypr/settings/windows.lua).
ColumnLayout {
    id: page
    spacing: 20

    readonly property string layout: Config.windows.layout

    SettingGroup {
        title: "Layout"
        SettingRow {
            label: "Arrange windows"
            hint: page.layout === "dwindle" ? "Each new window splits the one you're in, in half"
                : page.layout === "master" ? "One main window, the others stacked beside it"
                : "Windows sit in columns side by side; scroll to the ones off screen"
            ConfigChoice { section: "windows"; key: "layout"; values: ["dwindle", "master", "scrolling"]; labels: ["Split", "Main + stack", "Scrolling"] }
        }
        SettingRow {
            visible: page.layout === "dwindle"
            label: "New windows open"
            ConfigChoice { section: "windows"; key: "newSplit"; values: [0, 1, 2]; labels: ["Toward the mouse", "Left or above", "Right or below"] }
        }
        SettingRow {
            visible: page.layout === "dwindle"
            label: "Split where the mouse is"
            hint: "Mouse in the top half of a window: the new one goes above it, and so on"
            ConfigToggle { section: "windows"; key: "smartSplit" }
        }
        SettingRow {
            visible: page.layout === "master"
            label: "A new window becomes"
            ConfigChoice { section: "windows"; key: "masterNew"; values: ["master", "slave"]; labels: ["The main one", "Part of the stack"] }
        }
        SettingRow {
            visible: page.layout === "master"
            label: "Main window sits"
            ConfigChoice { section: "windows"; key: "masterSide"; values: ["left", "right", "top", "center"]; labels: ["Left", "Right", "Top", "Centre"] }
        }
        SettingRow {
            visible: page.layout === "scrolling"
            label: "Column width"
            hint: "Share of the screen each new column takes"
            ConfigSlider { section: "windows"; key: "columnWidth"; from: 0.3; to: 1; step: 0.05; format: v => Math.round(v * 100) + "%" }
        }
    }

    SettingGroup {
        title: "Focus"
        SettingRow {
            label: "Focus follows the mouse"
            hint: "Off: click a window to use it"
            ConfigToggle { section: "windows"; key: "followMouse" }
        }
        SettingRow {
            label: "Let apps bring themselves forward"
            hint: "For example a link opening in the browser on another desktop takes you there"
            ConfigToggle { section: "windows"; key: "focusOnActivate" }
        }
        SettingRow {
            label: "Move the pointer to the focused window"
            hint: "When you switch windows from the keyboard"
            ConfigToggle { section: "windows"; key: "warpCursor" }
        }
        SettingRow {
            label: "Desktop shortcut goes back"
            hint: "Pressing the shortcut of the desktop you're on returns to the last one"
            ConfigToggle { section: "windows"; key: "backAndForth" }
        }
    }

    SettingGroup {
        title: "Moving and resizing"
        SettingRow {
            label: "Resize by dragging a window's edge"
            hint: "Super + right-drag works anywhere in the window either way"
            ConfigToggle { section: "windows"; key: "resizeOnBorder" }
        }
        SettingRow {
            label: "Floating windows snap"
            hint: "To the screen edges and to each other"
            ConfigToggle { section: "windows"; key: "snap" }
        }
        SettingRow {
            label: "Hide the pointer while typing"
            ConfigToggle { section: "windows"; key: "hideCursorTyping" }
        }
    }

    ResetGroup {
        sections: ["windows"]
        keys: ["layout", "newSplit", "smartSplit", "masterNew", "masterSide", "columnWidth", "followMouse", "focusOnActivate",
               "warpCursor", "backAndForth", "resizeOnBorder", "snap", "hideCursorTyping"]
    }
}
