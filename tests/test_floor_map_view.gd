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
		assert_eq(FloorMapView.MINI_DOTS.has(icon), DoorSign.has_sign(icon), "%s (%s)" % [room_type, icon])
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


# A 4 px dot at 1x is told apart only by a clear difference: every two dots, and each dot against the
# lines and grounds it sits on or beside (the stamp's red outlines the current room), are at least 20
# apart in CIEDE2000. Godot has no CIELAB, so the test computes it (sRGB, D65), checked first against
# published reference pairs.
const MIN_DOT_DISTANCE := 20.0


func test_every_two_dots_are_far_apart_in_ciede2000() -> void:
	# Reference pairs from Sharma, Wu and Dalal's CIEDE2000 test data.
	assert_near(_de00_lab(Vector3(50.0, 2.6772, -79.7751), Vector3(50.0, 0.0, -82.7485)), 2.0425, "reference pair 1")
	assert_near(_de00_lab(Vector3(50.0, 2.5, 0.0), Vector3(73.0, 25.0, -18.0)), 27.1492, "reference pair 7")
	assert_near(_de00_lab(Vector3(2.0776, 0.0795, -1.1350), Vector3(0.9033, -0.0636, -0.5514)), 0.9082, "reference pair 34")
	var icons: Array = FloorMapView.MINI_DOTS.keys()
	var nearest := INF
	for i in icons.size():
		var a: Color = FloorMapView.MINI_DOTS[icons[i]]
		for j in range(i + 1, icons.size()):
			var d := _de00(a, FloorMapView.MINI_DOTS[icons[j]])
			nearest = minf(nearest, d)
			assert_true(d >= MIN_DOT_DISTANCE, "%s and %s: %.1f" % [icons[i], icons[j], d])
		for line: Color in [MapPaper.STAMP, MapPaper.INK, MapPaper.PENCIL, MapPaper.PAPER, MapPaper.ROOM_FILL]:
			var d := _de00(a, line)
			assert_true(d >= MIN_DOT_DISTANCE, "%s against %s: %.1f" % [icons[i], line.to_html(false), d])
	assert_true(nearest < 100.0, "pairs were measured")


func _lab(c: Color) -> Vector3:
	var lin: Array[float] = []
	for v: float in [c.r, c.g, c.b]:
		lin.append(v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4))
	var x := (0.4124 * lin[0] + 0.3576 * lin[1] + 0.1805 * lin[2]) / 0.95047
	var y := 0.2126 * lin[0] + 0.7152 * lin[1] + 0.0722 * lin[2]
	var z := (0.0193 * lin[0] + 0.1192 * lin[1] + 0.9505 * lin[2]) / 1.08883
	var f := func(t: float) -> float: return pow(t, 1.0 / 3.0) if t > 0.008856 else 7.787 * t + 16.0 / 116.0
	var fy: float = f.call(y)
	return Vector3(116.0 * fy - 16.0, 500.0 * (float(f.call(x)) - fy), 200.0 * (fy - float(f.call(z))))


func _de00(a: Color, b: Color) -> float:
	return _de00_lab(_lab(a), _lab(b))


func _de00_lab(p: Vector3, q: Vector3) -> float:
	var c1 := Vector2(p.y, p.z).length()
	var c2 := Vector2(q.y, q.z).length()
	var cb := (c1 + c2) / 2.0
	var g := 0.5 * (1.0 - sqrt(pow(cb, 7.0) / (pow(cb, 7.0) + pow(25.0, 7.0))))
	var a1 := (1.0 + g) * p.y
	var a2 := (1.0 + g) * q.y
	var c1p := Vector2(a1, p.z).length()
	var c2p := Vector2(a2, q.z).length()
	var h1 := fposmod(rad_to_deg(atan2(p.z, a1)), 360.0) if c1p > 0.0 else 0.0
	var h2 := fposmod(rad_to_deg(atan2(q.z, a2)), 360.0) if c2p > 0.0 else 0.0
	var dl := q.x - p.x
	var dc := c2p - c1p
	var dh := 0.0
	if c1p * c2p != 0.0:
		dh = h2 - h1
		if dh > 180.0:
			dh -= 360.0
		elif dh < -180.0:
			dh += 360.0
	var dhh := 2.0 * sqrt(c1p * c2p) * sin(deg_to_rad(dh) / 2.0)
	var lb := (p.x + q.x) / 2.0
	var cbp := (c1p + c2p) / 2.0
	var hb := h1 + h2
	if c1p * c2p != 0.0:
		if absf(h1 - h2) <= 180.0:
			hb = (h1 + h2) / 2.0
		elif h1 + h2 < 360.0:
			hb = (h1 + h2 + 360.0) / 2.0
		else:
			hb = (h1 + h2 - 360.0) / 2.0
	var t := 1.0 - 0.17 * cos(deg_to_rad(hb - 30.0)) + 0.24 * cos(deg_to_rad(2.0 * hb)) + 0.32 * cos(deg_to_rad(3.0 * hb + 6.0)) - 0.20 * cos(deg_to_rad(4.0 * hb - 63.0))
	var dtheta := 30.0 * exp(-pow((hb - 275.0) / 25.0, 2.0))
	var rc := 2.0 * sqrt(pow(cbp, 7.0) / (pow(cbp, 7.0) + pow(25.0, 7.0)))
	var sl := 1.0 + 0.015 * pow(lb - 50.0, 2.0) / sqrt(20.0 + pow(lb - 50.0, 2.0))
	var sc := 1.0 + 0.045 * cbp
	var sh := 1.0 + 0.015 * cbp * t
	var rt := -sin(deg_to_rad(2.0 * dtheta)) * rc
	return sqrt(pow(dl / sl, 2.0) + pow(dc / sc, 2.0) + pow(dhh / sh, 2.0) + rt * (dc / sc) * (dhh / sh))


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


