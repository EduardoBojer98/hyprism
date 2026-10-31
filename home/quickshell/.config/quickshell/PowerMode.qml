pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick

// Power mode for the Control Center and Settings: 0 Quiet, 1 Balanced, 2 Performance.
// On ASUS laptops it goes through `powermode` (asusd), which also applies that mode's fan curves
// and power limits; elsewhere through power-profiles-daemon, as before.
Singleton {
    readonly property var names: ["quiet", "balanced", "performance"]
    property int asusProfile: 1
    readonly property int profile: Machine.asus ? asusProfile : PowerProfiles.profile

    function set(i) {
        if (!Machine.asus) { PowerProfiles.profile = i; return }
        asusProfile = i   // show it at once; watch confirms
        Quickshell.execDetached(["powermode", names[i]])
    }

    Process {
        running: Machine.asus
        command: ["powermode", "watch"]
        stdout: SplitParser {
            onRead: line => { const i = names.indexOf(line.trim()); if (i >= 0) asusProfile = i }
        }
    }
}
