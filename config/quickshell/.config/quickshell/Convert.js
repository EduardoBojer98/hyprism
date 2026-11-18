.pragma library
// The launcher's converters, beside its calculator (Search.qml). parse(query, now, rates) answers
//   units      "5 km in mi", "70 f to c", "2 gb in mb"
//   currencies "100 eur to ron" (rates: { EUR: 1, USD: 1.08, … } from the ECB; { need: true } without them)
//   time zones "time in new york", "3pm tokyo": { kind: "tz", zone, at } for Search to ask `date` (no tz data in JS)
//   dates      "days until 25 dec", "today + 90 days", "days since 1 jan 2020"
// with { kind, title, subtitle, copy } or null. Checked by tests/converters.sh.

// factor to the dimension's base unit; temperature is converted on its own
const UNITS = {}
function add(dim, factor, names) { for (const n of names.split(" ")) UNITS[n] = { dim: dim, f: factor, name: names.split(" ")[0] } }
add("length", 0.001, "mm millimeter millimeters millimetre millimetres")
add("length", 0.01, "cm centimeter centimeters centimetre centimetres")
add("length", 1, "m meter meters metre metres")
add("length", 1000, "km kilometer kilometers kilometre kilometres")
add("length", 0.0254, "in inch inches")
add("length", 0.3048, "ft foot feet")
add("length", 0.9144, "yd yard yards")
add("length", 1609.344, "mi mile miles")
add("length", 1852, "nmi")
add("mass", 1e-6, "mg milligram milligrams")
add("mass", 0.001, "g gram grams")
add("mass", 1, "kg kilo kilos kilogram kilograms")
add("mass", 1000, "t tonne tonnes ton tons")
add("mass", 0.028349523125, "oz ounce ounces")
add("mass", 0.45359237, "lb lbs pound pounds")
add("mass", 6.35029318, "st stone stones")
add("volume", 0.001, "ml milliliter milliliters millilitre millilitres")
add("volume", 0.01, "cl")
add("volume", 0.1, "dl")
add("volume", 1, "l liter liters litre litres")
add("volume", 3.785411784, "gal gallon gallons")
add("volume", 0.946352946, "qt quart quarts")
add("volume", 0.473176473, "pt pint pints")
add("volume", 0.2365882365, "cup cups")
add("volume", 0.0295735295625, "floz")
add("volume", 0.01478676478125, "tbsp")
add("volume", 0.00492892159375, "tsp")
add("data", 0.125, "bit bits")
add("data", 1, "b byte bytes")
add("data", 1e3, "kb kilobyte kilobytes")
add("data", 1e6, "mb megabyte megabytes")
add("data", 1e9, "gb gigabyte gigabytes")
add("data", 1e12, "tb terabyte terabytes")
add("data", 1e15, "pb petabyte petabytes")
add("data", 1024, "kib")
add("data", 1048576, "mib")
add("data", 1073741824, "gib")
add("data", 1099511627776, "tib")
add("speed", 1, "m/s mps")
add("speed", 1 / 3.6, "km/h kmh kph")
add("speed", 0.44704, "mph")
add("speed", 0.514444, "kn knot knots")
add("time", 0.001, "ms millisecond milliseconds")
add("time", 1, "s sec secs second seconds")
add("time", 60, "min mins minute minutes")
add("time", 3600, "h hr hrs hour hours")
add("time", 86400, "d day days")
add("time", 604800, "wk week weeks")
add("time", 31557600, "yr year years")
add("area", 1, "m2 sqm")
add("area", 1e6, "km2")
add("area", 1e4, "ha hectare hectares")
add("area", 4046.8564224, "acre acres")
add("area", 0.09290304, "ft2 sqft")
add("energy", 1, "j joule joules")
add("energy", 1000, "kj")
add("energy", 4184, "kcal calorie calories")
add("energy", 3600000, "kwh")
const TEMP = { c: "°C", "°c": "°C", celsius: "°C", f: "°F", "°f": "°F", fahrenheit: "°F", k: "K", kelvin: "K" }

// a few names `date` can't find in /usr/share/zoneinfo (cities are matched there by Search: "new york" -> America/New_York)
const ZONES = { utc: "UTC", gmt: "UTC", est: "America/New_York", edt: "America/New_York", cst: "America/Chicago", pst: "America/Los_Angeles",
    pdt: "America/Los_Angeles", cet: "Europe/Paris", cest: "Europe/Paris", eet: "Europe/Bucharest", ist: "Asia/Kolkata", jst: "Asia/Tokyo",
    nyc: "America/New_York", "new york city": "America/New_York", la: "America/Los_Angeles", "san francisco": "America/Los_Angeles",
    "silicon valley": "America/Los_Angeles", seattle: "America/Los_Angeles", boston: "America/New_York", washington: "America/New_York",
    miami: "America/New_York", dallas: "America/Chicago", houston: "America/Chicago", beijing: "Asia/Shanghai", delhi: "Asia/Kolkata",
    mumbai: "Asia/Kolkata", india: "Asia/Kolkata", japan: "Asia/Tokyo", china: "Asia/Shanghai", uk: "Europe/London", england: "Europe/London",
    germany: "Europe/Berlin", france: "Europe/Paris", spain: "Europe/Madrid", italy: "Europe/Rome", romania: "Europe/Bucharest",
    serbia: "Europe/Belgrade", "novi sad": "Europe/Belgrade", "cluj": "Europe/Bucharest", sydney: "Australia/Sydney" }

