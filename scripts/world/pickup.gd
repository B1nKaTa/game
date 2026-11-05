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
# Bone white, so the skull stands out from the cursed name's purple on any floor.
const SKULL_COLOR := Color("ece9e0")

var requires_interact := false
# How near his feet must come to take it. A heal under the Pill Crusher wants him nearer.
var collect_radius := COLLECT_RADIUS
var can_take := Callable()
var flies := false
var prompt := PROMPT_TEXT
# What the name is drawn in, and whether a skull sits before it, as a cursed item's does.
var label_color := Color.WHITE
var skull := false
var _label := ""
var _color := Color.WHITE
var _player: Node2D
var _done := false
var _paid := false
var _flying := false
var _fly_time := 0.0
var _prompt_shown := false


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


# New words only, keeping the colours.
func set_text(label: String) -> void:
	_label = label
	queue_redraw()


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
	var in_range := distance <= collect_radius
	if can_take.is_valid() and not can_take.call():
		in_range = false
	var show_prompt := requires_interact and in_range
	if show_prompt != _prompt_shown:
		_prompt_shown = show_prompt
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
	Npc._draw_centered(self, _label, Vector2(0, -12), label_color)
	if skull:
		var width := ThemeDB.fallback_font.get_string_size(_label, HORIZONTAL_ALIGNMENT_LEFT, -1, Npc.FONT_SIZE).x
		draw_skull(self, Vector2(-width / 2.0 - 8.0, -16.0), SKULL_COLOR)
	if _prompt_shown:
		Npc._draw_centered(self, KeyBindings.with_key("interact", prompt), Vector2(0, 22), Color("ffd24a"))


# A small skull, drawn in code: a round head, a jaw, two dark eyes. It marks a cursed item's name.
static func draw_skull(canvas: CanvasItem, at: Vector2, color: Color) -> void:
	canvas.draw_rect(Rect2(at + Vector2(-3.5, 2.0), Vector2(7, 4)), Color.BLACK)
	canvas.draw_circle(at, 5.5, Color.BLACK)
	canvas.draw_circle(at, 4.5, color)
	canvas.draw_rect(Rect2(at + Vector2(-2.5, 2.5), Vector2(5, 2.5)), color)
	canvas.draw_circle(at + Vector2(-1.8, -0.2), 1.3, Color.BLACK)
	canvas.draw_circle(at + Vector2(1.8, -0.2), 1.3, Color.BLACK)
	canvas.draw_line(at + Vector2(-1.0, 3.0), at + Vector2(-1.0, 5.0), Color.BLACK, 1.0)
	canvas.draw_line(at + Vector2(1.0, 3.0), at + Vector2(1.0, 5.0), Color.BLACK, 1.0)



# A plain coloured disc. Pickups with a shape of their own, such as chests, draw that instead.

func _draw_body() -> void:
	draw_circle(Vector2.ZERO, 8.0, _color)
	draw_arc(Vector2.ZERO, 8.0, 0.0, TAU, 16, Color.BLACK, 1.0)
