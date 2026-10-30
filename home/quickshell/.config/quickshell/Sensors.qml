pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// CPU (k10temp) and GPU temperatures in °C from hwmon, every 3 seconds.
// GPU is the Radeon iGPU that draws the desktop; the NVIDIA GPU is normally off and
// reading it would wake it.
Singleton {
    id: root

    property real cpu: NaN
    property real gpu: NaN

    Process {
        id: read
        // hwmon numbers change between boots, so find the sensors by name each time
        command: ["sh", "-c", "for n in k10temp amdgpu; do h=$(grep -lx $n /sys/class/hwmon/*/name | head -1); "
                            + "cat ${h%name}temp1_input 2>/dev/null || echo nan; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = text.trim().split("\n").map(x => parseInt(x) / 1000)
                root.cpu = v[0]
                root.gpu = v[1]
            }
        }
    }

    Timer { interval: 3000; running: true; repeat: true; triggeredOnStart: true; onTriggered: read.running = true }
}