const MONTHS = ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"]
const DAY = 86400000

function num(s) { return Number(String(s).replace(/,/g, "")) }
function fmt(v) {
    if (!isFinite(v)) return String(v)
    const a = Math.abs(v)
    if (a !== 0 && (a >= 1e15 || a < 1e-6)) return v.toExponential(4)
    return String(Number(v.toPrecision(a >= 1e6 ? 10 : 6)))
}
function dayStart(d) { return new Date(d.getFullYear(), d.getMonth(), d.getDate()) }
function showDate(d) {
    return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][d.getDay()] + " " + d.getDate() + " "
        + MONTHS[d.getMonth()].replace(/^./, c => c.toUpperCase()) + " " + d.getFullYear()
}

// "25 dec", "dec 25", "25 december 2026", "2026-12-25", "25.12.2026", "25/12", today, tomorrow, yesterday, christmas,
// new year; null if it isn't one. Without a year: this year's, or next year's if `future` and it has passed.
function parseDate(s, now, future) {
    s = s.trim().toLowerCase().replace(/(\d)(st|nd|rd|th)\b/, "$1")
    const today = dayStart(now)
    if (s === "today" || s === "now") return today
    if (s === "tomorrow") return new Date(today.getTime() + DAY)
    if (s === "yesterday") return new Date(today.getTime() - DAY)
    if (s === "christmas" || s === "xmas") s = "25 dec"
    if (s === "new year" || s === "new year's" || s === "new years") s = "1 jan"
    let y = null, m = null, d = null, r
    if ((r = /^(\d{4})-(\d{1,2})-(\d{1,2})$/.exec(s))) { y = +r[1]; m = +r[2] - 1; d = +r[3] }
    else if ((r = /^(\d{1,2})[./](\d{1,2})(?:[./](\d{2,4}))?$/.exec(s))) { d = +r[1]; m = +r[2] - 1; y = r[3] ? +r[3] : null }
    else if ((r = /^(\d{1,2})\s+([a-z]+)\.?(?:,?\s+(\d{4}))?$/.exec(s))) { d = +r[1]; m = MONTHS.indexOf(r[2].slice(0, 3)); y = r[3] ? +r[3] : null }
    else if ((r = /^([a-z]+)\.?\s+(\d{1,2})(?:,?\s+(\d{4}))?$/.exec(s))) { m = MONTHS.indexOf(r[1].slice(0, 3)); d = +r[2]; y = r[3] ? +r[3] : null }
    else return null
    if (m < 0 || m > 11 || d < 1 || d > 31) return null
    if (y !== null && y < 100) y += 2000
    let out = new Date(y ?? today.getFullYear(), m, d)
    if (y === null && future && out < today) out = new Date(today.getFullYear() + 1, m, d)
    return out.getMonth() === m ? out : null   // 31 feb isn't a date
}

function dates(q, now) {
    let r
    // days until / to / till X, days since / from X
    if ((r = /^(?:how many\s+)?(days|weeks)\s+(until|till|to|since|from)\s+(.+)$/.exec(q))) {
        const since = r[2] === "since" || r[2] === "from"
        const d = parseDate(r[3], now, !since)
        if (!d) return null
        const days = Math.round((since ? dayStart(now) - d : d - dayStart(now)) / DAY)
        const n = r[1] === "weeks" ? Math.round(days / 7 * 10) / 10 : days
        const unit = r[1] === "weeks" ? (n === 1 ? "week" : "weeks") : (n === 1 ? "day" : "days")
        return { kind: "date", title: n + " " + unit, subtitle: (since ? "Since " : "Until ") + showDate(d), copy: String(n) }
    }
    // X + / - N days|weeks|months|years ("in 90 days", "90 days from today", "2 weeks ago")
    let base = null, sign = 1, n = 0, unit = ""
    if ((r = /^(.+?)\s*([+-])\s*(\d+)\s*(d|days?|w|weeks?|m|months?|y|years?)$/.exec(q))) { base = parseDate(r[1], now, false); sign = r[2] === "-" ? -1 : 1; n = +r[3]; unit = r[4] }
    else if ((r = /^in\s+(\d+)\s+(days?|weeks?|months?|years?)$/.exec(q))) { base = dayStart(now); n = +r[1]; unit = r[2] }
    else if ((r = /^(\d+)\s+(days?|weeks?|months?|years?)\s+(from|after|before)\s+(.+)$/.exec(q))) { base = parseDate(r[4], now, false); n = +r[1]; unit = r[2]; sign = r[3] === "before" ? -1 : 1 }
    else if ((r = /^(\d+)\s+(days?|weeks?|months?|years?)\s+ago$/.exec(q))) { base = dayStart(now); n = +r[1]; unit = r[2]; sign = -1 }
    if (!base) return null
    const out = new Date(base)
    const u = unit[0]
    if (u === "d") out.setDate(out.getDate() + sign * n)
    else if (u === "w") out.setDate(out.getDate() + sign * n * 7)
    else if (u === "m") out.setMonth(out.getMonth() + sign * n)
    else out.setFullYear(out.getFullYear() + sign * n)
    const days = Math.round((out - dayStart(now)) / DAY)
    return { kind: "date", title: showDate(out), subtitle: days === 0 ? "Today" : days > 0 ? "In " + days + " days" : -days + " days ago",
             copy: out.getFullYear() + "-" + String(out.getMonth() + 1).padStart(2, "0") + "-" + String(out.getDate()).padStart(2, "0") }
}

