import QtQuick

// The usual bar item: a glyph and/or a value, in the bar's voice (icons, mixed, words, caps); vertical bars
// stack them. It also applies the settings every item shares (BarItems.settings): your icon, your format,
// your click / right-click / scroll actions, the tooltip, and the warn / critical levels.
BarItem {
    id: ind
    required property var bar         // the BarWidget it sits in: tone, voice, family, vertical, cfg, say()
    property string glyph: ""
    property string word: ""          // words/caps voice: "vol"
    property string value: ""         // "45", "72%"
    property bool showValue: false    // icons voice: the value beside the glyph
    property bool textual: false      // a readout: in the mixed voice it reads as words ("cpu 5%"), no glyph
    property real level: -1           // what warn / critical compare against (e.g. a percentage); -1 = nothing to judge

    readonly property var cfg: bar.cfg
    // these come from your settings for the item; an item that shows several readings sets them per reading
    property var icon: cfg.icon
    property var format: cfg.format
    property var warnAt: cfg.warn
    property var criticalAt: cfg.critical
    // 0 fine, 1 warn, 2 critical. Shown by colour and by "!" marks, so it never rests on colour alone.
    readonly property int alarm: level < 0 ? 0 : (typeof criticalAt === "number" && level >= criticalAt) ? 2
                                                : (typeof warnAt === "number" && level >= warnAt) ? 1 : 0
    readonly property string shownGlyph: typeof icon === "string" && icon !== "" ? icon : glyph
    readonly property string shownValue: (typeof format === "string" && format !== ""
                                          ? format.replace("{value}", value).replace("{word}", word) : value)
                                         + (alarm === 2 ? " !!" : alarm === 1 ? " !" : "")
    readonly property bool asWords: bar.words || (bar.mixed && textual && !bar.vertical)
    property color ink: alarm === 2 ? Theme.error : alarm === 1 ? Theme.warning : bar.tone

    actions: cfg
    Accessible.name: ((word !== "" ? word + " " : "") + value).trim() !== "" ? ((word !== "" ? word + " " : "") + value).trim() : tip
    vertical: bar.vertical
    spacing: 4
    Text {
        visible: !ind.asWords && ind.shownGlyph !== ""
        text: ind.shownGlyph
        color: ind.ink
        font { family: Theme.iconFont; pixelSize: 16 }
    }
    Text {
        visible: ind.asWords || ((ind.showValue || ind.bar.mixed || ind.alarm > 0) && ind.shownValue !== "" && !(ind.bar.mixed && ind.bar.vertical))
        text: ind.asWords ? ind.bar.say(ind.word + (ind.shownValue !== "" ? (ind.bar.vertical ? "\n" : " ") + ind.shownValue : "")) : ind.shownValue
        horizontalAlignment: Text.AlignHCenter
        color: ind.ink
        font { family: ind.bar.family; pixelSize: Theme.fontLabel; letterSpacing: ind.bar.voice === "caps" ? 1 : 0; features: { "tnum": 1 } }
    }
}
