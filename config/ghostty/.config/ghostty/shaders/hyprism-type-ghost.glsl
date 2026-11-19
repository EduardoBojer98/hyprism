// Typing effect "Ghost" (Settings > Appearance > Terminal > Typing effect): the cursor leaves an afterimage where it
// just was, which sinks, thins to a line and fades, so typing draws a short fading wake behind the cursor.

const float LIFE = 0.32;

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = texture(iChannel0, fragCoord / iResolution.xy);
    float t = (iTime - iTimeCursorChange) / LIFE;
    if (t >= 1.0 || iFocus == 0) return;
    vec2 size = iPreviousCursor.zw;
    if (distance(iCurrentCursor.xy, iPreviousCursor.xy) > iCurrentCursor.w * 1.5) return;   // a jump: the smear has it
    float e = t * t;
    // the old cell, its top coming down to a thin line at its foot, the whole thing sinking a little
    vec2 lo = iPreviousCursor.xy - vec2(0.0, size.y) - vec2(0.0, size.y * 0.25 * e);
    vec2 hi = vec2(lo.x + max(size.x, size.y * 0.5), lo.y + size.y * mix(1.0, 0.12, sqrt(t)));
    vec2 inside = step(lo, fragCoord) * step(fragCoord, hi);
    float a = inside.x * inside.y * 0.5 * (1.0 - t) * (1.0 - t);
    fragColor = vec4(mix(fragColor.rgb, iCurrentCursorColor.rgb, a), fragColor.a);
}
