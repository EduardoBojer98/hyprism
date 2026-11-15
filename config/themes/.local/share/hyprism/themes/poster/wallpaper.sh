# shellcheck shell=bash disable=SC2154,SC2086  # W and H are theme-wallpaper's sheet size
# Poster's wallpapers, drawn with ImageMagick on a W x H sheet (theme-wallpaper sources this file and scales the
# result to your screen). One recipe per half: "poster" and "poster".
# To use a picture instead, delete this file and put poster.png (and poster.png) beside theme.json.
wallpaper() {
    local out=$2
    case $1 in
        poster) # a Bauhaus poster: red disc, cobalt band, a yellow quarter, paper column, ink rules, on charcoal
            magick -size ${W}x${H} xc:'#141414' \
                -fill '#ffc400' -draw 'path "M 2560,1600 L 2560,1040 A 560,560 0 0,0 2000,1600 Z"' \
                -fill '#ff3b1f' -draw 'circle 1640,640 1640,1100' \
                -fill '#2d5bff' -draw 'rectangle 0,1150 1460,1330' \
                -fill '#f4f1ea' -draw 'rectangle 1460,1150 1520,1600' -draw 'rectangle 240,0 262,1150' \
                -fill '#141414' -draw 'rectangle 1180,600 2100,622' \
                -fill '#f4f1ea' -draw 'circle 2240,300 2240,330' "$out"
            ;;
        *) return 1 ;;
    esac
}
