shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform float flicker = 0.0;

void fragment() {
	vec3 c = textureLod(screen_tex, SCREEN_UV, 0.0).rgb;
	float lum = dot(c, vec3(0.299, 0.587, 0.114));
	vec3 sepia = vec3(lum * 1.07 + 0.03, lum * 0.88 + 0.02, lum * 0.64 + 0.01);
	sepia *= 1.0 + flicker;
	COLOR = vec4(mix(c, sepia, strength), 1.0);
}
