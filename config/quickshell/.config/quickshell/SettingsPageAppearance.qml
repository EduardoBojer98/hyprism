import Quickshell
import QtQuick
import QtQuick.Layouts

// Themes: pick the whole desktop design, then adjust it. Every theme (Themes.qml) brings its own
// layout, type, shape, colours, motion, lock screen, terminal and wallpaper; the Adjust group lays
// your changes over the active one (saved per theme in Config.appearance.custom, so switching away
// and back keeps them). Same as `theme NAME` in a terminal.
ColumnLayout {
    id: page
    spacing: 20

    readonly property var a: Config.appearance
    readonly property var base: Themes.get(a.theme)          // the theme as shipped
    readonly property var r: Theme.current                     // with your adjustments
    readonly property var mine: (a.custom ?? {})[a.theme] ?? {}
    // bundled fonts first, then every other installed family
    readonly property var fonts: {
        const own = ["Outfit", "IBM Plex Sans", "Archivo", "Martian Mono", "Cantarell", "JetBrainsMono Nerd Font", "Inter"]
        return own.concat(Qt.fontFamilies().filter(f => !own.includes(f) && !/Nerd Font|Emoji|Symbols/.test(f)))
    }
    // the colours offered as accents
    readonly property var swatches: [
        "#ff9e7a", "#ffb000", "#b6ff3b", "#9fd18b", "#5ad1c2", "#5b9cff", "#3584e4", "#8ab4ff", "#c7a3ff", "#ff6b8a", "#ff3b1f", "#e30613", "#f2d48a", "#e8e8ea", "#1a1a1a"]   // palette

    function adjust(key, value) { return Themes.adjust(key, value) }
    function hex(t) {
        let h = String(t).trim().replace(/^#/, "")
        if (/^[0-9a-fA-F]{3}$/.test(h)) h = h.split("").map(ch => ch + ch).join("")
        return /^[0-9a-fA-F]{6}$/.test(h) ? "#" + h.toLowerCase() : ""
    }

    // ---- the gallery --------------------------------------------------------------------------------
    // the previews show each theme's wallpaper: draw the missing ones once, in the background
    Component.onCompleted: Quickshell.execDetached(["theme-wallpaper", "--all"])
    SettingGroup {
        title: "Theme"
        SettingRow {
            label: "Light or dark"
            hint: page.a.mode === "theme" ? "Each theme's own (" + page.base.name + " is " + (page.base.dark ? "dark" : "light") + "); every theme has both"
                : "Every theme in its " + page.a.mode + " version; windows, apps, terminal and wallpaper follow"
            ConfigChoice { section: "appearance"; key: "mode"; values: ["theme", "light", "dark"]; labels: ["Default", "Light", "Dark"] }
        }
        Text {
            Layout.fillWidth: true
            Layout.margins: 16
            text: page.base.name + ": " + page.base.about
            color: Theme.subtext
            wrapMode: Text.Wrap
            font { family: Theme.font; pixelSize: Theme.fontLabel }
        }
        GridLayout {
            id: gallery
            Layout.fillWidth: true
            Layout.margins: 12
            columns: Math.max(2, Math.floor((width + columnSpacing) / (178 + columnSpacing)))
            columnSpacing: 12
            rowSpacing: 12
            Repeater {
                model: Themes.list
                ThemePreview {
                    required property var modelData
                    theme: Themes.resolve(modelData.id, {}, page.a.mode)   // each in the light or dark half you picked
                    chosen: page.a.theme === modelData.id
                    Layout.fillWidth: true
                    onPicked: Config.set("appearance", "theme", modelData.id)
                }
            }
        }
    }

    // ---- adjust the active theme ---------------------------------------------------------------------
    SettingGroup {
        title: "Adjust " + page.base.name

        SettingRow {
            label: "Accent colour"
            hint: "Workspaces, selection, toggles and the window frame"
            Flow {
                width: 8 * 28
                spacing: 4
                Repeater {
                    model: [page.base.colour.accent].concat(page.swatches.filter(c => c !== page.base.colour.accent))
                    Rectangle {
                        id: sw
                        required property string modelData
                        required property int index
                        readonly property bool chosen: String(Theme.accent).slice(0, 7) === modelData
                        width: 24; height: 24; radius: Math.min(12, Theme.radiusSmall + 4)
                        color: modelData
                        border { color: chosen ? Theme.text : Theme.stroke; width: chosen ? 2 : 1 }
                        Text { visible: sw.index === 0; anchors.centerIn: parent; text: "\u{F0674}"; color: Themes.textOn(sw.modelData, page.base.colour); font { family: Theme.iconFont; pixelSize: 11 } }
                        MouseArea { id: swArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.adjust("accent", sw.index === 0 ? undefined : sw.modelData) }
                        ToolTipText { shown: swArea.containsMouse; text: sw.index === 0 ? "The theme's own" : sw.modelData }
                    }
                }
            }
            TextField {
                width: 88
                placeholder: "#hex"
                text: page.mine.accent ?? ""
                invalid: text !== "" && page.hex(text) === ""
                // empty: back to the theme's; a bad value is refused (the field stays red), never saved
                onAccepted: { if (text.trim() === "") page.adjust("accent", undefined); else if (page.hex(text) !== "") page.adjust("accent", page.hex(text)) }
            }
        }
        SettingRow {
            label: "Second colour"
            hint: "Window frame gradients, glows and highlights (" + page.base.colour.accent2 + " by default)"
            Rectangle { width: 24; height: 24; radius: Theme.radiusSmall; color: Theme.accent2; border { color: Theme.stroke; width: 1 } }
            TextField {
                width: 88
                placeholder: "#hex"
                text: page.mine.accent2 ?? ""
                invalid: text !== "" && page.hex(text) === ""
                // empty: back to the theme's; a bad value is refused (the field stays red), never saved
                onAccepted: { if (text.trim() === "") page.adjust("accent2", undefined); else if (page.hex(text) !== "") page.adjust("accent2", page.hex(text)) }
            }
        }
        AdjustSlider { label: "Corners"; hint: "Panels, menus and windows"; key: "radius"; value: page.r.shape.radius; from: 0; to: 28; unit: " px" }
        AdjustSlider { label: "Gaps between windows"; key: "gapsIn"; value: page.r.hypr.gapsIn; from: 0; to: 24; unit: " px" }
        AdjustSlider { label: "Gaps at the screen edge"; key: "gapsOut"; value: page.r.hypr.gapsOut; from: 0; to: 48; unit: " px" }
        AdjustSlider { label: "Window frame"; hint: "0 hides it"; key: "border"; value: page.r.hypr.border; from: 0; to: 6; unit: " px" }
        AdjustSlider { label: "Text size"; hint: "Body text in the shell; the rest scales from it"; key: "size"; value: page.r.font.size; from: 11; to: 18; unit: " px" }
        SettingRow {
            label: "Font"
            hint: "The theme's own is " + page.base.font.ui
            Dropdown { width: 200; options: page.fonts; current: page.r.font.ui; onPicked: v => page.adjust("font", v === page.base.font.ui ? undefined : v) }
        }
        SettingRow {
            label: "Window motion"
            hint: "How windows and workspaces move (panels follow the theme's own motion)"
            Choice {
                readonly property var values: ["instant", "crisp", "snappy", "ease", "spring", "slam", "fade"]
                options: ["Instant", "Crisp", "Snappy", "Ease", "Spring", "Slam", "Fade"]
                index: values.indexOf(page.r.hypr.motion)
                onPicked: i => page.adjust("motion", values[i] === page.base.hypr.motion ? undefined : values[i])
            }
        }
        SettingRow {
            label: "Window shadow"
            Choice {
                readonly property var values: ["none", "soft", "paper", "hard"]
                options: ["None", "Soft", "Paper", "Hard"]
                index: values.indexOf(page.r.hypr.shadow)
                onPicked: i => page.adjust("shadow", values[i] === page.base.hypr.shadow ? undefined : values[i])
            }
        }
        SettingRow {
            label: "Blur behind windows"
            hint: "Translucent apps show a blurred desktop"
            Toggle { checked: page.r.hypr.blur; onToggled: c => page.adjust("blur", c === page.base.hypr.blur ? undefined : c) }
        }
        SettingRow {
            label: "Reset " + page.base.name
            hint: Object.keys(page.mine).length ? Object.keys(page.mine).length + (Object.keys(page.mine).length === 1 ? " change" : " changes") + " from the original" : "No changes"
            PillButton { text: "Reset"; enabled: Object.keys(page.mine).length > 0; onClicked: Config.set("appearance", "custom", Object.fromEntries(Object.entries(page.a.custom ?? {}).filter(([k]) => k !== page.a.theme))) }
        }
        SaveTheme {}
    }

    // ---- personal: kept whatever the theme ---------------------------------------------------------
    SettingGroup {
        title: "Everywhere"
        SettingRow {
            label: "Theme wallpaper"
            hint: "Each theme brings its own picture; off keeps yours (Wallpaper page)"
            ConfigToggle { section: "appearance"; key: "wallpaper" }
        }
        SettingRow {
            label: "Terminal colours"
            hint: "Ghostty switches to the theme's palette and font, live"
            ConfigToggle { section: "appearance"; key: "terminal" }
        }
        SettingRow {
            label: "Scale all text"
            hint: "On top of the theme's text size, on every screen"
            ConfigSlider { section: "appearance"; key: "fontScale"; from: 0.85; to: 1.25; step: 0.05; format: v => Math.round(v * 100) + "%" }
        }
        SettingRow {
            label: "Animations"
            hint: Config.appearance.motion === "reduced" ? "Short fades only; nothing slides, scales or bounces"
                : Config.appearance.motion === "off" ? "Everything appears at once" : "Each theme's own motion"
            ConfigChoice { section: "appearance"; key: "motion"; values: ["full", "reduced", "off"]; labels: ["Full", "Reduced", "Off"] }
        }
    }

    // a slider for one numeric adjustment; letting go on the theme's own value removes the override
    component AdjustSlider: SettingRow {
        id: as
        property string key
        property real value
        property real from: 0
        property real to: 10
        property string unit: ""
        Row {
            spacing: 10
            Slider {
                width: 170; height: 22
                anchors.verticalCenter: parent.verticalCenter
                value: (as.value - as.from) / (as.to - as.from)
                onMoved: v => {
                    const n = Math.round(as.from + v * (as.to - as.from))
                    const orig = ({ radius: page.base.shape.radius, gapsIn: page.base.hypr.gapsIn, gapsOut: page.base.hypr.gapsOut,
                                    border: page.base.hypr.border, barSize: page.base.bar.size, size: page.base.font.size })[as.key]
                    if (n !== as.value) page.adjust(as.key, n === orig ? undefined : n)
                }
            }
            Text {
                width: 44
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(as.value) + as.unit
                color: Theme.subtext
                horizontalAlignment: Text.AlignRight
                font { family: Theme.font; pixelSize: Theme.fontCaption; features: { "tnum": 1 } }
            }
        }
    }
}
