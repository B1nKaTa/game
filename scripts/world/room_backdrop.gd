class_name RoomBackdrop
extends Node2D

const TILE := 32
const FLOOR_A := Color("6a6677")
const FLOOR_B := Color("625e6f")
const WALL := Color("3a3547")

var _rows: PackedStringArray = []


static func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, cell.y * TILE + TILE / 2.0)


func setup(rows: PackedStringArray) -> void:
	_rows = rows
	z_index = -10


func _ready() -> void:
	for y in _rows.size():
		for x in _rows[y].length():
			if _rows[y][x] == "#":
				_add_wall(Vector2i(x, y))
	queue_redraw()


func _add_wall(cell: Vector2i) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = cell_center(cell)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(TILE, TILE)
	shape.shape = rect
	body.add_child(shape)
	add_child(body)


func _draw() -> void:
	for y in _rows.size():
		for x in _rows[y].length():
			var color := WALL if _rows[y][x] == "#" else (FLOOR_A if (x + y) % 2 == 0 else FLOOR_B)
			draw_rect(Rect2(x * TILE, y * TILE, TILE, TILE), color)
