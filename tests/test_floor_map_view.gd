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
	var stubs_tested := 0
	for file in DirAccess.get_files_at("res://data/floors"):
		if not file.ends_with(".tres"):
			continue
		var def: FloorDef = load("res://data/floors/" + file)
		# The Waiting Room builds its own map (Departments) and the Crossroads and landings have none.
		if def.rooms_dir.is_empty() or def.id == "waiting_room":
			continue
		var pool := RoomCatalog.load_valid(def.rooms_dir)
		var seeds := 100 if def.id == "floor_1" else 20
		for seed_value in seeds:
			var rng := RandomNumberGenerator.new()
			rng.seed = seed_value
			var map := FloorBuilder.build_from_pool(rng, def, pool)
			var extent := map.bounds().size
			var spacing := FloorMapView.big_spacing(extent)
			var origin := FloorMapView.big_origin(extent, spacing)
			for room in map.rooms:
				var rect := FloorMapView.room_rect(FloorMapView.map_position(map, room), origin, spacing)
				assert_true(FloorMapView.BIG_AREA.encloses(rect), "%s seed %d %s" % [def.id, seed_value, str(rect)])
			# Every main room walked, no detour: each detour door is a stub, and stub and sign stay inside.
			var progress := FloorProgress.new(map)
			for room in map.main_rooms():
				progress.enter(room.id)
			var stubs := FloorMapView.exit_stubs(map, progress, FloorMapView.shown_ids(map, progress, false))
			for stub in stubs:
				var from: FloorRoom = map.room(stub["from"])
				var from_rect := FloorMapView.room_rect(FloorMapView.map_position(map, from), origin, spacing)
				var box := FloorMapView.stub_box(from_rect, stub["side"], spacing)
				assert_true(FloorMapView.BIG_AREA.encloses(box), "%s seed %d stub %s" % [def.id, seed_value, str(box)])
				stubs_tested += 1
	assert_true(stubs_tested > 100, "stubs were tested: %d" % stubs_tested)


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


# The small map has no room for a 9 px sign, so each sign is a dot of colour there. Every room type
# with a sign has one, in a colour of its own that reads on the paper and on a walked room's floor.
func test_every_sign_has_a_dot_on_the_small_map() -> void:
	for room_type: String in RoomRules.ICONS:
		var icon := RoomRules.door_icon(room_type)
		# The Crossroads is drawn blank and smaller on both maps, as its sign is a signpost.
		var dotted := DoorSign.has_sign(icon) and room_type != RoomLayout.TYPE_CROSSROADS
		assert_eq(FloorMapView.MINI_DOTS.has(icon), dotted, "%s (%s)" % [room_type, icon])
	assert_true(FloorMapView.MINI_DOTS.has("?"), "the unknown, as a stub to a plain fight room ends")
	var seen := {}
	for icon: String in FloorMapView.MINI_DOTS:
		var color: Color = FloorMapView.MINI_DOTS[icon]
		assert_false(seen.has(color.to_html()), "%s has a colour of its own" % icon)
		seen[color.to_html()] = true
		for ink: Color in [MapPaper.INK, MapPaper.PENCIL, MapPaper.STAMP, MapPaper.PAPER_EDGE]:
			assert_false(color.is_equal_approx(ink), "%s is no line's colour" % icon)
		for ground: Color in [MapPaper.PAPER, MapPaper.ROOM_FILL]:
			assert_true(_contrast(color, ground) >= 3.0, "%s on %s: %.2f" % [icon, ground.to_html(), _contrast(color, ground)])


func _luminance(c: Color) -> float:
	var parts: Array[float] = []
	for v: float in [c.r, c.g, c.b]:
		parts.append(v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4))
	return 0.2126 * parts[0] + 0.7152 * parts[1] + 0.0722 * parts[2]


func _contrast(a: Color, b: Color) -> float:
	var la := _luminance(a)
	var lb := _luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


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


# The small map reaches below the HUD's rows: it fades while anything that matters is under its panel on
# screen, not only a warning. under_hud is the rule: any screen rect overlapping the panel.
func test_under_hud_is_any_thing_overlapping_the_panel() -> void:
	var panel := Hud.MAP_PANEL
	var none: Array[Rect2] = []
	assert_false(MapFade.under_hud(panel, none), "nothing at all")
	assert_true(MapFade.under_hud(panel, [Rect2(600, 30, 16, 16)] as Array[Rect2]), "inside it")
	assert_true(MapFade.under_hud(panel, [Rect2(510, 65, 20, 20)] as Array[Rect2]), "over its bottom left corner")
	assert_false(MapFade.under_hud(panel, [Rect2(510, 80, 20, 20)] as Array[Rect2]), "below it")
	assert_false(MapFade.under_hud(panel, [Rect2(panel.position.x - 20.0, 10, 20, 20)] as Array[Rect2]), "only touching its edge")
	assert_false(MapFade.under_hud(panel, [Rect2(100, 100, 40, 40), Rect2(300, 20, 30, 30)] as Array[Rect2]), "all elsewhere")
	assert_true(MapFade.under_hud(panel, [Rect2(100, 100, 40, 40), Rect2(630, 70, 4, 4)] as Array[Rect2]), "any one of them")


