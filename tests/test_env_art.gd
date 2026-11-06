extends TestCase

# Room art (tools/art/env_art.py, TileArt, PropArt): every path's tiles are complete and flat, a missing
# set or picture falls back to the code drawing, the patch tones and wall faces pick the right tile,
# stateful props switch pictures with their state, pictures sit on whole pixels where their props stand,
# and no picture changes a prop's body.

const PATHS := ["floor_1", "cemetery", "sunset_shores", "furnace_works", "funeral_parlour", "last_resort_cruise",
	"terminal_zero", "head_office", "waiting_room", "crossroads", "flashback_cinema", "seance_hotline"]
const ROWS := ["#####", "#...#", "#...#", "#####"]


func _image(texture: Texture2D) -> Image:
	var image := texture.get_image()
	if image.is_compressed():
		image.decompress()
	return image


func _backdrop(tile_set: String) -> RoomBackdrop:
	var backdrop := RoomBackdrop.new()
	backdrop.setup(PackedStringArray(ROWS), RoomPalette.new(), 3, tile_set)
	return backdrop


func _reset_art_set() -> void:
	PropArt.art_set = ""


func test_every_path_has_a_complete_tile_set() -> void:
	for path in PATHS:
		var art := TileArt.for_set(path)
		assert_true(art != null, "%s has floor tones a, b and c and a wall" % path)
		if art == null:
			continue
		for tone in 3:
			assert_true(art.floors[tone].size() >= 2, "%s tone %d has variants" % [path, tone])
		assert_false(art.wall_faces.is_empty(), "%s has wall faces" % path)


func test_tiles_are_whole_opaque_cells() -> void:
	for path in PATHS:
		var art := TileArt.for_set(path)
		if art == null:
			continue
		var all: Array = art.walls + art.wall_faces
		for tone in art.floors:
			all += tone
		for texture: Texture2D in all:
			assert_eq(texture.get_size(), Vector2(RoomBackdrop.TILE, RoomBackdrop.TILE), texture.resource_path)
			var image := _image(texture)
			assert_eq(image.get_pixel(0, 0).a, 1.0, texture.resource_path)
			assert_eq(image.get_pixel(31, 31).a, 1.0, texture.resource_path)


# The floor tones are drawn unlit within about 10% of each other in value, so the bodies on them stay
# the strongest contrast in the room (docs/art/art-inventory.md 4.4).
func test_a_paths_floor_tones_stay_close_in_value() -> void:
	for path in PATHS:
		var art := TileArt.for_set(path)
		if art == null:
			continue
		var values: Array[float] = []
		for tone in art.floors:
			var total := 0.0
			for texture: Texture2D in tone:
				var image := _image(texture)
				var sum := 0.0
				for y in range(0, 32, 2):
					for x in range(0, 32, 2):
						sum += image.get_pixel(x, y).v
				total += sum / 256.0
			values.append(total / tone.size())
		assert_true(values.max() - values.min() <= 0.1, "%s floor tones %s" % [path, str(values)])


func test_a_missing_set_draws_the_patterns() -> void:
	assert_eq(TileArt.for_set("no_such_set"), null)
	assert_eq(TileArt.for_set(""), null)
	var backdrop := _backdrop("no_such_set")
	assert_false(backdrop.has_tile_art())
	assert_eq(backdrop.tile_texture(Vector2i(1, 1)), null)
	backdrop.free()


func test_floor_cells_keep_their_patch_tone() -> void:
	var backdrop := _backdrop("floor_1")
	assert_true(backdrop.has_tile_art())
	var palette := RoomPalette.new()
	for cell: Vector2i in [Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 2)]:
		var tone: String = TileArt.TONES[palette.patch_of(cell, 3)]
		var texture := backdrop.tile_texture(cell)
		assert_true(texture.resource_path.contains("floor_%s_" % tone), "%s takes tone %s, got %s" % [cell, tone, texture.resource_path])
	backdrop.free()


