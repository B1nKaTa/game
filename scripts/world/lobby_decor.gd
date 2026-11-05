class_name LobbyDecor
extends Node2D

# The lobby's decor, bought at the Decor Office with Condolences. Each piece has one fixed spot, with
# no free placing. Pieces on the top wall hang on the line between the wall and the first floor row,
# as the trophy frames do. Placeholder shapes, drawn in code until the art pass.

# Decor id -> the lobby cells it stands on. The cells keep clear of every station, every door cell and
# the run door. The second lamp hangs at column 26 and the fish tank stands at (27, 2), since the
# trophy frames span columns 18 to 23 and the run door stands at (26, 8).
const SPOTS := {
	"potted_fern": [Vector2i(2, 2)],
	"motivational_poster": [Vector2i(9, 1)],
	"better_chair": [Vector2i(3, 8)],
	"warm_lamps": [Vector2i(8, 1), Vector2i(26, 1)],
	"fish_tank": [Vector2i(27, 2)],
}
# Hung on the top wall rather than standing on the floor.
const WALL_FACE := ["motivational_poster", "warm_lamps"]
const WALL_FACE_Y := 34.0
# The carpet is a rug under everything else in the middle of the lobby.
const CARPET := "new_carpet"
const CARPET_CENTER := Vector2i(15, 6)
const CARPET_CELLS := Vector2(10, 5)
const LAMP_LIGHT := Color("ffc070")
const LAMP_ENERGY := 0.6
const LAMP_SCALE := 1.0
const OUTLINE := Color(0.08, 0.06, 0.05)
const POT := Color("8a5a3a")
const FISH := Color("f08a3c")

var _owned := {}
var _defs: Array[CosmeticDef] = []
var _lights: Array[PointLight2D] = []
var _carpet: CarpetLayer


class CarpetLayer extends Node2D:
	var color := Color.WHITE

	func _draw() -> void:
		LobbyDecor.draw_kind(self, "carpet", LobbyDecor.carpet_rect().get_center(), color)