# --- fix round 1 ---

# A Crossroads with a door on every side. Drawn as a smaller square on the small map, its corridors were
# as wide as it, and the hub's outline read as a plus. It is a whole room there now, with its own dot,
# and the shape painted round it is a room with doors: each corridor at most half as wide as the room
# on its side and shorter than half its height, so no two arms of equal length run through it.
func test_a_four_door_crossroads_on_the_small_map_is_no_plus() -> void:
	var map := FloorMap.new()
	var hub := _add(map, RoomLayout.TYPE_CROSSROADS, Vector2i(1, 1))
	for cell: Vector2i in [Vector2i(1, 0), Vector2i(2, 1), Vector2i(1, 2), Vector2i(0, 1)]:
		map.join(hub, _add(map, RoomLayout.TYPE_ITEM, cell))
	var progress := FloorProgress.new(map)
	for room in map.rooms:
		progress.enter(room.id)
	var view := _mini_view(map, progress, 1)
	var image := _paper_image()
	view.paint_mini(image)
	var rect: Rect2 = view.mini_room_rects[hub.id]
	var room := FloorMapView.room_size(FloorMapView.MINI_SPACING)
	assert_eq(rect.size, room, "a whole room, not a smaller square")
	assert_true(image.get_pixelv(Vector2i(FloorMapView.mini_dot_rect(rect).position)).is_equal_approx(FloorMapView.MINI_DOTS["+"]), "its own dot")
	var gap := FloorMapView.MINI_SPACING - room
	for side: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
		# Across the gap's middle on this side: the corridor's span, from its first marked pixel to its last.
		var length := int(gap.y if side.y != 0 else gap.x)
		var at := Vector2i(MapPaper.edge_mid(rect, side)) + side * (length / 2 + (0 if side.x > 0 or side.y > 0 else 1))
		var across := Vector2i(absi(side.y), absi(side.x))
		var first := 999
		var last := -999
		for k in range(-10, 11):
			var p := at + across * k
			if not image.get_pixelv(p).is_equal_approx(MapPaper.PAPER):
				first = mini(first, k)
				last = maxi(last, k)
		var width := last - first + 1
		var hub_side := rect.size.x if side.y != 0 else rect.size.y
		assert_true(width >= 2 and width * 2 <= hub_side, "%s: a corridor %d px wide against the room's %d" % [str(side), width, hub_side])
		assert_true(length * 2 < minf(rect.size.x, rect.size.y), "%s: a corridor %d px long" % [str(side), length])
	assert_true(_crossings(image, FloorMapView.MINI_RECT).is_empty())
	view.free()


# A stub into a Crossroads ends in the Crossroads' own dot, as the big map ends it in its sign.
func test_a_stub_into_a_crossroads_ends_in_its_dot() -> void:
	var map := FloorMap.new()
	var start := _add(map, RoomLayout.TYPE_COMBAT, Vector2i(0, 0))
	var hub := _add(map, RoomLayout.TYPE_CROSSROADS, Vector2i(1, 0))
	map.join(start, hub)
	var progress := FloorProgress.new(map)
	progress.enter(start.id)
	var stubs := FloorMapView.exit_stubs(map, progress, FloorMapView.shown_ids(map, progress, false))
	assert_eq(stubs.size(), 1)
	assert_eq(stubs[0]["icon"], "+")
	var view := _mini_view(map, progress, start.id)
	var image := _paper_image()
	view.paint_mini(image)
	var dot := FloorMapView.mini_stub_dot(view.mini_room_rects[start.id], Vector2i.RIGHT)
	assert_true(image.get_pixelv(Vector2i(dot.position)).is_equal_approx(FloorMapView.MINI_DOTS["+"]), "the Crossroads' dot, not the unknown's")
	view.free()


