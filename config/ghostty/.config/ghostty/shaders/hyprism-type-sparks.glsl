// Typing effect "Sparks" (Settings > Appearance > Terminal > Typing effect): each keystroke throws a handful of
// sparks from the cursor; they fly up and out, fall back under a little gravity and burn out. Every keystroke throws
// a different pattern (seeded by when it happened).

const float LIFE = 0.45;
const int COUNT = 12;

float hash(float n) { return fract(sin(n) * 43758.5453123); }

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = texture(iChannel0, fragCoord / iResolution.xy);
    float t = (iTime - iTimeCursorChange) / LIFE;
    if (t >= 1.0 || iFocus == 0) return;
    vec2 size = iCurrentCursor.zw;
    vec2 cur = iCurrentCursor.xy + vec2(size.x, -size.y) * 0.5;
    if (distance(fragCoord, cur) > size.y * 3.5) return;   // nothing reaches further: most pixels stop here
    vec3 hot = mix(iCurrentCursorColor.rgb, vec3(1.0), 0.45);
    float seed = floor(iTimeCursorChange * 997.0);
    float fly = 1.0 - (1.0 - t) * (1.0 - t);   // fast out, slowing
    float a = 0.0;
    for (int i = 0; i < COUNT; i++) {
        float fi = float(i);
        float ang = 0.35 + 2.45 * hash(seed + fi * 7.13);          // mostly upward, a fan from right to left
        float speed = size.y * (1.5 + 1.8 * hash(seed + fi * 3.71));
        vec2 p = cur + vec2(cos(ang), sin(ang)) * speed * fly - vec2(0.0, size.y * 1.6 * t * t);   // y is up
        float r = size.y * (0.11 + 0.07 * hash(seed + fi)) * (1.0 - t * 0.6);
        a = max(a, 1.0 - smoothstep(r * 0.4, r, distance(fragCoord, p)));
    }
    fragColor = vec4(mix(fragColor.rgb, hot, a * (1.0 - t)), fragColor.a);
}
