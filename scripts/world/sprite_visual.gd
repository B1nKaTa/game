class_name SpriteVisual
extends Node2D

# Art from res://art/sprites/<art_id>/<anim>.png, one row of frames per anim, or a placeholder box
# when there is none. Frames are frame_width wide, or square (as wide as the strip is tall) when it
# is 0. With set_feet the node stands on the feet, and each strip is placed by its own lowest used
# row so the feet land on this node's origin in every anim (PixelLab drifts a few rows between anims).

const FPS := 10.0
const HIT_FLASH_TIME := 0.08
const FLASH_FADE := 0.3
const ART_PATH := "res://art/sprites/%s/%s.png"
# What shows when an anim has no strip: the windup, the attack and the walk fall back to the idle, and
# any other (a behavior's own, such as a whistle) to the attack first.
const FALLBACKS := {"windup": "idle", "attack": "idle", "walk": "idle"}
const SPECIAL_FALLBACK := "attack"
const SHADER_CODE := """
shader_type canvas_item;
uniform vec3 flash_color = vec3(1.0);
// The light a body is shown in when the room's own light does not reach it (the depth look's bodies
// draw unshaded, so a dark corner never swallows them). White leaves it as drawn.
uniform vec3 body_light = vec3(1.0);
// Lifts the darks of that even light (1 leaves the art as drawn), so a dark suit keeps its shape.
uniform float body_gamma = 1.0;
uniform float amount = 0.0;
uniform float alpha = 1.0;
uniform vec3 tint = vec3(1.0);
// A recolour for a floor variant sharing its base's art: hues within hue_width of hue_from (all in
// turns, 0 to 1) move by hue_shift, on pixels at least min_sat saturated, so skin, greys and whites
// stay, and their value is multiplied by value_gain (to lift a robe a dark floor would swallow).
// A zero hue_width leaves the art as drawn.
uniform float hue_from = 0.0;
uniform float hue_width = 0.0;
uniform float hue_shift = 0.0;
uniform float min_sat = 0.15;
uniform float value_gain = 1.0;

vec3 to_hsv(vec3 c) {
	vec4 k = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, k.wz), vec4(c.gb, k.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + 1.0e-10)), d / (q.x + 1.0e-10), q.x);
}

vec3 to_rgb(vec3 c) {
	vec3 p = abs(fract(c.xxx + vec3(1.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0);
	return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec3 rgb = c.rgb;
	if (hue_width > 0.0) {
		vec3 hsv = to_hsv(rgb);
		float gap = abs(fract(hsv.x - hue_from + 0.5) - 0.5);
		if (gap <= hue_width && hsv.y >= min_sat) {
			rgb = to_rgb(vec3(fract(hsv.x + hue_shift), hsv.y, min(hsv.z * value_gain, 1.0)));
		}
	}
	rgb = pow(rgb, vec3(body_gamma));
	COLOR = vec4(mix(rgb * tint * body_light, flash_color, amount), c.a * alpha);
}
"""
# The same, drawn unshaded: in the depth look (DepthLook.active) bodies keep one even light wherever they
# stand, so the dark room never hides an enemy or Harold.
const UNSHADED_MODE := "render_mode unshaded;"

var _art_id := ""
var _size := Vector2(20, 24)
var _color := Color.WHITE
var _frame_width := 32
# The anim asked for, and the one shown after the fallbacks.
var _anim := ""
var _shown := ""
var _sprite: Sprite2D
var _time := 0.0
var _once_duration := 0.0
var _flash_color := Color.WHITE
var _flash_left := 0.0
var _flash_time := 0.0
var _alpha := 1.0
# Multiplies the art's colour, as for a sunburnt Harold in an ending scene. White leaves it as drawn.
var _tint := Color.WHITE
# hue_from, hue_width, hue_shift, in turns, and the value gain. See the shader.
var _recolor := Vector3.ZERO
var _value_gain := 1.0
var _material: ShaderMaterial
# Set by set_feet: this node stands on the feet, so a y-sorting parent sorts it by them.
var _on_feet := false
var _feet_y := 0.0

