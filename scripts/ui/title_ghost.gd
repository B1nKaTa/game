class_name TitleGhost
extends Node2D

# One ghost in the title screen's queue, in room pixels. Seated, its origin is its chair's seat anchor
# and every frame is drawn with that frame's own sit point on it (TitleSeats.frame_offset with
# TitleFrames.GHOST_SIT), so talking, turning, crossing its legs or shifting never lifts it off the seat.
# It sits facing front, turns to whoever it talks or listens to, talks, crosses and uncrosses its legs,
# shifts, and now and then gets up, drifts along the row and sits down in another chair (TitleRoom
# claims that chair first). Standing up and sitting down keep the sit point of the first frame of
# standing up, so the art's own rise plays out from the seat; on arrival it lands exactly on the new
# anchor before any seated frame shows. The art faces south-east; facing west mirrors it.

signal arrived

const FPS := 8.0
const TALK_FPS := 6.0
const DRIFT_SPEED := 22.0
# A drifting ghost rises this far over the row, easing up and down over EASE px at each end of its
# path, so its head clears the seated ones it passes in front of (a seated head peeking just over a
# drifting one read as a ring over it).
const HOVER := 12.0
const EASE := 10.0
const BOB := 1.0

enum State { SITTING, TALKING, PLAYING, RISING, DRIFTING, LANDING }

var seat := 0
var state := State.SITTING
var crossed := false
var frame := TitleFrames.GHOST_FRONT
var _sprite: Sprite2D
var _art: Texture2D
var _art_id := ""
var _tint := Color.WHITE
var _sits: Array = []
var _face := 0
var _anim := ""
var _reverse := false
var _hold := false
var _time := 0.0
var _talk_left := 0.0
var _target_x := 0.0
var _start_x := 0.0
var _bob_time := 0.0
var _lift := 0.0
var _mirrored := false


func setup(art: Texture2D, tint: Color, art_id: String) -> void:
	_art = art
	_tint = tint
	_art_id = art_id
	_sits = TitleFrames.GHOST_SIT[art_id]


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = _art
	_sprite.centered = false
	_sprite.hframes = TitleFrames.GHOST_FRAMES
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.self_modulate = _tint
	add_child(_sprite)
	_bob_time = randf() * TAU
	_rest()


func is_free() -> bool:
	return state == State.SITTING


func is_seated() -> bool:
	return state == State.SITTING or state == State.TALKING or state == State.PLAYING


# Where its head is, for a speech bubble, in room pixels from the room's origin.
func head_top() -> Vector2:
	return position + Vector2(0, _sprite.position.y + TitleFrames.GHOST_ROWS[_art_id].x)


# Where the current frame is drawn from the ghost's origin: seated frames put their own sit point on
# the seat anchor; standing up, drifting and sitting down use the sit point of the first standing-up
# frame, lifted while it drifts.
func expected_offset() -> Vector2:
	if is_seated():
		return TitleSeats.frame_offset(_sits[frame], TitleFrames.GHOST_SIZE, _mirrored)
	var stand_start: int = TitleFrames.GHOST_ANIMS["stand_up"][0]
	return TitleSeats.frame_offset(_sits[stand_start], TitleFrames.GHOST_SIZE) - Vector2(0, _lift)


func sprite_offset() -> Vector2:
	return _sprite.position


# Turns to the west (-1), the east (1) or the front (0).
func face(direction: int) -> void:
	_face = direction
	if state == State.SITTING:
		_rest()


func talk(seconds: float, toward: int) -> void:
	_face = toward
	state = State.TALKING
	_talk_left = seconds
	_time = 0.0


func fidget() -> void:
	if crossed:
		_start_anim("cross_legs", true, false)
		crossed = false
	elif randf() < 0.5:
		_start_anim("cross_legs", false, true)
		crossed = true
	else:
		_start_anim("shift", false, false)


# Gets up and drifts to the seat anchor at x; the caller has claimed new_seat for it already.
func move_to(x: float, new_seat: int) -> void:
	_target_x = x
	_start_x = position.x
	seat = new_seat
	crossed = false
	_face = 0
	state = State.RISING
	_anim = "stand_up"
	_reverse = false
	_time = 0.0
	_lift = 0.0
	_show(int(TitleFrames.GHOST_ANIMS["stand_up"][0]), 0)


func _start_anim(anim: String, reverse: bool, hold: bool) -> void:
	state = State.PLAYING
	_anim = anim
	_reverse = reverse
	_hold = hold
	_time = 0.0


func _process(delta: float) -> void:
	_time += delta
	_bob_time += delta
	match state:
		State.TALKING:
			_talk_left -= delta
			var span: Array = TitleFrames.GHOST_ANIMS["talk"]
			_show(int(span[0]) + int(_time * TALK_FPS) % int(span[1]), _face)
			if _talk_left <= 0.0:
				state = State.SITTING
				_rest()
		State.PLAYING, State.RISING, State.LANDING:
			var span: Array = TitleFrames.GHOST_ANIMS[_anim]
			var count := int(span[1])
			var index := int(_time * FPS)
			if index >= count:
				_finish()
				return
			var at := count - 1 - index if _reverse else index
			# Talk, crossing and shifting were drawn turned; standing up was drawn front on.
			_show(int(span[0]) + at, 0 if _anim == "stand_up" else (_face if _face != 0 else 1))
		State.DRIFTING:
			var way := signf(_target_x - position.x)
			position.x = move_toward(position.x, _target_x, DRIFT_SPEED * delta)
			var ends := minf(absf(position.x - _start_x), absf(_target_x - position.x))
			_lift = round(HOVER * clampf(ends / EASE, 0.0, 1.0) + sin(_bob_time * 4.0) * BOB * clampf(ends / EASE, 0.0, 1.0))
			_show(TitleFrames.GHOST_DRIFT, int(way))
			if is_equal_approx(position.x, _target_x):
				# Exactly on the new anchor before it sits down.
				position.x = _target_x
				_lift = 0.0
				state = State.LANDING
				_anim = "stand_up"
				_reverse = true
				_time = 0.0
				_show(int(TitleFrames.GHOST_ANIMS["stand_up"][0]) + int(TitleFrames.GHOST_ANIMS["stand_up"][1]) - 1, 0)


func _finish() -> void:
	match state:
		State.RISING:
			state = State.DRIFTING
			z_index = 5
		State.LANDING:
			z_index = 0
			state = State.SITTING
			_rest()
			arrived.emit()
		_:
			state = State.SITTING
			if _hold:
				var span: Array = TitleFrames.GHOST_ANIMS[_anim]
				_show(int(span[0]) + int(span[1]) - 1, _face if _face != 0 else 1)
			else:
				_rest()


func _rest() -> void:
	if _sprite == null:
		return
	if crossed:
		var span: Array = TitleFrames.GHOST_ANIMS["cross_legs"]
		_show(int(span[0]) + int(span[1]) - 1, _face if _face != 0 else 1)
	elif _face == 0:
		_show(TitleFrames.GHOST_FRONT, 0)
	else:
		_show(TitleFrames.GHOST_TURNED, _face)


# Shows a frame, mirrored when it faces west (the art faces east), drawn where expected_offset puts it.
func _show(index: int, direction: int) -> void:
	frame = index
	_mirrored = direction < 0
	_sprite.frame = index
	_sprite.flip_h = _mirrored
	_sprite.position = expected_offset()


func is_mirrored() -> bool:
	return _mirrored