func test_a_wall_over_open_floor_shows_its_face() -> void:
	var backdrop := _backdrop("floor_1")
	# (1, 0) has floor below it; (0, 0) has wall below; (1, 3) is the bottom wall, with nothing below.
	assert_true(backdrop.tile_texture(Vector2i(1, 0)).resource_path.contains("wall_face_"))
	assert_false(backdrop.tile_texture(Vector2i(0, 0)).resource_path.contains("wall_face_"))
	assert_false(backdrop.tile_texture(Vector2i(1, 3)).resource_path.contains("wall_face_"))
	backdrop.free()


func test_a_tile_choice_is_steady() -> void:
	var first := _backdrop("floor_1")
	var again := _backdrop("floor_1")
	for x in 5:
		for y in 4:
			assert_eq(first.tile_texture(Vector2i(x, y)), again.tile_texture(Vector2i(x, y)))
	first.free()
	again.free()


func test_a_path_picture_wins_and_a_missing_one_falls_back_to_the_shared() -> void:
	PropArt.art_set = "no_such_path"
	assert_eq(PropArt.texture("crate").resource_path, "res://art/props/crate.png")
	assert_eq(PropArt.texture("no_such_prop"), null)
	_reset_art_set()
	PropArt.art_set = "flashback_cinema"
	var seats := PropArt.texture("seat_row")
	assert_true(seats != null and seats.resource_path.begins_with("res://art/props/flashback_cinema/"), "the Cinema's own seats")
	_reset_art_set()
	assert_eq(PropArt.texture("seat_row"), null, "no shared seats")


func test_pictures_land_on_whole_pixels() -> void:
	var art: Texture2D = PropArt.texture("chest_urn")
	var at := PropArt.centred(art, Vector2(0.5, 0.25))
	assert_eq(at, at.floor())
	var stand := PropArt.standing(art, Vector2(0, 6))
	assert_eq(stand.y + art.get_height(), 6.0, "the picture's bottom row on its feet")
	assert_eq(stand, stand.floor())


func test_a_breakable_keeps_its_body_with_art() -> void:
	var crate := BreakableBlock.new()
	crate._ready()
	assert_true(crate.art_texture() != null)
	var shape: CollisionShape2D = crate.get_child(0)
	assert_eq((shape.shape as RectangleShape2D).size, Vector2(RoomBackdrop.TILE, RoomBackdrop.TILE))
	crate.free()


func test_grass_shows_its_cut_picture_once_cut() -> void:
	var tuft := GrassTuft.new()
	assert_eq(tuft.art_texture().resource_path, "res://art/props/grass.png")
	tuft.cut = true
	assert_eq(tuft.art_state(), "cut")
	assert_eq(tuft.art_texture().resource_path, "res://art/props/grass_cut.png")
	tuft.variant = 1
	assert_true(tuft.art_flipped())
	tuft.free()


func test_a_prop_with_no_picture_draws_its_placeholder() -> void:
	var block := BreakableBlock.new()
	assert_eq(PropArt.state_texture("crate", "no_such_state"), null)
	block.free()


func test_a_door_shows_the_picture_for_its_state() -> void:
	var door := Door.new()
	door.locked = true
	assert_eq(door.art_state(), "locked")
	door.locked = false
	door.requires_key = true
	assert_eq(door.art_state(), "key")
	door.requires_key = false
	assert_eq(door.art_state(), "open")
	door.chained = true
	assert_eq(door.art_state(), "chained")
	for state in ["locked", "key", "open", "chained"]:
		assert_true(PropArt.state_texture("door", state) != null, "door_%s" % state)
	door.free()


func test_every_chest_has_a_closed_and_an_open_picture() -> void:
	for kind in [ChestRules.LUNCHBOX, ChestRules.LOCKED, ChestRules.SAFE, ChestRules.URN]:
		var chest := Chest.new()
		chest.kind = kind
		assert_true(PropArt.texture(chest.art_id_for()) != null, kind)
		assert_true(PropArt.texture(chest.art_id_for("open")) != null, kind + " open")
		chest.free()


