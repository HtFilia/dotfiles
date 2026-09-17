// Optional static CRT texture. No warping or animation loop.
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 screen = texture(iChannel0, uv);
    float scanline = 0.97 + 0.03 * cos(fragCoord.y * 3.14159265);
    fragColor = vec4(screen.rgb * scanline, screen.a);
}
