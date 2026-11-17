pragma Singleton
import Quickshell
import QtQuick

// What a hot corner can do (HotCorners.qml runs them, Settings > Hot Corners lists them): any action id
// (Actions.qml). The list offers the ones shown in corners; ids saved before the registry still work (Actions.aliases).
Singleton {
    readonly property var list: [{ id: "", name: "Nothing" }].concat(Actions.forSurface("corner").map(a => ({ id: a.id, name: a.name })))
    function name(id) { return id ? Actions.get(id)?.name ?? id : "Nothing" }
    function run(id) { if (id) Actions.run(id) }
}
