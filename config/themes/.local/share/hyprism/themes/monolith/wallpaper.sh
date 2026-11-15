# shellcheck shell=bash disable=SC2154,SC2086  # W and H are theme-wallpaper's sheet size
# Monolith's wallpapers, drawn with ImageMagick on a W x H sheet (theme-wallpaper sources this file and scales the
# result to your screen). One recipe per half: "monolith" and "monolith-light".
# To use a picture instead, delete this file and put monolith.png (and monolith-light.png) beside theme.json.
#
# A slab in the 1 : 4 : 9 proportion stands on a horizon over a grid of character cells; light comes up behind
# it and catches its top edge in the accent. A prompt waits in the corner. Everything sits on a 40 px cell.
#
# monolith_draw SKY_TOP SKY_LOW FLOOR CELL HORIZON GLOW(from-to) SLAB SLAB_EDGE GLINT PROMPT CURSOR RATIO OUT GLOW_BLEND
monolith_draw() {
    local cell=40 hz=$((H * 3 / 4 / 40 * 40)) # the horizon, on the grid
    local sh=720 sw=320                       # the slab's face: 4 by 9
    local sx=$((W * 61 / 100 / 40 * 40)) sy=$((hz - sh))
    magick \
        \( -size ${W}x${hz} gradient:"$1-$2" \) \( -size ${W}x$((H - hz)) xc:"$3" \) -append \
        \( -size ${cell}x${cell} xc:none -fill "$4" -draw 'rectangle 0,0 1,1' -write mpr:cell +delete \) \
        \( -size ${W}x${H} tile:mpr:cell \) -compose over -composite \
        \( -size 2200x1000 -define gradient:radii=1100,500 radial-gradient:"$6" \) -geometry +$((sx + sw / 2 - 1100))+$((hz - 620)) -compose "${14}" -composite \
        -fill "$5" -draw "rectangle 0,$hz $W,$hz" \
        -fill "$7" -stroke "$8" -strokewidth 1 -draw "rectangle $sx,$sy $((sx + sw)),$hz" -stroke none \
        -fill "$9" -draw "rectangle $sx,$sy $((sx + sw)),$((sy + 1))" \
        -font 'JetBrainsMono-NF-Regular' -pointsize 18 -fill "${12}" -gravity northwest \
        -annotate +$sx+$((hz + 22)) '1 : 4 : 9' \
        -font 'JetBrainsMono-NF-Bold' -pointsize 40 -fill "${10}" -annotate +120+$((H - 160)) '~ $' \
        -fill "${11}" -draw "rectangle 222,$((H - 158)) 245,$((H - 108))" \
        "${13}"
}

wallpaper() {
    case $1 in
        monolith) # night: a black slab against a low lime dawn, cells in the dark
            monolith_draw '#080907' '#10120e' '#070806' '#171a14' '#22261e' '#1d290b-black' '#040504' '#1c2018' '#b6ff3b' \
                '#4f5747' '#b6ff3b' '#2a2f26' "$2" screen
            ;;
        monolith-light) # day: the same slab in ink on paper, its edge still lit
            monolith_draw '#eef0e8' '#e2e5da' '#e6e8df' '#d6d9cd' '#c2c7b6' '#e4e9d6-white' '#191c15' '#191c15' '#b6ff3b' \
                '#7a8170' '#22300a' '#b4b9a8' "$2" multiply
            ;;
        *) return 1 ;;
    esac
}