# Strip path -> its lowest used row, end exclusive, so each strip is read once.
static var _feet_rows := {}
# One shader for every body (and one unshaded), so a spawn compiles nothing new.
static var _shader: Shader
static var _unshaded_shader: Shader
# Whether this body is shown in the depth look's even light now.
var _depth_lit := false


static func shared_shader(unshaded: bool) -> Shader:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER_CODE
		_unshaded_shader = Shader.new()
		_unshaded_shader.code = SHADER_CODE.replace("shader_type canvas_item;", "shader_type canvas_item; " + UNSHADED_MODE)
	return _unshaded_shader if unshaded else _shader


static func frame_count(texture_width: int, frame_width: int) -> int:
	if frame_width <= 0:
		return 1
	return maxi(texture_width / frame_width, 1)


# How wide one frame of a strip is: frame_width, or as wide as the strip is tall when it is 0.
static func frame_size(texture_width: int, texture_height: int, frame_width: int) -> int:
	if frame_width > 0:
		return frame_width
	return clampi(texture_height, 1, maxi(texture_width, 1))


static func art_path(art_id: String, anim: String) -> String:
	return ART_PATH % [art_id, anim]


static func has_anim(art_id: String, anim: String) -> bool:
	return not art_id.is_empty() and not anim.is_empty() and ResourceLoader.exists(art_path(art_id, anim))


# The anim that shows for anim, given which strips exist (exists takes an anim name), or "" when
# not even the idle does, so the placeholder draws.
static func resolve(anim: String, exists: Callable) -> String:
	var seen: Array[String] = []
	var at := anim
	while not at.is_empty() and not seen.has(at):
		if exists.call(at):
			return at
		seen.append(at)
		if FALLBACKS.has(at):
			at = FALLBACKS[at]
		elif at == "idle":
			at = ""
		else:
			at = SPECIAL_FALLBACK
	return ""


# The lowest used row of a strip, end exclusive: where its feet are. The whole height when the
# pixels can't be read.
static func feet_row(texture: Texture2D) -> int:
	if texture == null:
		return 0
	var key := texture.resource_path
	if not key.is_empty() and _feet_rows.has(key):
		return _feet_rows[key]
	var rows := NpcSprite.used_rows(texture)
	var row := rows.y if rows.y > rows.x else texture.get_height()
	if not key.is_empty():
		_feet_rows[key] = row
	return row


# Where a centred sprite of this height must sit so its feet row lands on y 0.
static func feet_offset(texture_height: int, row: int) -> float:
	return texture_height / 2.0 - row


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


# Stands this node on the feet, feet_y below its parent's origin, and places every strip by its
# lowest row there. The placeholder box stays where it was, centred on the parent.
func set_feet(feet_y: float) -> void:
	_on_feet = true
	_feet_y = feet_y
	position = Vector2(0.0, feet_y)
	_place()
	queue_redraw()


func play(anim: String) -> void:
	if anim == _anim:
		return
	_anim = anim
	_time = 0.0
	_once_duration = 0.0
	_shown = resolve(anim, func(name: String) -> bool: return has_anim(_art_id, name))
	if _shown.is_empty():
		if _sprite != null:
			_sprite.visible = false
		queue_redraw()
		return
	if _sprite == null:
		_sprite = Sprite2D.new()
		_material = ShaderMaterial.new()
		_depth_lit = DepthLook.active
		_material.shader = shared_shader(_depth_lit)
		_sprite.material = _material
		add_child(_sprite)
		move_child(_sprite, 0)
		_apply_look()
	var texture: Texture2D = load(art_path(_art_id, _shown))
	_sprite.texture = texture
	_sprite.hframes = frame_count(texture.get_width(), frame_size(texture.get_width(), texture.get_height(), _frame_width))
	_sprite.frame = 0
	_sprite.visible = true
	_place()
	queue_redraw()


func play_once(anim: String, duration: float) -> void:
	_anim = ""
	play(anim)
	_once_duration = duration


func is_playing_once() -> bool:
	return _once_duration > 0.0 and _time < _once_duration


func has_art() -> bool:
	return _sprite != null and _sprite.visible


