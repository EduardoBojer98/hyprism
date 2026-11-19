import QtQuick
import QtQuick.Layouts
import "WindowFrames.js" as Frames

// Window Look: the focused window's border, title bars, and how windows you're not using look.
// The border's style, angle and turning are Config.windows (ThemeSync sends them to Hyprland with the theme;
// WindowFrames.js gives the colours, so the previews here are the frames you get). Its width and the gaps are
// the theme's (Themes > Adjust). Title bars come from the hyprbars plugin (hypr/modules/plugins.lua) in the
// theme's colours. Opacity and dimming are Config.windows (hypr/modules/windows.lua). Corners stay on
// Appearance because they shape panels and menus too.
ColumnLayout {
    id: page
    spacing: 20

    readonly property var w: Config.windows
    readonly property var hypr: Theme.current.hypr
    function hex(c) { return "#" + c.toString().slice(1, 7) }
    function framesOf(style) {
        return Frames.colours(style === "theme" ? (page.hypr.frame ?? "accent") : style,
            { accent: hex(Theme.accent), accent2: hex(Theme.accent2), text: hex(Theme.text), light: Theme.light,
              own: page.hypr.active, custom: page.w.borderColors })
    }
    readonly property var current: framesOf(w.border)
    readonly property bool several: current.length > 1   // angle and turning only mean something for these

    // A small window in the frame a style gives: drawn the way Hyprland draws it (a linear gradient at the angle;
    // neon with its glow)
    component FramePreview: Canvas {
        id: fp
        property var colours: []
        property real angle: 45
        property bool glow: false
        property real radius: Math.min(Theme.current.hypr.rounding ?? 8, 10)
        readonly property real inset: 7   // room for the glow
        width: 76; height: 54
        onColoursChanged: requestPaint()
        onAngleChanged: requestPaint()
        onGlowChanged: requestPaint()
        onRadiusChanged: requestPaint()
        Connections { target: Theme; function onCurrentChanged() { fp.requestPaint() } }
        onPaint: {
            const ctx = getContext("2d"), x = inset, y = inset, w = width - 2 * inset, h = height - 2 * inset
            ctx.reset()
            // Hyprland's angle turns the gradient clockwise from left-to-right (0° left to right, 90° top to bottom)
            const a = angle * Math.PI / 180, cx = width / 2, cy = height / 2, r = (Math.abs(w * Math.cos(a)) + Math.abs(h * Math.sin(a))) / 2
            const g = ctx.createLinearGradient(cx - r * Math.cos(a), cy - r * Math.sin(a), cx + r * Math.cos(a), cy + r * Math.sin(a))
            const cs = colours.length ? colours : ["808080ff"]
            cs.forEach((c, i) => g.addColorStop(cs.length === 1 ? 0 : i / (cs.length - 1), "#" + String(c).slice(0, 6)))
            if (cs.length === 1) g.addColorStop(1, "#" + String(cs[0]).slice(0, 6))
            ctx.fillStyle = g
            if (glow) { ctx.shadowColor = "#" + String(cs[0]).slice(0, 6); ctx.shadowBlur = 9 }
            ctx.beginPath(); ctx.roundedRect(x, y, w, h, radius, radius); ctx.fill()
            ctx.shadowBlur = 0
            // the window: a title strip on its surface
            const b = 2.5, ir = Math.max(0, radius - b)
            ctx.fillStyle = Theme.surfaceColor
            ctx.beginPath(); ctx.roundedRect(x + b, y + b, w - 2 * b, h - 2 * b, ir, ir); ctx.fill()
            ctx.fillStyle = Theme.raised
            ctx.fillRect(x + b + 5, y + b + 5, (w - 2 * b) * 0.45, 3)
        }
    }

    SettingGroup {
        title: "Border of the window you're using"
        Flow {
            id: styles
            Layout.fillWidth: true
            Layout.margins: 12
            spacing: 6
            Repeater {
                model: Frames.styles
                Rectangle {
                    id: tile
                    required property string modelData
                    required property int index
                    readonly property bool chosen: page.w.border === modelData
                    width: 92; height: 82
                    radius: Theme.radiusSmall
                    color: tileArea.containsMouse || tileArea.activeFocus ? Theme.fillHover : "transparent"
                    border { color: chosen ? Theme.text : "transparent"; width: chosen ? 2 : 0 }
                    FramePreview {
                        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 4 }
                        colours: page.framesOf(tile.modelData)
                        angle: page.w.borderAngle
                        glow: tile.modelData === "neon" || (tile.modelData === "theme" && page.hypr.frame === "neon")
                    }
                    Text {
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 6 }
                        text: Frames.names[tile.index]
                        color: tile.chosen ? Theme.text : Theme.subtext
                        font { family: Theme.font; pixelSize: Theme.fontCaption; weight: tile.chosen ? Font.DemiBold : Font.Normal }
                    }
                    MouseArea {
                        id: tileArea
                        anchors.fill: parent
                        hoverEnabled: true
                        activeFocusOnTab: true
                        cursorShape: Qt.PointingHandCursor
                        Accessible.role: Accessible.RadioButton
                        Accessible.name: "Border " + Frames.names[tile.index]
                        Accessible.checked: tile.chosen
                        Keys.onSpacePressed: Config.set("windows", "border", tile.modelData)
                        Keys.onReturnPressed: Config.set("windows", "border", tile.modelData)
                        onClicked: Config.set("windows", "border", tile.modelData)
                    }
                }
            }
        }
        SettingRow {
            visible: page.w.border === "custom"
            label: "Your colours"
            hint: "Two or three, as #hex. Leave the third empty for two"
            Repeater {
                model: 3
                Row {
                    id: slot
                    required property int index
                    readonly property string value: Array.from(page.w.borderColors ?? [])[index] ?? ""
                    spacing: 4
                    Rectangle {
                        width: 20; height: 20; radius: 10
                        anchors.verticalCenter: parent.verticalCenter
                        color: Frames.hexOk(slot.value) ? slot.value : "transparent"
                        border { color: Theme.stroke; width: 1 }
                    }
                    TextField {
                        width: 84
                        placeholder: slot.index === 2 ? "optional" : "#hex"
                        accessibleName: "Border colour " + (slot.index + 1)
                        text: slot.value
                        invalid: text !== "" && !Frames.hexOk(page.cleanHex(text))
                        onAccepted: page.setColour(slot.index, text)
                    }
                }
            }
        }
        SettingRow {
            visible: page.several
            label: "Angle"
            hint: "Which way the colours run across the frame"
            ConfigSlider { section: "windows"; key: "borderAngle"; from: 0; to: 345; step: 15; format: v => Math.round(v) + "°" }
        }
        SettingRow {
            visible: page.several
            label: "Turn the colours"
            hint: page.w.borderAnimate && Theme.motionLevel !== "full" ? "Waiting for animations on Full (Themes > Motion); it stands still until then"
                : "Slowly, around the frame. Only with animations on Full, and never in the Silent power mode"
            ConfigToggle { section: "windows"; key: "borderAnimate" }
        }
        SettingRow {
            visible: page.several && page.w.borderAnimate
            label: "Speed"
            ConfigSlider { section: "windows"; key: "rainbowSpeed"; from: 1; to: 10; step: 1; format: v => v <= 3 ? "Slow" : v >= 8 ? "Fast" : "Medium" }
        }
        SettingRow {
            visible: page.several && page.w.borderAnimate
            label: "Keep turning on battery"
            hint: "A turning border redraws the screen all the time, which costs battery"
            ConfigToggle { section: "windows"; key: "rainbowOnBattery" }
        }
        SettingRow {
            label: "Width"
            hint: (page.hypr.border ?? 0) + " px now. The width is part of the theme: Themes > Adjust > Window frame"
            PillButton { text: "Open Themes"; onClicked: SettingsApp.show("appearance") }
        }
    }
    function cleanHex(t) {
        let h = String(t).trim().replace(/^#/, "")
        if (/^[0-9a-fA-F]{3}$/.test(h)) h = h.split("").map(ch => ch + ch).join("")
        return "#" + h.toLowerCase()
    }
    // a bad value is refused (the field stays red), never saved; an empty third slot leaves two colours
    function setColour(i, text) {
        const list = Array.from(page.w.borderColors ?? []).filter(Frames.hexOk).slice(0, 3)
        const t = String(text).trim()
        if (t === "") { if (i === 2 && list.length > 2) Config.set("windows", "borderColors", list.slice(0, 2)); return }
        const c = cleanHex(t)
        if (!Frames.hexOk(c)) return
        while (list.length < i) list.push(list[list.length - 1] ?? page.hex(Theme.accent))
        list[i] = c
        Config.set("windows", "borderColors", list)
    }

    SettingGroup {
        title: "Title bars"
        SettingRow {
            label: "Title bars on apps without buttons"
            hint: "Minimise, maximise, close and ⋯ (the window menu, also Super+Z). Apps that draw their own, like Chrome, Firefox and GNOME apps, keep theirs"
            ConfigToggle { section: "windows"; key: "titleBars" }
        }
        // the bar as plugins.lua draws it: the theme's surface, text and type, at the size and sides picked below
        Rectangle {
            id: barPreview
            visible: page.w.titleBars
            readonly property int barH: ({ small: 24, medium: 28, large: 34 })[page.w.titleBarSize] ?? Math.round(28 * Math.sqrt(Theme.density))
            readonly property bool buttonsLeft: page.w.titleButtons === "left"
            Layout.fillWidth: true
            Layout.margins: 12
            implicitHeight: barH + 2 * Theme.line
            radius: Math.min(Theme.current.hypr.rounding ?? 0, 12)
            color: Theme.surfaceColor
            border { color: Theme.stroke; width: Theme.line }
            Accessible.role: Accessible.Graphic
            Accessible.name: "Title bar preview"
            Text {
                readonly property real room: 10 + 4 * 22 + 8
                x: page.w.titleAlign === "left" ? (barPreview.buttonsLeft ? room : 10) : (parent.width - width) / 2
                width: Math.min(implicitWidth, parent.width - 2 * room)
                anchors.verticalCenter: parent.verticalCenter
                text: "Terminal — ~/projects"
                elide: Text.ElideRight
                color: Theme.text
                // plugins.lua: text size from the height, in points
                font { family: Theme.font; pointSize: barPreview.barH <= 25 ? 9 : barPreview.barH <= 31 ? 10 : 11; weight: Font.Medium }
            }
            Row {
                anchors.verticalCenter: parent.verticalCenter
                x: barPreview.buttonsLeft ? 10 : parent.width - width - 10
                layoutDirection: barPreview.buttonsLeft ? Qt.LeftToRight : Qt.RightToLeft
                spacing: 8
                Repeater {
                    model: ["✕", "□", "–", "⋯"]
                    Rectangle {
                        required property string modelData
                        required property int index
                        width: 14; height: 14; radius: 7
                        color: index === 0 ? "#ff5f57" : "#868b92"   // palette: plugins.lua's button discs
                        Text { anchors.centerIn: parent; text: parent.modelData; color: "#1e1e1e"; font { family: Theme.font; pixelSize: Theme.fontBadge } }   // palette
                    }
                }
            }
        }
        SettingRow {
            visible: page.w.titleBars
            label: "Size"
            hint: "The theme's follows how roomy it is"
            ConfigChoice { section: "windows"; key: "titleBarSize"; values: ["theme", "small", "medium", "large"]; labels: ["Theme's", "Small", "Medium", "Large"] }
        }
        SettingRow {
            visible: page.w.titleBars
            label: "Buttons"
            hint: "Close sits nearest the edge"
            ConfigChoice { section: "windows"; key: "titleButtons"; values: ["left", "right"]; labels: ["Left", "Right"] }
        }
        SettingRow {
            label: "Maximise button"
            hint: "Float: a tiled window floats as a normal window, a floating one fills the screen and comes back on the next click. Apps' own buttons do the same"
            ConfigChoice { section: "windows"; key: "maxButton"; values: ["float", "fill"]; labels: ["Float", "Fill the screen"] }
        }
        SettingRow {
            visible: page.w.titleBars
            label: "Title"
            ConfigChoice { section: "windows"; key: "titleAlign"; values: ["left", "center"]; labels: ["Left", "Centre"] }
        }
    }


    SettingGroup {
        title: "Windows you're not using"
        SettingRow {
            label: "Opacity"
            ConfigSlider { section: "windows"; key: "inactiveOpacity"; from: 0.6; to: 1; step: 0.01; format: v => Math.round(v * 100) + "%" }
        }
        SettingRow {
            label: "Dim them"
            ConfigToggle { section: "windows"; key: "dimInactive" }
        }
        SettingRow {
            visible: Config.windows.dimInactive
            label: "How much"
            ConfigSlider { section: "windows"; key: "dimStrength"; from: 0.05; to: 0.6; step: 0.01; format: v => Math.round(v * 100) + "%" }
        }
    }

    SettingGroup {
        SettingRow {
            label: "Reset to defaults"
            hint: "Only the options on this page"
            PillButton {
                text: "Reset"
                onClicked: {
                    Config.reset("windows", ["border", "borderAngle", "borderColors", "borderAnimate", "rainbowSpeed", "rainbowOnBattery",
                                             "titleBars", "titleBarSize", "titleButtons", "titleAlign", "maxButton",
                                             "inactiveOpacity", "dimInactive", "dimStrength"])
                }
            }
        }
    }
}
