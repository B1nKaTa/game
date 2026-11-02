class_name EnemyMarks
extends Node2D

# Signs drawn over an enemy's body, so its type and its shield read without any art.
const SHIELD_COLOR := Color("dfe9f5")
const SHIELD_FLASH := Color("ffd24a")
const SHIELD_FLASH_TIME := 0.15
const SHIELD_GAP := 5.0
const SHIELD_WIDTH := 4.0
const STAMP_COLOR := Color("f3eaff")
const FUSE_COLOR := Color("1c1208")
const SPARK_COLOR := Color("ffe58a")
const TEETH_COLOR := Color("20240f")
const DIRT_COLOR := Color("4a3a24")
const SPADE_HANDLE := Color("6b4a2a")
const SPADE_BLADE := Color("c9cdd6")
const HAT_COLOR := Color("15131a")
const HAT_BAND := Color("7a2f3a")

var _def: EnemyDef
var _facing := Vector2.RIGHT
var _flash_left := 0.0


func setup(def: EnemyDef) -> void:
	_def = def


func show_facing(facing: Vector2) -> void:
	if _def.shield_half_angle > 0.0 and not facing.is_equal_approx(_facing):
		_facing = facing
		queue_redraw()


func flash_shield() -> void:
	_flash_left = SHIELD_FLASH_TIME
	queue_redraw()


func _process(delta: float) -> void:
	if _flash_left > 0.0:
		_flash_left -= delta
		queue_redraw()


func _draw() -> void:
	if _def == null:
		return
	var half := _def.body_size / 2.0
	match _def.mark:
		"stamp":
			draw_rect(Rect2(-half.x + 3.0, -half.y + 3.0, half.x * 2.0 - 6.0, 7.0), STAMP_COLOR)
			draw_rect(Rect2(-2.0, -half.y + 10.0, 4.0, 5.0), STAMP_COLOR)
		"fuse":
			draw_line(Vector2(0.0, -half.y), Vector2(5.0, -half.y - 6.0), FUSE_COLOR, 2.0)
			draw_circle(Vector2(5.0, -half.y - 7.0), 2.5, SPARK_COLOR)
		"teeth":
			for x in [-3.0, 1.0]:
				draw_rect(Rect2(x, -1.0, 2.0, 3.0), TEETH_COLOR)
		"dirt":
			for x in [-half.x + 2.0, -2.0, half.x - 5.0]:
				draw_rect(Rect2(x, half.y - 6.0, 4.0, 6.0), DIRT_COLOR)
		"spade":
			draw_line(Vector2(half.x + 3.0, -half.y), Vector2(half.x + 3.0, half.y - 8.0), SPADE_HANDLE, 2.0)
			draw_rect(Rect2(half.x, half.y - 9.0, 7.0, 9.0), SPADE_BLADE)
		"top_hat":
			draw_rect(Rect2(-half.x * 0.6, -half.y - 10.0, half.x * 1.2, 12.0), HAT_COLOR)
			draw_rect(Rect2(-half.x * 0.85, -half.y + 1.0, half.x * 1.7, 3.0), HAT_COLOR)
			draw_rect(Rect2(-half.x * 0.6, -half.y - 2.0, half.x * 1.2, 2.0), HAT_BAND)
	if _def.shield_half_angle > 0.0:
		var reach := maxf(half.x, half.y) + SHIELD_GAP
		var half_arc := deg_to_rad(_def.shield_half_angle)
		var color := SHIELD_FLASH if _flash_left > 0.0 else SHIELD_COLOR
		draw_arc(Vector2.ZERO, reach, _facing.angle() - half_arc, _facing.angle() + half_arc, 16, Color.BLACK, SHIELD_WIDTH + 2.0)
		draw_arc(Vector2.ZERO, reach, _facing.angle() - half_arc, _facing.angle() + half_arc, 16, color, SHIELD_WIDTH)
