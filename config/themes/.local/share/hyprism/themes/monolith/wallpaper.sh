# shellcheck shell=bash disable=SC2154,SC2086  # W and H are theme-wallpaper's sheet size
# Monolith's wallpapers, drawn with ImageMagick on a W x H sheet (theme-wallpaper sources this file and scales the
# result to your screen). One recipe per half: "monolith" and "monolith-light".
# To use a picture instead, delete this file and put monolith.png (and monolith-light.png) beside theme.json.
wallpaper() {
    local out=$2
    case $1 in
        monolith) # a terminal at rest: faint scanlines, the machine's name, a lime prompt and cursor
            magick -size ${W}x${H} xc:'#0b0c0a' \
                -fill '#11140f' -draw "$(for y in $(seq 0 6 $H); do printf 'rectangle 0,%d %d,%d ' "$y" "$W" "$((y + 2))"; done)" \
                -font 'JetBrainsMono-NF-Bold' -pointsize 300 -fill '#151813' -gravity southwest -annotate +80+60 "$(hostname 2>/dev/null || cat /etc/hostname)" \
                -font 'JetBrainsMono-NF-Bold' -pointsize 72 -fill '#b6ff3b' -gravity southwest -annotate +100+430 '~ $' \
                -fill '#b6ff3b' -draw 'rectangle 274,1100 317,1172' "$out"
            ;;
        monolith-light) # the terminal on paper: faint scanlines, the machine's name, an olive prompt and cursor
            magick -size ${W}x${H} xc:'#eceee6' \
                -fill '#e5e8de' -draw "$(for y in $(seq 0 6 $H); do printf 'rectangle 0,%d %d,%d ' "$y" "$W" "$((y + 2))"; done)" \
                -font 'JetBrainsMono-NF-Bold' -pointsize 300 -fill '#dfe2d6' -gravity southwest -annotate +80+60 "$(hostname 2>/dev/null || cat /etc/hostname)" \
                -font 'JetBrainsMono-NF-Bold' -pointsize 72 -fill '#4a7d00' -gravity southwest -annotate +100+430 '~ $' \
                -fill '#4a7d00' -draw 'rectangle 274,1100 317,1172' "$out"
            ;;
        *) return 1 ;;
    esac
}
