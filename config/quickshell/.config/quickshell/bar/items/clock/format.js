.pragma library
// What one clock shows, from its settings (bar.items.<id>), as Qt date-time patterns (Qt.formatDateTime).
// Used by the clock (Item.qml) and its settings (SettingsBarClock.qml), so the preview is the bar.
//   time  false hides it          h24 / seconds   true / false (left out: `d`, the shared defaults)
//   date  false hides it          weekday  none | short | long     day  false hides it
//   month none | short | long | number                             year  true adds it
//   first "date" | "time"         separator  text between the two (default two spaces)
//   custom  a Qt pattern of your own ("ddd d MMM HH:mm"); it wins over everything above
// d: defaults for what a setting leaves out: { h24, seconds, date }
// Returns { time, date, all, custom }: the time's pattern, the date's, both together, and whether `all` is yours.

// literal text in a pattern goes in single quotes; a quote inside is doubled ('' alone would print a quote)
function quote(s) { return s === "" ? "" : "'" + s.replace(/'/g, "''") + "'" }

function patterns(c, d) {
    c = c ?? {}
    const h24 = c.h24 ?? d.h24, secs = c.seconds ?? d.seconds
    const time = c.time === false ? "" : (h24 ? "HH:mm" : "h:mm") + (secs ? ":ss" : "") + (h24 ? "" : " AP")
    let date = ""
    if (c.date ?? d.date) {
        const month = c.month ?? "short"
        const rest = [c.day === false ? "" : "d", ({ short: "MMM", long: "MMMM", number: "M" })[month] ?? "", c.year === true ? "yyyy" : ""]
        const weekday = ({ short: "ddd", long: "dddd" })[c.weekday ?? "short"] ?? ""
        date = [weekday, rest.filter(x => x).join(month === "number" ? "/" : " ")].filter(x => x).join(" ")
    }
    const custom = typeof c.custom === "string" && c.custom.trim() !== ""
    const pair = c.first === "time" ? [time, date] : [date, time]
    const all = custom ? c.custom : pair.filter(x => x).join(quote(typeof c.separator === "string" ? c.separator : "  "))
    return { time: time, date: date, all: all, custom: custom }
}

// does a pattern show seconds (outside quoted text)? Then the clock ticks every second.
function ticksSeconds(p) { return p.replace(/'[^']*'/g, "").includes("s") }
