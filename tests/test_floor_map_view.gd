extends TestCase


func _add(map: FloorMap, room_type: String, cell: Vector2i) -> FloorRoom:
	var room := FloorRoom.new()
	room.id = map.rooms.size()
	room.room_type = room_type
	room.cell = cell
	map.rooms.append(room)
	return room


func test_a_room_is_drawn_at_its_grid_cell_from_the_corner_of_the_floor() -> void:
	var map := FloorMap.new()
	_add(map, RoomLayout.TYPE_COMBAT, Vector2i(3, 2))
	var far := _add(map, RoomLayout.TYPE_ITEM, Vector2i(5, 6))
	assert_eq(FloorMapView.map_position(map, far), Vector2(2, 4))


func test_the_big_map_fits_every_built_floor_in_its_panel() -> void:
	var def: FloorDef = load("res://data/floors/floor_1.tres")
	var pool := RoomCatalog.load_valid(def.rooms_dir)
	for seed_value in 100:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var map := FloorBuilder.build_from_pool(rng, def, pool)
		var extent := map.bounds().size
		var spacing := FloorMapView.big_spacing(extent)
		var origin := FloorMapView.big_origin(extent, spacing)
		for room in map.rooms:
			var rect := FloorMapView.room_rect(FloorMapView.map_position(map, room), origin, spacing)
			assert_true(FloorMapView.BIG_AREA.encloses(rect), "seed %d %s" % [seed_value, str(rect)])


func test_the_big_map_keeps_rooms_tall_enough_for_their_icons() -> void:
	var spacing := FloorMapView.big_spacing(FloorDef.new().grid_size)
	assert_true(FloorMapView.room_size(spacing).y >= 16.0, str(spacing))


func test_the_mini_map_centers_on_the_current_room() -> void:
	var origin := FloorMapView.mini_origin(Vector2(4, 2))
	var rect := FloorMapView.room_rect(Vector2(4, 2), origin, FloorMapView.MINI_SPACING)
	assert_eq(rect.get_center(), FloorMapView.MINI_RECT.get_center())


func test_rooms_keep_a_gap_their_door_link_can_show_in() -> void:
	for spacing: Vector2 in [FloorMapView.MINI_SPACING, FloorMapView.BIG_SPACING]:
		var left := FloorMapView.room_rect(Vector2(0, 0), Vector2.ZERO, spacing)
		var right := FloorMapView.room_rect(Vector2(1, 0), Vector2.ZERO, spacing)
		var below := FloorMapView.room_rect(Vector2(0, 1), Vector2.ZERO, spacing)
		assert_true(left.end.x < right.position.x, str(spacing))
		assert_true(left.end.y < below.position.y, str(spacing))


func test_every_room_type_has_a_color() -> void:
	for room_type: String in RoomRules.ICONS:
		assert_true(FloorMapView.ROOM_COLORS.has(room_type), room_type)


func test_night_vision_shows_secret_rooms_before_they_are_found() -> void:
	var map := FloorMap.new()
	var start := _add(map, RoomLayout.TYPE_COMBAT, Vector2i(0, 0))
	var secret := _add(map, RoomLayout.TYPE_SECRET, Vector2i(1, 0))
	var progress := FloorProgress.new(map)
	progress.enter(start.id)
	assert_false(FloorMapView.shown_ids(map, progress, false).has(secret.id), "hidden until found")
	assert_true(FloorMapView.shown_ids(map, progress, true).has(secret.id), "Night Vision shows it")
	assert_true(FloorMapView.shown_ids(map, progress, true).has(start.id))
	progress.enter(secret.id)
	assert_true(FloorMapView.shown_ids(map, progress, false).has(secret.id), "found rooms always show")
	assert_eq(FloorMapView.shown_ids(map, progress, true).size(), 2, "never listed twice")


# The DualSense showed "Create: Close", which reads as an action. A pad names its back button, which
# closes the map as every panel, and the prompt fits inside the panel's top right for every family.
func test_the_big_maps_close_prompt_names_the_back_button_on_a_pad() -> void:
	KeyBindings.reset_to_defaults()
	assert_eq(FloorMapView.close_hint(true, PadInput.PLAYSTATION), "Circle: Close")
	assert_eq(FloorMapView.close_hint(true, PadInput.PLAYSTATION_4), "Circle: Close")
	assert_eq(FloorMapView.close_hint(true, PadInput.XBOX), "B: Close")
	assert_eq(FloorMapView.close_hint(false, PadInput.XBOX), "M: Close")
	var font := ThemeDB.fallback_font
	for family in [PadInput.PLAYSTATION, PadInput.XBOX]:
		var width := font.get_string_size(FloorMapView.close_hint(true, family), HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		assert_true(width < 120.0, "the prompt stays a short tag in the corner")


# A warning under the small map shows through it: while one lies under the map's panel, the map, its
# floor name and its panel fade (MapFade); a prop there, a warning elsewhere or a hidden one does not.
func test_the_small_map_fades_while_a_warning_lies_under_it() -> void:
	assert_eq(MapFade.world_rect(Transform2D.IDENTITY), Hud.MAP_PANEL, "with no camera move, the panel itself")
	assert_eq(MapFade.world_rect(Transform2D(0.0, Vector2(-300, -100))), Rect2(Hud.MAP_PANEL.position + Vector2(300, 100), Hud.MAP_PANEL.size), "follows the camera")
	var area := Hud.MAP_PANEL
	var room := Node2D.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(room)
	var prop := Node2D.new()
	prop.position = area.get_center()
	room.add_child(prop)
	assert_false(MapFade.covered(room, area), "a prop under the map is no warning")
	var far := GroundStrike.new()
	far.setup(null, 30.0, 2.0)
	far.position = Vector2(100, 250)
	room.add_child(far)
	assert_false(MapFade.covered(room, area), "a warning elsewhere leaves the map whole")
	var near := GroundStrike.new()
	near.setup(null, 30.0, 2.0)
	near.position = area.position + Vector2(-20, area.size.y + 10)
	room.add_child(near)
	assert_true(MapFade.covered(room, area), "a ring reaching under its corner")
	near.free()
	# A lane from far away that runs under the map counts by its own shape, not its start.
	var lane := RunwayLane.new()
	lane.setup(null, Vector2.RIGHT, 600.0, 24.0, 0.0, 2.0)
	lane.position = Vector2(0, area.get_center().y)
	room.add_child(lane)
	assert_true(MapFade.covered(room, area), "a lane crossing under it")
	lane.position = Vector2(0, area.end.y + 40)
	assert_false(MapFade.covered(room, area), "the same lane below it")
	room.free()
	var alpha := 1.0
	for i in 30:
		alpha = MapFade.step(alpha, true, 1.0 / 60.0)
	assert_near(alpha, MapFade.FADED, "faded within half a second")
	for i in 30:
		alpha = MapFade.step(alpha, false, 1.0 / 60.0)
	assert_near(alpha, 1.0, "and whole again")


# The panel behind the small map is its own piece, faded with it; the big map keeps full colour.
func test_the_maps_panel_fades_with_the_small_map() -> void:
	var hud := Hud.new()
	hud._ready()
	var view := FloorMapView.new()
	view.setup(FloorMap.new(), null, false)
	hud.add_child(view)
	hud.set_map_alpha(MapFade.FADED, view)
	assert_near(hud.map_alpha(), MapFade.FADED)
	assert_near(view.modulate.a, MapFade.FADED)
	hud.set_map_alpha(1.0, view)
	assert_near(view.modulate.a, 1.0)
	hud.free()