# The dots have a key: each big-map key entry with a dot shows a swatch of it between its sign and its
# label. A plain fight room has no dot and no swatch.
func test_the_big_maps_key_shows_each_dot() -> void:
	var map := _cross_floor()
	var progress := FloorProgress.new(map)
	progress.enter(0)
	var view := FloorMapView.new()
	view.setup(map, progress, true, "The Records Basement")
	view.set_current(0)
	var image := _paper_image()
	view.paint_big(image)
	var shown := FloorMapView.shown_ids(map, progress, false)
	var icons := FloorMapView.key_icons(map, progress, shown, FloorMapView.exit_stubs(map, progress, shown), false)
	var swatches := 0
	for i in icons.size():
		var at := FloorMapView.key_entry_at(i)
		var swatch := FloorMapView.key_swatch_rect(at)
		assert_true(FloorMapView.KEY_RECT.encloses(swatch))
		assert_false(swatch.intersects(Rect2(at, Vector2(DoorSign.SIZE, DoorSign.SIZE))), "clear of the sign")
		assert_true(swatch.end.x < at.x + DoorSign.SIZE + 3.0 + FloorMapView.KEY_SWATCH_ROOM, "clear of the label")
		var c := image.get_pixelv(Vector2i(swatch.position))
		if FloorMapView.MINI_DOTS.has(icons[i]):
			assert_true(c.is_equal_approx(FloorMapView.MINI_DOTS[icons[i]]), "the %s swatch" % icons[i])
			swatches += 1
		else:
			assert_true(c.is_equal_approx(MapPaper.PAPER), "no swatch for %s" % icons[i])
	assert_eq(swatches, 3, "item, shop and unknown: %s" % str(icons))
	view.free()


# --- pickups left behind (the user, 2026-11-14) ---

const LeftBank := preload("res://tests/support/stub_bank.gd")


# A plain room's view, cleared, built from a saved state when one is given (as a resumed room is).
func _plain_view(run: RunState, player: Player, restore := {}) -> RoomView:
	var room := FloorRoom.new()
	var layout := RoomLayout.new()
	layout.room_type = RoomLayout.TYPE_COMBAT
	var rows := ["####################"]
	for y in range(1, 10):
		rows.append("#..................#")
	rows.append("####################")
	layout.rows = PackedStringArray(rows)
	room.layout = layout
	room.room_type = RoomLayout.TYPE_COMBAT
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var view := RoomView.new()
	view.setup(room, null, load("res://data/floors/floor_1.tres"), run, player, rng, null, null)
	view.restore = restore
	view._ready()
	return view


# Room ids to what stands for each room's saved state, as the floor scene keeps it: the room itself (a
# RoomView) while it is kept, or the checkpoint's copy of it (a Dictionary).
func _state_of(room_id: int, rooms: Dictionary) -> Dictionary:
	var source: Variant = rooms.get(room_id)
	if source is RoomView:
		return (source as RoomView).snapshot()
	return source if source is Dictionary else {}


# _cross_floor with the start walked. Room 0 (the start) and room 1 (the shop, not walked into) each have
# a plain room view standing for their state.
func _left_rig() -> Dictionary:
	InputSetup.ensure()
	var map := _cross_floor()
	var progress := FloorProgress.new(map)
	progress.enter(0)
	var run := ItemKit.new().make_run()
	var player := Player.new()
	player.setup(run)
	var rooms := {0: _plain_view(run, player), 1: _plain_view(run, player)}
	progress.room_state = _state_of.bind(rooms)
	return {"map": map, "progress": progress, "run": run, "player": player, "rooms": rooms}


func _free_left_rig(rig: Dictionary) -> void:
	for source in (rig["rooms"] as Dictionary).values():
		if source is RoomView:
			source.free()
	rig["player"].free()


func _kinds(kinds: Array) -> Array[String]:
	var out: Array[String] = []
	for kind: String in kinds:
		out.append(kind)
	return out


func _first_active() -> ItemDef:
	for item in Content.items():
		if item.is_active():
			return item
	return null


func _first_passive() -> ItemDef:
	for item in Content.items():
		if not item.is_active() and not item.cursed:
			return item
	return null


