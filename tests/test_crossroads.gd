extends TestCase

const LAYOUT_PATH := "res://data/rooms/crossroads/crossroads.tres"


func _layout() -> RoomLayout:
	return load(LAYOUT_PATH)


func _floor(seed_value: int, path := "res://data/floors/floor_1.tres") -> FloorMap:
	var def: FloorDef = load(path)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return FloorBuilder.build_from_pool(rng, def, RoomCatalog.load_valid(def.rooms_dir))


# --- the room ---

func test_the_crossroads_is_a_small_valid_room_with_nothing_to_fight_or_find() -> void:
	var layout := _layout()
	assert_eq(layout.room_type, RoomLayout.TYPE_CROSSROADS)
	assert_eq(layout.validate().size(), 0, str(layout.validate()))
	assert_eq(layout.size_class(), RoomLayout.SIZE_SMALL)
	for symbol in "EBIHTCSPRXOQVZAY":
		assert_eq(layout.cells_of(symbol).size(), 0, "'%s' has no place here" % symbol)


func test_its_floor_has_a_name_and_no_enemies_to_place() -> void:
	var def: FloorDef = load("res://data/floors/crossroads.tres")
	assert_eq(def.display_name, "The Crossroads")
	assert_eq(def.enemies.size(), 0)
	var rng := RandomNumberGenerator.new()
	assert_eq(EnemyPlan.plan(_layout(), def, 0, rng).size(), 0)


func test_a_map_of_just_the_crossroads_starts_in_it() -> void:
	var map := FloorMap.with_only_crossroads(_layout())
	assert_eq(map.rooms.size(), 1)
	assert_eq(map.room(map.start_id).room_type, RoomLayout.TYPE_CROSSROADS)
	assert_eq(FloorProgress.new(map).arrival_cell(map.start_id, -1), _layout().door_cell(RoomLayout.SOUTH), "he walks in from the south, between the two exits")


# --- the exits ---

func test_a_chained_door_never_opens() -> void:
	assert_false(Door.should_enter(false, false, false, true, true, true), "chained")
	assert_true(Door.should_enter(false, false, false, true, true, false), "the same door unchained")


func test_a_chained_door_takes_no_slip_either() -> void:
	assert_false(Door.can_spend_key(false, false, true, true))


# --- attaching it to a floor ---

func test_every_built_floor_keeps_a_free_cell_beside_its_start() -> void:
	for path in ["res://data/floors/floor_1.tres", "res://data/floors/cemetery.tres"]:
		for seed_value in 300:
			var map := _floor(seed_value, path)
			var free := 0
			for side in RoomLayout.SIDES:
				if map.room_at(map.room(map.start_id).cell + side) == null:
					free += 1
			assert_true(free > 0, "%s seed %d" % [path, seed_value])


func test_the_crossroads_attaches_on_the_side_he_came_from_with_a_one_way_door() -> void:
	for seed_value in 100:
		var map := _floor(seed_value)
		var count := map.rooms.size()
		var start := map.room(map.start_id)
		var doors_before := start.doors.size()
		var room := map.attach_crossroads(_layout(), RoomLayout.EAST)
		assert_eq(map.rooms.size(), count + 1)
		assert_eq(room.room_type, RoomLayout.TYPE_CROSSROADS)
		assert_true(room.is_detour(), "it never counts toward the floor's size")
		assert_eq(start.doors.size(), doors_before, "there is no way back")
		assert_eq(room.doors.size(), 1)
		assert_eq(room.doors[start.cell - room.cell], start.id)
		var cells := {}
		for each in map.rooms:
			assert_false(cells.has(each.cell), "seed %d shares a cell" % seed_value)
			cells[each.cell] = true


func test_it_takes_the_wanted_side_when_that_cell_is_free() -> void:
	var map := FloorMap.new()
	var start := FloorRoom.new()
	start.room_type = RoomLayout.TYPE_COMBAT
	start.cell = Vector2i(3, 3)
	start.layout = _layout()
	map.rooms.append(start)
	var east := map.attach_crossroads(_layout(), RoomLayout.EAST)
	assert_eq(east.cell, Vector2i(4, 3))


