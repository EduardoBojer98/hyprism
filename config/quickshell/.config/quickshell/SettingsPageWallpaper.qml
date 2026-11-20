import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

// Wallpaper: what is shown now (with next, pause and show-in-Files), a library of every picture and video in the
// folders plus every theme's own (filter by kind or name; click one to use it; hover for lock screen and Files),
// the folders, the slideshow, video, blur and colour settings. With the slideshow on "Selected", the round badge
// on each tile adds it to or removes it from the rotation. Opening the page rescans the folders.
ColumnLayout {
    id: page
    spacing: 20

    readonly property var c: Config.wallpaper
    readonly property bool picking: c.slideshow && c.source === "selected"
    property string folderError: ""

    // the screen being changed ("" = every screen without one of its own); the picker shows with two screens or more
    property string target: ""
    readonly property var screens: Hyprland.monitors.values.filter(m => Machine.realScreen(m.name))
    readonly property bool own: target !== "" && Wallpapers.screens[target] !== undefined
    readonly property string cur: target ? Wallpapers.on(target) : Wallpapers.current
    readonly property bool curVideo: Wallpapers.isVideo(cur)
    readonly property string home: Quickshell.env("HOME")
    function name(p) { return p.split("/").pop() }
    function tilde(p) { return p.startsWith(home + "/") ? "~" + p.slice(home.length) : p }
    function kind(p) { return Wallpapers.isVideo(p) ? "Video" : Wallpapers.isTheme(p) ? "Theme picture" : "Picture" }

    // library filter: 0 all, 1 pictures, 2 videos, 3 themes
    property int filter: 0
    readonly property var kinds: [p => true, p => !Wallpapers.isVideo(p) && !Wallpapers.isTheme(p), p => Wallpapers.isVideo(p), p => Wallpapers.isTheme(p)]
    readonly property var counts: kinds.map(k => Wallpapers.images.filter(k).length)
    readonly property var shown: {
        const q = search.text.trim().toLowerCase()
        return Wallpapers.images.filter(p => kinds[filter](p) && (q === "" || name(p).toLowerCase().includes(q)))
    }

    // tiles fill the row: as many 200 px+ columns as fit
    readonly property int cols: Math.max(1, Math.floor((grid.width + 14) / 214))
    readonly property real tileW: Math.floor((grid.width - 14 * (cols - 1)) / cols)

    // a round button over a picture (dark, so it reads on light and dark pictures alike)
    component TileButton: Rectangle {
        id: tb
        property string glyph
        property string tip
        signal clicked()
        width: 28; height: 28; radius: 14
        color: tbArea.containsMouse ? Qt.rgba(0, 0, 0, 0.75) : Qt.rgba(0, 0, 0, 0.55)
        Accessible.role: Accessible.Button
        Accessible.name: tb.tip
        Accessible.onPressAction: tb.clicked()
        Text { anchors.centerIn: parent; text: tb.glyph; color: "white"; font { family: Theme.iconFont; pixelSize: Theme.iconSmall } }
        MouseArea { id: tbArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tb.clicked() }
        ToolTipText { shown: tbArea.containsMouse; text: tb.tip }
    }

    function addFolder(path) {
        path = path.trim().replace(/\/+$/, "")
        if (!path) return
        if (c.folders.includes(path)) { folderError = "Already in the list"; return }
        check.path = path
        check.running = true
    }
    function toggleSelected(path) {
        const s = c.selected
        Config.set("wallpaper", "selected", s.includes(path) ? s.filter(p => p !== path) : s.concat([path]))
    }

    Component.onCompleted: Wallpapers.refresh()   // files added since the last look show up

    // the folder has to exist before it goes in the list
    Process {
        id: check
        property string path
        command: ["sh", "-c", "[ -d \"$1\" ]", "sh", Wallpapers.expand(path)]
        onExited: code => {
            if (code === 0) { Config.set("wallpaper", "folders", page.c.folders.concat([path])); folderInput.text = ""; page.folderError = "" }
            else page.folderError = "No such folder"
        }
    }
    // folder picker (GTK file dialog via zenity)
    Process {
        id: browse
        command: ["zenity", "--file-selection", "--directory", "--title=Wallpaper folder", "--filename=" + Quickshell.env("HOME") + "/Pictures/"]
        stdout: StdioCollector { onStreamFinished: if (text.trim()) page.addFolder(text.trim()) }
    }

    // ── Now showing ──
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: now.implicitHeight + 2 * Theme.spaceL
        radius: Theme.radius
        color: Theme.fill
        border { color: Theme.stroke; width: 1 }

        GridLayout {
            id: now
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceL }
            columns: width > 560 ? 2 : 1
            columnSpacing: Theme.spaceL
            rowSpacing: Theme.spaceM

            Rectangle {
                Layout.preferredWidth: 256; Layout.preferredHeight: 160
                radius: Theme.radiusSmall
                color: Theme.fillActive
                clip: true
                Image {
                    anchors.fill: parent
                    source: page.cur ? "file://" + Wallpapers.still(page.cur) : ""
                    sourceSize: Qt.size(512, 320)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
                Rectangle {
                    visible: page.curVideo
                    anchors { left: parent.left; bottom: parent.bottom; margins: 8 }
                    width: 24; height: 24; radius: 12
                    color: Qt.rgba(0, 0, 0, 0.45)
                    Text { anchors.centerIn: parent; text: Wallpapers.userPaused ? "\u{F03E4}" : "\u{F040A}"; color: "white"; font { family: Theme.iconFont; pixelSize: Theme.iconSmall } }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: Theme.spaceXs
                Choice {
                    visible: page.screens.length > 1
                    Layout.bottomMargin: Theme.spaceS
                    accessibleName: "Screen to change"
                    options: ["Every screen"].concat(page.screens.map(m => Displays.label(m) + (Wallpapers.screens[m.name] ? " \u00b7 own" : "")))
                    index: Math.max(0, page.screens.findIndex(m => m.name === page.target) + 1)
                    onPicked: i => page.target = i === 0 ? "" : page.screens[i - 1].name
                }
                Text {
                    Layout.fillWidth: true
                    visible: page.screens.length > 1
                    text: page.target === "" ? (Object.keys(Wallpapers.screens).length ? "Screens marked own keep theirs. Pick one to change it on its own." : "Pick a screen to give it a wallpaper of its own.")
                        : page.own ? "Has its own wallpaper. The slideshow and Focus modes leave it be." : "Shows the same wallpaper as the others. Pick one below to give it its own."
                    wrapMode: Text.Wrap
                    color: Theme.muted
                    font { family: Theme.font; pixelSize: Theme.fontCaption }
                }
                Text {
                    Layout.fillWidth: true
                    text: page.cur ? page.name(page.cur) : "No wallpaper yet"
                    elide: Text.ElideMiddle
                    color: Theme.text
                    font { family: Theme.font; pixelSize: Theme.fontTitle; weight: Font.DemiBold }
                }
                Text {
                    Layout.fillWidth: true
                    visible: page.cur !== ""
                    text: page.kind(page.cur) + " · " + page.tilde(page.cur.slice(0, page.cur.lastIndexOf("/")))
                    elide: Text.ElideMiddle
                    color: Theme.subtext
                    font { family: Theme.font; pixelSize: Theme.fontLabel }
                }
                Text {
                    Layout.fillWidth: true
                    visible: page.curVideo
                    text: Wallpapers.userPaused ? "Paused by you until the next wallpaper"
                        : Wallpapers.batteryPause ? "Paused on battery (Play on battery is below)"
                        : page.c.livePause === "windows" ? "Plays on an empty workspace, pauses behind any window"
                        : "Plays, and pauses behind fullscreen windows"
                    wrapMode: Text.Wrap
                    color: Theme.muted
                    font { family: Theme.font; pixelSize: Theme.fontCaption }
                }
                Text {
                    Layout.fillWidth: true
                    visible: page.c.slideshow
                    text: "Slideshow: " + Wallpapers.pool.length + (Wallpapers.pool.length === 1 ? " wallpaper" : " wallpapers") + (page.c.order === "shuffle" ? ", shuffled" : ", by name")
                    color: Theme.muted
                    font { family: Theme.font; pixelSize: Theme.fontCaption }
                }
                Flow {
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.spaceS
                    spacing: Theme.spaceS
                    PillButton { text: "Next"; visible: Wallpapers.pool.length > 1 && !page.own; onClicked: Wallpapers.next() }
                    PillButton { text: "Same as the other screens"; visible: page.own; onClicked: Wallpapers.shared(page.target) }
                    PillButton { text: Wallpapers.userPaused ? "Play" : "Pause"; visible: page.curVideo; onClicked: Wallpapers.userPaused = !Wallpapers.userPaused }
                    PillButton { text: "Show in Files"; visible: page.cur !== ""; onClicked: Wallpapers.reveal(page.cur) }
                }
            }
        }
    }

    // ── Library ──
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Theme.spaceM

        Flow {
            Layout.fillWidth: true
            spacing: Theme.spaceS
            Choice {
                accessibleName: "Show"
                options: ["All " + page.counts[0], "Pictures " + page.counts[1], "Videos " + page.counts[2], "Themes " + page.counts[3]]
                index: page.filter
                onPicked: i => page.filter = i
            }
            TextField { id: search; width: 180; placeholder: "Filter by name"; accessibleName: "Filter wallpapers by name" }
            PillButton { text: "Rescan"; onClicked: Wallpapers.refresh() }
        }

        Text {
            Layout.fillWidth: true
            visible: Wallpapers.images.length === 0 || page.shown.length === 0
            text: Wallpapers.images.length === 0
                ? "No pictures or videos found. Add .png, .jpg or .webp pictures, or .mp4, .webm, .mkv or .mov videos, to one of the folders below."
                : "Nothing matches."
            color: Theme.subtext
            wrapMode: Text.Wrap
            font { family: Theme.font; pixelSize: Theme.fontLabel }
        }

        Flow {
            id: grid
            Layout.fillWidth: true
            spacing: 14
            Repeater {
                model: page.shown
                Column {
                    id: tile
                    required property string modelData
                    readonly property bool isCurrent: modelData === page.cur
                    readonly property bool inRotation: page.c.selected.includes(modelData)
                    readonly property bool video: Wallpapers.isVideo(modelData)
                    spacing: 6
                    Rectangle {
                        width: page.tileW; height: Math.round(page.tileW * 0.625); radius: Theme.radius
                        color: Theme.fill
                        border { color: tile.isCurrent ? Theme.accent : Theme.stroke; width: tile.isCurrent ? 2 : 1 }
                        clip: true
                        HoverHandler { id: hover }
                        Image {
                            anchors { fill: parent; margins: 2 }
                            source: "file://" + Wallpapers.still(tile.modelData)
                            sourceSize: Qt.size(400, 250)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Wallpapers.pick(tile.modelData, page.target)
                            Accessible.role: Accessible.Button
                            Accessible.name: "Use " + page.name(tile.modelData) + " as the wallpaper"
                            Accessible.onPressAction: Wallpapers.pick(tile.modelData, page.target)
                        }
                        Rectangle {   // a video (live wallpaper)
                            visible: tile.video
                            anchors { left: parent.left; bottom: parent.bottom; margins: 8 }
                            width: 24; height: 24; radius: 12
                            color: Qt.rgba(0, 0, 0, 0.45)
                            Text { anchors.centerIn: parent; text: "\u{F040A}"; color: "white"; font { family: Theme.iconFont; pixelSize: Theme.iconSmall } }
                            Accessible.role: Accessible.StaticText
                            Accessible.name: "Video"
                        }
                        Rectangle {   // the one shown now
                            visible: tile.isCurrent
                            anchors { right: parent.right; bottom: parent.bottom; margins: 8 }
                            width: 24; height: 24; radius: 12
                            color: Theme.accent
                            Text { anchors.centerIn: parent; text: "\u{F012C}"; color: Theme.accentText; font { family: Theme.iconFont; pixelSize: Theme.iconSmall } }
                            Accessible.role: Accessible.StaticText
                            Accessible.name: "Shown now"
                        }
                        Row {   // on hover: lock screen, Files
                            visible: hover.hovered
                            anchors { left: parent.left; top: parent.top; margins: 8 }
                            spacing: 6
                            TileButton {
                                visible: !tile.video
                                glyph: Config.lockscreen.wallpaper === tile.modelData ? "\u{F012C}" : "\u{F033E}"
                                tip: Config.lockscreen.wallpaper === tile.modelData ? "On the lock screen (click: follow the desktop again)" : "Use on the lock screen"
                                onClicked: Config.set("lockscreen", "wallpaper", Config.lockscreen.wallpaper === tile.modelData ? "" : tile.modelData)
                            }
                            TileButton { glyph: "\u{F0770}"; tip: "Show in Files"; onClicked: Wallpapers.reveal(tile.modelData) }
                        }
                        Rectangle {   // slideshow badge
                            visible: page.picking
                            anchors { right: parent.right; top: parent.top; margins: 8 }
                            width: 24; height: 24; radius: 12
                            color: tile.inRotation ? Theme.accent : Qt.rgba(0, 0, 0, 0.45)
                            border { color: Qt.rgba(1, 1, 1, 0.7); width: tile.inRotation ? 0 : 1.5 }
                            Text { anchors.centerIn: parent; visible: tile.inRotation; text: "\u{F012C}"; color: Theme.accentText; font { family: Theme.iconFont; pixelSize: Theme.iconSmall } }
                            MouseArea { anchors { fill: parent; margins: -4 } cursorShape: Qt.PointingHandCursor; onClicked: page.toggleSelected(tile.modelData); Accessible.role: Accessible.CheckBox; Accessible.name: "In the slideshow: " + page.name(tile.modelData); Accessible.checked: tile.inRotation }
                        }
                    }
                    Text {
                        width: page.tileW
                        text: page.name(tile.modelData)
                        elide: Text.ElideMiddle
                        color: tile.isCurrent ? Theme.text : Theme.subtext
                        font { family: Theme.font; pixelSize: Theme.fontCaption }
                    }
                }
            }
        }

        // files in the folders that can't be used, named so a missing wallpaper has an answer
        Text {
            Layout.fillWidth: true
            visible: Wallpapers.skipped.length > 0
            readonly property var names: Wallpapers.skipped.map(page.name)
            text: (names.length === 1 ? "1 file can't be used: " : names.length + " files can't be used: ")
                + names.slice(0, 3).join(", ") + (names.length > 3 ? " and " + (names.length - 3) + " more" : "")
                + ". Wallpapers are .png, .jpg, .webp pictures or .mp4, .webm, .mkv, .mov videos."
            wrapMode: Text.Wrap
            color: Theme.muted
            font { family: Theme.font; pixelSize: Theme.fontCaption }
        }
    }

    SettingGroup {
        title: "Folders"
        Repeater {
            model: page.c.folders
            SettingRow {
                required property string modelData
                readonly property var inside: Wallpapers.images.filter(p => p.startsWith(Wallpapers.expand(modelData) + "/"))
                readonly property int videos: inside.filter(Wallpapers.isVideo).length
                label: modelData
                hint: inside.length === 0 ? "Empty, or missing" : [inside.length - videos > 0 ? (inside.length - videos) + (inside.length - videos === 1 ? " picture" : " pictures") : "",
                                                                    videos > 0 ? videos + (videos === 1 ? " video" : " videos") : ""].filter(x => x).join(" · ")
                PillButton { text: "Open"; onClicked: Quickshell.execDetached(["xdg-open", Wallpapers.expand(modelData)]) }
                PillButton { text: "Remove"; enabled: page.c.folders.length > 1; onClicked: Config.set("wallpaper", "folders", page.c.folders.filter(f => f !== modelData)) }
            }
        }
        SettingRow {
            label: "Add a folder"
            hint: page.folderError !== "" ? page.folderError : "Type a path (~ works) or browse. Subfolders one level down are included."
            TextField { id: folderInput; width: 200; placeholder: "~/Pictures/Backgrounds"; invalid: page.folderError !== ""; onAccepted: page.addFolder(text) }
            PillButton { text: "Add"; onClicked: page.addFolder(folderInput.text) }
            PillButton { text: "Browse…"; onClicked: browse.running = true }
        }
    }

    SettingGroup {
        title: "Slideshow"
        SettingRow {
            label: "Change the wallpaper automatically"
            ConfigToggle { section: "wallpaper"; key: "slideshow" }
        }
        SettingRow {
            visible: page.c.slideshow
            label: "Every"
            ConfigChoice { section: "wallpaper"; key: "interval"; values: [5, 15, 30, 60, 180, 1440]; labels: ["5 min", "15 min", "30 min", "1 h", "3 h", "Day"] }
        }
        SettingRow {
            visible: page.c.slideshow
            label: "Use"
            hint: page.c.source === "selected" ? `${Wallpapers.pool.length} picked: click the round badge on a wallpaper to add or remove it` : `All ${Wallpapers.images.length} wallpapers in the library`
            ConfigChoice { section: "wallpaper"; key: "source"; values: ["all", "selected"]; labels: ["All", "Selected"] }
        }
        SettingRow {
            visible: page.c.slideshow
            label: "Order"
            ConfigChoice { section: "wallpaper"; key: "order"; values: ["shuffle", "name"]; labels: ["Shuffle", "By name"] }
        }
    }

    SettingGroup {
        title: "Video wallpapers"
        visible: Wallpapers.images.some(p => Wallpapers.isVideo(p))
        SettingRow {
            label: "Pause behind"
            hint: "A playing video about doubles the power the desktop uses, even behind windows"
            ConfigChoice { section: "wallpaper"; key: "livePause"; values: ["fullscreen", "windows"]; labels: ["Fullscreen windows", "Any window"] }
        }
        SettingRow {
            label: "Play on battery"
            hint: "Off: the video stands still on battery"
            ConfigToggle { section: "wallpaper"; key: "liveOnBattery" }
        }
    }

    SettingGroup {
        title: "Look"
        SettingRow {
            label: "Blur"
            hint: "The desktop only (a video's still frame, not the video); the lock screen has its own blur in Lock Screen"
            ConfigSlider { section: "wallpaper"; key: "blur"; from: 0; to: 30; step: 1; format: v => v === 0 ? "Off" : String(v) }
        }
        SettingRow {
            label: "Colours from the wallpaper"
            hint: "The accent colours follow your own picture. Off: the theme's own colours."
            ConfigToggle { section: "appearance"; key: "wallpaperColours" }
        }
    }

    ResetGroup { sections: ["wallpaper"] }
}
