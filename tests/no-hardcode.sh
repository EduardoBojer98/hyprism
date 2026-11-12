#!/usr/bin/env bash
# Fails when the core names one particular computer's hardware (docs/CONVENTIONS.md, hard rule 4), or when a
# package-manager command appears outside distros/ (hard rule 5). Modules and test fixtures may name hardware.
#   tests/no-hardcode.sh          check everything
#   tests/no-hardcode.sh known    also list the places still waiting for their roadmap item
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
fail=0

core=(install.sh lib config/hypr config/scripts config/fish config/quickshell config/satty config/ghostty config/fuzzel config/starship packages/manifest.txt)

# One computer's values. Comment lines may use a name as an example; code may not.
hardware='eDP-[0-9]|HDMI-A-[0-9]|\bDP-[0-9]|0000:[0-9a-f]{2}:[0-9a-f]{2}\.[0-9]|renderD12[89]|\bBAT[0-9]\b|k10temp|iwlwifi|amd-igpu|[Aa]cer|XZ322|Keychron|GV301|[Ff]low ?X13|JuhRadial|juhradial|rog-control|/home/eduardo'
# Places that still name hardware, each with the roadmap item that removes it. Nothing may be added here.
known='^config/quickshell/.*/(Sensors|ConfigData|SettingsPageMonitor|SettingsPageDisplays|SettingsPagePower|Search|SettingsPageAbout|SettingsPageAsus)\.qml:' # D3 (metrics by device class), E4 (displays)

# comments may name a device as an example ("e.g. eDP-1"); code may not, so comments are cut off first
hits=$(grep -rnE "$hardware" "${core[@]}" --exclude='*.md' 2>/dev/null |
    sed -E 's/^([^:]+:[0-9]+:)[[:space:]]*(#|--|\/\/).*/\1/; s/[[:space:]]+(#|--|\/\/) .*$//' |
    grep -E "^[^:]+:[0-9]+:.*($hardware)" |
    grep -vE 'k10temp.*coretemp|coretemp.*k10temp' |                         # a list of every vendor's CPU sensor driver is not one machine's name
    grep -vE '^config/hypr/.config/hypr/modules/env.lua:.*amd-igpu' || true) # the pre-2.0 link name, kept so old installs keep working
new=$(grep -vE "$known" <<<"$hits" | grep -v '^$' || true)
if [[ -n $new ]]; then
    echo "xx hardware named in core (ask hardware.toml instead; see docs/hardware.md):"
    cut -c1-170 <<<"$new" | awk '{ print "   " $0 }'
    fail=1
fi
if [[ ${1:-} == known ]]; then
    echo "still waiting for their roadmap item:"
    grep -E "$known" <<<"$hits" | cut -c1-150 | sed 's/^/   /'
fi

distro=$(grep -rnwE 'pacman|paru|yay|dnf|rpm|limine-update|grubby' install.sh lib config/hypr config/scripts config/fish modules migrations --exclude='*.md' 2>/dev/null |
    grep -vE '^[^:]+:[0-9]+:[[:space:]]*(#|--)' || true)
if [[ -n $distro ]]; then
    echo "xx distro commands outside distros/ (add a backend function; see distros/README.md):"
    cut -c1-170 <<<"$distro" | awk '{ print "   " $0 }'
    fail=1
fi

((fail == 0)) && echo "ok: no hardware names and no distro commands in core"
exit "$fail"
