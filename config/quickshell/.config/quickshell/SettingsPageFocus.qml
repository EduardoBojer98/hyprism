import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Focus: the mode on now, and the modes themselves (Focus.qml): pick one above to edit it below.
ColumnLayout {
    id: page
    spacing: 20

    property string sel: Config.focus.active || (Focus.modes[0]?.id ?? "")
    readonly property var mode: Focus.modes.find(m => m.id === sel) ?? Focus.modes[0] ?? null
    function change(changes) { if (mode) Focus.update(mode.id, changes) }
    function schedule(changes) { change({ schedule: Object.assign({}, mode.schedule, changes) }) }
    function hhmm(t) { return t.length === 4 ? "0" + t : t }
    readonly property var dayNames: [[1, "Mon"], [2, "Tue"], [3, "Wed"], [4, "Thu"], [5, "Fri"], [6, "Sat"], [0, "Sun"]]
    // apps that sent notifications (still in the history) and aren't let through yet
    readonly property var seenApps: [...new Set(Notifications.history.map(n => n.appName).filter(a => a))]
        .filter(a => !(page.mode?.allow ?? []).some(x => x.toLowerCase() === a.toLowerCase())).sort().slice(0, 8)
    property string appQuery: ""
    readonly property var appMatches: {
        const q = appQuery.trim().toLowerCase()
        if (!q) return []
        return DesktopEntries.applications.values
            .filter(e => !e.noDisplay && !(page.mode?.apps ?? []).includes(e.id) && (e.name.toLowerCase().includes(q) || e.id.toLowerCase().includes(q)))
            .sort((a, b) => a.name.localeCompare(b.name)).slice(0, 6)
    }
    function appName(id) { return DesktopEntries.byId(id)?.name ?? id }

    Process {
        id: picker
        command: ["zenity", "--file-selection", "--title=Wallpaper for " + (page.mode?.name ?? "this mode"),
                  "--filename=" + Quickshell.env("HOME") + "/Pictures/", "--file-filter=Pictures and videos | *.png *.jpg *.jpeg *.webp *.mp4 *.webm *.mkv"]
        stdout: StdioCollector { onStreamFinished: { const p = text.trim(); if (p.startsWith("/")) page.change({ wallpaper: p }) } }
    }

    SettingGroup {
        SettingRow {
            label: "Focus"
            hint: Focus.mode ? (Config.focus.auto ? "On by its schedule, until " + Focus.mode.schedule.to : "On until you turn it off")
                             : "Off. Also from the Control Center's Focus tile, the launcher, and qs ipc call focus set <name>"
            Dropdown {
                width: 180
                accessibleName: "Focus mode on now"
                options: ["Off"].concat(Focus.modes.map(m => m.name))
                current: Focus.mode?.name ?? "Off"
                onPicked: v => Focus.set(Focus.modes.find(m => m.name === v)?.id ?? "")
            }
        }
    }

    // ---- the modes: one chip each; the picked one is edited below ----
    SettingGroup {
        title: "Modes"
        Flow {
            Layout.fillWidth: true
            Layout.margins: 12
            spacing: 6
            Repeater {
                model: Focus.modes
                Chip {
                    required property var modelData
                    icon: modelData.icon || "\u{F0594}"
                    label: modelData.name + (Config.focus.active === modelData.id ? "  ·  on" : "")
                    active: page.mode?.id === modelData.id
                    onClicked: page.sel = modelData.id
                }
            }
            Chip { icon: "\u{F0415}"; label: "Add mode"; iconColor: Theme.accent; onClicked: page.sel = Focus.add() }
        }
    }

    SettingGroup {
        title: page.mode ? page.mode.name : ""
        visible: page.mode !== null
        SettingRow {
            label: "Name"
            TextField {
                width: 200
                accessibleName: "Mode name"
                text: page.mode?.name ?? ""
                invalid: text.trim() === ""
                onTextChanged: if (page.mode && text.trim() && text.trim() !== page.mode.name) page.change({ name: text.trim().slice(0, 40) })
            }
        }
        SettingRow {
            label: "Icon"
            Flow {
                width: Math.min(480, page.width - 160)
                spacing: 2
                Repeater {
                    model: Focus.icons
                    Chip {
                        required property string modelData
                        icon: modelData
                        accessibleName: "Icon"
                        active: page.mode?.icon === modelData
                        onClicked: page.change({ icon: modelData })
                    }
                }
            }
        }
        SettingRow {
            label: "Turn it on now"
            hint: "Turning a mode off puts back the wallpaper, Night Light and Caffeine as they were"
            PillButton {
                readonly property bool on: Config.focus.active === page.mode?.id
                text: on ? "Turn off" : "Turn on"
                primary: !on
                onClicked: Focus.set(on ? "" : page.mode.id)
            }
        }
    }

    SettingGroup {
        title: "Notifications"
        visible: page.mode !== null
        SettingRow {
            label: "Do Not Disturb"
            hint: "Notifications wait in the notification centre; critical ones still pop up"
            Toggle { checked: page.mode?.dnd ?? false; onToggled: on => page.change({ dnd: on }) }
        }
        SettingRow {
            visible: page.mode?.dnd ?? false
            label: "Let these apps through"
            hint: (page.mode?.allow ?? []).length ? "Click one to remove it" : "None: every app waits"
            Flow {
                width: Math.min(360, page.width - 240)
                spacing: 4
                Repeater {
                    model: page.mode?.allow ?? []
                    Chip {
                        required property string modelData
                        icon: "\u{F0156}"
                        label: modelData
                        accessibleName: "Remove " + modelData
                        active: true
                        onClicked: page.change({ allow: page.mode.allow.filter(a => a !== modelData) })
                    }
                }
            }
        }
        SettingRow {
            visible: page.mode?.dnd ?? false
            label: "Add an app"
            hint: page.seenApps.length ? "Or one that sent you something:" : "Its name as its notifications show it"
            TextField {
                id: allowField
                width: 200
                placeholder: "App name, then Enter"
                onAccepted: { const a = text.trim(); if (a && !page.mode.allow.includes(a)) page.change({ allow: page.mode.allow.concat([a]) }); text = "" }
            }
        }
        Flow {
            visible: (page.mode?.dnd ?? false) && page.seenApps.length > 0
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            Layout.bottomMargin: 12
            spacing: 4
            Repeater {
                model: page.seenApps
                Chip {
                    required property string modelData
                    icon: "\u{F0415}"
                    label: modelData
                    onClicked: page.change({ allow: page.mode.allow.concat([modelData]) })
                }
            }
        }
    }

    SettingGroup {
        title: "When it turns on"
        visible: page.mode !== null
        SettingRow {
            label: "Wallpaper"
            hint: page.mode?.wallpaper ? page.mode.wallpaper.split("/").pop() : "Keeps the wallpaper you have"
            PillButton { visible: !!page.mode?.wallpaper; text: "None"; onClicked: page.change({ wallpaper: "" }) }
            PillButton { text: "Use current"; enabled: Wallpapers.current !== "" && Wallpapers.current !== page.mode?.wallpaper; onClicked: page.change({ wallpaper: Wallpapers.current }) }
            PillButton { text: "Choose…"; onClicked: picker.running = true }
        }
        SettingRow {
            label: "Night Light"
            hint: "Warm screen while the mode is on"
            Toggle { checked: page.mode?.nightLight ?? false; onToggled: on => page.change({ nightLight: on }) }
        }
        SettingRow {
            label: "Caffeine"
            hint: "The screen stays awake while the mode is on"
            Toggle { checked: page.mode?.caffeine ?? false; onToggled: on => page.change({ caffeine: on }) }
        }
        SettingRow {
            visible: (page.mode?.apps ?? []).length > 0
            label: "Open apps"
            hint: "Click one to remove it"
            Flow {
                width: Math.min(360, page.width - 240)
                spacing: 4
                Repeater {
                    model: page.mode?.apps ?? []
                    Chip {
                        required property string modelData
                        icon: "\u{F0156}"
                        label: page.appName(modelData)
                        accessibleName: "Remove " + label
                        active: true
                        onClicked: page.change({ apps: page.mode.apps.filter(a => a !== modelData) })
                    }
                }
            }
        }
        SettingRow {
            label: (page.mode?.apps ?? []).length ? "Open another app" : "Open apps"
            hint: (page.mode?.apps ?? []).length ? "" : "None yet: search to add one"
            TextField { id: appSearch; width: 200; placeholder: "Search apps"; onTextChanged: page.appQuery = text }
        }
        Repeater {
            model: page.appMatches
            SettingRow {
                required property var modelData
                label: modelData.name
                PillButton { text: "Add"; onClicked: { page.change({ apps: page.mode.apps.concat([modelData.id]) }); appSearch.text = "" } }
            }
        }
    }

    SettingGroup {
        title: "Schedule"
        visible: page.mode !== null
        SettingRow {
            label: "On a schedule"
            hint: page.mode?.schedule?.on ? Focus.about(page.mode) + ". Turned off by hand, it stays off until the next time." : "Only when you turn it on"
            Toggle { checked: page.mode?.schedule?.on ?? false; onToggled: on => page.schedule({ on: on }) }
        }
        SettingRow {
            visible: page.mode?.schedule?.on ?? false
            label: "Days"
            Repeater {
                model: page.dayNames
                Chip {
                    required property var modelData
                    readonly property bool on: (page.mode?.schedule?.days ?? []).includes(modelData[0])
                    label: modelData[1]
                    accessibleName: modelData[1] + (on ? ", on" : ", off")
                    active: on
                    onClicked: page.schedule({ days: on ? page.mode.schedule.days.filter(d => d !== modelData[0]) : page.mode.schedule.days.concat([modelData[0]]) })
                }
            }
        }
        SettingRow {
            visible: page.mode?.schedule?.on ?? false
            label: "From – to"
            hint: "24-hour clock, Enter to save; an end before the start runs past midnight"
            Repeater {
                model: ["from", "to"]
                TextField {
                    required property string modelData
                    width: 72
                    accessibleName: modelData === "from" ? "Starts at" : "Ends at"
                    text: page.mode?.schedule?.[modelData] ?? ""
                    invalid: !/^([01]?\d|2[0-3]):[0-5]\d$/.test(text)
                    onAccepted: if (!invalid) page.schedule({ [modelData]: page.hhmm(text) })
                }
            }
        }
    }

    SettingGroup {
        visible: page.mode !== null
        SettingRow {
            label: "Delete this mode"
            hint: Focus.modes.length === 1 ? "The last mode: Focus is plain Do Not Disturb without one" : ""
            PillButton { text: "Delete"; onClicked: { const id = page.mode.id; page.sel = ""; Focus.remove(id) } }
        }
    }
}
