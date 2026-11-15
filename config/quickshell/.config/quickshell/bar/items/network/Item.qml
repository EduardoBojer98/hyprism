import QtQuick
import qs

// Wi-Fi or wired state and signal strength; click opens its flyout (the Wi-Fi list).
BarIndicator {
    glyph: Sys.networkGlyph
    word: Sys.wired ? "eth" : !Sys.wifiOn ? "wifi off" : Sys.signal < 0 ? "offline" : "wifi"
    value: Sys.wired || Sys.signal < 0 ? "" : String(Sys.signal)
    ink: Sys.signal < 0 && !Sys.wired ? bar.dim : bar.tone
    tip: Sys.wired ? "Network: wired" : !Sys.wifiOn ? "Wi-Fi is off" : Sys.signal < 0 ? "Offline" : "Wi-Fi " + Sys.signal + "%"
    opens: "network"
    active: Flyouts.isOpen("network")
    onPressed: Flyouts.toggle("network")
}