# One of every kind the maps mark, laid in the view, plus the things they never mark.
func _lay_everything(view: RoomView) -> void:
	view._add_shop_entry(Vector2(300, 60), {"kind": ShopRules.KIND_ITEM, "price": 10, "item": _first_passive(), "potion": null, "half": false})
	view._add_shop_entry(Vector2(340, 60), {"kind": ShopRules.KIND_HEAL, "price": 5, "item": null, "potion": null, "half": false})
	view._create_chest(Vector2i(14, 6), ChestRules.LOCKED)
	view._add_recipe_pickup(Vector2(380, 100), _first_passive())
	view._add_heal(Vector2(60, 60), 2)
	view._drop_consumable(Vector2(100, 60), RoomRules.DROP_BOMB)
	view._drop_consumable(Vector2(140, 60), RoomRules.DROP_KEY)
	view.drop_reel(Vector2(180, 140), Eras.FOOTBALL, func() -> void: pass)
	view.drop_active(_first_active(), 2, Vector2(60, 220))
	view._add_item_pickup(Vector2(220, 220), _first_passive())
	view._drop_potion(Vector2(260, 220), Content.potion("swift_tea"))


func test_a_potion_left_in_a_walked_room_is_listed_until_taken() -> void:
	var rig := _left_rig()
	var map: FloorMap = rig["map"]
	var progress: FloorProgress = rig["progress"]
	var run: RunState = rig["run"]
	var view: RoomView = rig["rooms"][0]
	assert_eq(FloorMapView.leftovers(map, progress), {}, "nothing left yet")
	var tea := Content.potion("swift_tea")
	var lying := view._drop_potion(Vector2(100, 100), tea)
	assert_eq(FloorMapView.leftovers(map, progress), {0: _kinds(["potion"])}, "a potion lying in a walked room")
	lying.collect()
	assert_eq(run.potion, tea)
	assert_eq(FloorMapView.leftovers(map, progress), {}, "taking it takes it off the map")
	# A swap lays the carried potion where the new one lay, and the map shows it at once.
	view._drop_potion(Vector2(140, 100), Content.potion("healing_tonic")).collect()
	assert_eq(FloorMapView.leftovers(map, progress), {0: _kinds(["potion"])}, "the potion swapped out is left")
	# The shop is not walked into: what lies there is not listed until he has been in.
	(rig["rooms"][1] as RoomView)._drop_potion(Vector2(100, 100), tea)
	assert_false(FloorMapView.leftovers(map, progress).has(1), "a room not walked into lists nothing")
	progress.enter(1)
	assert_eq(FloorMapView.leftovers(map, progress).get(1), _kinds(["potion"]), "once walked into, it is")
	_free_left_rig(rig)


func test_only_what_he_can_come_back_for_is_a_leftover() -> void:
	var rig := _left_rig()
	var map: FloorMap = rig["map"]
	var progress: FloorProgress = rig["progress"]
	var view: RoomView = rig["rooms"][0]
	view._add_shop_entry(Vector2(300, 60), {"kind": ShopRules.KIND_ITEM, "price": 10, "item": _first_passive(), "potion": null, "half": false})
	view._create_chest(Vector2i(14, 6), ChestRules.LOCKED)
	view._add_recipe_pickup(Vector2(380, 100), _first_passive())
	view._drop_coin(Vector2(200, 100), 5)
	assert_eq(FloorMapView.leftovers(map, progress), {}, "wares, a closed chest, a recipe and coins are not leftovers")
	_lay_everything(view)
	assert_eq(FloorMapView.leftovers(map, progress), {0: _kinds(FloorMapView.LEFTOVER_ORDER)}, "each kind once, in the map's order")
	assert_eq(FloorMapView.LEFTOVER_ORDER, ["potion", "item", "reel", "key", "bomb", "heal"])
	# Taking every one of a kind takes the kind off the map.
	for child in view.get_children():
		if child is Pickup and child.carry_kind == RoomRules.DROP_KEY:
			child.collect()
	assert_eq(FloorMapView.leftovers(map, progress)[0], _kinds(["potion", "item", "reel", "bomb", "heal"]), "the Slip was taken")
	_free_left_rig(rig)


