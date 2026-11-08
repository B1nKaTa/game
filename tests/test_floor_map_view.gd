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


# A warning under the small map shows through it: the HUD copies the world under the map's panel before
# any of its own pieces draw, and the small map (only) lays a WarningWindow over its whole panel.
func test_warnings_under_the_small_map_show_through_it() -> void:
	var hud := Hud.new()
	hud._ready()
	var copy := hud.get_child(0)
	assert_true(copy is BackBufferCopy, "the copy is the HUD's first piece")
	assert_eq((copy as BackBufferCopy).copy_mode, BackBufferCopy.COPY_MODE_RECT)
	assert_eq((copy as BackBufferCopy).rect, Hud.MAP_PANEL)
	var views: Array[FloorMapView] = []
	for is_big in [false, true]:
		var view := FloorMapView.new()
		view.setup(FloorMap.new(), null, is_big)
		hud.add_child(view)
		view._ready()
		views.append(view)
	var windows := _windows(views[0])
	assert_eq(windows.size(), 1, "the small map has its window")
	if windows.is_empty():
		hud.free()
		return
	var window := windows[0]
	assert_eq(Rect2(views[0].position + window.position, window.size), Hud.MAP_PANEL, "over its whole panel")
	assert_eq(_windows(views[1]).size(), 0, "the big map has none")
	window._ready()
	assert_true(window.material is ShaderMaterial and (window.material as ShaderMaterial).shader.code.contains("hint_screen_texture"), "it reads the copied world")
	assert_true(WarningWindow.REACH >= SpliceLane.WIDTH / 2.0, "it reaches a lane's middle from its outline")
	hud.free()


func _windows(view: Node) -> Array[WarningWindow]:
	var found: Array[WarningWindow] = []
	for child in view.get_children():
		if child is WarningWindow:
			found.append(child)
	return found
