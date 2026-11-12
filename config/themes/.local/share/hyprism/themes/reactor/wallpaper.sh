# shellcheck shell=bash disable=SC2154,SC2086  # W and H are theme-wallpaper's sheet size
# Reactor's wallpapers, drawn with ImageMagick on a W x H sheet (theme-wallpaper sources this file and scales the
# result to your screen). One recipe per half: "reactor" and "reactor-light".
# To use a picture instead, delete this file and put reactor.png (and reactor-light.png) beside theme.json.
wallpaper() {
    local out=$2
    case $1 in
        reactor) # radioactive: an acid disc burning through near-black, an orange core, hazard stripes low left
            magick -size ${W}x${H} xc:'#0c0d08' \
                \( -size ${W}x${H} xc:none -fill '#e4ff1a' -draw 'circle 1820,620 1820,1120' -blur 0x120 -channel A -evaluate multiply 0.55 +channel \) -composite \
                -fill '#e4ff1a' -draw 'circle 1820,620 1820,940' -fill '#ff6b0a' -draw 'circle 1820,620 1820,760' \
                -fill '#e4ff1a' -draw "$(for i in 0 1 2 3 4 5; do
                    x=$((120 + i * 110))
                    printf 'polygon %d,1600 %d,1600 %d,1260 %d,1260 ' $x $((x + 50)) $((x + 130)) $((x + 80))
                done)" \
                -attenuate 0.05 +noise Gaussian -colorspace sRGB "$out"
            ;;
        reactor-light) # Reactor by day: the disc in burnt orange on bone, the hazard tape still acid on a dark band
            magick -size ${W}x${H} xc:'#f5f6ea' \
                \( -size ${W}x${H} xc:none -fill '#ffb36b' -draw 'circle 1820,620 1820,1120' -blur 0x120 -channel A -evaluate multiply 0.45 +channel \) -composite \
                -fill '#f0b27a' -draw 'circle 1820,620 1820,940' -fill '#b14800' -draw 'circle 1820,620 1820,760' \
                -fill '#181a0e' -draw 'rectangle 0,1260 820,1600' \
                -fill '#e4ff1a' -draw "$(for i in 0 1 2 3 4 5; do
                    x=$((120 + i * 110))
                    printf 'polygon %d,1600 %d,1600 %d,1260 %d,1260 ' $x $((x + 50)) $((x + 130)) $((x + 80))
                done)" \
                -attenuate 0.03 +noise Gaussian -colorspace sRGB "$out"
            ;;
        *) return 1 ;;
    esac
}
