pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Caffeine: keeps the screen on and the laptop awake for a while. Holds a systemd idle inhibitor
// (hypridle and logind both honour it). The inhibitor's child waits on Quickshell's PID, so it is
// released when the time runs out, when you turn it off, or when the shell stops. On or off is
// saved in settings.json and comes back when the shell starts again (reload, login, reboot); a
// timed run still ends at its original time.
//   qs ipc call caffeine toggle | start <minutes, 0 = until turned off> | stop
Singleton {
    id: root

    readonly property bool active: inhibitor.running
    property int minutes: 0            // length of the current run, 0 = indefinite
    property double endsAt: 0          // ms since epoch, 0 = indefinite
    readonly property var choices: [30, 60, 120, 0]

    function start(min) {
        min = Math.max(0, min)
        run(min, min > 0 ? Date.now() + min * 60000 : 0)
        save()
    }
    function stop() { expiry.stop(); inhibitor.running = false; endsAt = 0; save() }
    function run(min, end) {
        minutes = min
        endsAt = end
        inhibitor.running = true
        if (end > 0) expiry.restart(); else expiry.stop()
    }
    function save() {
        Config.set("caffeine", "on", inhibitor.running)
        Config.set("caffeine", "minutes", minutes)
        Config.set("caffeine", "endsAt", endsAt)
    }
    // once settings.json is read: pick up where the last session left off
    function restore() {
        const c = Config.caffeine
        if (!c.on || inhibitor.running) return
        if (c.endsAt === 0 || c.endsAt > Date.now()) run(c.minutes, c.endsAt)
        else Config.set("caffeine", "on", false)   // the timed run ended while the shell was off
    }
    // a tick later: `loaded` turns true before the file's values reach the adapter
    Component.onCompleted: if (Config.loaded) Qt.callLater(restore)
    Connections { target: Config; function onLoadedChanged() { if (Config.loaded) Qt.callLater(root.restore) } }
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
