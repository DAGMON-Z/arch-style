// Makes colors a little more vivid and brighter, for screens that look dull.
// Turned on per computer in ~/.config/hypr/monitors.lua. See docs/03-hyprland.md.
#version 300 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// 1.0 = unchanged. Raise SATURATION for stronger colors, BRIGHTNESS for lighter.
const float SATURATION = 1.15;
const float BRIGHTNESS = 1.05;

void main() {
    vec4 color = texture(tex, v_texcoord);
    // Grey version of the pixel, weighted the way eyes see brightness
    float grey = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
    vec3 vivid = mix(vec3(grey), color.rgb, SATURATION) * BRIGHTNESS;
    fragColor = vec4(clamp(vivid, 0.0, 1.0), color.a);
}
