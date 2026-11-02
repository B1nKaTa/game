class_name Pickup
extends Node2D

signal collected

const COLLECT_RADIUS := 18.0
const PROMPT_TEXT := "E: Take"

var requires_interact := false
var can_take := Callable()
var _label := ""
var _color := Color.WHITE
var _player: Node2D
var _done := false
var _prompt_shown := false


static func should_collect(needs_interact: bool, in_range: bool, interact_pressed: bool) -> bool:
	return in_range and (interact_pressed or not needs_interact)


func setup(label: String, color: Color, player: Node2D, needs_interact := false) -> void:
	_label = label
	_color = color
	_player = player
	requires_interact = needs_interact


func _ready() -> void:
	add_to_group("pickups")
	queue_redraw()


func _process(_delta: float) -> void:
	if _done or not is_instance_valid(_player):
		return
	var in_range := global_position.distance_to(_player.global_position) <= COLLECT_RADIUS
	if can_take.is_valid() and not can_take.call():
		in_range = false
	var show_prompt := requires_interact and in_range
	if show_prompt != _prompt_shown:
		_prompt_shown = show_prompt
		queue_redraw()
	if should_collect(requires_interact, in_range, Input.is_action_just_pressed("interact")):
		collect()


func collect() -> void:
	if _done or is_queued_for_deletion():
		return
	_done = true
	collected.emit()
	queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 8.0, _color)
	draw_arc(Vector2.ZERO, 8.0, 0.0, TAU, 16, Color.BLACK, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(-18, -12), _label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
	if _prompt_shown:
		draw_string(ThemeDB.fallback_font, Vector2(-18, 22), PROMPT_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("ffd24a"))
