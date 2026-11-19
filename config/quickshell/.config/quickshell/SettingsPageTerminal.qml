import Quickshell
import QtQuick
import QtQuick.Layouts

// Terminal: Ghostty's look (live) and fish's behaviour (new shells). "Theme" takes the active theme's
// term look (theme.json term.cursorStyle, blink, padding); ThemeSync writes ghostty/theme.conf and hyprism/fish.fish.
ColumnLayout {
    id: page
    spacing: 20

    SettingGroup {
        title: "Ghostty"
        TerminalPreview { Layout.fillWidth: true; Layout.margins: 12 }
        SettingRow {
            label: "Theme colours"
            hint: "Ghostty switches to the theme's palette and font, live"
            ConfigToggle { section: "appearance"; key: "terminal" }
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
    }

    SettingGroup {
        title: "Cursor"
        SettingRow {
            label: "Shape"
            hint: "Live in every open terminal"
            ConfigChoice { section: "terminal"; key: "cursor"; values: ["theme", "block", "bar", "underline", "block_hollow"]; labels: ["Theme", "Block", "Bar", "Line", "Hollow"] }
        }
        SettingRow {
            label: "Blink"
            ConfigChoice { section: "terminal"; key: "blink"; values: ["theme", "on", "off"]; labels: ["Theme", "On", "Off"] }
        }
        SettingRow {
            label: "Animation"
            hint: Config.terminal.trail && !(Theme.motionLevel === "full") ? "Paused: Animations is not on Full"
                : "A smear when the cursor jumps, and the typing effect below. Keeps a focused terminal drawing every frame; off on battery"
            ConfigToggle { section: "terminal"; key: "trail" }
        }
        SettingRow {
            label: "Typing effect"
            enabled: Config.terminal.trail
            opacity: enabled ? 1 : 0.5
            hint: ({ pulse: "A ring pops out of the cursor and fades",
                     sparks: "Sparks fly up from the cursor and fall back, a new pattern every key",
                     ghost: "The cursor leaves a sinking afterimage, a short wake behind your typing",
                     ripple: "A wave rolls out from the cursor and bends the text it crosses",
                     none: "Only the jump smear" })[Config.terminal.typing] ?? ""
            ConfigChoice { section: "terminal"; key: "typing"; values: ["pulse", "sparks", "ghost", "ripple", "none"]; labels: ["Pulse", "Sparks", "Ghost", "Ripple", "None"] }
        }
    }

    SettingGroup {
        title: "fish shell"
        SettingRow {
            label: "Transient prompt"
            hint: "Past prompts shrink to one symbol, so the scrollback shows commands and output. New terminals"
            ConfigToggle { section: "terminal"; key: "transientPrompt" }
        }
        SettingRow {
            label: "Greeting"
            hint: Config.terminal.greeting === "pokemon" ? "A random Pokémon beside the system summary, now and then a shiny one (pokemon-colorscripts)"
                : Config.terminal.greeting === "bonsai" ? "A bonsai tree grown fresh for every shell, holding a short fortune (cbonsai, fortune)"
                : "What a new shell prints first. Fastfetch: a system summary"
            ConfigChoice { section: "terminal"; key: "greeting"; values: ["default", "off", "fastfetch", "pokemon", "bonsai"]; labels: ["Default", "Off", "Fastfetch", "Pokémon", "Bonsai"] }
        }
    }

    ResetGroup { sections: ["terminal"] }
}
