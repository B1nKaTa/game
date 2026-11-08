class_name TitleHarold
extends Node2D

# Seated Harold on the title screen, in room pixels. His origin is his chair's seat anchor, and every
# frame is drawn with its own sit point (TitleFrames.HAROLD_SIT, the underside of his thighs) on it, so
# no idle lifts him off the seat; across, his seat stays where the rest frame's is. He waits:
# every few seconds he taps his cane, checks his ticket or sighs (with a small puff of breath), and
# otherwise holds his rest frame. He wears what the save has him wear (SeatedLook): his cardigan outfit
# strip, his cane recoloured by a small shader, and his hat or tie drawn over him at each frame's anchor.

const FPS := 8.0
const WAIT_MIN := 3.5
const WAIT_MAX := 7.0
const ANIMS: Array[String] = ["cane_tap", "ticket_check", "sigh"]
# He faces south-west in the art, so a hat's peak points left.
const FACING := -1.0
const STRIPE_BAND := GrandpaLook.STRIPE_BAND
const PUFF_TIME := 1.4
# Where his breath leaves him in the sigh, from the head anchor, and how far it drifts.
const MOUTH := Vector2(-5, 4)
const PUFF_DRIFT := Vector2(-6, -5)
const PUFF_COLOR := Color(0.92, 0.94, 1.0, 0.75)

const CANE_SHADER := """
shader_type canvas_item;
uniform sampler2D cane_mask : filter_nearest;
uniform bool recolour = false;
uniform vec4 cane_color : source_color = vec4(1.0);
uniform bool stripes = false;
uniform vec4 stripe_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float frame_height = 64.0;

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec4 mask = texture(cane_mask, UV);
	if (recolour && mask.a > 0.5) {
		// The mask's grey is the cane's own tone: 1.0 lit, about 0.6 in shade.
		float shade = mix(0.62, 1.0, clamp((mask.r - 0.58) / 0.42, 0.0, 1.0));
		vec3 colour = cane_color.rgb;
		if (stripes && mod(floor(UV.y * frame_height / 2.0), 2.0) > 0.5) {
			colour = stripe_color.rgb;
		}
		base.rgb = colour * shade;
	}
	COLOR = base;
}
"""

var look: Dictionary = SeatedLook.describe({})
var frame := TitleFrames.HAROLD_REST
var _sprite: Sprite2D
var _overlay: Node2D
var _anim := ""
var _anim_time := 0.0
var _wait := 2.0
var _puff_time := -1.0
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.centered = false
	_sprite.hframes = TitleFrames.HAROLD_FRAMES
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var material := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = CANE_SHADER
	material.shader = shader
	_sprite.material = material
	add_child(_sprite)
	_overlay = Node2D.new()
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)
	apply_look(look)


# Puts on a seated look (SeatedLook.describe).
func apply_look(seated: Dictionary) -> void:
	look = seated
	if _sprite == null:
		return
	_sprite.texture = load(str(look["art"]))
	var material := _sprite.material as ShaderMaterial
	material.set_shader_parameter("cane_mask", load(SeatedLook.art_path("harold_cane")))
	material.set_shader_parameter("recolour", look["cane"])
	material.set_shader_parameter("cane_color", look["cane_color"])
	material.set_shader_parameter("stripes", look["stripes"])
	material.set_shader_parameter("stripe_color", STRIPE_BAND)
	material.set_shader_parameter("frame_height", float(TitleFrames.HAROLD_SIZE))
	_show(frame)


func _process(delta: float) -> void:
	if _puff_time >= 0.0:
		_puff_time += delta
		if _puff_time > PUFF_TIME:
			_puff_time = -1.0
		_overlay.queue_redraw()
	if _anim.is_empty():
		_wait -= delta
		if _wait <= 0.0:
			play(ANIMS[_rng.randi() % ANIMS.size()])
		return
	_anim_time += delta
	var span: Array = TitleFrames.HAROLD_ANIMS[_anim]
	var index := int(_anim_time * FPS)
	if index >= int(span[1]):
		_anim = ""
		_wait = _rng.randf_range(WAIT_MIN, WAIT_MAX)
		_show(TitleFrames.HAROLD_REST)
		return
	_show(int(span[0]) + index)
	# The breath leaves him as his shoulders drop, halfway through the sigh.
	if _anim == "sigh" and index == int(span[1]) / 2 and _puff_time < 0.0:
		_puff_time = 0.0


func play(anim: String) -> void:
	_anim = anim
	_anim_time = 0.0


# Where frame is drawn from his origin, so its sit point lands on the seat anchor.
static func expected_offset(index: int) -> Vector2:
	return Vector2(-TitleFrames.HAROLD_SIT[TitleFrames.HAROLD_REST].x, -TitleFrames.HAROLD_SIT[index].y)


func sprite_offset() -> Vector2:
	return _sprite.position


func _show(index: int) -> void:
	frame = index
	_sprite.frame = index
	_sprite.position = expected_offset(index)
	_overlay.queue_redraw()


func head() -> Vector2:
	return _sprite.position + TitleFrames.HAROLD_HEAD[frame]


func _draw_overlay() -> void:
	if look["tie"]:
		GrandpaLook.draw_tie(_overlay, _sprite.position + TitleFrames.HAROLD_TIE[frame], look["tie_color"])
	if not str(look["hat"]).is_empty():
		GrandpaLook.draw_hat(_overlay, str(look["hat"]), head(), look["hat_color"], FACING)
	if _puff_time >= 0.0:
		var k := _puff_time / PUFF_TIME
		var at := head() + MOUTH + PUFF_DRIFT * k
		var color := PUFF_COLOR
		color.a *= 1.0 - k
		# Three small round blobs that spread as they rise, on the room's pixel grid.
		for offset: Vector2 in [Vector2.ZERO, Vector2(-2, -1), Vector2(-1, -2)]:
			var r := 1.0 + k * 1.5
			var c := (at + offset * (0.6 + k)).round()
			_overlay.draw_rect(Rect2(c - Vector2(r, r).floor(), Vector2(r, r).floor() * 2.0 + Vector2.ONE), color)
