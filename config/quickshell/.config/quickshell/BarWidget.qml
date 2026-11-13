import Quickshell
import QtQuick

// One bar item, by id. The bar lays these out in its three sections (Theme.barLayout); every item
// works across a horizontal bar and down a vertical one, and speaks the theme's voice:
//   icons  glyphs (Material Design Icons from the Nerd Font) with numbers where they help
//   mixed  a glyph and its value on every item ("<glyph> 45"), in the bar's face (Monolith, Console)
//   words  lowercase words and numbers ("vol 45"), caps: the same in capitals ("VOL 45")
// Adding an item: a folder in bar/items/ (see BarItems.qml).
Loader {
    id: w
    required property string kind
    required property var monitor
    property bool vertical: false
    property color tone: Theme.text          // ink on this bar's ground
    property color dim: Theme.subtext
    property string voice: "icons"
    property string family: Theme.font
    property int thickness: Theme.barSize
    property bool separated: false           // a thin rule before this item (Bar's sep)


    readonly property bool words: voice === "words" || voice === "caps"
    readonly property bool mixed: voice === "mixed"
    function say(s) { return voice === "caps" || Theme.barStyle.caps === true ? s.toUpperCase() : s }
    // your settings for this item, over its defaults (BarItems.settings)
    readonly property var cfg: BarItems.settings(kind)
    // every item lives in its own folder (bar/items/<id>/). The registry fills a moment after start, so wait for it.
    function load() {
        if (BarItems.has(kind)) setSource(BarItems.url(kind), { bar: w })
        else {
            source = ""
            if (BarItems.ready) console.warn("bar: no item '" + kind + "' in bar/items/")
        }
    }
    Component.onCompleted: load()
    onKindChanged: load()
    Connections { target: BarItems; function onDefsChanged() { w.load() } }
    // the separator sits in the gap before the item, outside it (the grid's spacing holds it)
    Rectangle {
        visible: w.separated && w.visible
        color: Qt.alpha(w.tone, 0.28)
        width: w.vertical ? Math.min(14, w.thickness * 0.45) : 1
        height: w.vertical ? 1 : Math.min(14, w.thickness * 0.45)
        x: w.vertical ? (w.width - width) / 2 : -8
        y: w.vertical ? -8 : (w.height - height) / 2
    }
    // an item with nothing to show takes no space (e.g. media with no player). Items say so with
    // `shown` (not `visible`, which follows this Loader and would never come back)
    visible: item ? (item.shown ?? true) && cfg.enabled !== false : false

}