# A saved reel of an era this build does not know is left out on resume, as a held one is.
func test_a_saved_reel_of_an_unknown_era_is_not_laid_back() -> void:
	InputSetup.ensure()
	var run := ItemKit.new().make_run()
	var player := Player.new()
	player.setup(run)
	var shot := {"cleared": true, "keep": [
		{"kind": RoomView.KEEP_REEL, "era": "no_such_era", "cell": [3, 3]},
		{"kind": RoomView.KEEP_REEL, "era": Eras.FOOTBALL, "cell": [6, 3]},
	]}
	var view := _plain_view(run, player, shot)
	var reels: Array = []
	for child in view.get_children():
		if child is Pickup and child.art_id == RoomView.ART_REEL:
			reels.append(child.get_meta(RoomView.KEEP)["era"])
	assert_eq(reels, [Eras.FOOTBALL], "only the known era's reel")
	view.free()
	player.free()


# Save and Quit, then resume: before he walks back in, the checkpoint's copy of the room lists the same
# leftovers as the room did, and the room rebuilt from it when he walks in lays every one out again.
func test_a_resumed_checkpoint_gives_the_same_leftovers() -> void:
	var rig := _left_rig()
	var map: FloorMap = rig["map"]
	var progress: FloorProgress = rig["progress"]
	var view: RoomView = rig["rooms"][0]
	_lay_everything(view)
	var before := FloorMapView.leftovers(map, progress)
	assert_eq(before.get(0), _kinds(FloorMapView.LEFTOVER_ORDER))
	var shot: Dictionary = JSON.parse_string(JSON.stringify(view.snapshot()))
	var rooms: Dictionary = rig["rooms"]
	rooms[0] = shot
	assert_eq(FloorMapView.leftovers(map, progress), before, "the checkpoint's copy lists the same")
	var again := _plain_view(rig["run"], rig["player"], shot)
	var played: Array[String] = []
	again.reel_taker = func(era: String) -> void: played.append(era)
	rooms[0] = again
	assert_eq(FloorMapView.leftovers(map, progress), before, "the room rebuilt from it lists the same")
	assert_eq(again.snapshot()["keep"].size(), shot["keep"].size(), "everything kept came back")
	for child in again.get_children():
		if child is Pickup and child.art_id == RoomView.ART_REEL:
			child.collect()
	assert_eq(played, [Eras.FOOTBALL] as Array[String], "the reel laid back is taken as the kept rule's reel")
	var heal_back := false
	for child in again.get_children():
		if child is Pickup and child.carry_kind == RoomRules.DROP_HEAL:
			heal_back = child.carry_amount == 2
	assert_true(heal_back, "a heal comes back with its pills")
	# The rig frees the views it holds now (the rebuilt room); the room before the save goes here.
	view.free()
	_free_left_rig(rig)


# The floor scene hands the maps its rooms' saved state: the kept room, else the checkpoint's copy.
func test_the_floor_scene_hands_the_maps_its_rooms_state() -> void:
	var scene := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
	assert_eq(scene.count("FloorProgress.new("), 1, "every floor's progress is made by _new_progress")
	assert_true(scene.count("_progress = _new_progress(") >= 4, "the start, a resume, a new floor and a landing")
	assert_true(scene.contains("progress.room_state = _room_state"))
	var state := scene.substr(scene.find("func _room_state("), 300)
	assert_true(state.contains("view.snapshot()") and state.contains("_restored.get(room_id"), state)
	assert_true(scene.contains("view.reel_taker = _rules.take_reel"), "a reel laid back on resume is the keeper's")
	assert_true(scene.contains("view.child_entered_tree.connect(_on_room_child_changed)"), "the small map redraws as one is laid down")
	assert_true(scene.contains("view.child_exiting_tree.connect(_on_room_child_changed)"), "and as one is taken")


func _turned(rows: Array) -> Array:
	var width := 0
	for row: String in rows:
		width = maxi(width, row.length())
	var turned: Array = []
	for x in width:
		var column := ""
		for row: String in rows:
			column += row[x] if x < row.length() else "."
		turned.append(column)
	return turned


