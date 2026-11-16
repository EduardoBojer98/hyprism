pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// The bar's items, found on disk: every folder bar/items/<id>/ with a defaults.json is one item.
//   Item.qml        what it draws (a BarIndicator or a BarItem)
//   defaults.json   { "name", "glyph", "settings": { … } }: its name in Settings and its default settings
//   README.md       what it shows and which settings it has
// Adding an item is adding a folder (copy bar/items/_template); nothing else lists them.
// Your own settings per item live in settings.json under bar.items.<id> and win over defaults.json.
// Every item can sit in the bar many times: each copy is an instance, "clock", "clock#2", "clock#3"…, with its own
// settings (bar.items["clock#2"]) over the same defaults.json. A plain id is the first instance.
Singleton {
    id: root
    readonly property string dir: Quickshell.shellDir + "/bar/items"
    property var defs: ({})          // id -> its defaults.json
    property bool ready: false

    function base(id) { return String(id).split("#")[0] }                 // "clock#2" -> "clock"
    function has(id) { return /^[^#]+(#[1-9][0-9]*)?$/.test(id) && defs[base(id)] !== undefined }
    function url(id) { return Qt.resolvedUrl("bar/items/" + base(id) + "/Item.qml") }
    // name and glyph for Settings: a second copy reads "Clock 2"
    function info(id) {
        const b = base(id), n = String(id).slice(b.length + 1)
        const it = catalogue.find(i => i.id === b) ?? { id: b, name: b, glyph: "\u{F02D7}", category: "Other" }
        return Object.assign({}, it, { id: id, name: it.name + (n ? " " + n : "") })
    }
    // the id a new copy of item `b` gets: the plain id when `list` lacks it, else the lowest "#n" no list uses and
    // no old settings hold, so a new copy starts from the defaults
    function newId(b, list, taken) {
        if (!list.includes(b)) return b
        let n = 2
        while (taken.includes(b + "#" + n) || Config.bar.items?.[b + "#" + n] !== undefined) n++
        return b + "#" + n
    }
    // name, glyph and category (defaults.json "category"; none = "Other") for Settings' item list
    readonly property var catalogue: Object.keys(defs).sort().map(id => ({ id: id, name: defs[id].name ?? id, glyph: defs[id].glyph ?? "", category: defs[id].category || "Other" }))
    readonly property var categories: ["Desktop", "System", "Connections & sound", "Time & info", "Other"]

    // Settings every item understands (docs/bar.md). Anything else in bar.items.<id> is the item's own.
    //   enabled      false hides it everywhere
    //   icon         another glyph        format    "{value}" and "{word}" inside your own text
    //   click / rightClick / scroll       an action (BarActions): "panel:weather", "settings:power", "run:…", "none"
    //   tooltip      false turns the hint off
    //   warn / critical                   levels where it turns amber / red and gains a "!"
    //   interval     seconds between readings, for items that measure something
    function settings(id) {
        const mine = Config.bar.items?.[id]
        return Object.assign({}, defs[base(id)]?.settings ?? {}, (mine && typeof mine === "object") ? mine : {})
    }

    // One pass over the folders: "<id><TAB><defaults.json on one line>" each. Lua and QML can't list a folder.
    Process {
        running: true
        command: ["sh", "-c", 'cd "$1" 2>/dev/null || exit 0; for d in */; do d=${d%/}; [ -f "$d/defaults.json" ] && [ -f "$d/Item.qml" ] && printf "%s\\t%s\\n" "$d" "$(tr -d "\\n" < "$d/defaults.json")"; done', "sh", root.dir]
        stdout: StdioCollector {
            onStreamFinished: {
                const found = {}
                for (const line of text.split("\n")) {
                    const tab = line.indexOf("\t")
                    if (tab < 1 || line[0] === "_") continue          // _template is not an item
                    try { found[line.slice(0, tab)] = JSON.parse(line.slice(tab + 1)) }
                    catch (e) { console.warn("bar item " + line.slice(0, tab) + ": defaults.json doesn't parse: " + e) }
                }
                root.defs = found
                root.ready = true
            }
        }
    }
}
