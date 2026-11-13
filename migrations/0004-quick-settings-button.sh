# shellcheck shell=bash
# The bar has a new quick-settings button (item "controls"), first on the left in every theme. Bar layouts you
# saved yourself (per theme in Settings > Themes, and the bar presets) are kept as they are, so it is added at the
# start of their left side in ~/.config/quickshell/settings.json. Nothing else in that file changes.
f=$HOME/.config/quickshell/settings.json
[[ -f $f ]] && command -v jq >/dev/null || return 0
add='if (.start | type) == "array" and (.start | index("controls") | not) then .start = ["controls"] + .start else . end'
new=$(jq "(.appearance.custom |= (if type == \"object\" then map_values(if (.barItems | type) == \"object\" then .barItems |= ($add) else . end) else . end))
          | (.bar.presets |= (if type == \"object\" then map_values($add) else . end))" "$f" 2>/dev/null) || return 0
[[ $new == "$(jq . "$f")" ]] && return 0
$DRY && { echo "   would add the quick-settings button to your saved bar layouts in $f"; return 0; }
printf '%s\n' "$new" >"$f.tmp" && mv -f "$f.tmp" "$f"