# Harold, a pickup still lying in the room and a live enemy each fade the map when the camera shows them
# under its panel; a pickup flying to him, a dead enemy, or any of them elsewhere does not.
func test_the_small_map_fades_while_harold_a_pickup_or_an_enemy_is_under_it() -> void:
	# The camera has moved: world (880, 140) is on screen at (580, 40), under the panel.
	var canvas := Transform2D(0.0, Vector2(-300, -100))
	var under := Vector2(880, 140)
	assert_true(Hud.MAP_PANEL.has_point(canvas * under))
	var room := Node2D.new()
	var harold := Node2D.new()
	harold.position = Vector2(500, 300)
	assert_false(MapFade.should_fade(room, harold, canvas), "an empty corner")
	harold.position = under
	assert_true(MapFade.should_fade(room, harold, canvas), "Harold under it")
	# His feet below the panel, his head and shoulders still under it.
	harold.position = Vector2(880, 100 + Hud.MAP_PANEL.end.y + 10.0)
	assert_true(MapFade.should_fade(room, harold, canvas), "his head under its bottom edge")
	harold.position = Vector2(500, 300)
	var pickup := Pickup.new()
	pickup.position = under
	room.add_child(pickup)
	assert_true(MapFade.should_fade(room, harold, canvas), "a pickup lying under it")
	pickup.fly()
	assert_false(MapFade.should_fade(room, harold, canvas), "a pickup already on its way to him")
	var enemy := Enemy.new()
	enemy.setup(load("res://data/enemies/intern_reaper.tres"), null, 0.5)
	enemy.position = under + Vector2(10, 10)
	room.add_child(enemy)
	assert_true(MapFade.should_fade(room, harold, canvas), "a live enemy under it")
	enemy._dead = true
	assert_false(MapFade.should_fade(room, harold, canvas), "a dead one")
	enemy._dead = false
	enemy.position = Vector2(400, 400)
	assert_false(MapFade.should_fade(room, harold, canvas), "a live one elsewhere")
	assert_false(MapFade.should_fade(null, null, canvas), "no room and no Harold")
	room.free()
	harold.free()


# --- the paper floor plan (playtest-9 note 3) ---

# A start room with a shop to the east, a fight room to the south, a secret to the west and an item room
# to the north, every door joined.
func _cross_floor() -> FloorMap:
	var map := FloorMap.new()
	var start := _add(map, RoomLayout.TYPE_COMBAT, Vector2i(1, 1))
	map.join(start, _add(map, RoomLayout.TYPE_SHOP, Vector2i(2, 1)))
	map.join(start, _add(map, RoomLayout.TYPE_COMBAT, Vector2i(1, 2)))
	map.join(start, _add(map, RoomLayout.TYPE_SECRET, Vector2i(0, 1)))
	map.join(start, _add(map, RoomLayout.TYPE_ITEM, Vector2i(1, 0)))
	return map


func _stub_to(stubs: Array[Dictionary], side: Vector2i) -> Dictionary:
	for stub in stubs:
		if stub["side"] == side:
			return stub
	return {}


func test_a_visited_room_shows_a_stub_for_each_door_not_yet_walked_through() -> void:
	var map := _cross_floor()
	var progress := FloorProgress.new(map)
	progress.enter(0)
	progress.enter(4)
	var stubs := FloorMapView.exit_stubs(map, progress, FloorMapView.shown_ids(map, progress, false))
	assert_eq(stubs.size(), 2, str(stubs))
	assert_eq(_stub_to(stubs, Vector2i.RIGHT), {"from": 0, "side": Vector2i.RIGHT, "icon": "$"}, "the shop's sign")
	assert_eq(_stub_to(stubs, Vector2i.DOWN), {"from": 0, "side": Vector2i.DOWN, "icon": "?"}, "a plain fight room is a ?")
	assert_true(_stub_to(stubs, Vector2i.LEFT).is_empty(), "an unfound secret gives no stub")
	assert_true(_stub_to(stubs, Vector2i.UP).is_empty(), "a room already shown gives no stub")
	# Night Vision shows the secret: it is shown now, so still no stub.
	stubs = FloorMapView.exit_stubs(map, progress, FloorMapView.shown_ids(map, progress, true))
	assert_true(_stub_to(stubs, Vector2i.LEFT).is_empty(), "a shown secret is a room, not a stub")
	# With the Floor Plan every room shows, and a room he has not walked into gives no stubs of its own.
	stubs = FloorMapView.exit_stubs(map, progress, FloorMapView.shown_ids(map, progress, false, true))
	assert_true(stubs.is_empty(), str(stubs))


func test_the_key_lists_only_the_room_types_on_this_floor() -> void:
	var map := _cross_floor()
	var progress := FloorProgress.new(map)
	progress.enter(0)
	var shown := FloorMapView.shown_ids(map, progress, false)
	var stubs := FloorMapView.exit_stubs(map, progress, shown)
	assert_eq(FloorMapView.key_icons(map, progress, shown, stubs, false), ["C", "I", "$", "?"] as Array[String], "no secret before it is found")
	progress.enter(3)
	shown = FloorMapView.shown_ids(map, progress, false)
	stubs = FloorMapView.exit_stubs(map, progress, shown)
	assert_true(FloorMapView.key_icons(map, progress, shown, stubs, false).has("S"), "a found secret joins the key")
	for icon in FloorMapView.KEY_ORDER:
		assert_true(FloorMapView.KEY_LABELS.has(icon), icon)
	for icon: String in RoomRules.ICONS.values():
		if DoorSign.has_sign(icon) or icon == "C":
			assert_true(FloorMapView.KEY_ORDER.has(icon), "%s has a place in the key" % icon)
	assert_true(FloorMapView.KEY_ORDER.size() <= FloorMapView.KEY_COLUMNS * FloorMapView.KEY_ROWS, "every entry fits the key's rows")


func _width(text: String, font_size: int) -> float:
	return HudStyle.font().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x