// "time in tokyo", "tokyo time", "3pm tokyo", "15:30 in new york": the zone (an IANA name, or a city for Search to
// look up) and the time of day there in 24 h ("" for now)
function zones(q) {
    let r, place = "", at = ""
    if ((r = /^(?:what(?:'s| is) the\s+)?time\s+(?:in|at)\s+(.+)$/.exec(q)) || (r = /^(.+?)\s+time$/.exec(q))) place = r[1]
    else if ((r = /^(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\s+(?:in\s+)?([a-z][a-z .'-]+)$/.exec(q))) {
        let h = +r[1]
        if (!r[2] && !r[3]) return null   // "5 km": not a time
        if (r[3] === "pm" && h < 12) h += 12
        if (r[3] === "am" && h === 12) h = 0
        if (h > 23 || +(r[2] ?? 0) > 59) return null
        at = String(h).padStart(2, "0") + ":" + (r[2] ?? "00")
        place = r[4]
    } else return null
    place = place.trim()
    if (UNITS[place] || TEMP[place] || /^[a-z]{3}$/.test(place) && !ZONES[place]) return null
    const name = place.replace(/\b\w/g, c => c.toUpperCase())
    return { kind: "tz", zone: ZONES[place] ?? "", city: place.replace(/ /g, "_"), place: name, at: at }
}

function units(q, rates) {
    const r = /^(-?[\d.,]*\d)\s*([a-z°µ\/0-9]+(?: [a-z]+)?)\s+(?:in|to|as|into|=)\s+([a-z°µ\/0-9]+)$/.exec(q)
    if (!r) return null
    const v = num(r[1]), a = r[2], b = r[3]
    if (!isFinite(v)) return null
    if (TEMP[a] && TEMP[b]) {
        const A = TEMP[a], B = TEMP[b]
        const c = A === "°C" ? v : A === "°F" ? (v - 32) * 5 / 9 : v - 273.15
        const out = B === "°C" ? c : B === "°F" ? c * 9 / 5 + 32 : c + 273.15
        return { kind: "units", title: fmt(out) + " " + B, subtitle: fmt(v) + " " + A, copy: fmt(out) }
    }
    const ua = UNITS[a], ub = UNITS[b]
    if (ua && ub) {
        if (ua.dim !== ub.dim) return null
        const out = v * ua.f / ub.f
        return { kind: "units", title: fmt(out) + " " + ub.name, subtitle: fmt(v) + " " + ua.name, copy: fmt(out) }
    }
    // currencies: ISO codes the rates know (EUR based)
    const A = a.toUpperCase(), B = b.toUpperCase()
    if (!/^[A-Z]{3}$/.test(A) || !/^[A-Z]{3}$/.test(B) || ua || ub) return null
    if (!rates || !rates.EUR) return { kind: "currency", need: true, title: "", subtitle: "", copy: "" }
    if (!rates[A] || !rates[B]) return null
    const out = v / rates[A] * rates[B]
    const money = Number(out.toFixed(out >= 1 ? 2 : 4))
    return { kind: "currency", title: money + " " + B, subtitle: fmt(v) + " " + A + " · 1 " + A + " = " + fmt(rates[B] / rates[A]) + " " + B, copy: String(money) }
}

function parse(query, now, rates) {
    const q = String(query).trim().toLowerCase().replace(/\s+/g, " ").replace(/[$€£]/g, s => ({ "$": "usd ", "€": "eur ", "£": "gbp " })[s])
    if (q.length < 3) return null
    return dates(q, now) ?? zones(q) ?? units(q.replace(/^(usd|eur|gbp) ([\d.,]+)/, "$2 $1"), rates)
}

// ECB daily XML -> { rates: { EUR: 1, USD: … }, date: "2026-11-17" }
function parseRates(xml) {
    const rates = { EUR: 1 }
    const re = /currency='([A-Z]{3})'\s+rate='([\d.]+)'/g
    let m
    while ((m = re.exec(xml))) rates[m[1]] = Number(m[2])
    const d = /time='(\d{4}-\d{2}-\d{2})'/.exec(xml)
    return { rates: Object.keys(rates).length > 1 ? rates : {}, date: d ? d[1] : "" }
}
