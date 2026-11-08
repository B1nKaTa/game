extends TestCase

# The Flashback Cinema's screens: the films they play (CinemaScenes), where a screen hangs, and what
# the Projectionist can make one do.


func _layout(width: int, height: int, thick_wall := true, type := RoomLayout.TYPE_COMBAT) -> RoomLayout:
	var rows := PackedStringArray(["#".repeat(width)])
	for y in range(1, height - 1):
		rows.append("#" + ".".repeat(width - 2) + "#")
	rows.append("#".repeat(width))
	if thick_wall:
		var door := width / 2
		rows[1] = "#".repeat(door) + "." + "#".repeat(width - door - 1)
	var layout := RoomLayout.new()
	layout.room_type = type
	layout.rows = rows
	return layout


# --- the films ---

func test_there_are_nineteen_films_each_with_a_title_and_a_description() -> void:
	assert_eq(CinemaScenes.ALL.size(), 19)
	var seen := {}
	for scene in CinemaScenes.ALL:
		var id: String = scene["id"]
		assert_false(seen.has(id), "%s twice" % id)
		seen[id] = true
		assert_true(id.is_valid_identifier() and id == id.to_lower(), "%s is a plain snake_case id" % id)
		assert_false(String(scene["title"]).is_empty(), id)
		var description: String = scene["description"]
		var sentences := description.count(". ") + 1
		assert_true(sentences >= 1 and sentences <= 3, "%s: %d sentences" % [id, sentences])
		assert_true(description.length() >= 80 and description.length() <= 330, "%s: %d letters" % [id, description.length()])
		assert_true(description.contains("Harold"), "%s shows Harold" % id)
	assert_eq(CinemaScenes.ids().size(), 19)
	assert_eq(CinemaScenes.scene("biscuit_walk")["title"], "Walking Biscuit")
	assert_true(CinemaScenes.scene("no_such_film").is_empty())


func test_the_films_are_the_ones_the_spec_asks_for() -> void:
	var text := ""
	for scene in CinemaScenes.ALL:
		text += " " + String(scene["title"]) + " " + String(scene["description"])
	for wanted in ["Gerald", "1974", "hedge", "Biscuit", "car", "works do", "Christmas", "fence", "retirement cake", "seaside", "umbrella", "dance", "roast", "wedding", "number 12", "marrow", "fishing", "caravan"]:
		assert_true(text.containsn(wanted), "a film about %s" % wanted)


# The screens show everyday life, never how his story ends, and never his house as somewhere to get to.
func test_no_film_shows_an_ending_or_his_house() -> void:
	for scene in CinemaScenes.ALL:
		var text := (String(scene["title"]) + " " + String(scene["description"])).to_lower()
		for banned in ["house", "home", "ending", "funeral", "grave", "coffin", "dies", "death", "heaven", "afterlife", "goodbye", "hospital"]:
			assert_false(text.contains(banned), "%s mentions %s" % [scene["id"], banned])


func test_a_rooms_film_comes_from_its_seed() -> void:
	var counts := {}
	for seed_value in 2000:
		var id := CinemaScenes.pick(seed_value)
		assert_eq(CinemaScenes.pick(seed_value), id, "the same seed, the same film")
		counts[id] = int(counts.get(id, 0)) + 1
	assert_eq(counts.size(), CinemaScenes.ALL.size(), "every film is shown somewhere")
	for id in counts:
		assert_true(counts[id] > 60 and counts[id] < 240, "%s picked %d times in 2000" % [id, counts[id]])


func _floor_map(seed_value: int) -> FloorMap:
	var def: FloorDef = load("res://data/floors/flashback_cinema.tres")
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return FloorBuilder.build_from_pool(rng, def, RoomCatalog.load_valid(def.rooms_dir))


func test_rooms_next_door_never_show_the_same_film() -> void:
	var rooms := 0
	for seed_value in 60:
		var map := _floor_map(seed_value)
		if map == null:
			continue
		var chosen := CinemaScenes.assign(map)
		assert_eq(CinemaScenes.assign(map), chosen, "the same floor, the same films")
		for room in map.rooms:
			if not CinemaScenes.shows_screen(room.room_type):
				assert_false(chosen.has(room.id), "a %s room has no screen" % room.room_type)
				continue
			rooms += 1
			assert_true(CinemaScenes.ids().has(chosen.get(room.id, "")), "room %d has a film" % room.id)
			for side in room.doors:
				var other: int = room.doors[side]
				if chosen.has(other):
					assert_true(chosen[other] != chosen[room.id], "seed %d: rooms %d and %d both show %s" % [seed_value, room.id, other, chosen[room.id]])
	assert_true(rooms > 400, "checked %d screen rooms" % rooms)


