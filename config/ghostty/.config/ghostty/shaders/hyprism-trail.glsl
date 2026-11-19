// Hyprism cursor animation (Settings > Appearance > Terminal > Cursor animation).
// Each keystroke: a thin ring in the cursor's colour pops out of the cursor and fades, with a soft glow under it.
// A jump (a new line, a click, a search hit): a short smear runs from where the cursor was to where it is.
// Ghostty runs it only while a terminal has focus; ThemeSync adds it only in full motion and on AC.

const float PULSE = 0.22;      // seconds a keystroke's ring lives
const float SMEAR = 0.16;      // seconds a jump's smear lives
const float OPACITY = 0.55;

float segment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-4), 0.0, 1.0);
    return length(pa - ba * h);
}

// distance to a rounded box centred at 0 with half size b and corner radius r
float box(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + r;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = texture(iChannel0, fragCoord / iResolution.xy);
    if (iFocus == 0) return;
    float dt = iTime - iTimeCursorChange;
    if (dt >= max(PULSE, SMEAR)) return;
    // xy is the cursor's left, top corner (y up); zw its size
    vec2 size = iCurrentCursor.zw;
    vec2 cur = iCurrentCursor.xy + vec2(size.x, -size.y) * 0.5;
    vec2 prev = iPreviousCursor.xy + vec2(iPreviousCursor.z, -iPreviousCursor.w) * 0.5;
    vec3 col = iCurrentCursorColor.rgb;
    float a = 0.0;

    // the pulse: a ring that grows out from the cursor's cell, easing out, fading as it goes
    float tp = dt / PULSE;
    if (tp < 1.0) {
        float left = 1.0 - tp;
        float grow = (1.0 - left * left) * size.y * 0.45;
        vec2 half_ = vec2(max(size.x, size.y * 0.5), size.y) * 0.5 + grow;
        float d = box(fragCoord - cur, half_, min(half_.x, half_.y) * 0.5);
        float ring = 1.0 - smoothstep(0.0, 1.5, abs(d) - 0.6);
        float glow = exp(-max(d, 0.0) / (size.y * 0.35)) * step(-size.y, d) * 0.35;
        a = max(a, (ring * 0.8 + glow) * left * left * OPACITY);
    }

    // the smear, only for moves longer than a cell or two
    float ts = dt / SMEAR;
    if (ts < 1.0 && distance(cur, prev) >= size.y * 1.5) {
        float left = 1.0 - ts;
        vec2 tail = mix(prev, cur, 1.0 - left * left * left);   // the tail catches up fast, then settles
        float radius = max(size.y * 0.3, 1.5) * (0.4 + 0.6 * left);
        float d = segment(fragCoord, tail, cur) - radius;
        a = max(a, (1.0 - smoothstep(-1.0, 1.0, d)) * OPACITY * left);
    }

    fragColor = vec4(mix(fragColor.rgb, col, clamp(a, 0.0, 1.0)), fragColor.a);
}
