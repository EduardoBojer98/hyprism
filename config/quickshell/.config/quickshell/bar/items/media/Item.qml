import QtQuick
import qs

// The playing track; hidden with no player. Click pauses or plays, scroll skips to the previous or next track.
BarIndicator {
    shown: Sys.player !== null && Sys.track !== ""
    glyph: Sys.player?.isPlaying ? "\u{F03E4}" : "\u{F040A}"
    word: Sys.player?.isPlaying ? "play" : "paused"
    value: bar.vertical ? "" : Sys.track.length > 38 ? Sys.track.slice(0, 37) + "…" : Sys.track
    showValue: !bar.vertical
    tip: (Sys.player?.isPlaying ? "Playing: " : "Paused: ") + Sys.track
    onPressed: Sys.player?.togglePlaying()
    onScrolled: d => d > 0 ? Sys.player?.previous() : Sys.player?.next()
}
