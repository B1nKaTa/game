class_name RoomBackdrop
extends Node2D

const TILE := 32

const VIEW_SIZE := Vector2(640, 360)
const OVERDRAW_MARGIN := 16.0

var _rows: PackedStringArray = []
var _palette: RoomPalette
var _seed := 0


# Reaches past the view and the room by more than the biggest screen shake, so
# shaking never shows the clear color, whatever the room's size.
static func overdraw_rect(room_size: Vector2) -> Rect2:
	var cover := Vector2(maxf(room_size.x, VIEW_SIZE.x), maxf(room_size.y, VIEW_SIZE.y))
	return Rect2((room_size - cover) / 2.0, cover).grow(OVERDRAW_MARGIN)


# A band of wall around the room, so a shake at the room's edge shows wall and
# not darkness. Past it, a room smaller than the view sits in darkness.
static func wall_rim_rect(room_size: Vector2) -> Rect2:
	return Rect2(Vector2.ZERO, room_size).grow(OVERDRAW_MARGIN)


static func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, cell.y * TILE + TILE / 2.0)


func setup(rows: PackedStringArray, palette: RoomPalette = null, seed_value := 0) -> void:
	_rows = rows
	_palette = palette if palette != null else RoomPalette.new()
	_seed = seed_value
	z_index = -10


func _ready() -> void:
	for y in _rows.size():
		for x in _rows[y].length():
			if RoomLayout.WALL_LIKE.contains(_rows[y][x]):
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
	var room_size := Vector2(_rows[0].length(), _rows.size()) * TILE
	draw_rect(overdraw_rect(room_size), _palette.darkness)
	draw_rect(wall_rim_rect(room_size), _palette.wall)
	for y in _rows.size():
		for x in _rows[y].length():
			var tile := Rect2(x * TILE, y * TILE, TILE, TILE)
			if RoomLayout.WALL_LIKE.contains(_rows[y][x]):
				draw_rect(tile, _palette.wall)
				draw_line(tile.position + Vector2(0, TILE / 2.0), tile.position + Vector2(TILE, TILE / 2.0), _palette.wall_line, 1.0)
				continue
			draw_rect(tile, _palette.floor_color(Vector2i(x, y), _seed))
			draw_line(tile.position, tile.position + Vector2(TILE, 0), _palette.grout, 1.0)
			draw_line(tile.position, tile.position + Vector2(0, TILE), _palette.grout, 1.0)
			if RoomDecor.noise(Vector2i(x, y), _seed + 7) < 0.25:
				var spot := tile.position + Vector2(RoomDecor.noise(Vector2i(y, x), _seed + 3), RoomDecor.noise(Vector2i(x, y), _seed + 5)) * (TILE - 4.0)
				draw_rect(Rect2(spot, Vector2(3, 2)), _palette.speckle)