# Each screen on a floor plays a film of its own while unused films remain, so each lobby card has its
# film's lines to itself.
func test_a_floor_shows_each_film_once_while_films_remain() -> void:
	var floors := 0
	for seed_value in 60:
		var map := _floor_map(seed_value)
		if map == null:
			continue
		var chosen := CinemaScenes.assign(map)
		if chosen.size() > CinemaScenes.ALL.size():
			continue
		floors += 1
		var films := {}
		for id in chosen.values():
			assert_false(films.has(id), "seed %d shows %s twice" % [seed_value, id])
			films[id] = true
	assert_true(floors > 40, "checked %d floors" % floors)


func test_screens_hang_in_fighting_and_boss_rooms_only() -> void:
	for type in [RoomLayout.TYPE_COMBAT, RoomLayout.TYPE_MINI_BOSS, RoomLayout.TYPE_FLOOR_BOSS]:
		assert_true(CinemaScenes.shows_screen(type), type)
	for type in [RoomLayout.TYPE_SHOP, RoomLayout.TYPE_TREASURE, RoomLayout.TYPE_ITEM, RoomLayout.TYPE_HEALING, RoomLayout.TYPE_SIDE, RoomLayout.TYPE_SECRET, RoomLayout.TYPE_VAULT, RoomLayout.TYPE_CROSSROADS, RoomLayout.TYPE_ARCADE]:
		assert_false(CinemaScenes.shows_screen(type), type)


# --- the art the screen loads ---

func test_scene_art_is_a_strip_of_frames_and_a_placeholder_stands_in() -> void:
	assert_eq(CinemaScenes.FRAME_SIZE, Vector2i(160, 64))
	assert_eq(CinemaScenes.FRAMES, 2)
	assert_eq(CinemaScenes.art_path("seaside_day"), "res://art/cinema/scenes/seaside_day.png")
	for id in CinemaScenes.ids():
		var image := CinemaScenes.placeholder_image(id)
		assert_eq(image.get_size(), Vector2i(320, 64), id)
	var image := CinemaScenes.placeholder_image("first_car")
	var warm := 0
	for x in range(0, 320, 5):
		var pixel := image.get_pixel(x, 6)
		if pixel.r >= pixel.g and pixel.g >= pixel.b:
			warm += 1
	assert_true(warm > 60, "a sepia sky")
	assert_false(image.get_region(Rect2i(0, 0, 160, 64)).get_data() == image.get_region(Rect2i(160, 0, 160, 64)).get_data(), "the frames differ, so the fade shows")


# Every film has its art: a 2-frame strip of 160x64 frames, which the screen loads instead of the
# placeholder.
func test_every_film_has_its_strip() -> void:
	for id in CinemaScenes.ids():
		var path := CinemaScenes.art_path(id)
		assert_true(ResourceLoader.exists(path), id + " has art")
		var texture: Texture2D = load(path)
		assert_eq(Vector2i(texture.get_size()), Vector2i(CinemaScenes.FRAME_SIZE.x * CinemaScenes.FRAMES, CinemaScenes.FRAME_SIZE.y), id)
		var screen := CinemaScreen.new()
		screen.setup(_layout(20, 11), id, 3)
		screen._ready()
		assert_eq(screen._texture.resource_path, path, id + " shows its art")
		assert_eq(screen._frames, 2, id + " fades between its two frames")
		screen.free()


# --- where it hangs ---

func test_the_screen_hangs_west_of_the_north_door_in_every_room_size() -> void:
	for width in [14, 20, 30]:
		var layout := _layout(width, 11)
		var wall := CinemaScreen.wall_rect(layout)
		var door := layout.door_cell(RoomLayout.NORTH)
		assert_near(wall.position.x, RoomBackdrop.TILE, "from the west wall")
		assert_true(wall.end.x <= door.x * RoomBackdrop.TILE, "short of the north door at width %d" % width)
		assert_near(wall.position.y, 0.0)
		assert_near(wall.size.y, RoomBackdrop.TILE * 2.0, "two cells deep")
		var picture := CinemaScreen.picture_rect_for(wall)
		assert_true(wall.encloses(picture.grow(CinemaScreen.FRAME_WIDTH)), "the framed picture fits the wall at width %d" % width)
		assert_near(picture.size.x, float(CinemaScenes.FRAME_SIZE.x), "a frame shows at 1:1 across")
		assert_near(picture.size.y, wall.size.y - CinemaScreen.THIN_MARGIN * 2.0, "as many rows as the wall leaves room for")
		var rows := CinemaScreen.shown_rows(picture.size)
		assert_near(rows.y, picture.size.y, "at 1:1 down too")
		assert_near(rows.x * 2.0 + rows.y, float(CinemaScenes.FRAME_SIZE.y), "the middle rows, trimmed evenly")
		assert_true(picture.end.y <= RoomBackdrop.TILE * 2.0, "never over the floor")


