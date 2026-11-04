class_name Pickup
extends Node2D

signal collected

const COLLECT_RADIUS := 18.0
const MAGNET_RADIUS := 64.0
const ARRIVE_RADIUS := 6.0
const FLY_START_SPEED := 120.0
const FLY_ACCELERATION := 700.0
const FLY_MAX_SPEED := 420.0
const PROMPT_TEXT := "Take"

var requires_interact := false
var can_take := Callable()
var flies := false
var prompt := PROMPT_TEXT
var _label := ""
var _color := Color.WHITE
var _player: Node2D
var _done := false
var _paid := false
var _flying := false
var _fly_time := 0.0
var _prompt_shown := false
# The button the prompt was drawn with, so it is drawn again when the device changes.
var _prompt_label := ""


static func should_collect(needs_interact: bool, in_range: bool, interact_pressed: bool) -> bool:
	return in_range and (interact_pressed or not needs_interact)


static func should_magnet(can_fly: bool, distance: float) -> bool:
	return can_fly and distance <= MAGNET_RADIUS


static func fly_speed(time: float) -> float:
	return minf(FLY_START_SPEED + FLY_ACCELERATION * time, FLY_MAX_SPEED)


static func fly_step(from: Vector2, to: Vector2, speed: float, delta: float) -> Vector2:
	var offset := to - from
	var step := speed * delta
	if offset.length() <= step:
		return to
	return from + offset.normalized() * step


func setup(label: String, color: Color, player: Node2D, needs_interact := false) -> void:
	_label = label
	_color = color
	_player = player
	requires_interact = needs_interact


func set_label(label: String, color: Color) -> void:
	_label = label
	_color = color
	queue_redraw()


func _ready() -> void:
	add_to_group("pickups")
	queue_redraw()


func is_flying() -> bool:
	return _flying


func _process(delta: float) -> void:
	if _done or not is_instance_valid(_player):
		return
	if _flying:
		_fly_toward_player(delta)
		return
	var distance := global_position.distance_to(_player.global_position)
	if should_magnet(flies, distance):
		fly()
		return
	var in_range := distance <= COLLECT_RADIUS
	if can_take.is_valid() and not can_take.call():
		in_range = false
	var show_prompt := requires_interact and in_range
	if show_prompt != _prompt_shown or (show_prompt and KeyBindings.prompt_label("interact") != _prompt_label):
		_prompt_shown = show_prompt
		_prompt_label = KeyBindings.prompt_label("interact")
		queue_redraw()
	if should_collect(requires_interact, in_range, Input.is_action_just_pressed("interact")):
		collect()


func _fly_toward_player(delta: float) -> void:
	_fly_time += delta
	global_position = fly_step(global_position, _player.global_position, fly_speed(_fly_time), delta)
	if global_position.distance_to(_player.global_position) <= ARRIVE_RADIUS:
		collect()


# The reward is paid when the coin starts flying, so leaving the room, dying or
# ending the run mid-flight can never lose it. The flight is only for show.
func fly() -> void:
	if _done or _flying or is_queued_for_deletion():
		return
	_flying = true
	queue_redraw()
	_pay()


func collect() -> void:
	if _done or is_queued_for_deletion():
		return
	_done = true
	_pay()
	queue_free()


func _pay() -> void:
	if _paid:
		return
	_paid = true
	collected.emit()


func _draw() -> void:
	_draw_body()
	if _flying:
		return
	# Centred and outlined, as people's names are, so they read on the palest floors and long names
	# never run into the next ware.
	Npc._draw_centered(self, _label, Vector2(0, -12), Color.WHITE)
	if _prompt_shown:
		Npc._draw_centered(self, KeyBindings.with_key("interact", prompt), Vector2(0, 22), Color("ffd24a"))


# A plain coloured disc. Pickups with a shape of their own, such as chests, draw that instead.
func _draw_body() -> void:
	draw_circle(Vector2.ZERO, 8.0, _color)
	draw_arc(Vector2.ZERO, 8.0, 0.0, TAU, 16, Color.BLACK, 1.0)
