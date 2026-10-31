import Quickshell
import Quickshell.Io
import QtQuick

// Pick a downloaded theme (archive or folder) with KDE's file dialog, then install it with
// ~/.local/bin/theme-add. Used by Settings > Icons and Settings > Cursor.
Item {
    id: root
    property string kind              // "icons" or "cursors"
    signal done(var names, string error)

    function pickFile() { picker.command = ["kdialog", "--title", "Add a theme", "--getopenfilename", Quickshell.env("HOME") + "/Downloads",
                                            "*.tar.gz *.tgz *.tar.xz *.tar.bz2 *.tar.zst *.zip|Theme archives"]; picker.running = true }
    function pickFolder() { picker.command = ["kdialog", "--title", "Add a theme", "--getexistingdirectory", Quickshell.env("HOME") + "/Downloads"]; picker.running = true }

    Process {
        id: picker
        stdout: StdioCollector { onStreamFinished: { const p = text.trim(); if (p) { install.command = ["theme-add", root.kind, p]; install.running = true } } }
    }
    Process {
        id: install
        stdout: StdioCollector { id: out }
        stderr: StdioCollector { id: err }
        onExited: code => root.done(code === 0 ? out.text.trim().split("\n").filter(n => n) : [],
                                    code === 0 ? "" : (err.text.trim().replace(/^theme-add: /, "") || "Couldn't add that theme"))
    }
}
