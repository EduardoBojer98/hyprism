import QtQuick
import QtQuick.Layouts

// Appearance & Themes: the knobs every shell surface derives its tokens from (Theme.qml).
// Applied live; the accent and corners also reach window borders, the lock screen, GTK apps and
// (with "Terminal colours") Ghostty. A preview of the desktop sits on top.
ColumnLayout {
    id: page
    spacing: 20

    readonly property var a: Config.appearance
    readonly property var swatches: ["theme", "blue", "lavender", "mauve", "pink", "red", "peach", "yellow", "champagne", "green", "mint", "teal", "sky", "silver", "custom"]
    // the three bundled UI fonts first, then every other installed family
    readonly property var fonts: {
        const own = ["Inter", "Cantarell", "Noto Sans"]
        return own.concat(Qt.fontFamilies().filter(f => !own.includes(f) && !/Nerd Font|Emoji|Symbols/.test(f)))
    }
    function luma(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }

    // ---- preview: the wallpaper with a bar, a window and a dock drawn in the current tokens -------
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 190
        radius: Theme.radiusLarge
        color: Theme.base
        clip: true
        border { color: Theme.stroke; width: 1 }

        Image {
            anchors.fill: parent
            source: Wallpapers.current ? "file://" + Wallpapers.current : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 900
            asynchronous: true
        }
        Rectangle {   // menu bar
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: 20
            color: Theme.glass
            Text {
                anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                text: "\u{F08C7}   Files"
                color: Theme.text
                font { family: Theme.font; pixelSize: 10; weight: Font.DemiBold }
            }
            Text {
                anchors.centerIn: parent
                text: Qt.formatDateTime(NightLight.now, "ddd d MMM  HH:mm")
                color: Theme.text
                font { family: Theme.font; pixelSize: 10 }
            }
        }
        Rectangle {   // focused window: the border is the gradient showing around the inset body
            id: frame
            readonly property int inset: Math.min(14, page.a.gaps)
            x: 24 + inset; y: 20 + inset
            width: Math.min(300, parent.width * 0.55); height: parent.height - y - 40
            radius: Theme.radius + page.a.borderSize
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: page.a.border === "rainbow" ? "#ed8796" : Theme.accent }
                GradientStop { position: 0.35; color: page.a.border === "rainbow" ? "#eed49f" : Theme.accent }
                GradientStop { position: 0.7; color: page.a.border === "rainbow" ? "#8bd5ca" : Qt.alpha(Theme.accent, 0.6) }
                GradientStop { position: 1; color: page.a.border === "rainbow" ? "#c6a0f6" : Qt.alpha(Theme.accent2, 0.6) }
            }
            Rectangle {
                anchors { fill: parent; margins: page.a.borderSize }
                radius: Theme.radius
                color: Theme.glassStrong
                Column {
                    anchors { fill: parent; margins: 14 }
                    spacing: 6
                    Text { text: "Graphite Glass"; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontTitle; weight: Font.DemiBold } }
                    Text {
                        width: parent.width
                        text: "Every panel, menu and window border follows these settings."
                        wrapMode: Text.Wrap
                        color: Theme.subtext
                        font { family: Theme.font; pixelSize: Theme.fontLabel }
                    }
                    Row {
                        spacing: 8
                        topPadding: 4
                        Rectangle {
                            width: btn.implicitWidth + 20; height: 24; radius: Math.min(12, Theme.radiusSmall + 4)
                            color: Theme.accent
                            Text { id: btn; anchors.centerIn: parent; text: "Button"; color: Theme.accentText; font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.Medium } }
                        }
                        Toggle { checked: true; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
            }
        }
        Rectangle {   // dock
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 8 }
            width: dockIcons.implicitWidth + 14; height: 28
            radius: Theme.radiusLarge
            color: Theme.glass
            border { color: Theme.stroke; width: 1 }
            Row {
                id: dockIcons
                anchors.centerIn: parent
                spacing: 6
                Repeater {
                    model: [Theme.accent, Theme.accents.peach, Theme.accents.green, Theme.accents.sky, Theme.text]
                    Rectangle { required property color modelData; width: 18; height: 18; radius: Math.round(5 * Theme.radiusScale); color: modelData; opacity: 0.9 }
                }
            }
        }
    }

    SettingGroup {
        title: "Theme"
        SettingRow {
            label: "Appearance"
            hint: page.a.mode === "auto" ? (Theme.light ? "Light now, dark after sunset" : "Dark now, light after sunrise") + " (from the weather location)"
                                         : "Light or dark glass for the bar, panels and Settings"
            ConfigChoice { section: "appearance"; key: "mode"; values: ["light", "dark", "auto"]; labels: ["Light", "Dark", "Auto"] }
        }
        Flow {   // theme gallery: each card is a tiny window in that theme's colours (in the current mode)
            id: gallery
            readonly property int cols: Math.max(2, Math.floor((width + spacing) / (110 + spacing)))
            readonly property real cardWidth: (width - spacing * (cols - 1)) / cols
            Layout.fillWidth: true
            Layout.margins: 14
            Layout.topMargin: 2
            spacing: 10
            Repeater {
                model: Theme.themeIds
                Item {
                    id: card
                    required property string modelData
                    readonly property var t: Theme.themes[modelData]
                    readonly property var p: Theme.light ? t.light : t.dark
                    readonly property bool chosen: page.a.theme === modelData
                    width: gallery.cardWidth; height: 92

                    Rectangle {
                        id: swatchBox
                        width: parent.width; height: 68
                        radius: Theme.radiusSmall + 2
                        color: card.p[0]
                        border { color: card.chosen ? Theme.accent : cardArea.containsMouse ? Theme.strokeStrong : Theme.stroke; width: card.chosen ? 2 : 1 }
                        scale: cardArea.pressed ? 0.97 : 1
                        Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                        Rectangle {   // title bar
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 2 }
                            height: 12
                            radius: Theme.radiusSmall
                            color: Qt.alpha(card.p[1], 0.08)
                        }
                        Column {
                            x: 10; y: 22
                            spacing: 5
                            Rectangle { width: 58; height: 5; radius: 2.5; color: card.p[1]; opacity: 0.85 }
                            Rectangle { width: 40; height: 5; radius: 2.5; color: card.p[1]; opacity: 0.4 }
                            Row {
                                spacing: 5
                                topPadding: 3
                                Rectangle { width: 26; height: 10; radius: 5; color: card.p[2] }
                                Rectangle { width: 10; height: 10; radius: 5; color: Qt.alpha(card.p[2], 0.45) }
                            }
                        }
                        Rectangle {   // tick on the chosen one
                            visible: card.chosen
                            anchors { right: parent.right; top: parent.top; margins: 18 }
                            width: 18; height: 18; radius: 9
                            color: Theme.accent
                            Text { anchors.centerIn: parent; text: "\u{F012C}"; color: Theme.accentText; font { family: Theme.iconFont; pixelSize: 12 } }
                        }
                    }
                    Text {
                        anchors { top: swatchBox.bottom; topMargin: 5; horizontalCenter: parent.horizontalCenter }
                        text: card.t.name
                        color: card.chosen ? Theme.text : Theme.subtext
                        font { family: Theme.font; pixelSize: 11; weight: card.chosen ? Font.DemiBold : Font.Normal }
                    }
                    MouseArea {
                        id: cardArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        // a theme brings its own accent; pick another below to override it
                        onClicked: { Config.set("appearance", "theme", card.modelData); Config.set("appearance", "accent", "theme") }
                    }
                }
            }
        }
        SettingRow {
            label: "Terminal colours"
            hint: "Ghostty switches to the matching theme, live"
            ConfigToggle { section: "appearance"; key: "terminal" }
        }
    }

    SettingGroup {
        title: "Accent colour"
        SettingRow {
            label: Theme.accentNames[page.a.accent] ?? "Accent"
            hint: "Active items, toggles, selection and window borders"
            Flow {
                width: 8 * 30
                spacing: 6
                Repeater {
                    model: page.swatches
                    Rectangle {
                        id: swatch
                        required property string modelData
                        readonly property bool chosen: page.a.accent === modelData
                        width: 24; height: 24; radius: 12
                        color: Theme.accents[modelData]
                        border { color: chosen ? Theme.text : Theme.stroke; width: chosen ? 2 : 1 }
                        scale: swatchArea.containsMouse ? 1.12 : 1
                        Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                        Text {   // the theme's own accent has a sparkle, the custom one a pencil
                            anchors.centerIn: parent
                            visible: swatch.modelData === "custom" || swatch.modelData === "theme"
                            text: swatch.modelData === "custom" ? "\u{F03EB}" : "\u{F0674}"
                            color: page.luma(swatch.color) > 0.6 ? "#1d1d1f" : "#ffffff"
                            font { family: Theme.iconFont; pixelSize: 12 }
                        }
                        MouseArea { id: swatchArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Config.set("appearance", "accent", swatch.modelData) }
                        ToolTipText { shown: swatchArea.containsMouse; text: Theme.accentNames[swatch.modelData] ?? "" }
                    }
                }
            }
        }
        SettingRow {
            id: customRow
            visible: page.a.accent === "custom"
            label: "Custom colour"
            hint: hexError !== "" ? hexError : "Drag for the hue, or type a hex colour (#ff7a59 or #f75)"
            property string hexError: ""
            Item {
                width: 150; height: 24
                Rectangle {   // hue strip; click or drag to pick (saturation and brightness stay pleasant)
                    id: hues
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width; height: 12; radius: 6
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Qt.hsva(0.0, 0.62, 0.98, 1) }
                        GradientStop { position: 0.17; color: Qt.hsva(0.17, 0.62, 0.98, 1) }
                        GradientStop { position: 0.33; color: Qt.hsva(0.33, 0.62, 0.98, 1) }
                        GradientStop { position: 0.5; color: Qt.hsva(0.5, 0.62, 0.98, 1) }
                        GradientStop { position: 0.67; color: Qt.hsva(0.67, 0.62, 0.98, 1) }
                        GradientStop { position: 0.83; color: Qt.hsva(0.83, 0.62, 0.98, 1) }
                        GradientStop { position: 1.0; color: Qt.hsva(1.0, 0.62, 0.98, 1) }
                    }
                    Rectangle {
                        x: Math.max(0, Theme.accent.hsvHue) * (hues.width - width)
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16; height: 16; radius: 8
                        color: Theme.accent
                        border { color: "#ffffff"; width: 2 }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    function pick(x) {
                        const c = Qt.hsva(Math.max(0, Math.min(0.999, x / width)), 0.62, 0.98, 1)
                        customRow.hexError = Config.set("appearance", "customAccent", c.toString().slice(0, 7))
                    }
                    onPressed: mouse => pick(mouse.x)
                    onPositionChanged: mouse => { if (pressed) pick(mouse.x) }
                }
            }
            TextField {
                width: 96
                text: page.a.customAccent
                onAccepted: {
                    let h = text.trim().replace(/^#/, "")
                    if (/^[0-9a-fA-F]{3}$/.test(h)) h = h.split("").map(ch => ch + ch).join("")   // #f75 -> #ff7755
                    customRow.hexError = Config.set("appearance", "customAccent", "#" + h.toLowerCase())
                }
            }
        }
    }

    SettingGroup {
        title: "Glass and shape"
        SettingRow {
            label: "Glass"
            hint: "Low lets more of the blurred wallpaper through panels"
            ConfigSlider { section: "appearance"; key: "glassOpacity"; from: 0.2; to: 0.9; step: 0.05; format: v => Math.round(v * 100) + "%" }
        }
        SettingRow {
            label: "Corners"
            hint: "Panels, menus, the dock and windows"
            ConfigSlider { section: "appearance"; key: "radiusScale"; from: 0; to: 1.5; step: 0.1; format: v => v === 0 ? "Square" : Theme.radius + " px" }
        }
        SettingRow {
            label: "Space around windows"
            hint: "Between two windows it is half"
            ConfigSlider { section: "appearance"; key: "gaps"; from: 0; to: 40; step: 1; format: v => v + " px" }
        }
    }

    SettingGroup {
        title: "Window border"
        SettingRow {
            label: "Focused window"
            hint: "The border around the window you're working in"
            ConfigChoice { section: "appearance"; key: "border"; values: ["rainbow", "accent"]; labels: ["Rainbow", "Accent colour"] }
        }
        SettingRow {
            visible: page.a.border === "rainbow"
            label: "Rainbow rotation"
            hint: Theme.animate ? "How fast the colours go round" : "Still while animations are off"
            ConfigChoice { section: "appearance"; key: "borderSpin"; values: [0, 120, 60, 25]; labels: ["Still", "Slow", "Medium", "Fast"] }
        }
        SettingRow {
            label: "Thickness"
            ConfigChoice { section: "appearance"; key: "borderSize"; values: [1, 2, 3, 4]; labels: ["1 px", "2 px", "3 px", "4 px"] }
        }
    }

    SettingGroup {
        title: "Text and motion"
        SettingRow {
            label: "Font"
            hint: "Inter, Cantarell and Noto Sans come with the setup; any installed font works"
            Dropdown {
                width: 200
                options: page.fonts
                current: page.a.font
                onPicked: v => Config.set("appearance", "font", v)
            }
        }
        SettingRow {
            label: "Text size"
            ConfigSlider { section: "appearance"; key: "fontScale"; from: 0.85; to: 1.25; step: 0.05; format: v => Math.round(v * 100) + "%" }
        }
        SettingRow {
            label: "Animations"
            hint: "Off makes every panel open and move instantly"
            ConfigToggle { section: "appearance"; key: "animations" }
        }
    }

    ResetGroup { sections: ["appearance"]; keys: Object.keys(Config.schema.appearance).filter(k => k !== "iconTheme") }   // icons have their own page
}
