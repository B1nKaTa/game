class_name AdjustLayer
extends CanvasLayer

# Brightness, contrast and gamma for the whole screen: a shader over everything drawn below it, on a
# layer above every panel. It hides when all three are at 0, so an untouched game draws nothing extra.

const LAYER := 120
const SHADER := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float brightness = 0.0;
uniform float contrast = 1.0;
uniform float gamma = 1.0;

void fragment() {
	vec3 c = textureLod(screen_tex, SCREEN_UV, 0.0).rgb;
	c = pow(max(c, vec3(0.0)), vec3(1.0 / gamma));
	c = (c - 0.5) * contrast + 0.5 + brightness;
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
"""

var _rect: ColorRect


func _ready() -> void:
	if _rect != null:
		return
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.size = Vector2(GameSettings.VIEW)
	var shader := Shader.new()
	shader.code = SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	_rect.material = material
	add_child(_rect)
	visible = false


func rect() -> ColorRect:
	return _rect


func set_levels(brightness: int, contrast: int, gamma: int) -> void:
	var material := _rect.material as ShaderMaterial
	material.set_shader_parameter("brightness", GameSettings.brightness_offset(brightness))
	material.set_shader_parameter("contrast", GameSettings.contrast_factor(contrast))
	material.set_shader_parameter("gamma", GameSettings.gamma_power(gamma))
	visible = not GameSettings.is_neutral(brightness, contrast, gamma)
