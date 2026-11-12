# shellcheck shell=bash disable=SC2154,SC2086  # W and H are theme-wallpaper's sheet size
# Console's wallpapers, drawn with ImageMagick on a W x H sheet (theme-wallpaper sources this file and scales the
# result to your screen). One recipe per half: "console" and "console-light".
# To use a picture instead, delete this file and put console.png (and console-light.png) beside theme.json.
wallpaper() {
    local out=$2
    case $1 in
        console) # an amber radar: range rings, a crosshair with ticks and a fading sweep
            magick -size ${W}x${H} radial-gradient:'#111a2b'-'#05080f' \
                \( -size ${W}x${H} xc:none -fill '#ffb00038' -draw 'path "M 1820,800 L 2620,640 A 820,820 0 0,1 2620,960 Z"' -blur 0x40 \) -composite \
                -fill none -stroke '#ffb00042' -strokewidth 2 \
                -draw 'circle 1820,800 1820,1000' -draw 'circle 1820,800 1820,1200' -draw 'circle 1820,800 1820,1400' -draw 'circle 1820,800 1820,1600' \
                -stroke '#ffb00030' -draw 'line 0,800 2560,800' -draw 'line 1820,0 1820,1600' \
                -stroke '#ffb000a0' -strokewidth 3 -draw 'line 1800,800 1840,800' -draw 'line 1820,780 1820,820' \
                -stroke '#ffb00070' -strokewidth 2 -draw "$(for x in $(seq 1020 100 2620); do printf 'line %d,790 %d,810 ' "$x" "$x"; done)" \
                -stroke none -fill '#ffb000' -draw 'circle 2240,610 2240,618' -fill '#ff6a3d' -draw 'circle 1500,1060 1500,1067' "$out"
            ;;
        console-light) # the radar by day: amber ink rings on warm paper
            magick -size ${W}x${H} radial-gradient:'#fbf8f0'-'#ece5d4' \
                \( -size ${W}x${H} xc:none -fill '#a35f0024' -draw 'path "M 1820,800 L 2620,640 A 820,820 0 0,1 2620,960 Z"' -blur 0x40 \) -composite \
                -fill none -stroke '#a35f0040' -strokewidth 2 \
                -draw 'circle 1820,800 1820,1000' -draw 'circle 1820,800 1820,1200' -draw 'circle 1820,800 1820,1400' -draw 'circle 1820,800 1820,1600' \
                -stroke '#a35f002c' -draw 'line 0,800 2560,800' -draw 'line 1820,0 1820,1600' \
                -stroke '#a35f00a0' -strokewidth 3 -draw 'line 1800,800 1840,800' -draw 'line 1820,780 1820,820' \
                -stroke '#a35f0070' -strokewidth 2 -draw "$(for x in $(seq 1020 100 2620); do printf 'line %d,790 %d,810 ' "$x" "$x"; done)" \
                -stroke none -fill '#a35f00' -draw 'circle 2240,610 2240,618' -fill '#c2410c' -draw 'circle 1500,1060 1500,1067' "$out"
            ;;
        *) return 1 ;;
    esac
}
