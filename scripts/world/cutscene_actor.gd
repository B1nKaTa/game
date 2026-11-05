class_name CutsceneActor
extends Node2D

# One puppet in an ending scene. Its position is where its feet are, so a fall turns it about its feet
# and it lies on the ground. Harold is his real sprite, playing his own walk, idle and attack; anyone
# else is drawn by ActorLook. The CutscenePlayer calls tick() every frame, so walking and one-shots
# keep to the scene's own clock, which tests can step.

const HAROLD := "harold"
const HAROLD_COLOR := Color("7d9a5c")
# Where Harold's sprite sits over his feet, and his head for a hat (GrandpaLook.HEAD over the feet).
const HAROLD_SPRITE_OFFSET := -Player.FEET_OFFSET
const HAROLD_HEAD := HAROLD_SPRITE_OFFSET + GrandpaLook.HEAD
const FLOAT_RISE := 10.0
const GHOST_ALPHA := 0.6

var id := ""
var facing := 1
var _body: Node2D
var _sprite: SpriteVisual
var _look: ActorLook
var _hat: HatLayer
var _to := Vector2.ZERO
var _speed := 0.0
var _walking := false
var _anim := ""
var _anim_time := 0.0
var _anim_length := 0.0
var _start_rotation := 0.0
var _end_rotation := 0.0
var _floating := false
var _float_started := -1.0
var _clock := 0.0


class HatLayer extends Node2D:
	var shape := ""
	var color := Color.WHITE
	var head := Vector2.ZERO
	var facing := 1.0

	func _draw() -> void:
		if not shape.is_empty():
			ActorLook.draw_hat(self, shape, head, color, facing)


func setup(actor_id: String) -> void:
	id = actor_id
	_body = Node2D.new()
	add_child(_body)
	if id == HAROLD:
		_sprite = SpriteVisual.new()
		_sprite.position = HAROLD_SPRITE_OFFSET
		_body.add_child(_sprite)
		_sprite.setup("grandpa", Vector2(20, 28), HAROLD_COLOR, Player.SPRITE_FRAME_WIDTH)
	else:
		_look = ActorLook.new()
		_look.id = id
		_body.add_child(_look)
	_hat = HatLayer.new()
	_hat.head = HAROLD_HEAD if id == HAROLD else ActorLook.head_of(id)
	_body.add_child(_hat)
	face(facing)


func place(at: Vector2, dir: int) -> void:
	position = at
	_walking = false
	face(dir)


func face(dir: int) -> void:
	facing = -1 if dir < 0 else 1
	if _sprite != null:
		_sprite.set_facing_left(facing < 0)
	if _look != null:
		_look.facing = facing
		_look.queue_redraw()
	_hat.facing = facing
	_hat.queue_redraw()


func walk_to(to: Vector2, speed: float) -> void:
	_to = to
	_speed = maxf(speed, 1.0)
	_walking = position.distance_to(to) > 0.01
	if not is_zero_approx(to.x - position.x):
		face(1 if to.x > position.x else -1)
	if not _walking:
		position = to


func play_anim(anim_name: String) -> void:
	# A group, such as the mourners, falls one by one in its own drawing rather than as one block.
	if _look != null and ActorLook.GROUPS.has(id) and anim_name in ["fall", "faint", "lie"]:
		_look.down = true
		_look.queue_redraw()
		_anim = anim_name
		_anim_time = 0.0
		_anim_length = float(CutsceneSteps.ANIM_TIME.get(anim_name, 0.0))
		_start_rotation = rotation
		_end_rotation = rotation
		if _anim_length <= 0.0:
			_anim = ""
		return
	_anim = anim_name
	_anim_time = 0.0
	_anim_length = float(CutsceneSteps.ANIM_TIME.get(anim_name, 0.0))
	_start_rotation = rotation
	match anim_name:
		"fall":
			_end_rotation = facing * PI / 2.0
		"faint":
			_end_rotation = -facing * PI / 2.0
		"lie":
			rotation = -facing * PI / 2.0
		"sit_up", "stand":
			_end_rotation = 0.0
			if anim_name == "stand":
				rotation = 0.0
		"float":
			_floating = true
		"swing":
			if _sprite != null:
				_sprite.play_once("attack", _anim_length)
		_:
			_end_rotation = rotation
	if _anim_length <= 0.0:
		_anim = ""


func is_walking() -> bool:
	return _walking


func is_animating() -> bool:
	return not _anim.is_empty()


# Harold's sprite draws through its own shader, which modulate never reaches, so he is tinted there.
func set_tint(color: Color) -> void:
	if _sprite != null:
		_sprite.set_tint(color)
	else:
		_body.modulate = Color(color.r, color.g, color.b, _body.modulate.a)


func set_look_state(state: String) -> void:
	if _look != null:
		_look.state = state
		_look.queue_redraw()


func set_hat(shape: String, color: Color) -> void:
	_hat.shape = shape
	_hat.color = color
	_hat.queue_redraw()


func tick(delta: float) -> void:
	_clock += delta
	if _walking:
		var step := _speed * delta
		if position.distance_to(_to) <= step:
			position = _to
			_walking = false
		else:
			position = position.move_toward(_to, step)
	if _sprite != null and (_sprite.is_playing_once() == false):
		_sprite.play("walk" if _walking else "idle")
	if _look != null:
		_look.walking = _walking
		_look.action = _anim
		_look.clock = _clock
		_look.queue_redraw()
	_tick_anim(delta)
	if _floating:
		_body.position.y = -FLOAT_RISE * minf(_clock_since_float(), 1.0) + sin(_clock * 3.0) * 1.5
		_body.modulate.a = GHOST_ALPHA
		if _sprite != null:
			_sprite.set_alpha(GHOST_ALPHA)


func _clock_since_float() -> float:
	if _float_started < 0.0:
		_float_started = _clock
	return (_clock - _float_started) / maxf(float(CutsceneSteps.ANIM_TIME["float"]), 0.01)


func _tick_anim(delta: float) -> void:
	if _anim.is_empty():
		return
	_anim_time += delta
	var t := clampf(_anim_time / _anim_length, 0.0, 1.0)
	match _anim:
		"fall", "faint", "sit_up":
			rotation = lerpf(_start_rotation, _end_rotation, t * t if _anim != "sit_up" else t)
		"shake_fist":
			_body.position.y = -absf(sin(_anim_time * 18.0)) * 2.0
		"hop":
			_body.position.y = -6.0 * sin(t * PI)
		"bow":
			rotation = facing * 0.45 * sin(t * PI)
	if _anim_time >= _anim_length:
		if _anim in ["fall", "faint", "sit_up"]:
			rotation = _end_rotation
		elif _anim in ["shake_fist", "hop"]:
			_body.position.y = 0.0
		elif _anim == "bow":
			rotation = 0.0
		_anim = ""
