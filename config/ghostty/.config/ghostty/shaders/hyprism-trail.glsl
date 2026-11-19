// Hyprism cursor smear (Settings > Appearance > Terminal > Cursor animation): when the cursor jumps (a new line, a
// click, a search hit) a short smear in its colour runs from where it was to where it is. Typing one cell at a time
// draws nothing here; the typing effect is the shader after this one (hyprism-type-*.glsl). Ghostty runs shaders only
// while a terminal has focus; ThemeSync adds them only in full motion and on AC.

const float SMEAR = 0.16;   // seconds
const float OPACITY = 0.55;

float segment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-4), 0.0, 1.0);
    return length(pa - ba * h);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = texture(iChannel0, fragCoord / iResolution.xy);
    float t = (iTime - iTimeCursorChange) / SMEAR;
    if (t >= 1.0 || iFocus == 0) return;
    // xy is the cursor's left, top corner (y up); zw its size
    vec2 cur = iCurrentCursor.xy + vec2(iCurrentCursor.z, -iCurrentCursor.w) * 0.5;
    vec2 prev = iPreviousCursor.xy + vec2(iPreviousCursor.z, -iPreviousCursor.w) * 0.5;
    if (distance(cur, prev) < iCurrentCursor.w * 1.5) return;
    float left = 1.0 - t;
    vec2 tail = mix(prev, cur, 1.0 - left * left * left);   // the tail catches up fast, then settles
    float radius = max(iCurrentCursor.w * 0.3, 1.5) * (0.4 + 0.6 * left);
    float d = segment(fragCoord, tail, cur) - radius;
    float a = (1.0 - smoothstep(-1.0, 1.0, d)) * OPACITY * left;
    fragColor = vec4(mix(fragColor.rgb, iCurrentCursorColor.rgb, a), fragColor.a);
}