func test_it_moves_to_another_side_when_a_room_stands_there() -> void:
	var map := FloorMap.new()
	var start := FloorRoom.new()
	start.room_type = RoomLayout.TYPE_COMBAT
	start.cell = Vector2i(3, 3)
	start.layout = _layout()
	map.rooms.append(start)
	var neighbor := FloorRoom.new()
	neighbor.id = 1
	neighbor.room_type = RoomLayout.TYPE_COMBAT
	neighbor.cell = Vector2i(4, 3)
	neighbor.layout = _layout()
	map.rooms.append(neighbor)
	var room := map.attach_crossroads(_layout(), RoomLayout.EAST)
	assert_true(room.cell != Vector2i(4, 3))
	assert_eq(absi(room.cell.x - 3) + absi(room.cell.y - 3), 1)


func test_he_arrives_on_the_side_facing_the_crossroads() -> void:
	for seed_value in 50:
		var map := _floor(seed_value)
		var room := map.attach_crossroads(_layout(), RoomLayout.WEST)
		var start := map.room(map.start_id)
		var side := room.cell - start.cell
		assert_eq(FloorProgress.new(map).arrival_cell(map.start_id, room.id), start.layout.door_cell(side))
		assert_false(start.doors.has(side), "no door stands where he arrives, seed %d" % seed_value)


func test_walking_a_floor_never_routes_back_through_the_crossroads() -> void:
	for seed_value in 50:
		var map := _floor(seed_value)
		var room := map.attach_crossroads(_layout(), RoomLayout.WEST)
		for other in map.rooms:
			if other.id != room.id:
				assert_false(map.walk_from(other.id).has(room.id), "seed %d" % seed_value)
		assert_true(map.only_hidden_rooms_need_a_bomb(), "seed %d" % seed_value)
		assert_true(map.hidden_rooms_are_dead_ends(), "seed %d" % seed_value)


# --- the maps ---

func test_the_crossroads_has_its_own_look_on_the_map() -> void:
	assert_true(RoomRules.ICONS.has(RoomLayout.TYPE_CROSSROADS))
	assert_false(FloorMapView.MINI_DOTS.has(RoomRules.door_icon(RoomLayout.TYPE_CROSSROADS)), "a smaller square on the small map, no dot")
	assert_eq(FloorMapView.KEY_LABELS.get(RoomRules.door_icon(RoomLayout.TYPE_CROSSROADS), ""), "Crossroads", "the big map's key names it")


func test_it_draws_smaller_than_a_room_and_inside_its_cell() -> void:
	var full := FloorMapView.room_rect(Vector2(1, 1), Vector2.ZERO, FloorMapView.MINI_SPACING)
	var small := FloorMapView.crossroads_rect(full)
	assert_true(small.size.x < full.size.x and small.size.y < full.size.y)
	assert_true(full.encloses(small))
	assert_true(small.get_center().is_equal_approx(full.get_center()))


func test_the_big_map_still_fits_a_floor_with_the_crossroads_attached() -> void:
	for seed_value in 100:
		var map := _floor(seed_value)
		map.attach_crossroads(_layout(), RoomLayout.WEST)
		var extent := map.bounds().size
		var spacing := FloorMapView.big_spacing(extent)
		var origin := FloorMapView.big_origin(extent, spacing)
		assert_true(FloorMapView.room_size(spacing).y >= 8.0, "seed %d" % seed_value)
		for room in map.rooms:
			var rect := FloorMapView.room_rect(FloorMapView.map_position(map, room), origin, spacing)
			assert_true(FloorMapView.BIG_AREA.encloses(rect), "seed %d %s" % [seed_value, str(rect)])


func test_the_floor_name_fits_above_the_mini_map_without_touching_it() -> void:
	assert_true(FloorMapView.MINI_RECT.position.y >= FloorMapView.NAME_FONT + 2.0, "room for the name above it")
	assert_true(FloorMapView.MINI_RECT.end.x <= RoomBackdrop.VIEW_SIZE.x)
	for path in ["res://data/floors/floor_1.tres", "res://data/floors/cemetery.tres", "res://data/floors/crossroads.tres"]:
		var def: FloorDef = load(path)
		var width := ThemeDB.fallback_font.get_string_size(def.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, FloorMapView.NAME_FONT).x
		assert_true(width <= FloorMapView.MINI_RECT.size.x, "%s is %f wide" % [def.display_name, width])