func test_every_text_on_the_big_map_fits_its_box_in_the_game_font() -> void:
	for icon: String in FloorMapView.KEY_LABELS:
		var label: String = FloorMapView.KEY_LABELS[icon]
		assert_true(_width(label, HudStyle.SMALL) <= FloorMapView.key_label_width(), "key label %s" % label)
	assert_true(_width(FloorMapView.TAB_TEXT, HudStyle.SMALL) <= FloorMapView.TAB.size.x - 8.0, "the tab")
	for file in DirAccess.get_files_at("res://data/floors"):
		if file.ends_with(".tres"):
			var floor_name: String = (load("res://data/floors/" + file) as FloorDef).display_name
			var size := FloorMapView.heading_size(floor_name)
			assert_true(_width(FloorMapView.heading_text(floor_name), size) <= FloorMapView.NAME_BOX.size.x, "the floor name %s" % floor_name)
			assert_true(MapPaper.line_height(size) <= FloorMapView.NAME_BOX.size.y, "its height at %d" % size)
	assert_eq(FloorMapView.heading_size("The Records Basement"), HudStyle.LARGE, "a short name is written large")
	# The line metrics the map lays text out by are the pixel font's own.
	var fnt := FileAccess.get_file_as_string(HudStyle.FONT_PATH)
	assert_true(fnt.contains("lineHeight=%d base=%d" % [MapPaper.FONT_LINE, MapPaper.FONT_BASE]), "the font file's line")
	assert_true(MapPaper.line_height(HudStyle.SMALL) <= FloorMapView.SETS_BOX.size.y, "the sets line's height")
	assert_true(MapPaper.line_height(HudStyle.SMALL) <= FloorMapView.KEY_ROW_HEIGHT, "a key row's height")
	KeyBindings.reset_to_defaults()
	for hint in [FloorMapView.close_hint(true, PadInput.PLAYSTATION), FloorMapView.close_hint(true, PadInput.PLAYSTATION_4), FloorMapView.close_hint(true, PadInput.XBOX), FloorMapView.close_hint(false, PadInput.XBOX)]:
		assert_true(_width(hint, HudStyle.SMALL) <= FloorMapView.HINT_WIDTH, hint)
	assert_true(FloorMapView.NAME_BOX.end.x + FloorMapView.HINT_WIDTH <= FloorMapView.SHEET.end.x - 12.0, "the hint's place right of the name")
	var stamp := MapPaper.stamp_size(FloorMapView.STAMP_TEXT, HudStyle.SMALL)
	assert_true(_width(FloorMapView.STAMP_TEXT, HudStyle.SMALL) + 4.0 <= stamp.x, "the stamp's words inside its frame")
	var many := PackedStringArray()
	for i in 12:
		many.append("A Rather Long Set Name %d" % i)
	var line := FloorMapView.sets_text(many, FloorMapView.SETS_BOX.size.x)
	assert_true(_width(line, HudStyle.SMALL) <= FloorMapView.SETS_BOX.size.x, line)
	assert_true(line.begins_with("Sets: A Rather Long Set Name 0"), line)
	assert_eq(FloorMapView.sets_text(PackedStringArray(["Full Set"]), FloorMapView.SETS_BOX.size.x), "Sets: Full Set")


func test_the_paper_map_sits_inside_its_sheet() -> void:
	for box: Rect2 in [FloorMapView.BIG_AREA, FloorMapView.KEY_RECT, FloorMapView.NAME_BOX, FloorMapView.SETS_BOX]:
		assert_true(FloorMapView.SHEET.encloses(box), str(box))
	assert_true(FloorMapView.SETS_BOX.end.y <= FloorMapView.BIG_AREA.position.y, "the sets line above the plan")
	assert_true(FloorMapView.BIG_AREA.end.y <= FloorMapView.KEY_RECT.position.y, "the plan above the key")
	assert_true(FloorMapView.SHEET.end.y <= 360.0 and FloorMapView.TAB.position.y >= 0.0)


# The paused map lists the run's formed sets (combos are retired).
func test_the_paused_map_lists_the_runs_sets() -> void:
	assert_eq(FloorMapView.sets_line(PackedStringArray(["Full Set", "Night Shift"])), "Sets: Full Set, Night Shift")
	var scene := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
	assert_true(scene.contains("_big_map.set_names = _run.effects.set_names()"))
	assert_false(scene.contains("combo_names"))


# --- the cross-shape rule, on the marks themselves ---

# Pixels of the plan that carry a mark: anything on the sheet (or `area`, such as the small map's scrap)
# that is not bare paper or a room's floor.
func _marked(image: Image, area := Rect2()) -> PackedByteArray:
	var marks := PackedByteArray()
	marks.resize(image.get_width() * image.get_height())
	var sheet := Rect2i(FloorMapView.SHEET if area.size == Vector2.ZERO else area)
	for y in range(sheet.position.y, sheet.end.y):
		for x in range(sheet.position.x, sheet.end.x):
			var c := image.get_pixel(x, y)
			if c.a > 0.0 and not c.is_equal_approx(MapPaper.PAPER) and not c.is_equal_approx(MapPaper.ROOM_FILL) and not c.is_equal_approx(CaseFile.MANILA):
				marks[y * image.get_width() + x] = 1
	return marks


func _run_length(marks: PackedByteArray, width: int, height: int, at: Vector2i, step: Vector2i) -> int:
	var n := 0
	var p := at + step
	while p.x >= 0 and p.y >= 0 and p.x < width and p.y < height and marks[p.y * width + p.x] == 1:
		n += 1
		p += step
	return n


# A thin straight stroke crossing another: arms of 4 or more pixels on all four sides of a spot, each arm
# 3 pixels wide or less a little way out. A T, an L, a filled block or a dot is no cross.
func _crossings(image: Image, area := Rect2()) -> Array[Vector2i]:
	var width := image.get_width()
	var height := image.get_height()
	var marks := _marked(image, area)
	var found: Array[Vector2i] = []
	for y in height:
		for x in width:
			if marks[y * width + x] == 0:
				continue
			var at := Vector2i(x, y)
			var arms := true
			for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				if _run_length(marks, width, height, at, step) < 4:
					arms = false
					break
			if not arms:
				continue
			var thin := true
			for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var out := at + step * 3
				var across := Vector2i(step.y, step.x)
				var span := 1 + _run_length(marks, width, height, out, across) + _run_length(marks, width, height, out, -across)
				if span > 3:
					thin = false
			if thin:
				found.append(at)
	return found


func _paper_image() -> Image:
	return Image.create(640, 360, false, Image.FORMAT_RGBA8)