# Each picture is small ink line art (ink, pencil or bare), fits the icon box, differs from the others and
# reads as no cross, upright or on its side, by test_art_direction's silhouette check.
func test_every_leftover_icon_is_small_ink_and_no_cross() -> void:
	var checker = load("res://tests/test_art_direction.gd").new()
	var seen := {}
	var marks: Array = FloorMapView.LEFTOVER_ORDER.duplicate()
	marks.append(FloorMapView.LEFTOVER_MORE)
	for mark: String in marks:
		assert_true(FloorMapView.LEFTOVER_ICONS.has(mark), mark)
		var rows: Array = FloorMapView.LEFTOVER_ICONS[mark]
		assert_true(rows.size() <= FloorMapView.LEFTOVER_ICON.y, "%s is %d tall" % [mark, rows.size()])
		var inked := 0
		for row: String in rows:
			assert_true(row.length() <= FloorMapView.LEFTOVER_ICON.x, "%s: %s" % [mark, row])
			for c in row:
				assert_true(c in ["x", "s", "."], "%s: %s" % [mark, c])
				if c == "x":
					inked += 1
		assert_true(inked >= 3, "%s has ink" % mark)
		assert_false(seen.has(str(rows)), "%s has a picture of its own" % mark)
		seen[str(rows)] = true
		assert_false(checker._reads_as_a_cross(rows), "%s reads as a cross" % mark)
		assert_false(checker._reads_as_a_cross(_turned(rows)), "%s on its side reads as a cross" % mark)
	for kind: String in FloorMapView.LEFTOVER_ORDER:
		assert_true(FloorMapView.LEFTOVER_LABELS.has(kind), kind)
	# At 1x the potion and the Thermos are told apart by their outline: the Thermos is a narrower cylinder
	# with straight sides (every row the same width), the potion a wider flask.
	var thermos: Array = FloorMapView.LEFTOVER_ICONS["bomb"]
	var potion: Array = FloorMapView.LEFTOVER_ICONS["potion"]
	for row: String in thermos:
		assert_eq(checker._extent(row), [0, (thermos[0] as String).length() - 1], "the Thermos row %s is straight-sided" % row)
	assert_true((thermos[0] as String).length() < (potion[3] as String).length(), "narrower than the potion's belly")


# Four icons fit every room box the big map draws, for every floor extent its grid allows: inside the
# outline with a pixel clear, a pixel clear of the sign's spot and of each other, and off the corners
# the stamp presses on.
func test_four_leftover_icons_fit_every_room_box_the_big_map_draws() -> void:
	var sizes := {}
	var grid := Vector2i.ZERO
	for file in DirAccess.get_files_at("res://data/floors"):
		if file.ends_with(".tres"):
			var size: Vector2i = (load("res://data/floors/" + file) as FloorDef).grid_size
			grid = Vector2i(maxi(grid.x, size.x), maxi(grid.y, size.y))
	for w in range(1, grid.x + 1):
		for h in range(1, grid.y + 1):
			var room := FloorMapView.room_size(FloorMapView.big_spacing(Vector2i(w, h)))
			var rect := Rect2(Vector2(100, 80), room)
			sizes[str(room)] = true
			var slots := FloorMapView.leftover_slots(rect, room)
			assert_eq(slots.size(), FloorMapView.LEFTOVER_SLOTS, "a %s room" % str(room))
			var inside := rect.grow(-float(MapPaper.outline_width(room) + 1))
			var sign_spot := FloorMapView.room_sign_rect(rect, room)
			var o := FloorMapView.STAMP_OVERLAP
			var corners: Array[Rect2] = [Rect2(rect.position, Vector2(o, o)), Rect2(rect.end.x - o, rect.position.y, o, o),
					Rect2(rect.position.x, rect.end.y - o, o, o), Rect2(rect.end - Vector2(o, o), Vector2(o, o))]
			for i in slots.size():
				var slot: Rect2 = slots[i]
				assert_eq(slot.size, FloorMapView.LEFTOVER_ICON)
				assert_true(inside.encloses(slot), "%s slot %d %s inside %s" % [str(room), i, str(slot), str(inside)])
				assert_false(slot.intersects(sign_spot.grow(1.0)), "%s slot %d clear of the sign" % [str(room), i])
				for corner in corners:
					assert_false(slot.intersects(corner), "%s slot %d off the stamp's corner" % [str(room), i])
				for j in range(i + 1, slots.size()):
					assert_false(slot.grow(1.0).intersects(slots[j]), "%s slots %d and %d apart" % [str(room), i, j])
	assert_true(sizes.size() >= 4, "room sizes tested: %s" % str(sizes.keys()))


# Three rooms in a row, all walked, standing in the first; the third's saved state as given.
func _row_view(states: Dictionary, is_big := true) -> FloorMapView:
	var map := FloorMap.new()
	var a := _add(map, RoomLayout.TYPE_COMBAT, Vector2i(0, 0))
	var b := _add(map, RoomLayout.TYPE_ITEM, Vector2i(1, 0))
	var c := _add(map, RoomLayout.TYPE_COMBAT, Vector2i(2, 0))
	map.join(a, b)
	map.join(b, c)
	var progress := FloorProgress.new(map)
	for room in map.rooms:
		progress.enter(room.id)
	progress.room_state = _state_of.bind(states)
	var view := FloorMapView.new()
	view.setup(map, progress, is_big, "The Records Basement")
	view.set_current(a.id)
	return view


