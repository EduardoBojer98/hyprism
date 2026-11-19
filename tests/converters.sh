#!/usr/bin/env bash
# Self-check for the launcher's converters (config/quickshell/.config/quickshell/Convert.js): runs it in Qt's own
# JavaScript engine (the `qml` tool from qt6-declarative, no display needed) against fixed answers. Run by tests/lint.sh.
#   tests/converters.sh
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
qml=""
for c in /usr/lib/qt6/bin/qml qml6 qml; do
    command -v "$c" >/dev/null && {
        qml=$c
        break
    }
done
[[ -n $qml ]] || {
    echo "xx the Qt 6 qml tool is missing (Arch: qt6-declarative)"
    exit 1
}
dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cat >"$dir/check.qml" <<QML
import QtQuick
import "file://$PWD/config/quickshell/.config/quickshell/Convert.js" as C
QtObject {
    Component.onCompleted: {
        const now = new Date(2026, 10, 18, 12, 0)   // Wed 18 Nov 2026
        const rates = C.parseRates("<Cube time='2026-11-17'><Cube currency='USD' rate='1.0500'/><Cube currency='RON' rate='5.0000'/></Cube>")
        const cases = [
            ["5 km in mi", "3.10686 mi"], ["70 f to c", "21.1111 °C"], ["2 gb in mb", "2000 mb"], ["0 c in k", "273.15 K"],
            ["1 lb to g", "453.592 g"], ["100 km/h in mph", "62.1371 mph"], ["90 min to h", "1.5 h"], ["5 km in kg", null], ["2,5 km in m", "2500 m"], ["1,000 m in km", "1 km"],
            ["100 eur to ron", "500 RON"], ["100 usd in eur", "95.24 EUR"], ["€20 to usd", "21 USD"], ["100 xyz to ron", null],
            ["days until 25 dec", "37 days"], ["days until 1 jan", "44 days"], ["days since 1 nov", "17 days"],
            ["today + 90 days", "Tue 16 Feb 2027"], ["today - 2 weeks", "Wed 4 Nov 2026"], ["2026-12-25 + 1 day", "Sat 26 Dec 2026"],
            ["in 3 months", "Thu 18 Feb 2027"], ["31 feb + 1 day", null], ["2*21", null], ["firefox", null], ["hello world", null],
        ]
        let bad = 0
        for (const [q, want] of cases) {
            const got = C.parse(q, now, rates.rates)
            const t = got ? got.title : null
            if (t !== want) { bad++; console.log("xx " + q + " -> " + t + " (want " + want + ")") }
        }
        const tz = C.parse("3pm tokyo", now, {}), tz2 = C.parse("time in new york", now, {}), tz3 = C.parse("10:30 est", now, {})
        if (tz?.kind !== "tz" || tz.at !== "15:00" || tz.city !== "tokyo") { bad++; console.log("xx 3pm tokyo -> " + JSON.stringify(tz)) }
        if (tz2?.city !== "new_york" || tz2.at !== "") { bad++; console.log("xx time in new york -> " + JSON.stringify(tz2)) }
        if (tz3?.zone !== "America/New_York" || tz3.at !== "10:30") { bad++; console.log("xx 10:30 est -> " + JSON.stringify(tz3)) }
        if (!C.parse("100 eur to ron", now, {})?.need) { bad++; console.log("xx no rates: should ask for them") }
        if (rates.date !== "2026-11-17") { bad++; console.log("xx rates date " + rates.date) }
        console.log(bad ? "xx converters: " + bad + " wrong" : "ok: converters (" + (cases.length + 5) + " cases)")
        Qt.exit(bad ? 1 : 0)
    }
}
QML
out=$(QT_FORCE_STDERR_LOGGING=1 QT_QPA_PLATFORM=offscreen timeout 30 "$qml" "$dir/check.qml" 2>&1)
code=$?
grep -E '(ok|xx)' <<<"$out" | sed 's/^qml: //'
((code == 0)) || { grep -qE 'xx' <<<"$out" || echo "xx converters: qml failed: $(head -3 <<<"$out")"; }
exit "$code"
