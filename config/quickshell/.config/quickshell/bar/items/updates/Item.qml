import QtQuick
import qs

// Updates waiting (system packages, AUR, Flatpak and Hyprism, from Updates): an icon with the count, hidden when
// there are none unless "always" is on. Click: the whole update in a terminal. Right-click: look again now.
BarIndicator {
    glyph: "\u{F06B0}"
    word: "upd"
    value: Updates.total > 0 ? String(Updates.total) : ""
    showValue: true
    shown: Updates.total > 0 || cfg.always === true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    tip: Updates.total > 0 ? Updates.summary + ": click to update" : Updates.checkingSystem ? "Looking for updates…" : "Everything is up to date"
    onPressed: button => button === Qt.RightButton ? Updates.refreshAll() : Updates.install()
}
