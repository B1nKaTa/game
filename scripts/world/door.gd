class_name Door
extends Node2D

signal entered(target_id: int)

const ENTER_RADIUS := 18.0

var locked := true
var _target_id := -1
var _icon := "?"
var _player: Node2D
var _used := false


func setup(target_id: int, icon: String, player: Node2D) -> void:
	_target_id = target_id
	_icon = icon
	_player = player


func _process(_delta: float) -> void:
	queue_redraw()
	if locked or _used or not is_instance_valid(_player):
		return
	if global_position.distance_to(_player.global_position) <= ENTER_RADIUS:
		_used = true
		entered.emit(_target_id)


func _draw() -> void:
	var color := Color("7a3b3b") if locked else Color("c98a3c")
	draw_rect(Rect2(-14, -14, 28, 28), color)
	draw_rect(Rect2(-14, -14, 28, 28), Color.BLACK, false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(-5, 6), _icon, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
