class_name RoomBackdrop
extends Node2D

const TILE := 32

const VIEW_SIZE := Vector2(640, 360)
const OVERDRAW_MARGIN := 16.0
# The Last Resort Cruise's floor and wall patterns, numbered well clear of the others.
const FLOOR_TEAK_DECK := 10
const WALL_SHIP_RAIL := 10
# Head Office: carpet tiles and plaster over a dado.
const FLOOR_OFFICE_CARPET := 12
const WALL_OFFICE_PLASTER := 12

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
				# The Last Resort Cruise: a ship's white rail, a top rail and a mid rail on posts.
				if _palette.wall_pattern == WALL_SHIP_RAIL:
					draw_rect(Rect2(tile.position + Vector2(0, 7), Vector2(TILE, 3)), _palette.wall_line)
					draw_rect(Rect2(tile.position + Vector2(0, 18), Vector2(TILE, 2)), _palette.wall_line)
					draw_line(tile.position + Vector2(0, 11), tile.position + Vector2(TILE, 11), _palette.brick_line, 1.0)
					if posmod(x + y, 2) == 0:
						draw_rect(Rect2(tile.position + Vector2(TILE / 2.0 - 1.5, 7), Vector2(3, 18)), _palette.wall_line)
				# Head Office walls: painted plaster over a darker dado, a chair rail between them and a
				# skirting board at the foot. Nothing upright, so it never reads as wood panelling.
				if _palette.wall_pattern == WALL_OFFICE_PLASTER:
					draw_rect(Rect2(tile.position + Vector2(0, TILE * 0.55), Vector2(TILE, TILE * 0.45)), _palette.brick_line)
					draw_rect(Rect2(tile.position + Vector2(0, TILE * 0.5), Vector2(TILE, 2)), _palette.wall_line)
					draw_rect(Rect2(tile.position + Vector2(0, TILE - 3), Vector2(TILE, 3)), _palette.wall_line)
				# The Flashback Cinema: dark panels with gold trim.
				if _palette.wall_pattern == CinemaLook.DECO_WALL:
					CinemaLook.draw_wall_tile(self, tile, Vector2i(x, y), _palette)
				# The Seance Hotline: dark teal panels under a thin teal rail, with small stars.
				if _palette.wall_pattern == SeanceLook.STAR_WALL:
					SeanceLook.draw_wall_tile(self, tile, Vector2i(x, y), _palette)
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
			# The Last Resort Cruise: teak deck planks running across, with dark caulked seams and staggered
			# butt joints. Only straight dark lines, so it never reads as a wet floor's bright streaks.
			if _palette.floor_pattern == FLOOR_TEAK_DECK:
				for plank in 4:
					var seam_y := tile.position.y + plank * TILE / 4.0
					draw_line(Vector2(tile.position.x, seam_y), Vector2(tile.end.x, seam_y), _palette.grout, 1.0)
					var joint_x := tile.position.x + posmod(x * 3 + y + plank * 2, 4) * TILE / 4.0
					if posmod(x + plank, 3) == 0:
						draw_line(Vector2(joint_x, seam_y), Vector2(joint_x, seam_y + TILE / 4.0), _palette.grout, 1.0)
					draw_line(Vector2(tile.position.x, seam_y + 1.0), Vector2(tile.end.x, seam_y + 1.0), _palette.carpet_motif, 1.0)
			# Head Office carpet tiles: a seam round each tile and a scatter of dark flecks in the pile.
			# Only dots and a square edge, never a stripe or a diagonal, so red tape always stands out.
			if _palette.floor_pattern == FLOOR_OFFICE_CARPET:
				draw_rect(tile.grow(-0.5), _palette.grout, false, 1.0)
				for fleck in 6:
					var fleck_at := Vector2(RoomDecor.noise(Vector2i(x * 7 + fleck, y), _seed + 11), RoomDecor.noise(Vector2i(x, y * 7 + fleck), _seed + 13))
					draw_rect(Rect2(tile.position + Vector2(3, 3) + fleck_at * (TILE - 8.0), Vector2(2, 2)), _palette.carpet_motif)
			# The Flashback Cinema: teal carpet with runners through the doors, and no speckles.
			if _palette.floor_pattern == CinemaLook.CARPET:
				CinemaLook.draw_floor_tile(self, tile, Vector2i(x, y), Vector2i(_rows[0].length(), _rows.size()), _palette)
				continue
			# The Seance Hotline: violet carpet with faint stars and moons, and no seams or speckles.
			if _palette.floor_pattern == SeanceLook.CARPET:
				SeanceLook.draw_floor_tile(self, tile, Vector2i(x, y), _palette)
				continue
			draw_line(tile.position, tile.position + Vector2(TILE, 0), _palette.grout, 1.0)
			draw_line(tile.position, tile.position + Vector2(0, TILE), _palette.grout, 1.0)
			if RoomDecor.noise(Vector2i(x, y), _seed + 7) < 0.25:
				var spot := tile.position + Vector2(RoomDecor.noise(Vector2i(y, x), _seed + 3), RoomDecor.noise(Vector2i(x, y), _seed + 5)) * (TILE - 4.0)
				draw_rect(Rect2(spot, Vector2(3, 2)), _palette.speckle)
