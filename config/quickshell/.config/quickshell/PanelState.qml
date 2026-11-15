import QtQuick

// What one panel's Control Center modules share while it is open: which list is folded out, the Wi-Fi
// network asking for a password, the tooltip. The Control Center has one, every flyout its own, so a module
// in a flyout never folds, hides or closes the Control Center. Modules take it as `host`.
QtObject {
    id: state
    property var popup: null                // the CursorPopup it lives in (hide, open)
    readonly property bool open: popup?.open ?? false
    property string expanded: ""            // "", "wifi", "bt", "caffeine", "out", "in"
    property string fixed: ""               // a flyout's one list: always folded out
    property var passwordFor: null          // Wi-Fi network waiting for a password
    property string wifiFailed: ""          // name of the network that just failed to connect
    property Item hintItem: null
    property string hintText: ""

    function toggleExpanded(name) { if (fixed === "") expanded = expanded === name ? "" : name; passwordFor = null; wifiFailed = "" }
    function hint(item, text) { hintText = text; hintItem = item }
    function unhint(item) { if (hintItem === item) hintItem = null }
    function hide() { popup?.hide() }
    function reset() { expanded = fixed; passwordFor = null; wifiFailed = ""; hintItem = null }
}