func test_a_mimic_wears_the_locked_chest() -> void:
	var chest := Chest.new()
	chest.kind = ChestRules.MIMIC
	assert_eq(chest.art_id_for(), "chest_locked")
	chest.free()


func test_an_opened_chest_leaves_its_open_picture_and_nothing_else() -> void:
	var room := Node2D.new()
	var chest := Chest.new()
	chest.kind = ChestRules.LOCKED
	chest.position = Vector2(48, 80)
	room.add_child(chest)
	var opened := chest._leave_opened()
	assert_true(opened != null)
	assert_eq(opened.texture, PropArt.texture("chest_locked_open"))
	assert_eq(opened.position, chest.position)
	assert_eq(opened.feet, Chest.BASE)
	assert_false(opened.is_in_group("pickups"), "the open box is no pickup")
	assert_eq(opened.get_child_count(), 0, "and blocks nothing")
	room.free()


func test_pickups_have_their_pictures() -> void:
	for id in [RoomView.ART_COIN, RoomView.ART_SLIP, RoomView.ART_THERMOS, RoomView.ART_POTION, RoomView.ART_PILL, RoomView.ART_RECIPE]:
		var art := PropArt.texture(id)
		assert_true(art != null, id)
		if art != null:
			assert_true(art.get_width() <= 18 and art.get_height() <= 18, "%s stays pickup sized" % id)
	var plain := Pickup.new()
	assert_eq(plain.art_id, "", "an item keeps its disc")
	plain.free()


func test_a_floors_art_set_is_its_id_unless_it_shares_one() -> void:
	var floor_1: FloorDef = load("res://data/floors/floor_1.tres")
	assert_eq(floor_1.art(), "floor_1")
	for landing in ["landing", "landing_3", "landing_4", "landing_5"]:
		var def: FloorDef = load("res://data/floors/%s.tres" % landing)
		assert_eq(def.art(), "crossroads", landing)


# The Cinema and the Seance Hotline load their own tiles by their ids, and their room props find their
# own pictures while their path's rooms are built. The partition shows the piece of its run it is.
func test_the_new_paths_wear_their_own_tiles_and_props() -> void:
	for id in ["flashback_cinema", "seance_hotline"]:
		var def: FloorDef = load("res://data/floors/%s.tres" % id)
		assert_eq(def.art(), id)
		assert_true(TileArt.for_set(def.art()) != null, id + " has its tiles")
	PropArt.art_set = "flashback_cinema"
	var seat := CinemaSeat.new()
	var ids: Array[String] = [seat.art_id(), CinemaPillar.ART_ID, AisleLight.ART_ID, "lobby_card"]
	seat.free()
	for id in ids:
		var art := PropArt.texture(id)
		assert_true(art != null and art.resource_path.begins_with("res://art/props/flashback_cinema/"), "the Cinema's " + id)
	_reset_art_set()
	PropArt.art_set = "seance_hotline"
	for piece: BreakableBlock in [PsychicDesk.new(), SeanceTable.new(), LavaLamp.new()]:
		var art := piece.art_texture()
		assert_true(art != null and art.resource_path.begins_with("res://art/props/seance_hotline/"), "the hotline's " + piece.art_id())
		piece.free()
	var curtain := BeadedCurtain.new()
	assert_true(PropArt.texture(curtain.art_id()) != null, "the curtain's beads")
	curtain.free()
	var partition := SeancePartition.new()
	assert_true(partition.art_texture().resource_path.ends_with("seance_hotline/cubicle_partition.png"), "a lone panel")
	partition.joins_east = true
	assert_eq(partition.art_state(), "west", "the west end of a run")
	partition.joins_west = true
	assert_eq(partition.art_state(), "mid")
	assert_true(partition.art_texture() != null, "every piece has its picture")
	partition.free()
	_reset_art_set()
