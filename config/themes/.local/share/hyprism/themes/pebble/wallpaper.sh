# shellcheck shell=bash disable=SC2154,SC2086  # W and H are theme-wallpaper's sheet size
# Pebble's wallpapers, drawn with ImageMagick on a W x H sheet (theme-wallpaper sources this file and scales the
# result to your screen). One recipe per half: "pebble" and "pebble-light".
# To use a picture instead, delete this file and put pebble.png (and pebble-light.png) beside theme.json.
wallpaper() {
    local out=$2
    case $1 in
        pebble) # dusk: three soft pebbles of light (coral, sea green, violet) and a little grain
            magick -size ${W}x${H} xc:'#16141f' \
                -fill '#6a3f86' -draw 'ellipse 640,520 760,520 0,360' -fill '#2f7f73' -draw 'ellipse 1960,1180 820,560 0,360' \
                -fill '#ff9e7a' -draw 'ellipse 1640,420 360,300 0,360' -fill '#16141f' -draw 'ellipse 1280,1500 1500,260 0,360' \
                -resize 25% -blur 0x48 -resize 400% -attenuate 0.14 +noise Gaussian -colorspace sRGB "$out"
            ;;
        pebble-light) # Pebble by day: the same pebbles of light, pale on lavender paper
            magick -size ${W}x${H} xc:'#f3eff8' \
                -fill '#dcc8f0' -draw 'ellipse 640,520 760,520 0,360' -fill '#bfe6dc' -draw 'ellipse 1960,1180 820,560 0,360' \
                -fill '#ffc4ad' -draw 'ellipse 1640,420 360,300 0,360' -fill '#f3eff8' -draw 'ellipse 1280,1500 1500,260 0,360' \
                -resize 25% -blur 0x48 -resize 400% -attenuate 0.08 +noise Gaussian -colorspace sRGB "$out"
            ;;
        *) return 1 ;;
    esac
}