func test_a_thin_wall_still_fits_a_smaller_picture() -> void:
	var layout := _layout(20, 11, false)
	var wall := CinemaScreen.wall_rect(layout)
	assert_near(wall.size.y, RoomBackdrop.TILE * 1.0, "one cell deep")
	var picture := CinemaScreen.picture_rect_for(wall)
	assert_true(wall.encloses(picture), "inside the wall")
	assert_true(absf(picture.size.x / picture.size.y - 160.0 / 64.0) < 0.1, "keeping its shape")
	assert_near(CinemaScreen.shown_rows(picture.size).y, 64.0, "shrunk, it shows every row")


# --- what the Projectionist drives ---

func _screen() -> CinemaScreen:
	var screen := CinemaScreen.new()
	screen.setup(_layout(20, 11), "burnt_roast", 5)
	screen._ready()
	return screen


func test_the_screen_cuts_to_black_and_comes_back() -> void:
	var screen := _screen()
	assert_false(screen.is_dark())
	screen.cut_to_black(1.0)
	assert_true(screen.is_dark(), "dark at once")
	screen._process(0.5)
	assert_true(screen.is_dark())
	assert_near(screen.darkness(), 1.0, "black after the quick fade")
	screen._process(0.6)
	screen._process(0.1)
	screen._process(0.4)
	assert_false(screen.is_dark(), "back after the cut")
	assert_near(screen.darkness(), 0.0)
	screen.free()


func test_the_screen_flashes_and_burns() -> void:
	var screen := _screen()
	screen.flash()
	assert_near(screen._flash, 1.0)
	screen._process(CinemaScreen.FLASH_TIME + 0.01)
	assert_near(screen._flash, 0.0, "the flash fades")
	screen.set_burning(0.4)
	assert_near(screen.burning(), 0.4)
	screen.set_burning(3.0)
	assert_near(screen.burning(), 1.0, "never more than burnt through")
	screen.set_burning(-1.0)
	assert_near(screen.burning(), 0.0)
	assert_false(screen.is_dark(), "a flash or a burn is not a cut")
	screen.free()


func test_the_screen_plays_its_film_with_the_shader_and_adds_no_body() -> void:
	var screen := _screen()
	assert_eq(screen.scene_id, "burnt_roast")
	assert_true(screen.is_in_group(CinemaScreen.GROUP) or not screen.is_inside_tree())
	assert_true(screen._material.shader == CinemaScreen.SHADER)
	assert_eq(screen._material.get_shader_parameter("frames"), CinemaScenes.FRAMES, "the strip has every frame")
	for child in screen.get_children():
		assert_false(child is CollisionObject2D, "purely decorative")
	assert_true(screen.z_index < 0, "under the bodies")
	assert_true(screen.picture_rect().size.x > 0.0)
	screen.free()


func test_the_shader_does_what_the_spec_asks() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/cinema_screen.gdshader")
	for part in ["darkness", "flash", "burn", "hash(", "smoothstep(hold", "sepia", "for (int i = 0; i < 2; i++)"]:
		assert_true(source.contains(part), part)


func test_the_beam_is_faint_and_lies_under_the_bodies() -> void:
	assert_true(CinemaBeam.Z < 0 and CinemaBeam.Z > Hole.FLOOR_Z, "above the floor's flat things, under the bodies")
	assert_true(CinemaBeam.ALPHA_AT_PORT <= 0.2 and CinemaBeam.ALPHA_AT_SCREEN < CinemaBeam.ALPHA_AT_PORT)
	var screen := _screen()
	var beam := CinemaBeam.new()
	var picture := screen.picture_rect()
	beam.setup(screen, picture, Vector2(640, 352))
	assert_near(beam.spot_in_beam(0.0, 0.5).y, 352.0 - RoomBackdrop.TILE * 0.5, "from the south wall")
	assert_near(beam.spot_in_beam(1.0, 0.5).y, picture.end.y, "up to the picture")
	assert_true(absf(beam.spot_in_beam(1.0, 0.5).x - picture.get_center().x) < 1.0, "straight up to its middle")
	assert_near(beam.strength(), 1.0)
	screen.cut_to_black(1.0)
	screen._process(0.5)
	assert_near(beam.strength(), 0.0, "the projector is off while the screen is black")
	beam.free()
	screen.free()
