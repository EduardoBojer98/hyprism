pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Caffeine: keeps the screen on and the laptop awake for a while. Holds a systemd idle inhibitor
// (hypridle and logind both honour it). The inhibitor's child waits on Quickshell's PID, so it is
// released when the time runs out, when you turn it off, when the session ends or if qs crashes.
//   qs ipc call caffeine toggle | start <minutes, 0 = until turned off> | stop
Singleton {
    id: root

    readonly property bool active: inhibitor.running
    property int minutes: 0            // length of the current run, 0 = indefinite
    property double endsAt: 0          // ms since epoch, 0 = indefinite
    readonly property var choices: [30, 60, 120, 0]

    function start(min) {
        minutes = Math.max(0, min)
        endsAt = minutes > 0 ? Date.now() + minutes * 60000 : 0
        inhibitor.running = true
        if (minutes > 0) expiry.restart(); else expiry.stop()
    }
    function stop() { expiry.stop(); inhibitor.running = false; endsAt = 0 }
    function toggle() { active ? stop() : start(Config.caffeine.defaultMinutes) }
    function label(min) { return min === 0 ? "Until turned off" : min < 60 ? `${min} min` : `${min / 60} h` }
    // "45 min left" style text for the Control Center
    function remaining(now) {
        if (!active) return "Off"
        if (endsAt === 0) return "On"
        const m = Math.max(1, Math.ceil((endsAt - now) / 60000))
        return m < 60 ? `${m} min left` : `${Math.floor(m / 60)} h ${m % 60} min left`
    }

    Process {
        id: inhibitor
        // $PPID inside sh is Quickshell; tail exits when it does, which drops the inhibitor
        command: ["sh", "-c", "exec systemd-inhibit --what=idle --who=Caffeine --why='Keeping the screen on' --mode=block tail --pid=$PPID -f /dev/null"]
    }
    Timer {
        id: expiry
        interval: Math.max(1000, root.endsAt - Date.now())
        onTriggered: root.stop()
    }

    IpcHandler {
        target: "caffeine"
        function toggle(): void { root.toggle() }
        function start(minutes: int): void { root.start(minutes) }
        function stop(): void { root.stop() }
        function status(): string { return root.remaining(Date.now()) }
    }
}
