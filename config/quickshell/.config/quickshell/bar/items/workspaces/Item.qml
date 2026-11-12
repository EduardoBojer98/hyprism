import QtQuick
import qs

// This screen's workspaces; click goes there, scroll steps through them (BarWs).
BarWs {
    required property var bar
    monitor: bar.monitor; vertical: bar.vertical; thickness: bar.thickness; tone: bar.tone; dim: bar.dim
}