# The Seance Hotline's long name ran left over the potion slot's "[H] Swift Tea" in the real window, as
# the Cinema's and Head Office's would: what the mini map writes must stay right of the slot.
func test_every_floor_name_on_the_mini_map_stays_clear_of_the_potion_slot() -> void:
	var slot_end := Hud.POTION_SLOT_AT.x + PotionSlot.SIZE.x
	assert_true(FloorMapView.MINI_RECT.position.x >= slot_end)
	for file in DirAccess.get_files_at("res://data/floors"):
		if not file.ends_with(".tres"):
			continue
		var def: FloorDef = load("res://data/floors/" + file)
		var shown := FloorMapView.mini_name(def.display_name)
		var width := ThemeDB.fallback_font.get_string_size(shown[0], HORIZONTAL_ALIGNMENT_LEFT, -1, shown[1]).x
		assert_true(FloorMapView.MINI_RECT.end.x - width >= slot_end, "%s: '%s' is %f wide" % [def.display_name, shown[0], width])
		assert_true(shown[1] >= FloorMapView.MIN_NAME_FONT)
	# A name that fits is written whole at the usual size; the hotline's keeps its first part.
	assert_eq(FloorMapView.mini_name("The Records Basement"), ["The Records Basement", FloorMapView.NAME_FONT])
	assert_eq(FloorMapView.mini_name("Beyond Calling Psychic Hotline, Night Shift")[0], "Beyond Calling Psychic Hotline")


# --- the signs ---

func test_a_sign_shows_its_details_only_nearby() -> void:
	assert_true(PathSign.shows_details(Vector2.ZERO, Vector2(PathSign.NEAR_RADIUS - 1.0, 0)))
	assert_false(PathSign.shows_details(Vector2.ZERO, Vector2(PathSign.NEAR_RADIUS + 1.0, 0)))


func test_a_sign_is_near_enough_to_read_from_its_own_exit() -> void:
	var layout := _layout()
	for side: Vector2i in [RoomLayout.WEST, RoomLayout.EAST]:
		var door := RoomBackdrop.cell_center(layout.door_cell(side))
		var sign_at := RoomBackdrop.cell_center(CrossroadsView.sign_cell(layout, side))
		assert_true(PathSign.shows_details(sign_at, door), str(side))


func test_signs_read_apart_from_the_middle_of_the_room() -> void:
	var layout := _layout()
	var arrival := RoomBackdrop.cell_center(layout.door_cell(RoomLayout.SOUTH))
	for side: Vector2i in [RoomLayout.WEST, RoomLayout.EAST]:
		var sign_at := RoomBackdrop.cell_center(CrossroadsView.sign_cell(layout, side))
		assert_false(PathSign.shows_details(sign_at, arrival), "he must walk over to read it, %s" % str(side))


func test_a_sign_says_what_its_state_calls_for() -> void:
	var open: FloorDef = load("res://data/floors/floor_1.tres")
	var closed: FloorDef = load("res://data/floors/cemetery.tres")
	assert_eq(PathSign.title_for(open, true), "The Records Basement")
	assert_eq(PathSign.detail_for(open, true), "")
	assert_eq(PathSign.title_for(closed, false), "The Unkempt Cemetery")
	assert_eq(PathSign.detail_for(closed, false), closed.closed_hint)
	assert_eq(PathSign.detail_for(closed, true), "", "no hint once it is open")


func test_skulls_match_the_danger_of_the_path() -> void:
	assert_eq(PathSign.skulls_for(load("res://data/floors/floor_1.tres")), 1)
	assert_eq(PathSign.skulls_for(load("res://data/floors/cemetery.tres")), 2)
	var none := FloorDef.new()
	none.danger = 0
	assert_eq(PathSign.skulls_for(none), 1, "a sign always shows at least one")


