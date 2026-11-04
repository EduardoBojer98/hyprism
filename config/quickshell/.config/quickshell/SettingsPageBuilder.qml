import Quickshell
import QtQuick
import QtQuick.Layouts

// Theme builder: make your own theme from any of the shipped ones and change every part of it —
// colours, type, shape, the bar's look, the dock, panels, motion, notifications, the launcher,
// windows, the lock screen, terminal and wallpaper. Your themes are saved in
// Config.appearance.userThemes as the parts you changed over their base (Themes.makeUser), show up
// in the Themes gallery and switch like any other. Changes apply live.
ColumnLayout {
    id: page
    spacing: 20

    readonly property var a: Config.appearance
    readonly property var mineAll: a.userThemes ?? {}
    readonly property bool editing: Themes.get(a.theme).user === true
    readonly property var t: Themes.get(a.theme)                  // the theme being edited, resolved
    readonly property var over: mineAll[a.theme] ?? {}            // just your parts

    readonly property var fonts: {
        const own = ["Outfit", "IBM Plex Sans", "Archivo", "Archivo Black", "Martian Mono", "Cantarell", "JetBrainsMono Nerd Font", "Inter"]
        return own.concat(Qt.fontFamilies().filter(f => !own.includes(f) && !/Nerd Font|Emoji|Symbols/.test(f)))
    }
    function slug(name) { return "custom-" + (name.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "").slice(0, 32) || "theme") }
    function create(name, base) {
        const all = JSON.parse(JSON.stringify(mineAll))
        let id = slug(name), n = 2
        while (all[id] || Themes.builtIn.some(b => b.id === id)) id = slug(name) + "-" + n++
        all[id] = { name: name.trim() || "My theme", base: base }
        Config.set("appearance", "userThemes", all)
        Config.set("appearance", "theme", id)
    }
    // write one part of the theme being edited: path like "colour.accent"; undefined puts the base's back
    function set(path, value) {
        const all = JSON.parse(JSON.stringify(mineAll)), keys = path.split(".")
        let o = all[a.theme]
        for (const k of keys.slice(0, -1)) o = o[k] = (typeof o[k] === "object" && o[k] !== null ? o[k] : {})
        if (value === undefined) delete o[keys[keys.length - 1]]; else o[keys[keys.length - 1]] = value
        Config.set("appearance", "userThemes", all)
    }
    function get(path) { return path.split(".").reduce((o, k) => o?.[k], page.t) }
    function hex(t) {
        let h = String(t).trim().replace(/^#/, "")
        if (/^[0-9a-fA-F]{3}$/.test(h)) h = h.split("").map(ch => ch + ch).join("")
        return /^[0-9a-fA-F]{6}$/.test(h) ? "#" + h.toLowerCase() : ""
    }

    // ---- make one ------------------------------------------------------------------------------------
    SettingGroup {
        title: page.editing ? "Editing " + page.t.name : "Make your own theme"
        SettingRow {
            label: "Start from"
            hint: "Every part can be changed afterwards"
            Choice {
                id: baseChoice
                options: Themes.builtIn.map(b => b.name)
                index: Math.max(0, Themes.builtIn.findIndex(b => b.id === (page.editing ? page.t.base : page.a.theme)))
            }
        }
        SettingRow {
            label: "Name"
            TextField { id: newName; width: 200; placeholder: "My theme" }
            PillButton { text: "Create"; primary: true; onClicked: { page.create(newName.text, Themes.builtIn[baseChoice.index].id); newName.text = "" } }
        }
        Repeater {   // your themes: switch to one, rename the one you're on, or delete
            model: Object.keys(page.mineAll)
            SettingRow {
                required property string modelData
                readonly property var mt: Themes.get(modelData)
                label: mt.name + (page.a.theme === modelData ? "  ·  editing" : "")
                hint: mt.about
                PillButton { visible: page.a.theme !== modelData; text: "Edit"; onClicked: Config.set("appearance", "theme", modelData) }
                PillButton {
                    text: "Delete"
                    onClicked: {
                        const all = JSON.parse(JSON.stringify(page.mineAll)); delete all[modelData]
                        if (page.a.theme === modelData) Config.set("appearance", "theme", mt.base)
                        Config.set("appearance", "userThemes", all)
                    }
                }
            }
        }
        SettingRow {
            visible: page.editing
            label: "Rename"
            TextField { width: 200; placeholder: page.t.name; onAccepted: if (text.trim()) page.set("name", text.trim()) }
        }
    }

    // ---- everything below edits the active own theme ----------------------------------------------
    Text {
        visible: !page.editing
        Layout.fillWidth: true
        text: "Create a theme above (or pick one of yours) to edit its colours, type, bar, dock, panels, motion and more."
        color: Theme.subtext
        wrapMode: Text.Wrap
        font { family: Theme.font; pixelSize: Theme.fontLabel }
    }

    SettingGroup {
        visible: page.editing
        title: "Colours"
        Repeater {
            model: [
                ["ground", "Desktop and bar ground"], ["surface", "Panels"], ["raised", "Controls and hover"], ["line", "Lines and frames"],
                ["text", "Text"], ["muted", "Secondary text"], ["faint", "Hints"], ["accent", "Accent: selection, toggles, the one thing to press"],
                ["accent2", "Second accent: gradients and highlights"], ["ok", "Good"], ["warn", "Warning"], ["err", "Error"]
            ]
            SettingRow {
                id: crow
                required property var modelData
                readonly property string key: "colour." + modelData[0]
                label: modelData[1]
                Rectangle { width: 26; height: 26; radius: Math.min(6, Theme.radiusSmall); color: page.get(crow.key) ?? "transparent"; border { color: Theme.stroke; width: 1 } }
                TextField {
                    width: 96
                    placeholder: page.get(crow.key) ?? "#hex"
                    invalid: text !== "" && page.hex(text) === ""
                    onAccepted: { const h = page.hex(text); if (h) { page.set(crow.key, h); text = "" } }
                }
            }
        }
        Pick { label: "Light or dark"; path: "dark"; values: [true, false]; labels: ["Dark", "Light"] }
    }

    SettingGroup {
        visible: page.editing
        title: "Type and shape"
        FontPick { label: "Interface font"; path: "font.ui" }
        FontPick { label: "Display font"; hint: "Clocks, big numbers, the lock screen"; path: "font.display" }
        FontPick { label: "Mono font"; hint: "Word and readout bars, terminal"; path: "font.mono" }
        Num { label: "Text size"; path: "font.size"; from: 11; to: 18; unit: " px" }
        Pick { label: "Display weight"; path: "font.displayWeight"; values: [300, 400, 500, 700, 900]; labels: ["Light", "Regular", "Medium", "Bold", "Black"] }
        Num { label: "Corners"; path: "shape.radius"; from: 0; to: 28; unit: " px"; also: v => page.set("shape.radiusSmall", Math.round(v * 0.65)) }
        Num { label: "Panel frame"; path: "shape.line"; from: 0; to: 4; unit: " px" }
        Pick { label: "Material"; hint: "Glass is see-through over the blurred desktop"; path: "shape.material"; values: ["solid", "glass"]; labels: ["Solid", "Glass"] }
    }

    SettingGroup {
        visible: page.editing
        title: "Menu bar look"
        Pick { label: "Place"; hint: "Settings > Menu Bar can still move it"; path: "bar.edge"; values: ["top", "bottom", "left", "right"]; labels: ["Top", "Bottom", "Left", "Right"] }
        Num { label: "Size"; path: "bar.size"; from: 24; to: 72; unit: " px" }
        Pick { label: "Ground"; path: "bar.fill"; values: ["glass", "surface", "ground", "ink", "none"]; labels: ["Glass", "Panel", "Desktop", "Ink", "None"] }
        Toggle2 { label: "Floating"; path: "bar.floating" }
        Toggle2 { label: "A pill per section"; path: "bar.segmented" }
        Num { label: "Edge line"; path: "bar.line"; from: 0; to: 4; unit: " px" }
        Pick { label: "Status as"; path: "bar.voice"; values: ["icons", "mixed", "words", "caps"]; labels: ["Icons", "Icons + values", "words", "CAPS"] }
        Toggle2 { label: "Mono text"; path: "bar.mono" }
        Toggle2 { label: "Rules between items"; path: "bar.sep" }
        Pick { label: "Workspaces"; path: "bar.ws"; values: ["dots", "numbers", "filled", "squares", "blocks", "text"]; labels: ["Dots", "Numbers", "Filled", "Squares", "Blocks", "Text"] }
        Pick { label: "Clock"; path: "bar.clock"; values: ["plain", "accent", "display", "block"]; labels: ["Plain", "Accent", "Big", "Block"] }
        Pick { label: "Corner brackets"; hint: "Accent marks in the screen corners"; path: "bar.decor"; values: ["", "brackets"]; labels: ["None", "Brackets"] }
    }

    SettingGroup {
        visible: page.editing
        title: "Dock look"
        Pick { label: "Place"; hint: "The bar's edge puts it inside the bar"; path: "dock.edge"; values: ["bottom", "left", "right", "top"]; labels: ["Bottom", "Left", "Right", "Top"] }
        Pick { label: "Shape"; path: "dock.shape"; values: ["pill", "tile", "block"]; labels: ["Pill", "Rounded", "Square"] }
        Pick { label: "Ground"; path: "dock.fill"; values: ["glass", "surface", "ink"]; labels: ["Glass", "Panel", "Ink"] }
        Pick { label: "Hover"; path: "dock.hover"; values: ["lift", "grow", "plate"]; labels: ["Lift", "Grow", "Plate"] }
        Pick { label: "Open-app mark"; path: "dock.mark"; values: ["line", "dot", "bar"]; labels: ["Line", "Dot", "Bar"] }
    }

    SettingGroup {
        visible: page.editing
        title: "Panels and motion"
        Pick { label: "Depth"; path: "popup.depth"; values: ["soft", "hard", "glow", "none"]; labels: ["Soft shadow", "Hard block", "Glow", "Frame only"] }
        Pick { label: "Panel accent"; path: "popup.decor"; values: ["", "brackets", "topline"]; labels: ["None", "Corner brackets", "Top line"] }
        Pick { label: "Tiles that are on"; path: "popup.tiles"; values: ["solid", "wash"]; labels: ["Solid accent", "Tinted"] }
        SettingRow {
            label: "Motion like"
            hint: "Copies a theme's timing, curve and travel; fine-tune below"
            Choice {
                options: Themes.builtIn.map(b => b.name)
                index: -1
                onPicked: i => page.set("motion", JSON.parse(JSON.stringify(Themes.builtIn[i].motion)))
            }
        }
        Num { label: "Open time"; path: "motion.enter"; from: 0; to: 300; step: 10; unit: " ms" }
        Num { label: "Close time"; path: "motion.exit"; from: 0; to: 250; step: 10; unit: " ms" }
        Num { label: "Travel"; hint: "How far panels move out of their trigger"; path: "motion.travel"; from: 0; to: 32; unit: " px" }
        Num { label: "Start size"; path: "motion.scale"; from: 0.9; to: 1; step: 0.01; format: v => Math.round(v * 100) + "%" }
        Num { label: "Button press"; path: "motion.press"; from: 0.9; to: 1; step: 0.01; format: v => Math.round(v * 100) + "%" }
        Pick { label: "Windows move"; path: "hypr.motion"; values: ["instant", "crisp", "snappy", "ease", "spring", "slam"]; labels: ["Instant", "Crisp", "Snappy", "Ease", "Spring", "Slam"] }
    }

    SettingGroup {
        visible: page.editing
        title: "Windows"
        Num { label: "Gaps between windows"; path: "hypr.gapsIn"; from: 0; to: 24; unit: " px" }
        Num { label: "Gaps at the screen edge"; path: "hypr.gapsOut"; from: 0; to: 48; unit: " px" }
        Num { label: "Frame"; path: "hypr.border"; from: 0; to: 6; unit: " px" }
        Num { label: "Rounding"; path: "hypr.rounding"; from: 0; to: 28; unit: " px" }
        Pick { label: "Shadow"; path: "hypr.shadow"; values: ["none", "soft", "paper", "hard"]; labels: ["None", "Soft", "Paper", "Hard"] }
        Toggle2 { label: "Blur behind see-through windows"; path: "hypr.blur" }
        SettingRow {
            label: "Frame colour"
            Choice {
                options: ["Accent", "Accent → second", "Line"]
                index: -1
                onPicked: i => page.set("hypr.active", i === 0 ? [page.get("colour.accent").slice(1) + "ff"]
                                         : i === 1 ? [page.get("colour.accent").slice(1) + "ff", page.get("colour.accent2").slice(1) + "ff"]
                                         : [page.get("colour.line").slice(1) + "ff"])
            }
        }
    }

    SettingGroup {
        visible: page.editing
        title: "Everything else"
        Pick { label: "Notifications corner"; path: "notify.corner"; values: ["top-left", "top-center", "top-right", "bottom-left", "bottom-right"]; labels: ["Top left", "Top", "Top right", "Bottom left", "Bottom right"] }
        Pick { label: "Notification style"; path: "notify.kind"; values: ["bubble", "card", "line", "block", "tag"]; labels: ["Bubble", "Card", "Line", "Block", "Tag"] }
        Pick { label: "Launcher"; path: "launcher.placement"; values: ["center", "strip", "half", "column", "fullscreen"]; labels: ["Centre", "Strip", "Half", "Column", "Full screen"] }
        Pick { label: "Launcher opens on"; path: "launcher.view"; values: ["home", "grid", "inline"]; labels: ["Suggestions", "All apps", "Just the field"] }
        Pick { label: "Launcher selection"; path: "launcher.select"; values: ["wash", "inverse"]; labels: ["Tint", "Solid block"] }
        Pick { label: "Launcher prompt"; path: "launcher.prompt"; values: ["", "❯", "▸", "$", ">"]; labels: ["Lens", "❯", "▸", "$", ">"] }
        Pick { label: "Lock clock"; path: "lock.clock"; values: ["big", "stacked", "terminal", "readout", "small"]; labels: ["Big", "Stacked", "Terminal", "Readout", "Small"] }
        Pick { label: "Lock layout"; path: "lock.align"; values: ["center", "top", "bottom", "left"]; labels: ["Centre", "Top", "Bottom", "Left"] }
        Pick { label: "Terminal colours"; path: "term"; values: Themes.builtIn.map(b => b.term); labels: Themes.builtIn.map(b => b.name) }
        Pick { label: "Wallpaper"; hint: "A drawn design; Settings > Wallpaper for your own pictures"; path: "wall"; values: Themes.builtIn.map(b => b.wall); labels: Themes.builtIn.map(b => b.name) }
        SettingRow {
            label: "Undo all changes"
            hint: Object.keys(page.over).filter(k => !["name", "base"].includes(k)).length + " part(s) changed from " + (Themes.get(page.t.base)?.name ?? "")
            PillButton {
                text: "Back to the base"
                onClicked: { const all = JSON.parse(JSON.stringify(page.mineAll)); all[page.a.theme] = { name: page.over.name, base: page.over.base }; Config.set("appearance", "userThemes", all) }
            }
        }
    }

    // ---- small editors bound to one part of the theme ------------------------------------------
    component Pick: SettingRow {
        id: pk
        property string path
        property var values: []
        property var labels: values.map(String)
        Choice {
            options: pk.labels
            index: pk.values.indexOf(page.get(pk.path))
            onPicked: i => page.set(pk.path, pk.values[i])
        }
    }
    component Toggle2: SettingRow {
        id: tg
        property string path
        Toggle { checked: page.get(tg.path) === true; onToggled: c => page.set(tg.path, c) }
    }
    component FontPick: SettingRow {
        id: fp
        property string path
        Dropdown { width: 220; options: page.fonts; current: page.get(fp.path) ?? ""; onPicked: v => page.set(fp.path, v) }
    }
    component Num: SettingRow {
        id: nm
        property string path
        property real from: 0
        property real to: 1
        property real step: 1
        property string unit: ""
        property var format: v => Math.round(v) + unit
        property var also: null                       // a second part that follows this one
        readonly property real value: page.get(path) ?? from
        Slider {
            width: 170
            anchors.verticalCenter: parent.verticalCenter
            value: (nm.value - nm.from) / (nm.to - nm.from)
            onMoved: v => {
                const n = Number((Math.round((nm.from + v * (nm.to - nm.from)) / nm.step) * nm.step).toFixed(3))
                if (Math.abs(n - nm.value) > 1e-6) { page.set(nm.path, n); if (nm.also) nm.also(n) }
            }
        }
        Text {
            width: 52
            anchors.verticalCenter: parent.verticalCenter
            text: nm.format(nm.value)
            color: Theme.subtext
            horizontalAlignment: Text.AlignRight
            font { family: Theme.font; pixelSize: Theme.fontLabel; features: { "tnum": 1 } }
        }
    }
}
