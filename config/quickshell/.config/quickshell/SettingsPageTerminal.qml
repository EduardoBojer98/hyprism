import Quickshell
import QtQuick
import QtQuick.Layouts

// Terminal: Ghostty's look (live) and fish's behaviour (new shells). "Theme" takes the active theme's
// term look (theme.json term.cursorStyle, blink, padding); ThemeSync writes ghostty/theme.conf and hyprism/fish.fish.
ColumnLayout {
    id: page
    spacing: 20

    SettingGroup {
        title: "Ghostty and fish"
        SettingRow {
            label: "Theme colours"
            hint: "Ghostty switches to the theme's palette and font, live"
            ConfigToggle { section: "appearance"; key: "terminal" }
        }
        SettingRow {
            label: "Cursor"
            hint: "Ghostty's cursor shape, live"
            ConfigChoice { section: "terminal"; key: "cursor"; values: ["theme", "block", "bar", "underline", "block_hollow"]; labels: ["Theme", "Block", "Bar", "Line", "Hollow"] }
        }
        SettingRow {
            label: "Cursor blink"
            ConfigChoice { section: "terminal"; key: "blink"; values: ["theme", "on", "off"]; labels: ["Theme", "On", "Off"] }
        }
        SettingRow {
            label: "Cursor animation"
            hint: Config.terminal.trail && !(Theme.motionLevel === "full") ? "Paused: Animations is not on Full"
                : "A pulse on each keystroke, a smear when the cursor jumps. Keeps a focused terminal drawing every frame; off on battery"
            ConfigToggle { section: "terminal"; key: "trail" }
        }
        SettingRow {
            label: "Background"
            hint: "See-through lets the wallpaper show behind the text"
            ConfigChoice { section: "terminal"; key: "opacity"; values: ["theme", "solid", "soft", "clear"]; labels: ["Theme", "Solid", "Soft", "Clear"] }
        }
        SettingRow {
            label: "Padding"
            hint: "Space between the window's edge and the text"
            ConfigChoice { section: "terminal"; key: "padding"; values: ["theme", "tight", "normal", "roomy"]; labels: ["Theme", "Tight", "Normal", "Roomy"] }
        }
        SettingRow {
            label: "Transient prompt"
            hint: "Past prompts shrink to one symbol, so the scrollback shows commands and output. New terminals"
            ConfigToggle { section: "terminal"; key: "transientPrompt" }
        }
        SettingRow {
            label: "Greeting"
            hint: Config.terminal.greeting === "pokemon" ? "A random Pokémon beside the system summary, now and then a shiny one (pokemon-colorscripts)"
                : "What a new shell prints first. Fastfetch: a system summary"
            ConfigChoice { section: "terminal"; key: "greeting"; values: ["default", "off", "fastfetch", "pokemon"]; labels: ["Default", "Off", "Fastfetch", "Pokémon"] }
        }
    }
}
