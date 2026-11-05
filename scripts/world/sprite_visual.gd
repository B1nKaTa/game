class_name SpriteVisual
extends Node2D

const FPS := 10.0
const HIT_FLASH_TIME := 0.08
const FLASH_FADE := 0.3
const SHADER_CODE := """
shader_type canvas_item;
uniform vec3 flash_color = vec3(1.0);
uniform float amount = 0.0;
uniform float alpha = 1.0;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	COLOR = vec4(mix(c.rgb, flash_color, amount), c.a * alpha);
}
"""

var _art_id := ""
var _size := Vector2(20, 24)
var _color := Color.WHITE
var _frame_width := 32
var _anim := ""
var _sprite: Sprite2D
var _time := 0.0
var _once_duration := 0.0
var _flash_color := Color.WHITE
var _flash_left := 0.0
var _flash_time := 0.0
var _alpha := 1.0
var _material: ShaderMaterial


static func frame_count(texture_width: int, frame_width: int) -> int:
	if frame_width <= 0:
		return 1
	return maxi(texture_width / frame_width, 1)


# Placeholders are never darker than this, so enemies stay readable on any floor.
const MIN_BRIGHTNESS := 0.55


static func readable(color: Color) -> Color:
	return Color.from_hsv(color.h, color.s, maxf(color.v, MIN_BRIGHTNESS), color.a)


static func flash_amount(remaining: float, duration: float) -> float:
	if duration <= 0.0 or remaining <= 0.0:
		return 0.0
	return clampf(remaining / (duration * FLASH_FADE), 0.0, 1.0)


static func once_frame(time: float, duration: float, count: int) -> int:
	if duration <= 0.0:
		return count - 1
	return mini(int(time / duration * count), count - 1)


func setup(art_id: String, body_size: Vector2, color: Color, frame_width: int) -> void:
	_art_id = art_id
	_size = body_size
	_color = color
	_frame_width = frame_width
	play("idle")


func play(anim: String) -> void:
	if anim == _anim:
		return
	_anim = anim
	_time = 0.0
	_once_duration = 0.0
	var path := "res://art/sprites/%s/%s.png" % [_art_id, anim]
	if not ResourceLoader.exists(path):
		if _sprite != null:
			_sprite.visible = false
		queue_redraw()
		return
	if _sprite == null:
		_sprite = Sprite2D.new()
		var shader := Shader.new()
		shader.code = SHADER_CODE
		_material = ShaderMaterial.new()
		_material.shader = shader
		_sprite.material = _material
		add_child(_sprite)
		_apply_look()
	var texture: Texture2D = load(path)
	_sprite.texture = texture
	_sprite.hframes = frame_count(texture.get_width(), _frame_width)
	_sprite.frame = 0
	_sprite.visible = true
	queue_redraw()


func play_once(anim: String, duration: float) -> void:
	_anim = ""
	play(anim)
	_once_duration = duration


func is_playing_once() -> bool:
	return _once_duration > 0.0 and _time < _once_duration


func has_art() -> bool:
	return _sprite != null and _sprite.visible


# A copy of the current frame, for leaving behind during a dodge. Null without art.
# A still copy of the frame shown now, for a look that stays, such as the Afterimage. Null without art.
func copy_frame() -> Sprite2D:
	if not has_art():
		return null
	var still := Sprite2D.new()
	still.texture = _sprite.texture
	still.hframes = _sprite.hframes
	still.frame = _sprite.frame
	still.flip_h = _sprite.flip_h
	return still


func make_ghost() -> DodgeGhost:
	if not has_art():
		return null
	var ghost := DodgeGhost.new()
	ghost.texture = _sprite.texture
	ghost.hframes = _sprite.hframes
	ghost.frame = _sprite.frame
	ghost.flip_h = _sprite.flip_h
	return ghost


func set_facing_left(left: bool) -> void:
	if _sprite != null:
		_sprite.flip_h = left


func flash(color := Color.WHITE, duration := HIT_FLASH_TIME) -> void:
	_flash_color = color
	_flash_time = duration
	_flash_left = duration
	_apply_look()


func set_alpha(alpha: float) -> void:
	if is_equal_approx(alpha, _alpha):
		return
	_alpha = alpha
	_apply_look()


func get_alpha() -> float:
	return _alpha


func _apply_look() -> void:
	if _material != null:
		_material.set_shader_parameter("flash_color", Vector3(_flash_color.r, _flash_color.g, _flash_color.b))
		_material.set_shader_parameter("amount", flash_amount(_flash_left, _flash_time))
		_material.set_shader_parameter("alpha", _alpha)
	queue_redraw()


func _process(delta: float) -> void:
	if _flash_left > 0.0:
		_flash_left = maxf(_flash_left - delta, 0.0)
		_apply_look()
	_time += delta
	if not has_art():
		return
	if _once_duration > 0.0:
		_sprite.frame = once_frame(_time, _once_duration, _sprite.hframes)
	else:
		_sprite.frame = int(_time * FPS) % _sprite.hframes


func _draw() -> void:
	if _sprite != null and _sprite.visible:
		return
	var fill := readable(_color).lerp(_flash_color, flash_amount(_flash_left, _flash_time))
	fill.a *= _alpha
	var outline := Color(0.0, 0.0, 0.0, _alpha)
	# A pale halo keeps a dark placeholder visible on a dark floor.
	draw_rect(Rect2(-_size / 2.0, _size).grow(1.0), Color(1.0, 1.0, 1.0, 0.5 * _alpha), false, 1.0)
	draw_rect(Rect2(-_size / 2.0, _size), fill)
	draw_rect(Rect2(-_size / 2.0, _size), outline, false, 1.0)