func test_the_cross_finder_sees_a_plus_and_not_a_corner() -> void:
	var image := _paper_image()
	MapPaper.fill(image, FloorMapView.SHEET, MapPaper.PAPER)
	MapPaper.fill(image, Rect2(100, 100, 21, 1), CaseFile.INK)
	MapPaper.fill(image, Rect2(110, 90, 1, 21), CaseFile.INK)
	assert_false(_crossings(image).is_empty(), "a plus")
	image = _paper_image()
	MapPaper.fill(image, FloorMapView.SHEET, MapPaper.PAPER)
	MapPaper.fill(image, Rect2(100, 100, 21, 1), CaseFile.INK)
	MapPaper.fill(image, Rect2(110, 101, 1, 10), CaseFile.INK)
	MapPaper.fill(image, Rect2(200, 100, 30, 20), CaseFile.INK)
	assert_true(_crossings(image).is_empty(), "a T and a block")


# A floor with every kind of mark on it: walked rooms with signs and corridors, the Floor Plan's pencil
# rooms, Night Vision's "?", a boss named by the Fortune Teller's Card, stubs, the stamp and the key.
func _painted_floor(seed_value: int, with_items: bool) -> Image:
	var def: FloorDef = load("res://data/floors/floor_1.tres")
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var map := FloorBuilder.build_from_pool(rng, def, RoomCatalog.load_valid(def.rooms_dir))
	var progress := FloorProgress.new(map)
	for id: int in map.main_path.slice(0, 4):
		progress.enter(id)
	var view := FloorMapView.new()
	view.setup(map, progress, true, def.display_name)
	view.set_current(map.main_path[1])
	view.set_names = PackedStringArray(["Full Set"])
	if with_items:
		view.show_secrets = true
		view.show_plan = true
		view.boss_names = FloorMapView.boss_names_for(def)
	var image := _paper_image()
	view.paint_big(image)
	view.free()
	return image


func test_no_mark_on_the_big_map_reads_as_a_cross() -> void:
	for seed_value in [1, 2, 3]:
		for with_items in [false, true]:
			var image := _painted_floor(seed_value, with_items)
			var crossings := _crossings(image)
			assert_true(crossings.is_empty(), "seed %d items %s: %s" % [seed_value, str(with_items), str(crossings.slice(0, 4))])
	var checker = load("res://tests/test_art_direction.gd").new()
	for icon: String in DoorSign.PICTURES:
		var rows := MapPaper.ink_cells(icon)
		assert_false(checker._reads_as_a_cross(rows), "the ink sign %s" % icon)
		var turned: Array = []
		for x in DoorSign.SIZE:
			var column := ""
			for row: String in rows:
				column += row[x]
			turned.append(column)
		assert_false(checker._reads_as_a_cross(turned), "the ink sign %s on its side" % icon)


func test_the_big_map_paints_the_plan_on_paper() -> void:
	var image := _painted_floor(1, false)
	var inked := 0
	var stamped := 0
	var area := Rect2i(FloorMapView.BIG_AREA)
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var c := image.get_pixel(x, y)
			if c.is_equal_approx(CaseFile.INK):
				inked += 1
			elif c.is_equal_approx(CaseFile.STAMP):
				stamped += 1
	assert_true(inked > 200, "ink outlines and signs: %d" % inked)
	assert_true(stamped > 40, "the red stamp: %d" % stamped)
	assert_true(image.get_pixelv(Vector2i(FloorMapView.TAB.get_center())).is_equal_approx(CaseFile.MANILA), "the manila tab")


# What the big map leaves for marks laid over it later (pickups left in a room): each shown room's box,
# the sign's spot inside it, and the stamp, all on the plan.
func test_the_big_map_tells_where_it_drew_each_room_and_the_stamp() -> void:
	var map := _cross_floor()
	var progress := FloorProgress.new(map)
	progress.enter(0)
	progress.enter(1)
	var view := FloorMapView.new()
	view.setup(map, progress, true, "The Records Basement")
	view.set_current(0)
	view.paint_big(_paper_image())
	assert_eq(view.big_room_rects.size(), 2, "the start and the shop, not the rooms behind its stubs")
	var spacing := FloorMapView.big_spacing(map.bounds().size)
	for room_id: int in view.big_room_rects:
		var rect: Rect2 = view.big_room_rects[room_id]
		assert_true(FloorMapView.BIG_AREA.encloses(rect))
		assert_true(rect.encloses(FloorMapView.room_sign_rect(rect, FloorMapView.room_size(spacing))), "the sign's spot is inside room %d" % room_id)
	assert_true(FloorMapView.BIG_AREA.encloses(view.big_stamp_rect), str(view.big_stamp_rect))
	assert_true(view.big_stamp_rect.intersects(view.big_room_rects[0]), "the stamp is pressed on the current room's corner")
	view.free()


# --- fix round 1 ---

# The key explains only the marks on the sheet: with only the start walked, no shop, treasure room or
# boss is listed unless a stub from the start shows its sign.
func test_the_key_gives_away_no_room_not_yet_found() -> void:
	var def: FloorDef = load("res://data/floors/floor_1.tres")
	var pool := RoomCatalog.load_valid(def.rooms_dir)
	var hidden_somewhere := 0
	for seed_value in 30:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var map := FloorBuilder.build_from_pool(rng, def, pool)
		var progress := FloorProgress.new(map)
		progress.enter(map.start_id)
		var shown := FloorMapView.shown_ids(map, progress, false)
		var stubs := FloorMapView.exit_stubs(map, progress, shown)
		var stub_icons := {}
		for stub in stubs:
			stub_icons[stub["icon"]] = true
		var icons := FloorMapView.key_icons(map, progress, shown, stubs, false)
		for icon: String in ["$", "T", "B", "M", "H", "A"]:
			assert_eq(icons.has(icon), stub_icons.has(icon), "seed %d: %s only when its stub shows" % [seed_value, icon])
		for room in map.rooms:
			if room.room_type == RoomLayout.TYPE_SHOP and not stub_icons.has("$"):
				hidden_somewhere += 1
	assert_true(hidden_somewhere > 0, "some floor had a shop the key kept quiet about")
	# Night Vision's secret not yet walked into is drawn as a "?", which the key lists as "Unknown" (no eye).
	var map := _cross_floor()
	var progress := FloorProgress.new(map)
	progress.enter(0)
	var shown := FloorMapView.shown_ids(map, progress, true, true)
	assert_eq(FloorMapView.drawn_sign(map, progress, map.room(3), false), "?", "the spec's ?")
	var icons := FloorMapView.key_icons(map, progress, shown, FloorMapView.exit_stubs(map, progress, shown), false)
	assert_true(icons.has("?") and not icons.has("S"), str(icons))
	progress.enter(3)
	assert_eq(FloorMapView.drawn_sign(map, progress, map.room(3), false), "S", "a walked secret shows its own sign")


