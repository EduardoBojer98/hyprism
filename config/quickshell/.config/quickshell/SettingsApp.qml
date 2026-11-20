pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC

// The Settings app: one glass window with a sidebar of groups, each opening into its pages (a
// submenu in the sidebar, or tabs when the window is narrow); one page shows at a time.
// Open with Super+I, the Control Center's gear, the launcher ("Settings"), or
// `qs ipc call settings open [group or page]`.
Singleton {
    id: root

    property bool open: false
    property string section: "appearance"   // the group open in the sidebar
    property string pageId: "appearance"    // the page shown

    // The sidebar: groups like a normal desktop's settings, each with one or more pages.
    // Page ids still work everywhere (show("sound"), `qs ipc call settings open bluetooth`).
    // Adding a setting: put its row on the page it belongs to (SettingsPage<Id>.qml) and a word for
    // it in that page's `keys` below, so search finds it. Adding a page: a SettingsPage<Id>.qml, an
    // entry in allSections, and its id in one group here.
    readonly property var allGroups: [
        { id: "appearance", name: "Appearance",          glyph: "\u{F03D8}", pages: ["appearance", "wallpaper", "icons", "cursor"] },
        { id: "desktop",    name: "Menu Bar & Dock",     glyph: "\u{F0E7F}", pages: ["bar", "dock", "controlcenter", "weather", "calendar"] },
        { id: "notify",     name: "Notifications",       glyph: "\u{F009A}", pages: ["notifications", "focus"] },
        { id: "windows",    name: "Windows & Workspaces", glyph: "\u{F05AF}", pages: ["windows", "windowlook", "workspaces", "missioncontrol", "hotcorners", "apprules"] },
        { id: "display",    name: "Displays",            glyph: "\u{F0379}", pages: ["displays", "monitor"] },
        { id: "input",      name: "Keyboard & Mouse",    glyph: "\u{F030C}", pages: ["input", "mouse", "touch", "keybinds"] },
        { id: "sound",      name: "Sound",               glyph: "\u{F057E}", pages: ["sound"] },
        { id: "network",    name: "Network & Bluetooth", glyph: "\u{F05A9}", pages: ["network", "bluetooth", "phone"] },
        { id: "power",      name: "Power",               glyph: "\u{F0079}", pages: ["power", "asus"] },
        { id: "lockGroup",  name: "Lock Screen",         glyph: "\u{F033E}", pages: ["lockscreen", "idle"] },
        { id: "tools",      name: "Search & Tools",      glyph: "\u{F0349}", pages: ["launcher", "actions", "clipboard", "capture"] },
        { id: "applications", name: "Apps",              glyph: "\u{F003B}", pages: ["installed", "apps", "startup", "terminal"] },
        { id: "system",     name: "System",              glyph: "\u{F02FD}", pages: ["about", "language"] },
    ]
    // ASUS Hardware only with asusctl; Touch & Tablet only with a touchscreen or the on-screen keyboard
    readonly property var sections: allGroups.map(g => Object.assign({}, g, { pages: g.pages.filter(p => (p !== "asus" || Machine.asus) && (p !== "touch" || Inputs.hasTouchscreen || Osk.installed)) }))
    readonly property var currentGroup: sections.find(g => g.id === section) ?? sections[0]
    function pageName(id) { return allSections.find(p => p.id === id)?.name ?? "" }

    // Pages: what each SettingsPage<Id>.qml is called, and the words search finds it by (Spotlight searches these too)
    readonly property var allSections: [
        { id: "appearance",    name: "Themes",              glyph: "\u{F03D8}", keys: "theme look colour accent font text size corners gaps shadow blur animations motion reduce dark light mode night day border frame window gaps rounding color colors gray grey" },
        { id: "wallpaper",     name: "Wallpaper",           glyph: "\u{F02E9}", keys: "background picture slideshow blur folder colours accent follow wallpaper" },
        { id: "icons",         name: "Icons",               glyph: "\u{F0BC1}", keys: "icon theme papirus" },
        { id: "cursor",        name: "Cursor",              glyph: "\u{F01BF}", keys: "pointer mouse size" },
        { id: "terminal",      name: "Terminal",            glyph: "\u{F018D}", keys: "terminal ghostty shell fish cursor blink animation trail pulse opacity padding prompt transient greeting fastfetch pokemon" },
        { id: "bar",           name: "Menu Bar",            glyph: "\u{F0E7F}", keys: "panel top bottom left right position size floating items widgets clock seconds date 24-hour window title monitor hide autohide hidden status preset layout screen screens save item settings icon label format click right-click scroll tooltip warn critical interval sysinfo readings" },
        { id: "dock",          name: "Dock",                glyph: "\u{F0A1F}", keys: "taskbar pinned apps icon size hide automatically running windows pictures position monitor mark indicator dot line bar ring diamond widgets" },
        { id: "lockscreen",    name: "Lock Screen",         glyph: "\u{F033E}", keys: "lock clock date avatar user picture blur brightness widgets battery media layout lock after password" },
        { id: "controlcenter", name: "Control Center",      glyph: "\u{F0493}", keys: "quick settings tiles toggles sliders shortcuts" },
        { id: "notifications", name: "Notifications",       glyph: "\u{F009A}", keys: "do not disturb dnd sound banners history muted apps osd on-screen display volume brightness microphone mic mute caps lock keyboard layout" },
        { id: "focus",         name: "Focus",               glyph: "\u{F0594}", keys: "focus modes work call meeting sleep do not disturb dnd allow apps schedule wallpaper night light caffeine concentrate quiet" },
        { id: "launcher",      name: "Search & Launcher",   glyph: "\u{F0349}", keys: "spotlight apps files web search actions" },
        { id: "actions",       name: "Actions",             glyph: "\u{F140B}", keys: "actions buttons toggles commands scripts snippets custom run sequence terminal shell" },
        { id: "clipboard",     name: "Clipboard",           glyph: "\u{F014C}", keys: "copy paste history images" },
        { id: "capture",       name: "Screenshots",         glyph: "\u{F0100}", keys: "screenshot screen capture print annotate satty record recording video audio folder delay" },
        { id: "weather",       name: "Weather",             glyph: "\u{F0595}", keys: "city forecast celsius fahrenheit" },
        { id: "calendar",      name: "Calendar",            glyph: "\u{F00ED}", keys: "holidays week numbers moon first day" },
        { id: "missioncontrol", name: "Mission Control",     glyph: "\u{F0570}", keys: "overview expose windows workspaces screens monitors exposé new workspace click" },
        { id: "hotcorners",    name: "Hot Corners",         glyph: "\u{F0A1C}", keys: "corner action" },
        { id: "windows",       name: "Window Behaviour",    glyph: "\u{F05AF}", keys: "layout tiling dwindle master scrolling focus follows mouse split snap gestures swipe" },
        { id: "windowlook",    name: "Window Look",         glyph: "\u{F03D8}", keys: "title bars opacity dim inactive border frame transparent" },
        { id: "apprules",      name: "App Rules",           glyph: "\u{F0493}", keys: "float pin workspace rule" },
        { id: "displays",      name: "Displays",             glyph: "\u{F0379}", keys: "preset presets identify main screen switch monitor resolution scale rotation refresh night light arrangement display screen hdmi external projector brightness vrr adaptive sync freesync gsync hdr highest refresh rate xwayland" },
        { id: "workspaces",    name: "Workspaces",          glyph: "\u{F0570}", keys: "workspace workspaces dynamic fixed persistent assign screen monitor display virtual desktop" },
        { id: "monitor",       name: "Shared Monitor",      glyph: "\u{F0E58}", keys: "ddc input switch kvm mirror" },
        { id: "input",         name: "Keyboard",            glyph: "\u{F030C}", keys: "layout serbian latin repeat keyboard layout language caps lock escape num lock numlock typing" },
        { id: "mouse",         name: "Mouse & Touchpad",    glyph: "\u{F037D}", keys: "mouse touchpad trackpad pointer sensitivity speed acceleration flat left-handed left handed natural scroll wheel tap gestures swipe fingers logitech solaar" },
        { id: "touch",         name: "Touch & Tablet",      glyph: "\u{F0741}", keys: "touchscreen touch screen pen stylus tablet mode rotate rotation on-screen keyboard osk squeekboard swipe 2-in-1" },
        { id: "keybinds",      name: "Keyboard Shortcuts",  glyph: "\u{F0313}", keys: "keys binds hotkeys shortcuts screenshot print capture record" },
        { id: "sound",         name: "Sound",               glyph: "\u{F057E}", keys: "volume output input microphone speakers audio mute headphones" },
        { id: "network",       name: "Wi-Fi & Network",     glyph: "\u{F05A9}", keys: "wifi ethernet internet vpn" },
        { id: "bluetooth",     name: "Bluetooth",           glyph: "\u{F00AF}", keys: "devices headphones pair" },
        { id: "phone",         name: "Phone",               glyph: "\u{F011C}", keys: "phone kde connect kdeconnect android iphone mobile pair battery ring find send file clipboard notifications remote media" },
        { id: "power",         name: "Battery & Power",     glyph: "\u{F0079}", keys: "battery charge limit power profile performance warning laptop energy saver" },
        { id: "idle",          name: "Lock & Sleep",        glyph: "\u{F04B2}", keys: "idle timeout screen off suspend lock after sleep hibernate screen saver dim" },
        { id: "asus",          name: "ASUS Hardware",       glyph: "\u{F061A}", keys: "fan curve keyboard light" },
        { id: "installed",     name: "Installed Apps",      glyph: "\u{F003B}", keys: "uninstall remove packages" },
        { id: "apps",          name: "Default Apps",        glyph: "\u{F003B}", keys: "browser mail terminal file manager task manager open with default" },
        { id: "startup",       name: "Startup Apps",        glyph: "\u{F040A}", keys: "autostart login start on login" },
        { id: "language",      name: "Language & Region",   glyph: "\u{F05CA}", keys: "locale formats date numbers timezone time zone region clock format" },
        { id: "about",         name: "About",               glyph: "\u{F02FD}", keys: "system version hardware update upgrade doctor reinstall version repo channel stable dev develop beta modules gaming ai ollama docker nvidia hibernate login" },
    ]
    // search: pages whose name, group or words match every word typed, then single settings (a row's label,
    // hint or group title) so "blink" finds Terminal > Cursor > Blink; picking a setting scrolls to it and flashes it
    property string query: ""
    readonly property var queryWords: query.trim().toLowerCase().split(/\s+/).filter(w => w)
    readonly property var results: {
        const words = queryWords
        if (!words.length) return []
        const visible = [].concat(...sections.map(g => g.pages.map(p => ({ page: p, group: g.name }))))   // no flatMap in this JS engine
        return visible.map(v => Object.assign({ group: v.group }, allSections.find(x => x.id === v.page)))
            .filter(p => p.id && words.every(w => (p.name + " " + p.group + " " + p.keys).toLowerCase().includes(w)))
    }
    readonly property var rowResults: {
        const words = queryWords
        if (!words.length) return []
        const shown = [].concat(...sections.map(g => g.pages))
        const hit = (r, text) => words.every(w => text.toLowerCase().includes(w))
        const found = rowIndex.filter(r => shown.includes(r.page) && hit(r, r.label + " " + r.hint + " " + r.group))
        // labels that match beat hints that match
        found.sort((a, b) => hit(b, b.label) - hit(a, a.label))
        return found.slice(0, 12)
    }
    function openResult(r) {   // a page result, or a row result ({ page, label, group })
        if (r.label === undefined) { show(r.id); return }
        show(r.page)
        pendingRow = r
        jump.restart()
    }

    // every row's label and hint, and the title of the group it is in, read once from the page files
    property var rowIndex: []
    property var pendingRow: null
    Process {
        running: root.open && root.rowIndex.length === 0
        workingDirectory: Quickshell.shellDir
        command: ["sh", "-c", "grep -nE '(label|hint|title): \"' SettingsPage*.qml"]
        stdout: StdioCollector { onStreamFinished: root.rowIndex = root.parseRows(text) }
    }
    function parseRows(text) {
        const rows = [], group = {}, field = /(label|hint|title): "((?:[^"\\]|\\.)*)"/g
        let last = null
        for (const line of text.split("\n")) {
            const m = /^SettingsPage(\w+)\.qml:(\d+):(.*)$/.exec(line)
            if (!m) continue
            const file = m[1].charAt(0).toLowerCase() + m[1].slice(1)   // DisplaysPresets is part of Displays
            const page = (allSections.find(p => p.id === file) ?? allSections.find(p => file.startsWith(p.id)))?.id
            if (!page) continue
            const n = Number(m[2])
            let f
            field.lastIndex = 0
            while ((f = field.exec(m[3])) !== null) {
                const value = f[2].replace(/\\"/g, '"')
                if (f[1] === "title") group[page] = value
                else if (f[1] === "label") { last = { page, label: value, hint: "", group: group[page] ?? "", line: n }; rows.push(last) }
                else if (last && last.page === page && n - last.line <= 2 && !last.hint) last.hint = value
            }
        }
        return rows
    }
    // after a row result opens its page: once laid out, scroll the row into view and flash it
    Timer { id: jump; interval: 60; onTriggered: if (root.pendingRow) { root.scrollToRow(root.pendingRow); root.pendingRow = null } }

    // s: a group id (its first page), a page id, or "" (where you left off)
    function show(s) {
        const g = sections.find(x => x.id === s) ?? sections.find(x => x.pages.includes(s))
        if (g) { section = g.id; pageId = g.pages.includes(s) ? s : g.pages[0] }
        open = true
    }

    IpcHandler {
        target: "settings"
        function open(section: string): void { root.show(section) }
        function toggle(): void { root.open = !root.open }
        function close(): void { root.open = false }
        // scroll the page: "top", "bottom", "+600"/"-600" (pixels), or a group's title ("Advanced")
        function scroll(where: string): string { return root.scrollPage(where) }
        // open Settings with this in the search field: `qs ipc call settings search blink`
        function search(text: string): void { root.open = true; win.startSearch(); searchField.text = text }
    }
    function scrollPage(where) {
        const max = Math.max(0, page.contentHeight - page.height)
        let y = where === "top" ? 0 : where === "bottom" ? max : /^[+-]\d+$/.test(where) ? page.contentY + Number(where) : -1
        if (y < 0) {   // a group by its title: the first SettingGroup on the page with that title (any case)
            const g = findOnPage(item => item.rows !== undefined && String(item.title).toLowerCase() === where.toLowerCase())
            if (!g) return "no group \"" + where + "\" on " + root.pageId
            y = g.mapToItem(page.contentItem, 0, 0).y - win.pad
        }
        page.contentY = Math.max(0, Math.min(y, max))
        return "scrolled to " + Math.round(page.contentY) + " of " + Math.round(max)
    }
    // the first item on the page that passes test(item, title of the SettingGroup it is in)
    function findOnPage(test) {
        const find = (item, group) => {
            if (test(item, group)) return item
            const g = item.rows !== undefined && item.title !== undefined ? String(item.title) : group
            for (const c of item.children) { const f = find(c, g); if (f) return f }
            return null
        }
        return pageLoader.item ? find(pageLoader.item, "") : null
    }
    function scrollToRow(r) {
        const isRow = (item, g) => item.stacked !== undefined && item.visible && item.label === r.label
        const row = findOnPage((item, g) => isRow(item) && (!r.group || g === r.group)) ?? findOnPage(isRow)
        if (!row) return
        const max = Math.max(0, page.contentHeight - page.height)
        page.contentY = Math.max(0, Math.min(row.mapToItem(page.contentItem, 0, 0).y - page.height / 3, max))
        row.flash()
    }

    // Lua table literal from a plain JS object (strings, numbers, booleans, nested objects)
    function lua(value, indent) {
        indent = indent || ""
        // JSON's \u00XX (control characters) isn't Lua; \xXX is
        if (typeof value === "string") return JSON.stringify(value).replace(/\\\\|\\u00([0-9a-fA-F]{2})/g, (m, h) => h ? "\\x" + h : m)
        if (value === null || value === undefined) return "nil"
        if (typeof value === "number" || typeof value === "boolean") return String(value)
        const inner = indent + "    "
        return "{\n" + Object.keys(value).map(k =>
            inner + "[" + JSON.stringify(k) + "] = " + lua(value[k], inner) + ",").join("\n") + "\n" + indent + "}"
    }

    // Write a text file under ~/.config (Hyprland's settings/ by default). The path and the text go in as
    // arguments, never as part of the script, so nothing in them can run as shell. mkdir: settings/ isn't
    // in git (your own choices), so a fresh install has to create it. Written to a temp file, then moved,
    // so a reader never sees half a file. then: a command line (argv) run after the write.
    function writeConfigFile(rel, text, then) {
        Quickshell.execDetached(["sh", "-c", 'f="$HOME/.config/$1"; mkdir -p "$(dirname "$f")" && printf "%s\\n" "$2" > "$f.tmp" && mv -f "$f.tmp" "$f" && shift 2 && [ $# -gt 0 ] && exec "$@"; true',
                                 "sh", rel, text].concat(then ?? []))
    }
    function writeHyprFile(rel, text) { writeConfigFile("hypr/" + rel, text) }

    FloatingWindow {
        id: win
        // Narrow window: the sidebar shrinks to icons and the page margins tighten; rows put their
        // control under the label when both don't fit (SettingRow). Anything still too big scrolls.
        readonly property bool compact: width < 780
        readonly property int pad: width < 640 ? Theme.spaceL : 28
        // filling (almost) the whole screen means Hyprland has it maximised
        readonly property bool maximised: screen ? width >= screen.width - 80 && height >= screen.height - 120 : false
        // a narrow window shows the search field only while searching (Ctrl+F, or the search button)
        property bool searching: false
        readonly property bool slim: compact && !searching   // the sidebar shows icons only
        function startSearch() { searching = true; searchField.forceActiveFocus() }
        function pick(r) { root.openResult(r); searchField.text = ""; searching = false }

        visible: root.open
        title: "Settings"
        color: "transparent"
        implicitWidth: 1020
        implicitHeight: 760
        minimumSize: Qt.size(460, 360)
        onVisibleChanged: if (!visible) root.open = false

        Glass {
            anchors.fill: parent
            strong: true
            radius: 0
            border.width: 0

            // ---- sidebar ---------------------------------------------------------------------
            Rectangle {
                id: sidebar
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                width: win.slim ? 64 : 240
                color: Theme.sidebar
                MoreBelow { z: 1; flick: nav; ground: Qt.tint(Theme.glassStrong, Theme.sidebar); anchors { left: parent.left; right: parent.right; bottom: parent.bottom } }

                Flickable {
                    id: nav
                    anchors.fill: parent
                    contentHeight: navColumn.implicitHeight + 30
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    QQC.ScrollBar.vertical: GlassScrollBar {}

                    Column {
                        id: navColumn
                        x: 12; y: 18
                        width: sidebar.width - 24
                        spacing: 2

                        Text {
                            visible: !win.slim
                            text: "Settings"
                            leftPadding: 10
                            bottomPadding: 12
                            color: Theme.text
                            font { family: Theme.font; pixelSize: Theme.fontHeading; weight: Font.Bold }
                        }
                        Rectangle {   // narrow window: a search button in place of the field
                            visible: win.slim
                            width: parent.width
                            height: Math.max(34, Theme.hit)
                            radius: Theme.radiusSmall
                            color: findArea.containsMouse ? Theme.fillHover : "transparent"
                            activeFocusOnTab: true
                            Keys.onReturnPressed: win.startSearch()
                            Keys.onSpacePressed: win.startSearch()
                            FocusRing {}
                            Text { anchors.centerIn: parent; text: "\u{F0349}"; color: Theme.text; font { family: Theme.iconFont; pixelSize: Theme.glyph } }
                            MouseArea { id: findArea; Accessible.role: Accessible.Button; Accessible.name: "Search settings"; Accessible.onPressAction: win.startSearch()
                                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.startSearch() }
                            ToolTipText { shown: findArea.containsMouse; text: "Search settings (Ctrl+F)" }
                        }
                        TextField {   // search: type to list matching pages and settings, Enter opens the first
                            id: searchField
                            visible: !win.slim
                            width: parent.width
                            placeholder: "Search settings"
                            accessibleName: "Search settings"
                            onTextChanged: root.query = text
                            onAccepted: { const r = root.results[0] ?? root.rowResults[0]; if (r) win.pick(r) }
                            Keys.onEscapePressed: { if (text !== "") text = ""; else win.searching = false }
                            Keys.onDownPressed: nextItemInFocusChain(true).forceActiveFocus()   // into the results or the sidebar
                        }
                        Item { width: 1; height: 8; visible: searchField.visible }
                        Column {   // nothing found: say so, and what does work
                            visible: root.queryWords.length > 0 && root.results.length === 0 && root.rowResults.length === 0
                            width: parent.width
                            leftPadding: 10; topPadding: 6; spacing: 4
                            Text { width: parent.width - 10; wrapMode: Text.Wrap; text: "Nothing matches \u201C" + root.query.trim() + "\u201D"; color: Theme.text
                                   font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.Medium } }
                            Text { width: parent.width - 10; wrapMode: Text.Wrap; text: "Try one word, like volume, dark or blink"; color: Theme.subtext
                                   font { family: Theme.font; pixelSize: Theme.fontCaption } }
                        }
                        Repeater {   // search results replace the groups while there is a query: pages first
                            model: root.results
                            SettingsSearchResult { required property var modelData; glyph: modelData.glyph; title: modelData.name; place: modelData.group; onChosen: win.pick(modelData) }
                        }
                        Text {
                            visible: root.rowResults.length > 0
                            leftPadding: 10; topPadding: root.results.length ? 10 : 2; bottomPadding: 2
                            text: "Settings"
                            color: Theme.subtext
                            font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
                        }
                        Repeater {   // then single settings
                            model: root.rowResults
                            SettingsSearchResult { required property var modelData; onChosen: win.pick(modelData); glyph: root.allSections.find(p => p.id === modelData.page)?.glyph ?? ""; title: modelData.label
                                           place: root.pageName(modelData.page) + (modelData.group ? " \u203A " + modelData.group : "") }
                        }

                        Repeater {
                            model: root.query.trim() === "" ? root.sections : []
                            Column {
                                id: navGroup
                                required property var modelData
                                readonly property bool current: root.section === modelData.id
                                readonly property bool open: current && modelData.pages.length > 1 && !win.slim
                                width: parent.width
                                spacing: 2
                                Rectangle {
                                    width: parent.width
                                    height: Math.max(34, Theme.hit)
                                    radius: Theme.radiusSmall
                                    // keyboard: Tab to the sidebar, Up / Down through it, Enter opens
                                    activeFocusOnTab: true
                                    Keys.onReturnPressed: root.show(modelData.id)
                                    Keys.onSpacePressed: root.show(modelData.id)
                                    Keys.onDownPressed: nextItemInFocusChain(true).forceActiveFocus()
                                    Keys.onUpPressed: nextItemInFocusChain(false).forceActiveFocus()
                                    FocusRing {}
                                    // one mark per place: a group with its pages open shows them instead of a plate
                                    readonly property bool plate: current && !navGroup.open
                                    color: plate ? Theme.fillActive : navArea.containsMouse ? Theme.fillHover : "transparent"
                                    border { color: plate ? Theme.stroke : "transparent"; width: 1 }
                                    Row {
                                        anchors { left: parent.left; leftMargin: win.slim ? (parent.width - 24) / 2 : 10; verticalCenter: parent.verticalCenter }
                                        spacing: 10
                                        Rectangle {
                                            width: 24; height: 24; radius: Math.min(7, Theme.radiusSmall)
                                            color: current ? Theme.accent : Theme.fill
                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.glyph
                                                color: current ? Theme.accentText : Theme.text
                                                font { family: Theme.iconFont; pixelSize: Theme.iconSmall - 2 }
                                            }
                                            Rectangle {   // Hyprism has updates (Settings > About says which)
                                                visible: modelData.id === "system" && Updates.count > 0
                                                anchors { right: parent.right; top: parent.top; margins: -3 }
                                                width: 9; height: 9; radius: 4.5
                                                color: Theme.accent
                                                border { color: Theme.base; width: 1.5 }
                                            }
                                        }
                                        Text {
                                            visible: !win.slim
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: sidebar.width - 24 - 54
                                            elide: Text.ElideRight
                                            text: modelData.name
                                            color: Theme.text
                                            font { family: Theme.font; pixelSize: Theme.fontLabel; weight: current ? Font.DemiBold : Font.Normal }
                                        }
                                    }
                                    MouseArea { id: navArea; Accessible.role: Accessible.Button; Accessible.name: modelData.name; Accessible.onPressAction: root.show(modelData.id); anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.show(modelData.id) }
                                }
                                // submenu: the open group's pages
                                Repeater {
                                    model: navGroup.open ? navGroup.modelData.pages : []
                                    Rectangle {
                                        required property string modelData
                                        readonly property bool current: root.pageId === modelData
                                        width: parent.width
                                        height: Math.max(30, Theme.hit)
                                        radius: Theme.radiusSmall
                                        activeFocusOnTab: true
                                        Keys.onReturnPressed: root.show(modelData)
                                        Keys.onSpacePressed: root.show(modelData)
                                        Keys.onDownPressed: nextItemInFocusChain(true).forceActiveFocus()
                                        Keys.onUpPressed: nextItemInFocusChain(false).forceActiveFocus()
                                        FocusRing {}
                                        color: subArea.containsMouse && !current ? Theme.fillHover : "transparent"
                                        Rectangle {   // a short accent bar beside the page you're on
                                            visible: parent.current
                                            anchors { left: parent.left; leftMargin: 26; verticalCenter: parent.verticalCenter }
                                            width: 3; height: 14; radius: 1.5
                                            color: Theme.accent
                                        }
                                        Text {
                                            anchors { left: parent.left; leftMargin: 44; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                                            text: root.pageName(modelData)
                                            elide: Text.ElideRight
                                            color: parent.current ? Theme.text : Theme.subtext
                                            font { family: Theme.font; pixelSize: Theme.fontLabel; weight: parent.current ? Font.DemiBold : Font.Normal }
                                        }
                                        MouseArea { id: subArea; Accessible.role: Accessible.Button; Accessible.name: modelData; Accessible.onPressAction: root.show(modelData); anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.show(modelData) }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle { // divider
                anchors { left: sidebar.right; top: parent.top; bottom: parent.bottom }
                width: 1
                color: Theme.stroke
            }

            // ---- page ------------------------------------------------------------------------
            Flickable {
                id: page
                anchors { left: sidebar.right; leftMargin: 1; right: parent.right; top: parent.top; bottom: parent.bottom }
                contentHeight: pageColumn.implicitHeight + win.pad * 2
                contentWidth: pageColumn.width + win.pad * 2     // wider than the window only below ~340 px of page
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                QQC.ScrollBar.vertical: GlassScrollBar {}
                QQC.ScrollBar.horizontal: GlassScrollBar {}

                Connections { target: root; function onPageIdChanged() { page.contentY = 0; page.contentX = 0 } }
                // Page Up / Page Down scroll the page wherever the keyboard focus is (the Flickable has no keys of its own)
                Shortcut { sequence: "PgDown"; context: Qt.WindowShortcut; onActivated: root.scrollPage("+" + Math.round(page.height * 0.85)) }
                Shortcut { sequence: "Ctrl+F"; context: Qt.WindowShortcut; onActivated: win.startSearch() }
                Shortcut { sequence: "PgUp"; context: Qt.WindowShortcut; onActivated: root.scrollPage("-" + Math.round(page.height * 0.85)) }

                ColumnLayout {
                    id: pageColumn
                    x: win.pad; y: win.pad
                    width: Math.max(page.width - win.pad * 2, 340)
                    spacing: 16

                    Text {   // the page's title; the sidebar already shows its group
                        Layout.fillWidth: true
                        Layout.rightMargin: 100   // clear of the window buttons
                        text: root.pageName(root.pageId)
                        elide: Text.ElideRight
                        color: Theme.text
                        font { family: Theme.displayFont; pixelSize: Theme.fontHeading + 1; weight: Theme.displayWeight > Font.Medium ? Theme.displayWeight : Font.Bold }
                    }

                    // narrow window: the sidebar shows icons only, so the group's pages become tabs
                    Choice {
                        visible: win.compact && root.currentGroup.pages.length > 1
                        options: root.currentGroup.pages.map(p => root.pageName(p))
                        index: root.currentGroup.pages.indexOf(root.pageId)
                        onPicked: i => root.show(root.currentGroup.pages[i])
                    }

                    Loader {
                        id: pageLoader
                        Layout.fillWidth: true
                        active: root.open
                        source: "SettingsPage" + root.pageId.charAt(0).toUpperCase() + root.pageId.slice(1) + ".qml"
                        // a new page fades in and rises a few pixels, so the swap reads as a change, not a flash
                        onLoaded: pageIn.restart()
                        transform: Translate { id: pageShift }
                        ParallelAnimation {
                            id: pageIn
                            NumberAnimation { target: pageLoader; property: "opacity"; from: 0; to: 1; duration: Theme.anim; easing.type: Theme.easing }
                            NumberAnimation { target: pageShift; property: "y"; from: Theme.moves ? 10 : 0; to: 0; duration: Theme.anim; easing.type: Theme.easing }
                        }
                    }
                }
            }
            MoreBelow { flick: page; anchors { left: page.left; right: page.right; bottom: page.bottom; rightMargin: 12 } }   // never a row cut in half

            // ---- window buttons: minimise, maximise, close (the shell draws its own, like a GTK app) ----
            Row {
                anchors { top: parent.top; right: parent.right; margins: 12 }
                spacing: 8
                Repeater {
                    model: [
                        { glyph: "\u{F05B0}", tip: "Minimise", act: () => Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.window.move({ workspace = \"special:minimized\", follow = false })"]) },
                        { glyph: win.maximised ? "\u{F05B2}" : "\u{F05AF}", tip: win.maximised ? "Restore" : "Maximise", act: () => Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.window.fullscreen({ action = \"toggle\", mode = \"maximized\" })"]) },
                        { glyph: "\u{F05AD}", tip: "Close", act: () => root.open = false }
                    ]
                    Rectangle {
                        required property var modelData
                        width: 24; height: 24; radius: Theme.radiusSmall
                        color: btnArea.pressed ? Theme.fillActive : btnArea.containsMouse ? Theme.fillHover : Theme.fill
                        border { color: Theme.stroke; width: 1 }
                        Text {
                            anchors.centerIn: parent
                            text: modelData.glyph
                            color: Theme.text
                            font { family: Theme.iconFont; pixelSize: Theme.glyphS }
                        }
                        MouseArea { id: btnArea; Accessible.role: Accessible.Button; Accessible.name: modelData.tip; Accessible.onPressAction: modelData.act(); anchors.fill: parent; hoverEnabled: true; onClicked: modelData.act() }
                        ToolTipText { shown: btnArea.containsMouse; text: modelData.tip }
                    }
                }
            }
        }
    }
}
