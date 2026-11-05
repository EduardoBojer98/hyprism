import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Language & Region: the languages apps use in the Hyprland session (the first one, then fallbacks
// for apps that lack it) and the region for dates, numbers and units. Saved in settings.json
// (language) and written to hypr/settings/language.lua, which hypr/modules/env.lua turns into LANG,
// LANGUAGE and LC_* at login. KDE keeps its own language. Languages not installed yet show the
// command that installs them (it needs sudo, so you run it).
ColumnLayout {
    id: page
    spacing: 20

    readonly property var chosen: Config.language.languages
    property var catalog: []          // [{ id: "sr_RS@latin", name: "Serbian Latin (Serbia)", gen: "sr_RS@latin UTF-8" }]
    property var installed: []        // normalised `locale -a`: "sr_rs.utf8@latin"
    property string query: ""
    property string status: ""

    function info(id) { return catalog.find(c => c.id === id) ?? { id: id, name: id, gen: id + ".UTF-8 UTF-8" } }
    // "sr_RS@latin" -> "sr_rs.utf8@latin", the way `locale -a` lists it
    function isInstalled(id) { const m = id.split("@"); return installed.includes((m[0] + ".utf8" + (m[1] ? "@" + m[1] : "")).toLowerCase()) }
    // "sr_RS@latin" -> "sr_RS.UTF-8@latin", the form LANG takes
    function langValue(id) { const m = id.split("@"); return m[0] + ".UTF-8" + (m[1] ? "@" + m[1] : "") }
    readonly property var missing: chosen.concat(Config.language.formats ? [Config.language.formats] : []).filter(id => !isInstalled(id))
    readonly property string installCommand: missing.length
        ? missing.map(id => `sudo sed -i 's/^#\\s*\\(${info(id).gen.replace(/\./g, "\\.")}\\)/\\1/' /etc/locale.gen`).join(" && ") + " && sudo locale-gen"
        : ""

    readonly property var matches: {
        const q = query.trim().toLowerCase()
        if (!q) return []
        return catalog.filter(c => !chosen.includes(c.id) && (c.name.toLowerCase().includes(q) || c.id.toLowerCase().startsWith(q))).slice(0, 8)
    }

    function fail(err) { page.status = "Couldn't save: " + err }
    function setLanguages(list) { const err = Config.set("language", "languages", list); if (err) fail(err); else write() }
    function add(id) { setLanguages(chosen.concat([id])); query = ""; search.text = "" }
    function remove(i) {
        if (chosen.length < 2) return
        // formats pointing at the removed language fall back to "" (the first language)
        if (chosen[i] === Config.language.formats) Config.set("language", "formats", "")
        setLanguages(chosen.filter((_, j) => j !== i))
    }
    function makeFirst(i) { const l = chosen.slice(); l.unshift(l.splice(i, 1)[0]); setLanguages(l) }
    function setFormats(id) { const err = Config.set("language", "formats", id); if (err) fail(err); else write() }

    // hypr/settings/language.lua: only installed languages, so apps never get a locale that isn't there
    function write() {
        Qt.callLater(() => {
            const usable = Config.language.languages.filter(isInstalled)
            const t = {}
            if (usable.length) {
                t.LANG = langValue(usable[0])
                // "sr_RS@latin:sr:en_US:en": each language, then its bare language code as a fallback
                t.LANGUAGE = usable.flatMap(id => [id, id.split(/[_@]/)[0]]).filter((x, i, a) => a.indexOf(x) === i).join(":")
            }
            const f = Config.language.formats
            if (f && isInstalled(f))
                for (const k of ["LC_TIME", "LC_NUMERIC", "LC_MONETARY", "LC_MEASUREMENT", "LC_PAPER"]) t[k] = langValue(f)
            SettingsApp.writeHyprFile("settings/language.lua", "-- Written by the Settings app (Language & Region). Applied at the next login.\nreturn " + SettingsApp.lua(t))
            page.status = "Saved. Apps use it after you log out and back in."
        })
    }

    Process {   // installed locales, then every UTF-8 locale glibc supports with its title
        id: reader
        running: true
        command: ["sh", "-c", "locale -a; echo '--'; grep -E ' UTF-8$' /usr/share/i18n/SUPPORTED | while read -r l c; do id=${l%.UTF-8}; t=$(grep -m1 '^title' \"/usr/share/i18n/locales/$id\" 2>/dev/null | sed 's/^title *\"//; s/\"$//'); echo \"$id|$l $c|$t\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const [have, all] = text.split("\n--\n")
                page.installed = have.trim().split("\n").map(x => x.toLowerCase())
                page.catalog = (all ?? "").trim().split("\n").map(line => {
                    const [id, gen, title] = line.split("|")
                    // "Serbian Latin locale for Serbia" -> "Serbian Latin (Serbia)"
                    const m = (title ?? "").match(/^(.+?) (?:language )?locale for (.+)$/i)
                    return { id: id, gen: gen, name: m ? `${m[1]} (${m[2].replace(/^the /i, "")})` : (title || id) }
                }).filter(c => c.id).sort((a, b) => a.name.localeCompare(b.name))
            }
        }
    }

    SettingGroup {
        title: "Preferred languages"
        Repeater {
            model: page.chosen
            Item {
                id: lang
                required property string modelData
                required property int index
                readonly property bool ok: page.isInstalled(modelData)
                Layout.fillWidth: true
                implicitHeight: 46
                Rectangle { visible: lang.index > 0; anchors { left: parent.left; right: parent.right; leftMargin: 16 } height: 1; color: Theme.stroke }
                Column {
                    anchors { left: parent.left; leftMargin: 16; right: buttons.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    Text { width: parent.width; text: page.info(lang.modelData).name; elide: Text.ElideRight; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontSize } }
                    Text {
                        text: !lang.ok ? "Not installed yet, see below" : lang.index === 0 ? "Apps use this language" : "Used when an app lacks the one above"
                        color: lang.ok ? Theme.subtext : Theme.warning
                        font { family: Theme.font; pixelSize: Theme.fontCaption }
                    }
                }
                Row {
                    id: buttons
                    anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    spacing: 6
                    PillButton { visible: lang.index > 0; text: "Make first"; onClicked: page.makeFirst(lang.index) }
                    PillButton { visible: page.chosen.length > 1; text: "Remove"; onClicked: page.remove(lang.index) }
                }
            }
        }
        SettingRow {
            label: "Region formats"
            hint: "Dates, times, numbers, currency and units"
            Dropdown {
                width: 220
                options: ["Same as first language"].concat(page.chosen.map(id => page.info(id).name))
                current: Config.language.formats ? page.info(Config.language.formats).name : "Same as first language"
                onPicked: v => page.setFormats(page.chosen.find(id => page.info(id).name === v) ?? "")
            }
        }
    }

    SettingGroup {
        title: "Add a language"
        SettingRow {
            label: "Search"
            hint: "A language or country, e.g. Serbian, German, Brazil"
            TextField {
                id: search
                width: 220
                placeholder: "e.g. Serbian"
                onTextChanged: page.query = text
                onAccepted: if (page.matches.length) page.add(page.matches[0].id)
            }
        }
        Repeater {
            model: page.matches
            Item {
                id: hit
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 40
                Rectangle { anchors { left: parent.left; right: parent.right; leftMargin: 16 } height: 1; color: Theme.stroke }
                Text {
                    anchors { left: parent.left; leftMargin: 16; right: addBtn.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    text: hit.modelData.name + (page.isInstalled(hit.modelData.id) ? "" : "  ·  not installed")
                    elide: Text.ElideRight
                    color: Theme.text
                    font { family: Theme.font; pixelSize: Theme.fontSize }
                }
                PillButton { id: addBtn; anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter } text: "Add"; primary: true; onClicked: page.add(hit.modelData.id) }
            }
        }
    }

    SettingGroup {   // languages picked but not on this computer yet
        visible: page.missing.length > 0
        title: "Install languages"
        Text {
            Layout.fillWidth: true
            Layout.margins: 16
            Layout.bottomMargin: 4
            text: "These aren't installed yet: " + page.missing.map(id => page.info(id).name).join(", ") + ". Run this once in a terminal (it asks for your password), then press Check again."
            wrapMode: Text.Wrap
            color: Theme.text
            font { family: Theme.font; pixelSize: Theme.fontLabel }
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 16; Layout.rightMargin: 16
            implicitHeight: cmd.implicitHeight + 16
            radius: Theme.radiusSmall
            color: Theme.fill
            Text {
                id: cmd
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 10 }
                text: page.installCommand
                wrapMode: Text.WrapAnywhere
                color: Theme.text
                font { family: Theme.monoFont; pixelSize: Theme.fontCaption }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 16
            Layout.topMargin: 8
            Item { Layout.fillWidth: true }
            PillButton { text: "Copy command"; onClicked: { Quickshell.execDetached(["wl-copy", page.installCommand]); page.status = "Copied" } }
            PillButton { text: "Check again"; primary: true; onClicked: { reader.running = false; reader.running = true; page.write() } }
        }
    }

    SettingGroup {
        title: "Typing"
        SettingRow {
            label: "Keyboard layouts"
            hint: "Typing languages are keyboard layouts"
            PillButton { text: "Open Keyboard & Touchpad"; onClicked: SettingsApp.show("input") }
        }
    }

    Text {
        Layout.fillWidth: true
        text: (page.status ? page.status + "  " : "") + "Changes apply to apps after you log out and back in. KDE Plasma keeps its own language; the shell's own menus stay in English."
        color: Theme.subtext
        wrapMode: Text.Wrap
        font { family: Theme.font; pixelSize: Theme.fontCaption }
    }
}
