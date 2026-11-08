class_name WarningWindow
extends Control

# A window through the small map for warnings. The map's panel sits in the top right of the view, over
# the play area, so in a large room a lane or ring warning there would lie under it. The HUD copies the
# world as drawn before any of its own pieces (Hud.BACK_COPY, a BackBufferCopy over MAP_PANEL), and this
# draws over the map, from that copy, every pixel that is or lies within REACH of the warning red, so a
# warning shows through the map where it lies and the map stays whole everywhere else.
#
# The look keeps the warning red out of every tile, prop and shot (docs/art/art-direction-notes.md,
# section 3), and warnings draw unshaded in full colour, so redness alone finds them. REACH carries the
# window over a lane's faint middle from its full-colour outline: the widest lane (the splice) is 36 px.
const REACH := 20.0
# How much of the world shows through where a warning lies.
const STRENGTH := 0.9
const SHADER_CODE := """
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D world : hint_screen_texture, filter_nearest;
uniform float reach = 20.0;
uniform float strength = 0.9;

float redness(vec2 uv) {
	vec3 c = texture(world, uv).rgb;
	return c.r - max(c.g, c.b);
}

void fragment() {
	float best = redness(SCREEN_UV);
	for (int i = 1; i <= 4; i++) {
		float d = reach * float(i) / 4.0;
		for (int k = 0; k < 8; k++) {
			float a = 0.785398 * float(k);
			best = max(best, redness(SCREEN_UV + vec2(cos(a), sin(a)) * d * SCREEN_PIXEL_SIZE));
		}
	}
	float shown = smoothstep(0.17, 0.30, best);
	COLOR = vec4(texture(world, SCREEN_UV).rgb, shown * strength);
}
"""

static var _shader: Shader


static func shader() -> Shader:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER_CODE
	return _shader


# The window over area, in its parent's space.
func setup(area: Rect2) -> void:
	position = area.position
	size = area.size


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var paint := ShaderMaterial.new()
	paint.shader = shader()
	paint.set_shader_parameter("reach", REACH)
	paint.set_shader_parameter("strength", STRENGTH)
	material = paint


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color.WHITE)
