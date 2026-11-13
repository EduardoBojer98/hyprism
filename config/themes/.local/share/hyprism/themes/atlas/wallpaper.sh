# shellcheck shell=bash disable=SC2154,SC2086  # W and H are theme-wallpaper's sheet size
# Atlas's wallpapers, drawn with ImageMagick on a W x H sheet (theme-wallpaper sources this file and scales the
# result to your screen). One recipe per half: "atlas" and "atlas-dark".
# To use a picture instead, delete this file and put atlas.png (and atlas-dark.png) beside theme.json.
wallpaper() {
    local out=$2
    case $1 in
        atlas) # Swiss: off-white, a red square, black bars on a grid
            magick -size ${W}x${H} xc:'#f2f2f0' -fill '#e30613' -draw 'rectangle 160,160 1040,1040' \
                -fill '#111111' -draw 'rectangle 1200,160 1260,1440' -draw 'rectangle 160,1200 2400,1240' "$out"
            ;;
        atlas-dark) # Swiss at night: black, the red square, white bars on the grid
            magick -size ${W}x${H} xc:'#121212' -fill '#e30613' -draw 'rectangle 160,160 1040,1040' \
                -fill '#f2f2f0' -draw 'rectangle 1200,160 1260,1440' -draw 'rectangle 160,1200 2400,1240' "$out"
            ;;
        *) return 1 ;;
    esac
}