# A boss room shown by the Fortune Teller's Card, beside a walked room: the walked room's door into it
# is a corridor with a door gap at both ends, not nothing.
func test_a_door_into_a_room_shown_but_not_walked_keeps_its_corridor() -> void:
	var map := FloorMap.new()
	var start := _add(map, RoomLayout.TYPE_COMBAT, Vector2i(0, 0))
	var boss := _add(map, RoomLayout.TYPE_FLOOR_BOSS, Vector2i(1, 0))
	map.join(start, boss)
	var progress := FloorProgress.new(map)
	progress.enter(start.id)
	assert_true(FloorMapView.shown_ids(map, progress, false, false, true).has(boss.id))
	assert_true(FloorMapView.corridor_shown(start, boss, progress, false), "a walked room's door into a shown room")
	var view := FloorMapView.new()
	view.setup(map, progress, true, "The Records Basement")
	view.set_current(start.id)
	view.boss_names = {RoomLayout.TYPE_FLOOR_BOSS: "Regional Reaper"}
	var image := _paper_image()
	view.paint_big(image)
	var spacing := FloorMapView.big_spacing(map.bounds().size)
	var half := MapPaper.corridor_half(FloorMapView.room_size(spacing))
	var from: Rect2 = view.big_room_rects[start.id]
	var to: Rect2 = view.big_room_rects[boss.id]
	var mid := Vector2i(MapPaper.edge_mid(from, Vector2i.RIGHT))
	assert_true(image.get_pixel(mid.x + 1, mid.y - half).is_equal_approx(MapPaper.PENCIL), "the corridor's top wall")
	assert_true(image.get_pixel(mid.x + 1, mid.y + half - 1).is_equal_approx(MapPaper.PENCIL), "the corridor's bottom wall")
	assert_true(image.get_pixel(mid.x - 1, mid.y).is_equal_approx(MapPaper.ROOM_FILL), "a door gap in the walked room")
	var far := Vector2i(MapPaper.edge_mid(to, Vector2i.LEFT))
	assert_true(image.get_pixel(far.x, far.y).is_equal_approx(MapPaper.PAPER), "a door gap in the boss room")
	assert_true(FloorMapView.exit_stubs(map, progress, FloorMapView.shown_ids(map, progress, false, false, true)).is_empty(), "a corridor, not also a stub")
	view.free()


# Under the Floor Plan, a door sign he saw from a walked room stays on the plan, in the room behind it.
func test_a_seen_door_sign_survives_the_floor_plan() -> void:
	var map := _cross_floor()
	var progress := FloorProgress.new(map)
	progress.enter(0)
	assert_eq(FloorMapView.drawn_sign(map, progress, map.room(1), false), "$", "the shop's sign, seen from the start")
	var far := _add(map, RoomLayout.TYPE_TREASURE, Vector2i(3, 1))
	map.join(map.room(1), far)
	assert_eq(FloorMapView.drawn_sign(map, progress, far, false), "", "a Floor Plan room he never saw a door to says nothing")
	var shown := FloorMapView.shown_ids(map, progress, false, true)
	var icons := FloorMapView.key_icons(map, progress, shown, FloorMapView.exit_stubs(map, progress, shown), false)
	assert_true(icons.has("$") and not icons.has("T"), str(icons))


func _items_view(def: FloorDef, seed_value: int) -> FloorMapView:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var map := FloorBuilder.build_from_pool(rng, def, RoomCatalog.load_valid(def.rooms_dir))
	var progress := FloorProgress.new(map)
	for id: int in map.main_path.slice(0, 4):
		progress.enter(id)
	var view := FloorMapView.new()
	view.setup(map, progress, true, def.display_name)
	view.set_current(map.main_path[1])
	view.show_secrets = true
	view.show_plan = true
	view.boss_names = FloorMapView.boss_names_for(def)
	return view


