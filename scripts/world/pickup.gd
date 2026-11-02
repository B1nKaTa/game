class_name Pickup
extends Node2D

signal collected

const COLLECT_RADIUS := 18.0

var _label := ""
var _color := Color.WHITE
var _player: Node2D
var _done := false


func setup(label: String, color: Color, player: Node2D) -> void:
	_label = label
	_color = color
	_player = player


func _ready() -> void:
	add_to_group("pickups")
	queue_redraw()


func _process(_delta: float) -> void:
	if _done or not is_instance_valid(_player):
		return
	if global_position.distance_to(_player.global_position) <= COLLECT_RADIUS:
		collect()


func collect() -> void:
	if _done:
		return
	_done = true
	collected.emit()
	queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 8.0, _color)
	draw_arc(Vector2.ZERO, 8.0, 0.0, TAU, 16, Color.BLACK, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(-18, -12), _label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
