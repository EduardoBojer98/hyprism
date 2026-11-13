# shellcheck shell=bash disable=SC2154,SC2086  # W and H are theme-wallpaper's sheet size
# Glass's wallpapers, drawn with ImageMagick on a W x H sheet (theme-wallpaper sources this file and scales the
# result to your screen). One recipe per half: "glass" and "glass-light".
# To use a picture instead, delete this file and put glass.png (and glass-light.png) beside theme.json.
wallpaper() {
    local out=$2
    case $1 in
        glass) # deep blue with an electric light falling from the top left and a violet glow below
            magick -size ${W}x${H} xc:'#0f131c' -fill '#2f6bff' -draw 'ellipse 700,260 900,420 0,360' \
                -fill '#8f86ff' -draw 'ellipse 2050,1380 760,380 0,360' -fill '#5b9cff' -draw 'ellipse 1250,720 300,180 0,360' \
                -resize 25% -blur 0x60 -resize 400% -attenuate 0.06 +noise Gaussian -colorspace sRGB "$out"
            ;;
        glass-light) # frosted daylight: pale blue light from the top left, a lilac glow below
            magick -size ${W}x${H} xc:'#e9edf4' -fill '#a9c4ff' -draw 'ellipse 700,260 900,420 0,360' \
                -fill '#cbc6ff' -draw 'ellipse 2050,1380 760,380 0,360' -fill '#bcd4ff' -draw 'ellipse 1250,720 300,180 0,360' \
                -resize 25% -blur 0x60 -resize 400% -attenuate 0.04 +noise Gaussian -colorspace sRGB "$out"
            ;;
        *) return 1 ;;
    esac
}