# The anim asked for last, and the one that shows for it ("" for the placeholder).
func anim() -> String:
	return _anim


func shown_anim() -> String:
	return _shown


func is_facing_left() -> bool:
	return _sprite != null and _sprite.flip_h


func sprite() -> Sprite2D:
	return _sprite


# Where the frame's middle sits from the parent's origin, for a copy left in the parent's place.
func frame_offset() -> Vector2:
	if _sprite == null:
		return position
	return position + _sprite.position + _sprite.offset


func _place() -> void:
	if _sprite == null or _sprite.texture == null:
		return
	if _on_feet:
		_sprite.offset = Vector2(0.0, feet_offset(_sprite.texture.get_height(), feet_row(_sprite.texture)))
	else:
		_sprite.offset = Vector2.ZERO


# A still copy of the frame shown now, for a look that stays, such as the Afterimage. Null without art.
func copy_frame() -> Sprite2D:
	if not has_art():
		return null
	var still := Sprite2D.new()
	still.texture = _sprite.texture
	still.hframes = _sprite.hframes
	still.frame = _sprite.frame
	still.flip_h = _sprite.flip_h
	still.offset = frame_offset()
	return still


# A copy of the current frame, for leaving behind during a dodge. Null without art.
func make_ghost() -> DodgeGhost:
	if not has_art():
		return null
	var ghost := DodgeGhost.new()
	ghost.texture = _sprite.texture
	ghost.hframes = _sprite.hframes
	ghost.frame = _sprite.frame
	ghost.flip_h = _sprite.flip_h
	ghost.offset = frame_offset()
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


# The shader draws the art itself, so modulate never reaches it: a tint goes through the shader.
func set_tint(color: Color) -> void:
	_tint = color
	_apply_look()


# Turns hues within width_deg of from_deg by to_deg - from_deg, as a floor variant's colour on its
# base's art, and multiplies their value by value_gain. A zero width turns it off.
func set_recolor(from_deg: float, to_deg: float, width_deg: float, value_gain := 1.0) -> void:
	_recolor = Vector3(from_deg / 360.0, maxf(width_deg, 0.0) / 360.0, (to_deg - from_deg) / 360.0)
	_value_gain = maxf(value_gain, 0.0)
	_apply_look()


func recolor() -> Vector3:
	return _recolor


func _apply_look() -> void:
	if _material != null:
		_material.set_shader_parameter("flash_color", Vector3(_flash_color.r, _flash_color.g, _flash_color.b))
		_material.set_shader_parameter("amount", flash_amount(_flash_left, _flash_time))
		_material.set_shader_parameter("alpha", _alpha)
		_material.set_shader_parameter("tint", Vector3(_tint.r, _tint.g, _tint.b))
		_material.set_shader_parameter("hue_from", _recolor.x)
		_material.set_shader_parameter("hue_width", _recolor.y)
		_material.set_shader_parameter("hue_shift", _recolor.z)
		_material.set_shader_parameter("value_gain", _value_gain)
		var lit := DepthLook.BODY_LIGHT if _depth_lit else Color.WHITE
		_material.set_shader_parameter("body_light", Vector3(lit.r, lit.g, lit.b))
		_material.set_shader_parameter("body_gamma", DepthLook.BODY_GAMMA if _depth_lit else 1.0)
	queue_redraw()


func _process(delta: float) -> void:
	if _material != null and DepthLook.active != _depth_lit:
		_depth_lit = DepthLook.active
		_material.shader = shared_shader(_depth_lit)
		_apply_look()
		# What is worn over the art (GrandpaLook, EnemyMarks) keeps the same light as the body.
		for child in get_children():
			if child != _sprite and child is CanvasItem:
				child.material = DepthLook.unshaded() if _depth_lit else null
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
	var box := Rect2(-_size / 2.0 - Vector2(0.0, _feet_y if _on_feet else 0.0), _size)
	# A pale halo keeps a dark placeholder visible on a dark floor.
	draw_rect(box.grow(1.0), Color(1.0, 1.0, 1.0, 0.5 * _alpha), false, 1.0)
	draw_rect(box, fill)
	draw_rect(box, outline, false, 1.0)