# Four skulls still count at a glance. Past that a sign shows one skull and the number beside it.
func test_a_deadly_path_shows_one_skull_and_its_number() -> void:
	var def := FloorDef.new()
	for danger in range(1, PathSign.MAX_SKULL_ROW + 1):
		def.danger = danger
		assert_eq(PathSign.skull_row_for(def), danger)
		assert_eq(PathSign.skull_number_for(def), "", "%d skulls are all drawn" % danger)
	for danger in [5, 6, 7, 8]:
		def.danger = danger
		assert_eq(PathSign.skull_row_for(def), 1)
		assert_eq(PathSign.skull_number_for(def), "x%d" % danger)


# --- the landing below a first floor ---

func _landing() -> RoomLayout:
	return load("res://data/rooms/landing/landing.tres")


func test_the_landing_is_a_small_valid_room_with_nothing_to_fight_or_find() -> void:
	var layout := _landing()
	assert_eq(layout.room_type, RoomLayout.TYPE_LANDING)
	assert_eq(layout.validate().size(), 0, str(layout.validate()))
	assert_eq(layout.size_class(), RoomLayout.SIZE_SMALL)
	for symbol in "EBIHTCSPRXOQVZAY":
		assert_eq(layout.cells_of(symbol).size(), 0, "'%s' has no place here" % symbol)


func test_the_landing_floor_is_named_floor_2_and_holds_no_enemies() -> void:
	var def: FloorDef = load("res://data/floors/landing.tres")
	assert_eq(def.display_name, "Floor 2")
	assert_eq(def.depth, 2)
	assert_eq(def.enemies.size(), 0)
	assert_eq(EnemyPlan.plan(_landing(), def, 0, RandomNumberGenerator.new()).size(), 0)


func test_a_landing_map_leads_from_the_landing_to_a_crossroads() -> void:
	var map := FloorMap.with_landing_and_crossroads(_landing(), _layout())
	assert_eq(map.rooms.size(), 2)
	var landing := map.room(map.start_id)
	assert_eq(landing.room_type, RoomLayout.TYPE_LANDING)
	assert_eq(landing.doors.size(), 1, "the landing has one way on")
	var crossroads := map.room(landing.doors.values()[0])
	assert_eq(crossroads.room_type, RoomLayout.TYPE_CROSSROADS)
	assert_eq(crossroads.side_towards(landing.id), -landing.side_towards(crossroads.id), "linked both ways")
	assert_true(landing.side_towards(crossroads.id) != Vector2i.ZERO)
	var arrival := FloorProgress.new(map).arrival_cell(map.start_id, -1)
	assert_true(arrival != _landing().door_cell(landing.side_towards(crossroads.id)), "he arrives away from the way on")
	assert_eq(FloorProgress.new(map).arrival_cell(crossroads.id, landing.id), _layout().door_cell(RoomLayout.SOUTH), "he enters the Crossroads from the south, between its two exits")


func test_every_second_floor_path_keeps_a_free_cell_beside_its_start() -> void:
	for path in ["res://data/floors/sunset_shores.tres", "res://data/floors/furnace_works.tres"]:
		for seed_value in 100:
			var map := _floor(seed_value, path)
			var room := map.attach_crossroads(_layout(), RoomLayout.EAST)
			assert_true(room != null, "%s seed %d" % [path, seed_value])


func test_the_second_crossroads_paths_and_their_rules() -> void:
	var sunset: FloorDef = load("res://data/floors/sunset_shores.tres")
	var furnace: FloorDef = load("res://data/floors/furnace_works.tres")
	assert_eq(sunset.id, "sunset_shores")
	assert_eq(sunset.display_name, "Sunset Shores Eternal Care")
	assert_eq(furnace.id, "furnace_works")
	assert_eq(furnace.display_name, "The Furnace Works")
	assert_eq(sunset.depth, 2)
	assert_eq(furnace.depth, 2)
	assert_true(furnace.danger > sunset.danger)
	assert_false(furnace.closed_hint.is_empty())
	var data := ProgressData.new()
	assert_true(sunset.is_open_for(data), "Sunset Shores is always open")
	data.record_floor_cleared(1, "floor_1")
	assert_false(furnace.is_open_for(data), "a first-floor clear does not open the Furnace Works")
	data.record_floor_cleared(2, "sunset_shores")
	assert_true(furnace.is_open_for(data))