func _kept(kinds: Array) -> Dictionary:
	var keep := []
	for kind: String in kinds:
		match kind:
			"potion":
				keep.append({"kind": RoomView.KEEP_POTION, "id": "swift_tea", "cell": [2, 2]})
			"item":
				keep.append({"kind": RoomView.KEEP_ITEM, "id": _first_passive().id, "cell": [3, 2]})
			"reel":
				keep.append({"kind": RoomView.KEEP_REEL, "era": Eras.FOOTBALL, "cell": [4, 2]})
			"key", "bomb":
				keep.append({"kind": RoomView.KEEP_DROP, "drop": kind, "cell": [5, 2]})
			"heal":
				keep.append({"kind": RoomView.KEEP_DROP, "drop": RoomRules.DROP_HEAL, "amount": 2, "cell": [6, 2]})
	keep.append({"kind": RoomView.KEEP_CHEST, "chest": ChestRules.LOCKED, "cell": [7, 2]})
	return {"cleared": true, "keep": keep}


func _ink_counts(image: Image, box: Rect2) -> Vector2i:
	var counts := Vector2i.ZERO
	var area := Rect2i(box)
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var c := image.get_pixel(x, y)
			if c.is_equal_approx(MapPaper.INK):
				counts.x += 1
			elif c.is_equal_approx(MapPaper.PENCIL):
				counts.y += 1
	return counts


func _picture_counts(mark: String) -> Vector2i:
	var counts := Vector2i.ZERO
	for row: String in FloorMapView.LEFTOVER_ICONS[mark]:
		counts += Vector2i(row.count("x"), row.count("s"))
	return counts


# The big map draws each kind's picture in its own slot of the walked room's box, in the map's order.
# Nothing else on the plan changes: not the room's sign, the stamp, a corridor or a stub. The key gains
# its "Left here" line only when some room has leftovers.
func test_the_big_map_draws_each_kind_left_in_a_walked_room() -> void:
	var bare := _row_view({2: {"cleared": true, "keep": []}})
	var plain := _paper_image()
	bare.paint_big(plain)
	var none := _row_view({})
	var unmarked := _paper_image()
	none.paint_big(unmarked)
	assert_eq(plain.get_data(), unmarked.get_data(), "no leftovers, no change anywhere (the key too)")
	var view := _row_view({2: _kept(["heal", "potion", "key"])})
	var image := _paper_image()
	view.paint_big(image)
	assert_eq(view.big_stamp_rect, bare.big_stamp_rect, "the stamp stays put")
	var spacing := FloorMapView.big_spacing(view._map.bounds().size)
	var room := FloorMapView.room_size(spacing)
	var slots := FloorMapView.leftover_slots(view.big_room_rects[2], room)
	var marks := ["potion", "key", "heal"]
	for i in marks.size():
		var slot: Rect2 = slots[i]
		assert_eq(_ink_counts(image, slot), _picture_counts(marks[i]), "slot %d holds the %s" % [i, marks[i]])
	assert_eq(_ink_counts(image, slots[3]), Vector2i.ZERO, "the fourth slot is empty")
	# Every changed pixel on the plan is inside a slot; under it, only the key changed.
	var changed_in_key := 0
	for y in 360:
		for x in 640:
			if image.get_pixel(x, y).is_equal_approx(plain.get_pixel(x, y)):
				continue
			var p := Vector2(x, y) + Vector2(0.5, 0.5)
			if FloorMapView.KEY_RECT.has_point(p):
				changed_in_key += 1
				continue
			var in_slot := false
			for slot: Rect2 in slots:
				in_slot = in_slot or slot.has_point(p)
			assert_true(in_slot, "a pixel changed at %d,%d outside the icons" % [x, y])
	assert_true(changed_in_key >= _picture_counts("potion").x, "the key's Left here line draws its icons: %d" % changed_in_key)
	var crossings := _crossings(image)
	assert_true(crossings.is_empty(), str(crossings.slice(0, 4)))
	for v: FloorMapView in [bare, none, view]:
		v.free()


