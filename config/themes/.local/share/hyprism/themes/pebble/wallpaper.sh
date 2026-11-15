# shellcheck shell=bash disable=SC2154,SC2086  # W and H are theme-wallpaper's sheet size
# Pebble's wallpapers, drawn with ImageMagick on a W x H sheet (theme-wallpaper sources this file and scales the
# result to your screen). One recipe per half: "pebble" and "pebble-light".
# To use a picture instead, delete this file and put pebble.png (and pebble-light.png) beside theme.json.

# A shallow riverbed seen from above: smooth stones lit from the upper left, each casting a soft shadow,
# the smallest one green with lichen.
# $1 ground, $2 stone, $3 shadow, $4 light, $5 lichen, $6 grain, $7 out
stones() {
    local s=(-draw 'ellipse 1800,1100 520,330 -12,360' -draw 'ellipse 625,1285 330,210 8,360'
        -draw 'ellipse 2220,400 250,170 20,360' -draw 'ellipse 1165,545 170,120 -25,360')
    local hi=(-draw 'ellipse 1640,980 380,190 -12,360' -draw 'ellipse 540,1210 230,120 8,360'
        -draw 'ellipse 2150,340 170,95 20,360' -draw 'ellipse 1120,505 110,65 -25,360')
    magick \( -size ${W}x${H} xc:black -fill white "${s[@]}" -blur 0x1.5 -write mpr:mask +delete \) \
        -size ${W}x${H} xc:"$1" \
        \( xc:"$3" \( mpr:mask -roll +36+52 -blur 0x42 -evaluate multiply 0.8 \) -alpha off -compose CopyOpacity -composite \) \
        -compose Over -composite \
        \( xc:"$2" mpr:mask -alpha off -compose CopyOpacity -composite \) -compose Over -composite \
        \( xc:"$4" \( -size ${W}x${H} xc:black -fill white "${hi[@]}" -blur 0x60 mpr:mask -compose Multiply -composite \) \
        -alpha off -compose CopyOpacity -composite \) -compose Over -composite \
        \( xc:"$5" \( -size ${W}x${H} xc:black -fill white -draw 'ellipse 1190,575 150,100 -25,360' -blur 0x40 \
        mpr:mask -compose Multiply -composite -evaluate multiply 0.85 \) -alpha off -compose CopyOpacity -composite \) \
        -compose Over -composite \
        -attenuate "$6" +noise Gaussian -colorspace sRGB "$7"
}

wallpaper() {
    case $1 in
        pebble) stones '#171918' '#232724' '#0b0c0b' '#343a35' '#46553a' 0.10 "$2" ;;
        pebble-light) stones '#dfe2dc' '#e6e8e3' '#b9beb6' '#f3f4f0' '#b9caa2' 0.05 "$2" ;;
        *) return 1 ;;
    esac
}
