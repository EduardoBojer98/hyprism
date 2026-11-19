import Quickshell
import Quickshell.Io
import QtQuick

// Quick Look's sheet: a large preview of one file. Images as they are, PDFs as their first pages (pdftoppm), videos
// as one frame (ffmpegthumbnailer or ffmpeg), text and code as their first lines in mono, folders as their listing,
// anything else as its icon, size and type. Shown by QuickLook.qml, over the launcher or on its own.
Glass {
    id: view
    // a path as a file URL; "#", "%", "?" in a name would otherwise break it
    function url(p) { return "file://" + p.split("/").map(encodeURIComponent).join("/") }
    property string path: ""
    strong: true
    radius: Math.max(Theme.radiusLarge, 14)

    readonly property string name: path.replace(/\/$/, "").split("/").pop()
    readonly property string cacheDir: Quickshell.env("HOME") + "/.cache/hyprism/quicklook"
    property string mime: ""
    property real bytes: -1
    property string kind: ""         // image | pages | frame | text | none, once `probe` answers
    property var pages: []           // rendered PNGs (PDF pages, the video frame)
    property string body: ""         // text, or a folder's listing
    property int pageCount: 0
    property bool busy: false
    property int serial: 0           // a fresh file name per preview, so Image never shows a stale cache

    function sizeText(b) {
        if (b < 0) return ""
        const u = ["B", "KB", "MB", "GB", "TB"]
        let i = 0
        while (b >= 1024 && i < u.length - 1) { b /= 1024; i++ }
        return (i ? b.toFixed(b < 10 ? 1 : 0) : b) + " " + u[i]
    }
    readonly property string typeText: mime === "inode/directory" ? "Folder"
        : kind === "pages" ? "PDF" + (pageCount ? " · " + pageCount + (pageCount === 1 ? " page" : " pages") : "")
        : (/\.(\w{1,5})$/.exec(name)?.[1] ?? mime.split("/").pop().replace(/^x-/, "")).toUpperCase()

    onPathChanged: {
        kind = ""; pages = []; body = ""; mime = ""; bytes = -1; pageCount = 0
        if (!path) return
        busy = true
        probe.command = ["sh", "-c", "file -Lb --mime-type -- \"$1\"; stat -Lc %s -- \"$1\"", "probe", path]
        probe.running = true
    }

    Process {
        id: probe
        property string ran
        onStarted: ran = command[4]
        onExited: if (ran !== command[4]) running = true   // the file changed while it ran: now for the new one
        stdout: StdioCollector {
            onStreamFinished: {
                if (probe.ran !== view.path) return
                const l = text.trim().split("\n")
                view.mime = l[0] ?? ""
                view.bytes = Number(l[1] ?? -1)
                const m = view.mime, p = view.path
                view.serial++
                if (m.startsWith("image/")) { view.kind = "image"; view.busy = false }
                else if (m === "application/pdf") {
                    view.kind = "pages"
                    render.command = ["sh", "-c", "rm -rf \"$1\"; mkdir -p \"$1/$3\"; pdfinfo -- \"$2\" 2>/dev/null | sed -n 's/^Pages: *//p';"
                        + " pdftoppm -png -r 90 -f 1 -l 3 -- \"$2\" \"$1/$3/p\" 2>/dev/null; ls \"$1/$3\"/*.png 2>/dev/null",
                        "pdf", view.cacheDir, p, String(view.serial)]
                    render.running = true
                } else if (m.startsWith("video/")) {
                    view.kind = "frame"
                    render.command = ["sh", "-c", "rm -rf \"$1\"; mkdir -p \"$1/$3\"; o=\"$1/$3/f.png\"; if command -v ffmpegthumbnailer >/dev/null;"
                        + " then ffmpegthumbnailer -s 1280 -i \"$2\" -o \"$o\" 2>/dev/null; else ffmpeg -v quiet -ss 3 -i \"$2\" -frames:v 1 \"$o\"; fi; echo; ls \"$o\" 2>/dev/null",
                        "video", view.cacheDir, p, String(view.serial)]
                    render.running = true
                } else if (m === "inode/directory") {
                    view.kind = "text"
                    read.command = ["sh", "-c", "ls -Ap --group-directories-first -- \"$1\" | head -200", "ls", p]
                    read.running = true
                } else if (m.startsWith("text/") || /json|xml|javascript|x-sh|x-empty|yaml|toml|php|sql|x-ruby|x-perl/.test(m)) {
                    view.kind = "text"
                    read.command = ["sh", "-c", "head -c 65536 -- \"$1\" | head -400", "head", p]
                    read.running = true
                } else { view.kind = "none"; view.busy = false }
            }
        }
    }
    // first line: the page count (PDF) or empty; then the PNGs it wrote
    Process {
        id: render
        property string ran
        onStarted: ran = command[6]
        onExited: if (ran !== command[6]) running = true
        stdout: StdioCollector {
            onStreamFinished: {
                if (render.ran !== String(view.serial)) return
                const l = text.split("\n")
                view.pageCount = Number(l[0]) || 0
                view.pages = l.slice(1).filter(s => s.endsWith(".png")).map(s => view.url(s))
                if (!view.pages.length) view.kind = "none"
                view.busy = false
            }
        }
    }
    Process {
        id: read
        property string ran
        onStarted: ran = command[4]
        onExited: if (ran !== command[4]) running = true
        stdout: StdioCollector { onStreamFinished: { if (read.ran !== read.command[4]) return; view.body = text.replace(/\t/g, "    "); view.busy = false } }
    }

    // ---- the sheet: title row, preview, key hints ------------------------------------------------
    Item {
        id: head
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceL }
        height: title.implicitHeight + meta.implicitHeight + 2
        Text {
            id: title
            width: parent.width
            text: view.name
            elide: Text.ElideMiddle
            color: Theme.text
            font { family: Theme.font; pixelSize: Theme.fontTitle; weight: Font.DemiBold }
        }
        Text {
            id: meta
            anchors.top: title.bottom
            anchors.topMargin: 2
            width: parent.width
            text: [view.typeText, view.sizeText(view.bytes), view.path.replace(Quickshell.env("HOME"), "~")].filter(s => s).join("  ·  ")
            elide: Text.ElideMiddle
            color: Theme.subtext
            font { family: Theme.font; pixelSize: Theme.fontCaption }
        }
    }

    Item {
        id: stage
        anchors { left: parent.left; right: parent.right; top: head.bottom; bottom: hints.top; margins: Theme.spaceL; topMargin: Theme.spaceM }
        clip: true

        Image {
            visible: view.kind === "image" || view.kind === "frame"
            anchors.fill: parent
            source: view.kind === "image" ? view.url(view.path) : view.kind === "frame" ? (view.pages[0] ?? "") : ""
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            cache: false
            smooth: true
            mipmap: true
            sourceSize { width: Math.ceil(width * 2); height: Math.ceil(height * 2) }
            // a video's frame gets a play mark: Enter plays it in your video app
            Rectangle {
                visible: view.kind === "frame" && parent.status === Image.Ready
                anchors.centerIn: parent
                width: 64; height: 64; radius: 32
                color: Qt.rgba(0, 0, 0, 0.45)
                Text { anchors.centerIn: parent; anchors.horizontalCenterOffset: 3; text: "\u{F040A}"; color: "white"; font { family: Theme.font; pixelSize: 30 } }   // palette, one-off: on the dark disc
            }
        }

        // PDF: the first pages side by side, each as large as fits
        Row {
            visible: view.kind === "pages"
            anchors.centerIn: parent
            spacing: Theme.spaceM
            Repeater {
                model: view.pages
                Image {
                    required property string modelData
                    source: modelData
                    sourceSize.height: stage.height   // decode at the size shown, not the page's full resolution
                    readonly property real slot: (stage.width - Theme.spaceM * (view.pages.length - 1)) / Math.max(1, view.pages.length)
                    width: Math.min(slot, stage.height * (implicitWidth / Math.max(1, implicitHeight)))
                    height: stage.height
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    cache: false
                    smooth: true
                    mipmap: true
                }
            }
        }

        Rectangle {
            visible: view.kind === "text"
            anchors.fill: parent
            radius: Theme.radius
            color: Theme.fill
            Flickable {
                id: textFlick
                anchors { fill: parent; margins: Theme.spaceM }
                contentWidth: width
                contentHeight: code.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                TextEdit {
                    id: code
                    width: parent.width
                    readOnly: true
                    selectByMouse: true
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.accentText
                    text: view.body || (view.busy ? "" : "(empty)")
                    wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
                    color: Theme.text
                    font { family: Theme.monoFont; pixelSize: Theme.fontLabel }
                }
            }
        }

        Column {
            visible: view.kind === "none" || view.kind === "" || view.busy
            anchors.centerIn: parent
            spacing: Theme.spaceS
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: view.busy ? "" : Search.fileGlyph(view.path)
                color: Theme.subtext
                font { family: Theme.font; pixelSize: 96 }   // one-off: the file-type glyph fills the empty preview
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: view.busy ? "Loading…" : "No preview for this kind of file"
                color: Theme.muted
                font { family: Theme.font; pixelSize: Theme.fontLabel }
            }
        }
    }

    // what the keys do, as key caps (the launcher's own footer style)
    Row {
        id: hints
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: Theme.spaceM }
        spacing: Theme.spaceL
        Repeater {
            model: [["↵", "open"], ["Space", "close"]].concat(QuickLook.inLauncher ? [["↑↓", "next file"]] : [])
            Row {
                required property var modelData
                spacing: Theme.spaceXs + 1
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(height, cap.implicitWidth + 10); height: cap.implicitHeight + 4
                    radius: Math.min(Theme.radiusSmall, 5)
                    color: Theme.fill
                    border { width: 1; color: Theme.stroke }
                    Text { id: cap; anchors.centerIn: parent; text: modelData[0]; color: Theme.subtext; font { family: Theme.monoFont; pixelSize: Theme.fontCaption - 1 } }
                }
                Text { anchors.verticalCenter: parent.verticalCenter; text: modelData[1]; color: Theme.muted; font { family: Theme.font; pixelSize: Theme.fontCaption } }
            }
        }
    }

    function scroll(dy) { textFlick.contentY = Math.max(0, Math.min(textFlick.contentHeight - textFlick.height, textFlick.contentY + dy)) }
}
