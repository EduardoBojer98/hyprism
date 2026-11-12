import QtQuick
import qs

// How busy the graphics card that draws the desktop is. Hidden where the card does not report it. Click opens the system panel.
BarMetric {
    metric: "gpu"
    active: Sensors.open
    opens: "system"
    onPressed: Sensors.toggle()
}
