import QtQuick
import qs

// How busy the processor is. The tooltip shows every core and the recent trend. Click opens the system panel.
BarMetric {
    metric: "cpu"
    active: Sensors.open
    opens: "system"
    onPressed: Sensors.toggle()
}
