class_name CutscenePlayer
extends CanvasLayer

# Plays an ending scene from a list of CutsceneSteps over whatever scene is current, on an opaque
# screen of its own. Steps run one after another; walks and one-shots can be told not to wait, and
# shakes and zooms always run behind what follows. Any key or click moves a text box on, once it has
# shown for MIN_SHOW_TIME so the press that won the fight never skips it. Holding interact for
# SKIP_HOLD skips the whole scene, but the first time a scene plays only once its first text box has
# gone. _process reads the input and calls advance(), which tests call directly.

signal finished

const LAYER := 30
const SKIP_HOLD := 1.0
const MIN_SHOW_TIME := 0.35
const SCREEN := Vector2(640, 360)
const BOX := Rect2(16, 290, 608, 60)
const BOX_COLOR := Color(0.05, 0.04, 0.06, 0.94)
const BOX_EDGE := Color("8a7a5a")
const NAME_COLOR := Color("ffd24a")
const TEXT_COLOR := Color("ece9e0")
const HINT_COLOR := Color(0.75, 0.72, 0.65, 0.85)
const TEXT_SIZE := 13
const NAME_SIZE := 11
const CARD_SIZE := 15
const HINT_SIZE := 9
const SKIP_TEXT := "hold to skip"
const MORE_TEXT := "Click or press any key"

var _steps: Array = []
var _first_time := false
var _index := -1
var _step_time := 0.0
var _step_length := 0.0
var _done := false
var _hold := 0.0
var _boxes_done := 0
var _actors := {}
var _text := ""
var _speaker := ""
var _is_card := false
var _fade := 1.0
var _fade_from := 1.0
var _fade_to := 1.0
var _fade_time := 0.0
var _fade_length := 0.0
var _zoom := 1.0
var _zoom_at := CutsceneSteps.CENTER
var _zoom_from := 1.0
var _zoom_to := 1.0
var _zoom_at_from := CutsceneSteps.CENTER
var _zoom_at_to := CutsceneSteps.CENTER
var _zoom_time := 0.0
var _zoom_length := 0.0
var _shake_amount := 0.0
var _shake_left := 0.0
var _shake_length := 0.0
var _rng := RandomNumberGenerator.new()
var _key_pressed := false
var _built := false

var _world: Node2D
var _stage: CutsceneStage
var _fade_rect: ColorRect
var _box: Panel
var _name_label: Label
var _line_label: Label
var _card_label: Label
var _hint_label: Label
var _hold_bar: ColorRect


func setup(steps: Array, first_time: bool) -> void:
	_steps = steps
	_first_time = first_time


func _ready() -> void:
	if _built:
		return
	_built = true
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	var back := ColorRect.new()
	back.color = Color.BLACK
	back.size = SCREEN
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(back)
	_world = Node2D.new()
	add_child(_world)
	_stage = CutsceneStage.new()
	_world.add_child(_stage)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, _fade)
	_fade_rect.size = SCREEN
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade_rect)
	_box = Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = BOX_COLOR
	style.border_color = BOX_EDGE
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	_box.add_theme_stylebox_override("panel", style)
	_box.position = BOX.position
	_box.size = BOX.size
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_box)
	_name_label = _make_label(Vector2(10, 4), Vector2(BOX.size.x - 20, 14), NAME_SIZE, NAME_COLOR)
	_box.add_child(_name_label)
	_line_label = _make_label(Vector2(10, 19), Vector2(BOX.size.x - 20, 38), TEXT_SIZE, TEXT_COLOR)
	_line_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_box.add_child(_line_label)
	_card_label = _make_label(Vector2(60, 120), Vector2(SCREEN.x - 120, 120), CARD_SIZE, TEXT_COLOR)
	_card_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_card_label)
	_hint_label = _make_label(Vector2(SCREEN.x - 216, BOX.position.y - 16), Vector2(200, 12), HINT_SIZE, HINT_COLOR)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint_label.text = KeyBindings.with_key("interact", SKIP_TEXT)
	add_child(_hint_label)
	_hold_bar = ColorRect.new()
	_hold_bar.color = NAME_COLOR
	_hold_bar.position = Vector2(SCREEN.x - 216, BOX.position.y - 3)
	_hold_bar.size = Vector2(0, 2)
	_hold_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hold_bar)
	_rng.randomize()
	_refresh_view()


