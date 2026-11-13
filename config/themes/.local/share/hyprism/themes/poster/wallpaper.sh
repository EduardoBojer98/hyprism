# shellcheck shell=bash disable=SC2154,SC2086  # W and H are theme-wallpaper's sheet size
# Poster's wallpapers, drawn with ImageMagick on a W x H sheet (theme-wallpaper sources this file and scales the
# result to your screen). One recipe per half: "poster" and "poster".
# To use a picture instead, delete this file and put poster.png (and poster.png) beside theme.json.
wallpaper() {
    local out=$2
    case $1 in
        poster) # Bauhaus poster: a red disc and a cobalt bar on charcoal
            magick -size ${W}x${H} xc:'#141414' -fill '#ff3b1f' -draw 'circle 1880,700 1880,1160' \
                -fill '#2d5bff' -draw 'rectangle 0,1180 1500,1360' -fill '#f4f1ea' -draw 'rectangle 1500,1180 1560,1600' "$out"
            ;;
        *) return 1 ;;
    esac
}
