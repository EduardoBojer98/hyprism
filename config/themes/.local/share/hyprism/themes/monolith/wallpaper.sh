# shellcheck shell=bash disable=SC2154,SC2086  # W and H are theme-wallpaper's sheet size
# Monolith's wallpapers, drawn with ImageMagick on a W x H sheet (theme-wallpaper sources this file and scales the
# result to your screen). One recipe per half: "monolith" and "monolith-light".
# To use a picture instead, delete this file and put monolith.png (and monolith-light.png) beside theme.json.
#
# A slab in the 1 : 4 : 9 proportion stands on a horizon over a grid of character cells, behind faint scanlines.
# Two lights meet on it: the accent comes up behind and catches its top edge, the second accent rims its right side.
# A ruler is ticked along the horizon like a HUD's scale; a prompt waits in the corner. Everything sits on a 40 px cell.
#
# monolith_draw SKY_TOP SKY_LOW FLOOR CELL SCAN HORIZON GLOW(from-to) RIM_GLOW(from-to) SLAB SLAB_EDGE GLINT RIM
#               TICK PROMPT CURSOR OUT BLEND
monolith_draw() {
    local cell=40 hz=$((H * 3 / 4 / 40 * 40)) # the horizon, on the grid
    local sh=720 sw=320                       # the slab's face: 4 by 9
    local sx=$((W * 61 / 100 / 40 * 40)) sy=$((hz - sh))
    local ticks="" x
    for ((x = 0; x <= W; x += cell)); do # the ruler: a short tick every cell, a long one every fifth
        if ((x % (cell * 5) == 0)); then ticks+="line $x,$hz $x,$((hz + 14)) "; else ticks+="line $x,$hz $x,$((hz + 6)) "; fi
    done
    magick \
        \( -size ${W}x${hz} gradient:"$1-$2" \) \( -size ${W}x$((H - hz)) xc:"$3" \) -append \
        \( -size ${cell}x${cell} xc:none -fill "$4" -draw 'rectangle 0,0 1,1' -write mpr:cell +delete \) \
        \( -size ${W}x${H} tile:mpr:cell \) -compose over -composite \
        \( -size 1x4 xc:none -fill "$5" -draw 'point 0,0' -write mpr:scan +delete \) \
        \( -size ${W}x${H} tile:mpr:scan \) -compose over -composite \
        \( -size 2200x1000 -define gradient:radii=1100,500 radial-gradient:"$7" \) -geometry +$((sx + sw / 2 - 1300))+$((hz - 620)) -compose "${17}" -composite \
        \( -size 1200x760 -define gradient:radii=600,380 radial-gradient:"$8" \) -geometry +$((sx + sw - 120))+$((hz - 520)) -compose "${17}" -composite \
        -fill "$6" -draw "rectangle 0,$hz $W,$hz" \
        -stroke "${13}" -strokewidth 1 -draw "$ticks" -stroke none \
        -fill "$9" -stroke "${10}" -strokewidth 1 -draw "rectangle $sx,$sy $((sx + sw)),$hz" -stroke none \
        -fill "${11}" -draw "rectangle $sx,$sy $((sx + sw)),$((sy + 1))" \
        -fill "${12}" -draw "rectangle $((sx + sw - 1)),$((sy + 2)) $((sx + sw)),$hz" \
        -font 'JetBrainsMono-NF-Regular' -pointsize 18 -fill "${13}" -gravity northwest \
        -annotate +$sx+$((hz + 26)) '1 : 4 : 9' \
        -font 'JetBrainsMono-NF-Bold' -pointsize 40 -fill "${14}" -annotate +120+$((H - 160)) '~ $' \
        -fill "${15}" -draw "rectangle 222,$((H - 158)) 245,$((H - 108))" \
        "${16}"
}

wallpaper() {
    case $1 in
        monolith) # night: a black slab between a lime dawn and a magenta rim light, scanned cells in the dark
            monolith_draw '#06070a' '#0d1016' '#05060a' '#161a22' '#00000066' '#262c37' '#1b2a0a-black' '#2a0d27-black' \
                '#030406' '#1b2029' '#b6ff3b' '#ff4ad8' '#3a4250' '#545d6c' '#b6ff3b' "$2" screen
            ;;
        monolith-light) # day: the same slab in ink on cool paper, its edges still lit
            monolith_draw '#eef0f3' '#e1e5ea' '#e5e8ec' '#d2d7de' '#ffffff59' '#bfc6cf' '#e2ead2-white' '#f1d7ec-white' \
                '#10141a' '#10141a' '#b6ff3b' '#b0179a' '#a3abb6' '#6c7581' '#10141a' "$2" multiply
            ;;
        *) return 1 ;;
    esac
}