func _make_label(at: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = at
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func is_done() -> bool:
	return _done


func can_skip() -> bool:
	return not _first_time or _boxes_done >= 1


func current_text() -> String:
	return _text


func current_speaker() -> String:
	return _speaker


func step_index() -> int:
	return _index


func stage_name() -> String:
	return _stage.stage_name if _stage != null else ""


func fade_alpha() -> float:
	return _fade


func skip_progress() -> float:
	return clampf(_hold / SKIP_HOLD, 0.0, 1.0)


func actor(id: String) -> CutsceneActor:
	var found: Variant = _actors.get(id)
	return found if is_instance_valid(found) else null


func _input(event: InputEvent) -> void:
	if _done:
		return
	if (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventMouseButton and event.pressed):
		_key_pressed = true
		get_viewport().set_input_as_handled()


# Polled, not read from input events alone, since the full loop presses keys with Input.action_press.
func _process(delta: float) -> void:
	var pressed := _key_pressed
	for action in ["attack", "interact", "dodge", "ui_accept"]:
		if InputMap.has_action(action) and Input.is_action_just_pressed(action):
			pressed = true
	_key_pressed = false
	var held := InputMap.has_action("interact") and Input.is_action_pressed("interact")
	advance(delta, pressed, held)


func advance(delta: float, pressed: bool, held: bool) -> void:
	if _done:
		return
	if held and can_skip():
		_hold += delta
		if _hold >= SKIP_HOLD - 0.0001:
			_finish()
			return
	else:
		_hold = 0.0
	if _index == -1:
		_next(0.0)
	_tick_background(delta)
	_step_time += delta
	if pressed and (_is_text_step()) and _step_time >= MIN_SHOW_TIME:
		_step_time = maxf(_step_time, _step_length)
	var guard := 0
	while not _done and _step_complete() and guard < 1000:
		guard += 1
		_next(maxf(_step_time - _step_length, 0.0) if _is_timed_step() else 0.0)
	_refresh_view()


func _current() -> Dictionary:
	return _steps[_index] if _index >= 0 and _index < _steps.size() else {}


func _is_text_step() -> bool:
	var op: String = _current().get("op", "")
	return op == "say" or op == "card"


func _is_timed_step() -> bool:
	var op: String = _current().get("op", "")
	return op in ["say", "card", "wait", "fade_out", "fade_in"]


func _step_complete() -> bool:
	var step := _current()
	match step.get("op", ""):
		"say", "card", "wait", "fade_out", "fade_in":
			return _step_time >= _step_length - 0.0001
		"walk":
			var walker := actor(step["id"])
			return not step["wait"] or walker == null or not walker.is_walking()
		"anim":
			var player := actor(step["id"])
			return not step["wait"] or player == null or not player.is_animating()
	return true


# Ends the step showing and starts the next, carrying over the time the last one ran past its end.
func _next(carry: float) -> void:
	if _is_text_step():
		_boxes_done += 1
		_text = ""
		_speaker = ""
		_is_card = false
	_index += 1
	_step_time = carry
	_step_length = 0.0
	if _index >= _steps.size():
		_finish()
		return
	_start(_current())


func _start(step: Dictionary) -> void:
	match step["op"]:
		"stage":
			_stage.set_stage(step["name"])
		"actor":
			var placed := actor(step["id"])
			if placed == null:
				placed = CutsceneActor.new()
				placed.setup(step["id"])
				_world.add_child(placed)
				_actors[step["id"]] = placed
			placed.place(step["at"], int(step.get("facing", 1)))
		"walk":
			var walker := actor(step["id"])
			if walker != null:
				walker.walk_to(step["to"], float(step["speed"]))
		"face":
			var turner := actor(step["id"])
			if turner != null:
				turner.face(int(step["dir"]))
		"anim":
			var player := actor(step["id"])
			if player != null:
				player.play_anim(step["name"])
		"say":
			_text = step["text"]
			_speaker = ActorLook.display_name(step["id"])
			_step_length = CutsceneSteps.say_time(_text)
		"card":
			_text = step["text"]
			_is_card = true
			_set_fade(1.0)
			_step_length = CutsceneSteps.card_time(_text)
		"wait":
			_step_length = float(step["seconds"])
		"fade_out", "fade_in":
			_step_length = float(step["seconds"])
			_fade_from = _fade
			_fade_to = 1.0 if step["op"] == "fade_out" else 0.0
			_fade_time = 0.0
			_fade_length = _step_length
			if _fade_length <= 0.0:
				_set_fade(_fade_to)
		"shake":
			_shake_amount = float(step["amount"])
			_shake_left = float(step["seconds"])
			_shake_length = _shake_left
		"zoom":
			_zoom_from = _zoom
			_zoom_at_from = _zoom_at
			_zoom_to = float(step["factor"])
			_zoom_at_to = step["at"]
			_zoom_time = 0.0
			_zoom_length = float(step["seconds"])
			if _zoom_length <= 0.0:
				_zoom = _zoom_to
				_zoom_at = _zoom_at_to
		"hide":
			var leaving := actor(step["id"])
			if leaving != null:
				if leaving.is_inside_tree():
					leaving.queue_free()
				else:
					leaving.free()
			_actors.erase(step["id"])
		"tint":
			var tinted := actor(step["id"])
			if tinted != null:
				tinted.set_tint(step["color"])
		"hat":
			var hatted := actor(step["id"])
			if hatted != null:
				hatted.set_hat(step["shape"], step["color"])


func _set_fade(alpha: float) -> void:
	_fade = alpha
	_fade_from = alpha
	_fade_to = alpha
	_fade_length = 0.0


func _tick_background(delta: float) -> void:
	for each: CutsceneActor in _actors.values():
		if is_instance_valid(each):
			each.tick(delta)
	if _fade_length > 0.0:
		_fade_time = minf(_fade_time + delta, _fade_length)
		_fade = lerpf(_fade_from, _fade_to, _fade_time / _fade_length)
		if _fade_time >= _fade_length:
			_fade_length = 0.0
	if _zoom_length > 0.0:
		_zoom_time = minf(_zoom_time + delta, _zoom_length)
		var t := smoothstep(0.0, 1.0, _zoom_time / _zoom_length)
		_zoom = lerpf(_zoom_from, _zoom_to, t)
		_zoom_at = _zoom_at_from.lerp(_zoom_at_to, t)
		if _zoom_time >= _zoom_length:
			_zoom_length = 0.0
	if _shake_left > 0.0:
		_shake_left = maxf(_shake_left - delta, 0.0)


func _finish() -> void:
	if _done:
		return
	_done = true
	_text = ""
	_speaker = ""
	_is_card = false
	_set_fade(1.0)
	_refresh_view()
	finished.emit()


func _refresh_view() -> void:
	if not _built:
		return
	var world_scale := CutsceneSteps.SCALE * _zoom
	var shake := Vector2.ZERO
	if _shake_left > 0.0 and _shake_length > 0.0:
		var strength := _shake_amount * _shake_left / _shake_length
		shake = Vector2(_rng.randf_range(-strength, strength), _rng.randf_range(-strength, strength))
	_world.scale = Vector2(world_scale, world_scale)
	_world.position = (SCREEN / 2.0 - _zoom_at * world_scale + shake).round()
	_fade_rect.color = Color(0, 0, 0, _fade)
	var saying := not _text.is_empty() and not _is_card
	_box.visible = saying
	_name_label.text = _speaker
	_line_label.text = _text if saying else ""
	_card_label.visible = _is_card
	_card_label.text = _text if _is_card else ""
	_hint_label.visible = can_skip() and not _done
	_hold_bar.size = Vector2(200.0 * skip_progress(), 2)
