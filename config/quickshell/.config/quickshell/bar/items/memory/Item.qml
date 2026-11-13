import QtQuick
import qs

// The memory in use. The tooltip shows used and total. Click opens the system panel.
BarMetric {
    metric: "ram"
    active: Sensors.open
    opens: "system"
    onPressed: Sensors.toggle()
}