static func cells_of(id: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell in SPOTS.get(id, []):
		cells.append(cell)
	return cells


# Where a piece is drawn: the middle of its cell, or on the wall line for a piece that hangs.
static func spot_position(id: String, cell: Vector2i) -> Vector2:
	var at := RoomBackdrop.cell_center(cell)
	if WALL_FACE.has(id):
		at.y = WALL_FACE_Y
	return at


static func carpet_rect() -> Rect2:
	var size := CARPET_CELLS * RoomBackdrop.TILE
	return Rect2(RoomBackdrop.cell_center(CARPET_CENTER) - size / 2.0, size)


# Owned is cosmetics_owned. Call again whenever it may have changed, and the lobby redraws.
func setup(owned: Dictionary) -> void:
	_owned = owned.duplicate()
	_defs.clear()
	for def in CosmeticDef.all():
		if def.slot == CosmeticDef.SLOT_DECOR and _owned.has(def.id):
			_defs.append(def)
	for light in _lights:
		if is_instance_valid(light):
			light.queue_free()
	_lights.clear()
	if _owned.has("warm_lamps"):
		for cell in cells_of("warm_lamps"):
			var light := Lighting.make_light(LAMP_LIGHT, LAMP_ENERGY, LAMP_SCALE)
			light.position = RoomBackdrop.cell_center(cell)
			add_child(light)
			_lights.append(light)
	if _carpet == null:
		_carpet = CarpetLayer.new()
		_carpet.z_index = -1
		add_child(_carpet)
	var carpet := CosmeticDef.find(CARPET, _defs)
	_carpet.visible = carpet != null
	if carpet != null:
		_carpet.color = carpet.color
	_carpet.queue_redraw()
	queue_redraw()


func has_decor(id: String) -> bool:
	return CosmeticDef.find(id, _defs) != null


func _draw() -> void:
	for def in _defs:
		for cell in cells_of(def.id):
			draw_kind(self, def.shape, spot_position(def.id, cell), def.color)


# Draws one kind of decor centred on at, in its colour. A picture at res://art/props/lobby_<kind>.png
# replaces the placeholder, in its own colours (each kind is one piece of decor).
static func draw_kind(canvas: CanvasItem, kind: String, at: Vector2, color := Color.WHITE) -> void:
	var art := PropArt.texture("lobby_" + kind)
	if art != null:
		PropArt.draw(canvas, art, at)
		return
	match kind:
		"fern":
			var pot := PackedVector2Array([at + Vector2(-7, 2), at + Vector2(7, 2), at + Vector2(5, 13), at + Vector2(-5, 13)])
			canvas.draw_colored_polygon(pot, POT)
			var rim := pot.duplicate()
			rim.append(pot[0])
			canvas.draw_polyline(rim, OUTLINE, 1.0)
			for i in 7:
				var angle := PI + PI * (i + 0.5) / 7.0
				var tip := at + Vector2(0, 1) + Vector2.from_angle(angle) * (12.0 if i % 2 == 0 else 9.0)
				canvas.draw_line(at + Vector2(0, 2), tip, color.darkened(0.25), 3.0)
				canvas.draw_line(at + Vector2(0, 2), tip, color, 1.5)
		"poster":
			var sheet := Rect2(at - Vector2(9, 11), Vector2(18, 22))
			canvas.draw_rect(sheet, color)
			canvas.draw_rect(sheet, OUTLINE, false, 1.0)
			# A cat hanging from a branch, in three strokes.
			canvas.draw_line(sheet.position + Vector2(3, 6), sheet.position + Vector2(15, 6), Color("5a3a28"), 1.5)
			canvas.draw_line(at + Vector2(0, -5), at + Vector2(0, 0), Color("6a6a6a"), 1.5)
			canvas.draw_circle(at + Vector2(0, 2), 3.0, Color("6a6a6a"))
			canvas.draw_line(sheet.position + Vector2(3, 18), sheet.position + Vector2(15, 18), OUTLINE, 1.0)
		"chair":
			canvas.draw_rect(Rect2(at + Vector2(-8, -12), Vector2(16, 12)), color.darkened(0.15))
			canvas.draw_rect(Rect2(at + Vector2(-9, -1), Vector2(18, 6)), color)
			canvas.draw_rect(Rect2(at + Vector2(-8, -12), Vector2(16, 12)), OUTLINE, false, 1.0)
			canvas.draw_rect(Rect2(at + Vector2(-9, -1), Vector2(18, 6)), OUTLINE, false, 1.0)
			canvas.draw_line(at + Vector2(-7, 5), at + Vector2(-7, 12), OUTLINE, 2.0)
			canvas.draw_line(at + Vector2(7, 5), at + Vector2(7, 12), OUTLINE, 2.0)
		"lamps":
			canvas.draw_rect(Rect2(at + Vector2(-1, -10), Vector2(2, 6)), OUTLINE)
			var shade := PackedVector2Array([at + Vector2(-3, -5), at + Vector2(3, -5), at + Vector2(6, 2), at + Vector2(-6, 2)])
			canvas.draw_colored_polygon(shade, color.darkened(0.2))
			canvas.draw_circle(at + Vector2(0, 4), 3.0, color.lightened(0.4))
			canvas.draw_circle(at + Vector2(0, 4), 8.0, Color(color, 0.25))
		"tank":
			canvas.draw_rect(Rect2(at + Vector2(-13, 6), Vector2(26, 7)), Color("3a2a1e"))
			var glass := Rect2(at + Vector2(-14, -12), Vector2(28, 18))
			canvas.draw_rect(glass, Color(color, 0.85))
			canvas.draw_line(glass.position + Vector2(0, 3), glass.position + Vector2(glass.size.x, 3), color.lightened(0.4), 1.0)
			for fish: Vector2 in [Vector2(-5, -3), Vector2(5, 1)]:
				canvas.draw_circle(at + fish, 2.5, FISH)
				canvas.draw_colored_polygon(PackedVector2Array([at + fish + Vector2(2, 0), at + fish + Vector2(5, -2), at + fish + Vector2(5, 2)]), FISH)
			canvas.draw_circle(at + Vector2(9, -6), 1.0, Color.WHITE)
			canvas.draw_circle(at + Vector2(10, -9), 0.8, Color.WHITE)
			canvas.draw_rect(glass, OUTLINE, false, 1.0)
		"carpet":
			var rug := Rect2(at - CARPET_CELLS * RoomBackdrop.TILE / 2.0, CARPET_CELLS * RoomBackdrop.TILE)
			canvas.draw_rect(rug, color)
			canvas.draw_rect(rug.grow(-6.0), color.lightened(0.25), false, 2.0)
			canvas.draw_rect(rug.grow(-12.0), color.darkened(0.2), false, 1.0)
			canvas.draw_rect(rug, OUTLINE, false, 1.0)