# A boss's name never covers a room, a corridor or a stub (it once erased a corridor and a wall): it sits
# near its room where the plan is clear, else in the key's row under the entries.
func test_a_boss_name_covers_no_room_corridor_or_stub() -> void:
	var named := 0
	var in_key := 0
	for floor_id in ["floor_1", "seance_hotline"]:
		var def: FloorDef = load("res://data/floors/%s.tres" % floor_id)
		for seed_value in range(1, 7):
			for plan in [true, false]:
				var view := _items_view(def, seed_value)
				view.show_plan = plan
				view.paint_big(_paper_image())
				for patch: Rect2 in view.big_name_rects:
					named += 1
					if FloorMapView.KEY_RECT.encloses(patch):
						in_key += 1
						continue
					assert_true(FloorMapView.BIG_AREA.encloses(patch), "%s seed %d: %s" % [floor_id, seed_value, str(patch)])
					for room_id: int in view.big_room_rects:
						assert_eq(patch.intersection(view.big_room_rects[room_id]).get_area(), 0.0, "%s seed %d plan %s: a name over room %d" % [floor_id, seed_value, str(plan), room_id])
					for link: Rect2 in view.big_link_rects:
						assert_eq(patch.intersection(link).get_area(), 0.0, "%s seed %d plan %s: a name over a corridor %s" % [floor_id, seed_value, str(plan), str(link)])
					assert_eq(patch.intersection(view.big_stamp_rect).get_area(), 0.0, "and the stamp keeps off it")
				view.free()
	assert_true(named >= 24, "names were placed: %d" % named)
	assert_true(in_key < named, "most names sit by their rooms: %d of %d in the key" % [in_key, named])
	# Both of any floor's bosses fit the key's name row, each with its sign, measured in the game font.
	for file in DirAccess.get_files_at("res://data/floors"):
		if file.ends_with(".tres"):
			var names := FloorMapView.boss_names_for(load("res://data/floors/" + file))
			var icons: Array[String] = []
			var in_order: Array[String] = []
			for type: String in names:
				icons.append(RoomRules.door_icon(type))
				in_order.append(names[type])
			var texts := FloorMapView.key_name_row(icons, in_order)
			var width := 0.0
			for i in texts.size():
				assert_true(texts[i].begins_with("Boss: " if icons[i] == "B" else "Mini boss: "), texts[i])
				width += DoorSign.SIZE + 2.0 + _width(texts[i], HudStyle.SMALL) + 2.0 + FloorMapView.KEY_NAME_GAP
			assert_true(width <= FloorMapView.key_name_room(), "%s: %s" % [file, str(texts)])
	# A name's patch is the glyph rows only: no glyph of the font reaches below them.
	var fnt := FileAccess.get_file_as_string(HudStyle.FONT_PATH)
	var glyph := RegEx.create_from_string("height=(\\d+) xoffset=-?\\d+ yoffset=(-?\\d+)")
	for found in glyph.search_all(fnt):
		assert_true(int(found.get_string(1)) + int(found.get_string(2)) <= MapPaper.FONT_GLYPH, found.get_string())


# The Crossroads' smaller square sits so the middle of each side matches its cell's, where corridors run.
func test_the_crossroads_door_gaps_meet_their_corridors() -> void:
	var map := FloorMap.new()
	var start := _add(map, RoomLayout.TYPE_COMBAT, Vector2i(1, 1))
	var crossroads := _add(map, RoomLayout.TYPE_CROSSROADS, Vector2i(1, 0))
	crossroads.doors[Vector2i.DOWN] = start.id
	var progress := FloorProgress.new(map)
	progress.enter(crossroads.id)
	progress.enter(start.id)
	var view := FloorMapView.new()
	view.setup(map, progress, true, "The Records Basement")
	view.set_current(start.id)
	view.paint_big(_paper_image())
	var spacing := FloorMapView.big_spacing(map.bounds().size)
	var origin := FloorMapView.big_origin(map.bounds().size, spacing)
	var cell := FloorMapView.room_rect(FloorMapView.map_position(map, crossroads), origin, spacing)
	var small: Rect2 = view.big_room_rects[crossroads.id]
	assert_true(small.size.x < cell.size.x, "it is drawn smaller")
	for side: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var along := Vector2(absi(side.y), absi(side.x))
		assert_eq(MapPaper.edge_mid(small, side) * along, MapPaper.edge_mid(cell, side) * along, str(side))
	view.free()


# A crowded Floor Plan: a 3x3 floor, every room joined to its neighbours, the boss in the middle. The plan
# has no clear spot for the boss's name, so the key's spare row writes it: "Boss: <name>" right after the
# boss's sign, inside the key box, over no key entry.
func test_a_boss_name_with_no_room_on_the_plan_goes_to_the_key() -> void:
	var map := FloorMap.new()
	var grid := {}
	for y in 3:
		for x in 3:
			grid[Vector2i(x, y)] = _add(map, RoomLayout.TYPE_FLOOR_BOSS if Vector2i(x, y) == Vector2i(1, 1) else RoomLayout.TYPE_COMBAT, Vector2i(x, y))
	for cell: Vector2i in grid:
		for step: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN]:
			if grid.has(cell + step):
				map.join(grid[cell], grid[cell + step])
	var progress := FloorProgress.new(map)
	progress.enter(0)
	var view := FloorMapView.new()
	view.setup(map, progress, true, "The Records Basement")
	view.set_current(0)
	view.show_plan = true
	view.boss_names = {RoomLayout.TYPE_FLOOR_BOSS: "Regional Reaper"}
	var image := _paper_image()
	view.paint_big(image)
	assert_eq(view.big_name_rects.size(), 1)
	var patch: Rect2 = view.big_name_rects[0]
	assert_true(FloorMapView.KEY_RECT.encloses(patch), "in the key: %s" % str(patch))
	assert_eq(patch.size.x, ceilf(_width(FloorMapView.key_name_text("B", "Regional Reaper"), HudStyle.SMALL) + 2.0), "sized for \"Boss: Regional Reaper\"")
	assert_eq(FloorMapView.key_name_text("B", "Regional Reaper"), "Boss: Regional Reaper")
	# The boss's sign right before it, inked, inside the key box.
	var sign_box := Rect2(patch.position.x - DoorSign.SIZE - 2.0, patch.position.y, DoorSign.SIZE, DoorSign.SIZE)
	assert_true(FloorMapView.KEY_RECT.encloses(sign_box))
	var inked := 0
	for y in range(int(sign_box.position.y), int(sign_box.end.y)):
		for x in range(int(sign_box.position.x), int(sign_box.end.x)):
			if image.get_pixel(x, y).is_equal_approx(MapPaper.INK):
				inked += 1
	assert_true(inked >= 20, "the boss's sign in ink: %d px" % inked)
	# Over no entry: each entry's sign and label box on the rows above.
	var shown := FloorMapView.shown_ids(map, progress, false, true, true)
	var icons := FloorMapView.key_icons(map, progress, shown, FloorMapView.exit_stubs(map, progress, shown), true)
	assert_true(icons.has("B"), "the boss's own entry is there too")
	var column := FloorMapView.key_column_width()
	for i in icons.size():
		var entry := Rect2(FloorMapView.KEY_RECT.position + Vector2(FloorMapView.KEY_TITLE_WIDTH + (i % FloorMapView.KEY_COLUMNS) * column, 5.0 + floorf(i / float(FloorMapView.KEY_COLUMNS)) * FloorMapView.KEY_ROW_HEIGHT), Vector2(column, DoorSign.SIZE))
		assert_false(entry.intersects(patch) or entry.intersects(sign_box), "entry %s" % icons[i])
	view.free()