# With more kinds than slots, the last slot holds "..." (a plus would read as a cross).
func test_a_room_with_more_kinds_than_slots_ends_in_dots() -> void:
	var view := _row_view({2: _kept(FloorMapView.LEFTOVER_ORDER)})
	var image := _paper_image()
	view.paint_big(image)
	var slots := FloorMapView.leftover_slots(view.big_room_rects[2], FloorMapView.room_size(FloorMapView.big_spacing(view._map.bounds().size)))
	var shown := FloorMapView.leftover_marks(_kinds(FloorMapView.LEFTOVER_ORDER), slots.size())
	assert_eq(shown, _kinds(["potion", "item", "reel", FloorMapView.LEFTOVER_MORE]))
	for i in shown.size():
		assert_eq(_ink_counts(image, slots[i]), _picture_counts(shown[i]), "slot %d: %s" % [i, shown[i]])
	assert_eq(FloorMapView.leftover_marks(_kinds(["potion", "item", "reel", "key"]), 4), _kinds(["potion", "item", "reel", "key"]), "four fit as they are")
	assert_true(_crossings(image).is_empty())
	view.free()


# The key's Left here line: its words and icons fit beside whatever entries the key holds, and it takes
# the row a boss name would otherwise borrow.
func test_the_keys_left_here_line_fits_beside_any_entries() -> void:
	var all := _kinds(FloorMapView.LEFTOVER_ORDER)
	var width := FloorMapView.leftover_line_width(all)
	var measured := _width(FloorMapView.LEFTOVER_TITLE, HudStyle.SMALL)
	for kind: String in all:
		measured += _width(FloorMapView.LEFTOVER_LABELS[kind], HudStyle.SMALL)
	assert_true(width > measured, "the line is measured in the game font: %.0f" % width)
	for entries in range(0, FloorMapView.KEY_ORDER.size() + 1):
		var at := FloorMapView.leftover_line_at(entries)
		var line := Rect2(at, Vector2(width, DoorSign.SIZE))
		assert_true(FloorMapView.KEY_RECT.grow(-2.0).encloses(line), "%d entries: %s" % [entries, str(line)])
		for i in entries:
			var entry := Rect2(FloorMapView.key_entry_at(i), Vector2(FloorMapView.key_column_width(), DoorSign.SIZE))
			assert_false(entry.intersects(line), "%d entries: entry %d" % [entries, i])
	assert_true(FloorMapView.key_has_name_row(6), "a name row under one row of entries")
	assert_false(FloorMapView.key_has_name_row(7, true), "the Left here line takes the last free row")
	assert_true(FloorMapView.key_has_name_row(6, true), "with two rows free, both fit")


# The small map marks a room with leftovers by one ink dot in its top right corner, and nothing else. It
# touches neither the outline nor the room's colour dot: a pixel of floor lies all round it, so it reads
# as a dot and never as a thicker corner.
func test_the_small_map_marks_a_room_with_leftovers_in_its_corner() -> void:
	var bare := _row_view({2: {"cleared": true, "keep": []}}, false)
	var plain := _paper_image()
	bare.paint_mini(plain)
	var view := _row_view({1: _kept(["potion"]), 2: _kept(["key", "reel"])}, false)
	var image := _paper_image()
	view.paint_mini(image)
	var marked := {}
	for room_id: int in [1, 2]:
		var rect: Rect2 = view.mini_room_rects[room_id]
		var dot := FloorMapView.mini_leftover_rect(rect)
		marked[room_id] = dot
		assert_eq(dot.size, Vector2(1, 1))
		var width := MapPaper.outline_width(FloorMapView.room_size(FloorMapView.MINI_SPACING))
		assert_true(rect.grow(-float(width) - 1.0).encloses(dot), "a pixel clear of room %d's outline" % room_id)
		assert_false(dot.grow(1.0).intersects(FloorMapView.mini_dot_rect(rect)), "a pixel clear of room %d's colour dot" % room_id)
		assert_eq(_ink_counts(image, dot), Vector2i(1, 0), "room %d's dot is ink" % room_id)
		# Painted: every pixel round it is the room's bare floor, so nothing touches it.
		var at := Vector2i(dot.position)
		for step: Vector2i in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)]:
			assert_true(image.get_pixelv(at + step).is_equal_approx(MapPaper.ROOM_FILL), "room %d: floor at %s beside the dot" % [room_id, str(at + step)])
	for y in range(int(FloorMapView.MINI_RECT.position.y), int(FloorMapView.MINI_RECT.end.y)):
		for x in range(int(FloorMapView.MINI_RECT.position.x), int(FloorMapView.MINI_RECT.end.x)):
			if image.get_pixel(x, y).is_equal_approx(plain.get_pixel(x, y)):
				continue
			var p := Vector2(x, y) + Vector2(0.5, 0.5)
			assert_true((marked[1] as Rect2).has_point(p) or (marked[2] as Rect2).has_point(p), "a pixel changed at %d,%d" % [x, y])
	assert_true(_crossings(image, FloorMapView.MINI_RECT).is_empty())
	bare.free()
	view.free()
