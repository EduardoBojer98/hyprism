import QtQuick
import qs

// The output volume. Click opens its flyout (sound and microphone), middle-click mutes, scroll changes it.
BarIndicator {
    glyph: Sys.volumeGlyph
    word: Sys.muted ? "muted" : "vol"
    value: Sys.muted ? "" : String(Math.round(Sys.volume * 100))
    ink: Sys.muted ? bar.dim : bar.tone
    tip: Sys.muted ? "Volume: muted" : "Volume " + Math.round(Sys.volume * 100) + "%"
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    opens: "volume"
    active: Flyouts.isOpen("volume")
    onPressed: button => button === Qt.MiddleButton ? Sys.toggleMute() : Flyouts.toggle("volume")
    onScrolled: d => Sys.nudgeVolume(d)
}