# --- the small map: a scrap of the same paper (playtest-9 note 2) ---

func _mini_view(map: FloorMap, progress: FloorProgress, current: int) -> FloorMapView:
	var view := FloorMapView.new()
	view.setup(map, progress, false, "The Records Basement")
	view.set_current(current)
	return view


# The colours of the dots painted on the small map, as MINI_DOTS letters.
func _dots_in(image: Image) -> Dictionary:
	var found := {}
	var area := Rect2i(FloorMapView.MINI_RECT)
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var c := image.get_pixel(x, y)
			for icon: String in FloorMapView.MINI_DOTS:
				if c.is_equal_approx(FloorMapView.MINI_DOTS[icon]):
					found[icon] = true
	return found


func test_the_small_map_is_a_paper_scrap_with_the_same_exit_stubs() -> void:
	var map := _cross_floor()
	var progress := FloorProgress.new(map)
	progress.enter(0)
	progress.enter(4)
	var view := _mini_view(map, progress, 0)
	var image := _paper_image()
	view.paint_mini(image)
	var scrap := FloorMapView.MINI_RECT
	assert_true(image.get_pixelv(Vector2i(scrap.position)).is_equal_approx(MapPaper.PAPER_EDGE), "the scrap's edge")
	assert_true(image.get_pixelv(Vector2i(scrap.position) + Vector2i(1, 1)).is_equal_approx(MapPaper.PAPER), "its paper")
	assert_eq(view.mini_room_rects.size(), 2, "the start and the item room, not the rooms behind the stubs")
	var start: Rect2 = view.mini_room_rects[0]
	var item: Rect2 = view.mini_room_rects[4]
	assert_true(image.get_pixelv(Vector2i(start.position)).is_equal_approx(MapPaper.STAMP), "the room he stands in, outlined in the stamp's red")
	assert_true(image.get_pixelv(Vector2i(item.position)).is_equal_approx(MapPaper.INK), "a walked room in ink")
	assert_true(image.get_pixelv(Vector2i(FloorMapView.mini_dot_rect(item).position)).is_equal_approx(FloorMapView.MINI_DOTS["I"]), "the item room's dot")
	assert_true(image.get_pixelv(Vector2i(FloorMapView.mini_dot_rect(start).position)).is_equal_approx(MapPaper.ROOM_FILL), "a plain fight room stays blank")
	var half := MapPaper.corridor_half(FloorMapView.room_size(FloorMapView.MINI_SPACING))
	var up := Vector2i(MapPaper.edge_mid(start, Vector2i.UP))
	assert_true(image.get_pixel(up.x - half, up.y - 1).is_equal_approx(MapPaper.INK), "the corridor between the walked rooms")
	assert_true(image.get_pixel(up.x, up.y).is_equal_approx(MapPaper.ROOM_FILL), "with a door gap in the room's edge")
	# The same stubs as the big map's: the shop's, ending in its dot, and a "?" for the fight room.
	var stubs := FloorMapView.exit_stubs(map, progress, FloorMapView.shown_ids(map, progress, false))
	assert_eq(stubs.size(), 2, str(stubs))
	for stub in stubs:
		var side: Vector2i = stub["side"]
		var dot := FloorMapView.mini_stub_dot(start, side)
		assert_true(image.get_pixelv(Vector2i(dot.position)).is_equal_approx(FloorMapView.MINI_DOTS[stub["icon"]]), "the %s stub's dot" % stub["icon"])
		var mid := Vector2i(MapPaper.edge_mid(start, side))
		var wall := mid + (Vector2i(0, -half) if side.x != 0 else Vector2i(-half, 0))
		assert_true(image.get_pixelv(wall).is_equal_approx(MapPaper.INK), "the %s stub's wall" % stub["icon"])
		assert_true(image.get_pixelv(wall + side).is_equal_approx(MapPaper.PAPER), "its wall dashed")
		assert_true(image.get_pixelv(mid - side).is_equal_approx(MapPaper.ROOM_FILL), "a door gap where it leaves")
	assert_eq(_dots_in(image).keys().size(), 3, "the item room's dot and two stubs' dots: %s" % str(_dots_in(image)))
	# The secret is not found: nothing at all in its cell.
	var origin := FloorMapView.mini_origin(FloorMapView.map_position(map, map.room(0)))
	var secret := Rect2i(FloorMapView.room_rect(FloorMapView.map_position(map, map.room(3)), origin, FloorMapView.MINI_SPACING))
	for y in range(secret.position.y, secret.end.y):
		for x in range(secret.position.x, secret.end.x):
			assert_true(image.get_pixel(x, y).is_equal_approx(MapPaper.PAPER), "the unfound secret's cell at %d,%d" % [x, y])
	view.free()


