// Typing effect "Pulse" (Settings > Appearance > Terminal > Typing effect): each keystroke pops a thin ring with a
// soft glow out of the cursor's cell; it eases out and fades in about a fifth of a second.

const float LIFE = 0.22;

float box(vec2 p, vec2 b, float r) {   // distance to a rounded box centred at 0
    vec2 q = abs(p) - b + r;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = texture(iChannel0, fragCoord / iResolution.xy);
    float t = (iTime - iTimeCursorChange) / LIFE;
    if (t >= 1.0 || iFocus == 0) return;
    vec2 size = iCurrentCursor.zw;
    vec2 cur = iCurrentCursor.xy + vec2(size.x, -size.y) * 0.5;
    float left = 1.0 - t;
    vec2 half_ = vec2(max(size.x, size.y * 0.5), size.y) * 0.5 + (1.0 - left * left) * size.y * 0.45;
    float d = box(fragCoord - cur, half_, min(half_.x, half_.y) * 0.5);
    float ring = 1.0 - smoothstep(0.0, 1.5, abs(d) - 0.6);
    float glow = exp(-max(d, 0.0) / (size.y * 0.35)) * step(-size.y, d) * 0.35;
    float a = clamp((ring * 0.8 + glow) * left * left * 0.55, 0.0, 1.0);
    fragColor = vec4(mix(fragColor.rgb, iCurrentCursorColor.rgb, a), fragColor.a);
}
