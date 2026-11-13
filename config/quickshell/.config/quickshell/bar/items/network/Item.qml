import QtQuick
import qs

// Wi-Fi or wired state and signal strength; click opens the Wi-Fi section of the Control Center.
BarIndicator {
    glyph: Sys.networkGlyph
    word: Sys.wired ? "eth" : !Sys.wifiOn ? "wifi off" : Sys.signal < 0 ? "offline" : "wifi"
    value: Sys.wired || Sys.signal < 0 ? "" : String(Sys.signal)
    ink: Sys.signal < 0 && !Sys.wired ? bar.dim : bar.tone
    tip: Sys.wired ? "Network: wired" : !Sys.wifiOn ? "Wi-Fi is off" : Sys.signal < 0 ? "Offline" : "Wi-Fi " + Sys.signal + "%"
    panel: "controlcenter"
    active: ControlCenter.open && ControlCenter.expanded === "wifi"
    onPressed: ControlCenter.showSection("wifi")
}