# The small map gives away no more than the big map's key does: a room's dot only for a mark the big map
# draws (drawn_sign), and a stub's dot only for a door he has seen.
func test_the_small_map_shows_only_what_is_drawn() -> void:
	var def: FloorDef = load("res://data/floors/floor_1.tres")
	var pool := RoomCatalog.load_valid(def.rooms_dir)
	var kept_quiet := 0
	for seed_value in 30:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var map := FloorBuilder.build_from_pool(rng, def, pool)
		var progress := FloorProgress.new(map)
		progress.enter(map.start_id)
		var stub_icons := {}
		for stub in FloorMapView.exit_stubs(map, progress, FloorMapView.shown_ids(map, progress, false)):
			stub_icons[stub["icon"]] = true
		var view := _mini_view(map, progress, map.start_id)
		var image := _paper_image()
		view.paint_mini(image)
		var dots := _dots_in(image)
		assert_eq(dots.keys().size(), stub_icons.keys().size(), "seed %d: %s against stubs %s" % [seed_value, str(dots), str(stub_icons)])
		for icon: String in stub_icons:
			assert_true(dots.has(icon), "seed %d: the %s stub's dot" % [seed_value, icon])
		for room in map.rooms:
			if room.room_type == RoomLayout.TYPE_SHOP and not stub_icons.has("$"):
				kept_quiet += 1
		# Under the Floor Plan, a room he never saw a door to is a pencil outline with no dot.
		view.show_plan = true
		image = _paper_image()
		view.paint_mini(image)
		var allowed := {}
		for room_id: int in view.mini_room_rects:
			var room := map.room(room_id)
			var mark := FloorMapView.drawn_sign(map, progress, room, false)
			allowed[mark] = true
			if mark.is_empty() or not FloorMapView.MINI_DOTS.has(mark):
				var spot := Vector2i(FloorMapView.mini_dot_rect(view.mini_room_rects[room_id]).position)
				var c := image.get_pixelv(spot)
				assert_true(c.is_equal_approx(MapPaper.PAPER) or c.is_equal_approx(MapPaper.ROOM_FILL), "seed %d: room %d keeps its middle blank" % [seed_value, room_id])
		for icon: String in _dots_in(image):
			assert_true(allowed.has(icon), "seed %d plan: a %s dot no room on the map draws" % [seed_value, icon])
		view.free()
	assert_true(kept_quiet > 0, "some floor had a shop the small map kept quiet about")


# A boss room the Fortune Teller's Card shows, beside a walked room: the door into it is a pencil
# corridor on the small map too (corridor_shown), with the boss's dot in it, not a stub.
func test_the_small_map_draws_the_door_into_a_boss_room_the_card_shows() -> void:
	var map := FloorMap.new()
	var start := _add(map, RoomLayout.TYPE_COMBAT, Vector2i(0, 0))
	var boss := _add(map, RoomLayout.TYPE_FLOOR_BOSS, Vector2i(1, 0))
	map.join(start, boss)
	var progress := FloorProgress.new(map)
	progress.enter(start.id)
	var view := _mini_view(map, progress, start.id)
	view.boss_names = {RoomLayout.TYPE_FLOOR_BOSS: "Regional Reaper"}
	var image := _paper_image()
	view.paint_mini(image)
	assert_true(view.mini_room_rects.has(boss.id), "the boss room is on the small map")
	var half := MapPaper.corridor_half(FloorMapView.room_size(FloorMapView.MINI_SPACING))
	var mid := Vector2i(MapPaper.edge_mid(view.mini_room_rects[start.id], Vector2i.RIGHT))
	assert_true(image.get_pixel(mid.x + 1, mid.y - half).is_equal_approx(MapPaper.PENCIL), "the corridor's top wall")
	assert_true(image.get_pixel(mid.x + 1, mid.y + half - 1).is_equal_approx(MapPaper.PENCIL), "the corridor's bottom wall")
	assert_true(image.get_pixel(mid.x + 2, mid.y - half).is_equal_approx(MapPaper.PENCIL), "solid, not a dashed stub")
	var far := Vector2i(MapPaper.edge_mid(view.mini_room_rects[boss.id], Vector2i.LEFT))
	assert_true(image.get_pixel(far.x, far.y).is_equal_approx(MapPaper.PAPER), "a door gap in the boss room")
	var dot := Vector2i(FloorMapView.mini_dot_rect(view.mini_room_rects[boss.id]).position)
	assert_true(image.get_pixelv(dot).is_equal_approx(FloorMapView.MINI_DOTS["B"]), "the boss's dot")
	view.free()


func test_no_mark_on_the_small_map_reads_as_a_cross() -> void:
	var def: FloorDef = load("res://data/floors/floor_1.tres")
	for seed_value in [1, 2, 3]:
		for with_items in [false, true]:
			var rng := RandomNumberGenerator.new()
			rng.seed = seed_value
			var map := FloorBuilder.build_from_pool(rng, def, RoomCatalog.load_valid(def.rooms_dir))
			var progress := FloorProgress.new(map)
			for id: int in map.main_path.slice(0, 4):
				progress.enter(id)
			var view := _mini_view(map, progress, map.main_path[1])
			if with_items:
				view.show_secrets = true
				view.show_plan = true
				view.boss_names = FloorMapView.boss_names_for(def)
			var image := _paper_image()
			view.paint_mini(image)
			assert_true(view.mini_room_rects.size() >= 4, "seed %d: rooms were drawn" % seed_value)
			var crossings := _crossings(image, FloorMapView.MINI_RECT)
			assert_true(crossings.is_empty(), "seed %d items %s: %s" % [seed_value, str(with_items), str(crossings.slice(0, 4))])
			view.free()


# What the small map leaves for a mark laid in a room later (Task 20's pickups left behind): each drawn
# room's box, all inside the scrap, and the dot's spot in its middle, clear of each corner inside the edge.
func test_the_small_map_tells_where_it_drew_each_room() -> void:
	var map := _cross_floor()
	var progress := FloorProgress.new(map)
	for id in [0, 1, 2, 4]:
		progress.enter(id)
	var view := _mini_view(map, progress, 0)
	view.paint_mini(_paper_image())
	assert_eq(view.mini_room_rects.size(), 4)
	var width := MapPaper.outline_width(FloorMapView.room_size(FloorMapView.MINI_SPACING))
	for room_id: int in view.mini_room_rects:
		var rect: Rect2 = view.mini_room_rects[room_id]
		assert_true(FloorMapView.mini_area().encloses(rect), str(rect))
		var inside := rect.grow(-float(width))
		var dot := FloorMapView.mini_dot_rect(rect)
		assert_true(inside.encloses(dot), "the dot inside room %d's edge" % room_id)
		for corner: Vector2 in [inside.position, Vector2(inside.end.x - 2.0, inside.position.y), Vector2(inside.position.x, inside.end.y - 2.0), inside.end - Vector2(2, 2)]:
			assert_false(dot.grow(1.0).intersects(Rect2(corner, Vector2(2, 2))), "a 2 px corner of room %d stays clear" % room_id)
	view.free()
