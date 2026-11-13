import QtQuick
import qs

// The output volume. Click opens the sound section of the Control Center, middle-click mutes, scroll changes it.
BarIndicator {
    glyph: Sys.volumeGlyph
    word: Sys.muted ? "muted" : "vol"
    value: Sys.muted ? "" : String(Math.round(Sys.volume * 100))
    ink: Sys.muted ? bar.dim : bar.tone
    tip: Sys.muted ? "Volume: muted" : "Volume " + Math.round(Sys.volume * 100) + "%"
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    onPressed: button => button === Qt.MiddleButton ? Sys.toggleMute() : ControlCenter.showSection("out")
    onScrolled: d => Sys.nudgeVolume(d)
}
