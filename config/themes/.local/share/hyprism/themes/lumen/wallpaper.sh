# shellcheck shell=bash disable=SC2154,SC2086  # W and H are theme-wallpaper's sheet size
# Lumen's wallpapers, drawn with ImageMagick on a W x H sheet (theme-wallpaper sources this file and scales the
# result to your screen). One recipe per half: "lumen" (light) and "lumen-dark".
# To use a picture instead, delete this file and put lumen.png (and lumen-dark.png) beside theme.json.

# A soft field of coloured light: wide blurred washes that sweep across the sheet like light through glass, a
# brighter band where they meet. Drawn small and blurred, then scaled up, so it stays smooth and quick.
# $1 ground, $2 blue, $3 violet, $4 teal, $5 warm, $6 band, $7 grain, $8 out
field() {
    local w=$((W / 8)) h=$((H / 8))
    magick -size ${w}x${h} xc:"$1" \
        -fill "$4" -draw "translate $((w * 18 / 100)),$((h * 30 / 100)) rotate -28 ellipse 0,0 $((w * 26 / 100)),$((h * 12 / 100)) 0,360" \
        -fill "$5" -draw "translate $((w * 88 / 100)),$((h * 22 / 100)) rotate -28 ellipse 0,0 $((w * 22 / 100)),$((h * 10 / 100)) 0,360" \
        -fill "$2" -draw "translate $((w * 40 / 100)),$((h * 78 / 100)) rotate -26 ellipse 0,0 $((w * 62 / 100)),$((h * 16 / 100)) 0,360" \
        -fill "$3" -draw "translate $((w * 70 / 100)),$((h * 62 / 100)) rotate -26 ellipse 0,0 $((w * 50 / 100)),$((h * 12 / 100)) 0,360" \
        -blur 0x$((w / 22)) \
        \( -size ${w}x${h} xc:none -fill "$6" -draw "translate $((w * 56 / 100)),$((h * 66 / 100)) rotate -26 ellipse 0,0 $((w * 58 / 100)),$((h * 3 / 100)) 0,360" \
        -blur 0x$((w / 60)) \) -compose Screen -composite \
        -filter Lanczos -resize ${W}x${H}! \
        -attenuate "$7" +noise Gaussian -colorspace sRGB "$8"
}

wallpaper() {
    case $1 in
        lumen) field '#e6ebf5' '#8db6ff' '#c2a8ff' '#93dcd6' '#ffd2b5' '#ffffffa0' 0.04 "$2" ;;
        lumen-dark) field '#0c0e18' '#1b47b8' '#5a2fb0' '#0d6670' '#7a2f5c' '#4a70c060' 0.08 "$2" ;;
        *) return 1 ;;
    esac
}
