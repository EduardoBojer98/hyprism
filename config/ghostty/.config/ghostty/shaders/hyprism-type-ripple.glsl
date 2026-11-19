// Typing effect "Ripple" (Settings > Appearance > Terminal > Typing effect): each keystroke sends a ring-shaped wave
// out from the cursor that bends the text it passes over, like a drop on water, with a faint glint on its crest.

const float LIFE = 0.4;

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    fragColor = texture(iChannel0, uv);
    float t = (iTime - iTimeCursorChange) / LIFE;
    if (t >= 1.0 || iFocus == 0) return;
    vec2 size = iCurrentCursor.zw;
    vec2 cur = iCurrentCursor.xy + vec2(size.x, -size.y) * 0.5;
    vec2 to = fragCoord - cur;
    float d = length(to);
    float radius = (1.0 - (1.0 - t) * (1.0 - t)) * size.y * 3.0;
    float width = size.y * 0.45;
    float x = (d - radius) / width;
    if (abs(x) > 1.0 || d < 0.5) return;
    float fade = (1.0 - t);
    float wave = sin(x * 3.14159) * (1.0 - x * x);           // one crest and one trough across the band
    vec2 bent = fragCoord - normalize(to) * wave * size.y * 0.18 * fade;
    fragColor = texture(iChannel0, bent / iResolution.xy);
    float glint = max(wave, 0.0) * 0.35 * fade;
    fragColor = vec4(mix(fragColor.rgb, iCurrentCursorColor.rgb, glint), fragColor.a);
}
