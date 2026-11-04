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
				# Brick walls: three more courses, each row of bricks set half a brick along.
				if _palette.wall_pattern == 1:
					for course in 4:
						var top := tile.position.y + course * TILE / 4.0
						draw_line(Vector2(tile.position.x, top), Vector2(tile.end.x, top), _palette.brick_line, 1.0)
						var joint := tile.position.x + (TILE / 4.0 if course % 2 == 0 else TILE * 0.75)
						draw_line(Vector2(joint, top), Vector2(joint, top + TILE / 4.0), _palette.brick_line, 1.0)
				# Wood panelling: upright boards, with a rail across the panels.
				if _palette.wall_pattern == 2:
					for board in 4:
						var left := tile.position.x + board * TILE / 4.0
						draw_line(Vector2(left, tile.position.y), Vector2(left, tile.end.y), _palette.brick_line, 1.0)
					draw_rect(Rect2(tile.position + Vector2(0, TILE * 0.3), Vector2(TILE, 3)), _palette.wall_line)
				# Closed shop shutters: thin slats across, with a bar and a lock at the foot.
				if _palette.wall_pattern == 3:
					for slat in 6:
						var top := tile.position.y + 3.0 + slat * 4.0
						draw_line(Vector2(tile.position.x, top), Vector2(tile.end.x, top), _palette.brick_line, 1.0)
					draw_rect(Rect2(tile.position + Vector2(0, TILE - 5), Vector2(TILE, 3)), _palette.wall_line)
					if posmod(x, 3) == 1:
						draw_rect(Rect2(tile.position + Vector2(TILE / 2.0 - 2, TILE - 6), Vector2(4, 4)), _palette.carpet_motif)
				# Fairway's End: clipped hedges.
				if _palette.wall_pattern == GolfLook.HEDGE_WALL:
					GolfLook.draw_wall_tile(self, tile, Vector2i(x, y), _palette)
				continue
			draw_rect(tile, _palette.floor_color(Vector2i(x, y), _seed))
			# A patterned floor lays carpet on its middle tone, woven and seamless, and tiles the rest.
			if _palette.floor_pattern == 1 and _palette.patch_of(Vector2i(x, y), _seed) == 1:
				var mid := tile.get_center()
				draw_colored_polygon(PackedVector2Array([mid + Vector2(0, -6), mid + Vector2(6, 0), mid + Vector2(0, 6), mid + Vector2(-6, 0)]), _palette.carpet_motif)
				draw_rect(Rect2(tile.position + Vector2(1, 1), Vector2(2, 2)), _palette.carpet_motif)
				continue
			# Iron tread plate: short raised ridges in a herringbone, with a bolt in each corner. It must
			# never look like a vent, so it has no dark slots.
			if _palette.floor_pattern == 2 and _palette.patch_of(Vector2i(x, y), _seed) == 1:
				for row in 3:
					for column in 3:
						var at := tile.position + Vector2(6 + column * 9, 6 + row * 9)
						var lean := 3.0 if (row + column) % 2 == 0 else -3.0
						draw_line(at + Vector2(-lean, -2), at + Vector2(lean, 2), _palette.carpet_motif, 2.0)
				for corner in [Vector2(2, 2), Vector2(TILE - 4, 2), Vector2(2, TILE - 4), Vector2(TILE - 4, TILE - 4)]:
					draw_rect(Rect2(tile.position + corner, Vector2(2, 2)), _palette.speckle)
				draw_rect(tile, _palette.grout, false, 1.0)
				continue
			# Polished mall tile: each tile's own grout line and a square of reflected light in a corner.
			# No streaks, so it never reads as a wet floor, and no arrows or dark bands, as a strip has.
			if _palette.floor_pattern == 3:
				draw_rect(tile, _palette.grout, false, 1.0)
				draw_rect(Rect2(tile.position + Vector2(3, 3), Vector2(9, 9)), _palette.carpet_motif)
				draw_rect(Rect2(tile.position + Vector2(3, 3), Vector2(4, 4)), _palette.speckle)
				continue
			# Fairway's End: mown stripes and nothing else, since dots are the sand's look.
			if _palette.floor_pattern == GolfLook.FAIRWAY:
				GolfLook.draw_floor_tile(self, tile, Vector2i(x, y), _palette)
				continue
			draw_line(tile.position, tile.position + Vector2(TILE, 0), _palette.grout, 1.0)
			draw_line(tile.position, tile.position + Vector2(0, TILE), _palette.grout, 1.0)
			if RoomDecor.noise(Vector2i(x, y), _seed + 7) < 0.25:
				var spot := tile.position + Vector2(RoomDecor.noise(Vector2i(y, x), _seed + 3), RoomDecor.noise(Vector2i(x, y), _seed + 5)) * (TILE - 4.0)
				draw_rect(Rect2(spot, Vector2(3, 2)), _palette.speckle)
