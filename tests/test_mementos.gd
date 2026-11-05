extends TestCase


func test_every_floor_boss_has_a_frame_and_its_floor_names_it() -> void:
	assert_eq(Mementos.ALL.size(), 10)
	for entry: Dictionary in Mementos.ALL:
		var floor_path := "res://data/floors/%s.tres" % entry["path"]
		var def: FloorDef = load(floor_path)
		assert_eq(PendingBosses.id_of(def.floor_boss.id), entry["boss"], entry["path"])


func test_a_fresh_save_hangs_nothing() -> void:
	assert_eq(Mementos.hung(ProgressData.new()).size(), 0)
	assert_eq(Mementos.perks(ProgressData.new()).size(), 0)


func test_a_cleared_path_hangs_its_memento_and_grants_its_perk() -> void:
	var data := ProgressData.new()
	data.record_floor_cleared(1, "cemetery")
	assert_eq(Mementos.hung(data).size(), 1)
	assert_true(Mementos.perks(data).has(Mementos.PROP_COINS_PERK))
	assert_false(Mementos.perks(data).has(Mementos.START_PENSION_PERK))


func test_looking_at_the_wall_lists_each_memento_or_says_it_is_empty() -> void:
	assert_eq(Mementos.wall_lines(ProgressData.new()), PackedStringArray([Mementos.EMPTY_WALL_TEXT]))
	var data := ProgressData.new()
	data.record_floor_cleared(1, "floor_1")
	data.record_floor_cleared(2, "furnace_works")
	var lines := Mementos.wall_lines(data)
	assert_eq(lines.size(), 2)
	assert_true(lines[0].begins_with("Name badge"), lines[0])
	assert_true(lines[1].begins_with("Coal shovel"), lines[1])


# Empty frames side by side name their bosses, so no two neighbouring captions may overlap.
func test_neighbouring_captions_never_run_together() -> void:
	var font := ThemeDB.fallback_font
	var boxes: Array[Rect2] = []
	for i in Mementos.ALL.size():
		var caption: String = Mementos.ALL[i]["short_name"]
		var width := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, TrophyWall.CAPTION_SIZE).x
		var ascent := font.get_ascent(TrophyWall.CAPTION_SIZE)
		var height := ascent + font.get_descent(TrophyWall.CAPTION_SIZE)
		var at := TrophyWall.frame_center(i) + Vector2(-width / 2.0, TrophyWall.caption_y(i) - ascent)
		boxes.append(Rect2(at, Vector2(width, height)).grow_individual(1.0, 0.0, 1.0, 0.0))
	for i in boxes.size() - 1:
		assert_false(boxes[i].intersects(boxes[i + 1]), "%s and %s" % [Mementos.ALL[i]["short_name"], Mementos.ALL[i + 1]["short_name"]])
	# Every second caption shares a row, two frame steps apart.
	for i in boxes.size() - 2:
		assert_false(boxes[i].intersects(boxes[i + 2]), "%s and %s" % [Mementos.ALL[i]["short_name"], Mementos.ALL[i + 2]["short_name"]])


# The frames hang on the lobby's top wall, so none may cover the north door or a lantern.
func test_the_frames_keep_clear_of_the_north_door_and_the_lanterns() -> void:
	var lobby: RoomLayout = Departments.load_layouts()[Departments.LOBBY]
	var middle := Departments.TROPHY_WALL_X
	var left := middle + TrophyWall.frame_center(0).x - TrophyWall.FRAME_SIZE.x / 2.0
	var right := middle + TrophyWall.frame_center(Mementos.ALL.size() - 1).x + TrophyWall.FRAME_SIZE.x / 2.0
	var blocked: Array[int] = [lobby.door_cell(RoomLayout.NORTH).x]
	for cell in lobby.cells_of(RoomLayout.SYMBOL_LANTERN):
		blocked.append(cell.x)
	for x in blocked:
		var cell_left := float(x * RoomBackdrop.TILE)
		assert_true(right <= cell_left or left >= cell_left + RoomBackdrop.TILE, "column %d" % x)


func _plain_run() -> RunState:
	var none: Array[UpgradeDef] = []
	return RunState.new(none, {})


func _run_with(perk: String) -> RunState:
	var run := _plain_run()
	run.perks = {perk: true}
	run.apply_perks()
	return run


func test_the_bedpan_adds_one_pill_to_the_first_heal_only() -> void:
	var run := _run_with(Mementos.FIRST_HEAL_PERK)
	run.health.hit(3)
	run.health.heal(1)
	assert_eq(run.health.pills, PlayerStats.BASE_PILLS - 3 + 2)
	run.health.heal(1)
	assert_eq(run.health.pills, PlayerStats.BASE_PILLS - 3 + 3)


func test_a_heal_on_full_pills_does_not_spend_the_bedpan() -> void:
	var run := _run_with(Mementos.FIRST_HEAL_PERK)
	run.health.heal(1)
	run.health.hit(2)
	run.health.heal(1)
	assert_eq(run.health.pills, PlayerStats.BASE_PILLS)


func test_without_the_bedpan_a_heal_is_plain() -> void:
	var run := _plain_run()
	run.apply_perks()
	run.health.hit(3)
	run.health.heal(1)
	assert_eq(run.health.pills, PlayerStats.BASE_PILLS - 2)


func test_the_coal_shovel_shrugs_off_every_second_fire_hit() -> void:
	var player := Player.new()
	player.setup(_run_with(Mementos.FIRE_PERK))
	assert_true(player.take_fire_hit(1))
	player.run.health.tick(Health.INVULN_TIME + 0.1)
	assert_false(player.take_fire_hit(1), "the second is shrugged off")
	assert_eq(player.run.health.pills, PlayerStats.BASE_PILLS - 1, "a shrugged hit costs nothing")
	player.run.health.tick(Health.INVULN_TIME + 0.1)
	assert_true(player.take_fire_hit(1))
	player.free()


func test_a_fire_hit_that_would_miss_does_not_use_up_the_shrug() -> void:
	var player := Player.new()
	player.setup(_run_with(Mementos.FIRE_PERK))
	assert_true(player.take_fire_hit(1))
	assert_false(player.take_fire_hit(1), "still safe from the first")
	player.run.health.tick(Health.INVULN_TIME + 0.1)
	assert_false(player.take_fire_hit(1), "the shrug was kept for a hit that would land")
	assert_eq(player.run.health.pills, PlayerStats.BASE_PILLS - 1)
	player.free()


func test_without_the_coal_shovel_every_fire_hit_lands() -> void:
	var player := Player.new()
	player.setup(_plain_run())
	assert_true(player.take_fire_hit(1))
	player.run.health.tick(Health.INVULN_TIME + 0.1)
	assert_true(player.take_fire_hit(1))
	player.free()


func test_the_bent_shovel_raises_prop_coin_odds() -> void:
	assert_near(_run_with(Mementos.PROP_COINS_PERK).prop_coin_mult(), 1.25)
	assert_near(_plain_run().prop_coin_mult(), 1.0)


# --- the deep floors' mementos ---

func test_frames_never_overlap_and_every_memento_has_a_drawing() -> void:
	assert_true(TrophyWall.FRAME_STEP > TrophyWall.FRAME_SIZE.x, "a gap between frames")
	var source := FileAccess.get_file_as_string("res://scripts/world/trophy_wall.gd")
	for perk in ["START_PENSION_PERK", "PROP_COINS_PERK", "FIRST_HEAL_PERK", "FIRE_PERK", "BOSS_ROOM_PILL_PERK", "TREASURE_CHOICE_PERK", "SLIDE_PERK", "CHARGE_PERK", "LANDING_PERK", "BOSS_DAMAGE_PERK"]:
		assert_true(source.contains("Mementos.%s:" % perk), perk)
	var perks := {}
	for entry: Dictionary in Mementos.ALL:
		assert_false(perks.has(entry["perk"]), "one memento per perk")
		perks[entry["perk"]] = true


func test_the_deep_floors_perks_have_their_ids() -> void:
	assert_eq(Mementos.SLIDE_PERK, "slide_half")
	assert_eq(Mementos.CHARGE_PERK, "charge_power")
	assert_eq(Mementos.LANDING_PERK, "landing_pill")
	assert_eq(Mementos.BOSS_DAMAGE_PERK, "boss_damage")
	var data := ProgressData.new()
	data.record_floor_cleared(5, "head_office")
	assert_true(Mementos.perks(data).has(Mementos.BOSS_DAMAGE_PERK))


func test_the_anchor_halves_slides_and_pushes() -> void:
	assert_near(_plain_run().slide_mult(), 1.0)
	assert_near(_run_with(Mementos.SLIDE_PERK).slide_mult(), 0.5)
	var player := Player.new()
	player.setup(_run_with(Mementos.SLIDE_PERK))
	player.push(Vector2(200, 0), 0.5)
	assert_eq(player._push, Vector2(100, 0))
	player.free()
	var plain := Player.new()
	plain.setup(_plain_run())
	plain.push(Vector2(200, 0), 0.5)
	assert_eq(plain._push, Vector2(200, 0))
	plain.free()
	var source := FileAccess.get_file_as_string("res://scripts/actors/player.gd")
	assert_true(source.contains("ShipDeck.slide_at(get_tree(), _feet.global_position) * run.slide_mult()"), "the roll slides him half as far too")


func test_the_golf_trophy_adds_to_a_charged_swing() -> void:
	assert_near(_plain_run().charge_damage_mult(), 1.0)
	assert_near(_run_with(Mementos.CHARGE_PERK).charge_damage_mult(), 1.15)
	var source := FileAccess.get_file_as_string("res://scripts/actors/player.gd")
	assert_true(source.contains("ChargeSwing.DAMAGE * run.charge_damage_mult()"))


func test_the_gold_gavel_hits_bosses_harder_and_nothing_else() -> void:
	var run := _run_with(Mementos.BOSS_DAMAGE_PERK)
	assert_near(run.boss_damage_mult(), 1.1)
	assert_near(_plain_run().boss_damage_mult(), 1.0)
	assert_near(PlayerStats.boss_damage(30.0, true, run.boss_damage_mult()), 33.0)
	assert_near(PlayerStats.boss_damage(30.0, false, run.boss_damage_mult()), 30.0)
	var dentures := FileAccess.get_file_as_string("res://scripts/actors/thrown_dentures.gd")
	assert_true(dentures.contains("PlayerStats.boss_damage(bite, enemy.def.is_boss, boss_mult)"), "the dentures too")


func test_the_boarding_pass_adds_a_pill_to_every_landing() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
	assert_true(source.contains("LANDING_HEAL + (Mementos.LANDING_EXTRA if _run.has_perk(Mementos.LANDING_PERK) else 0)"))
	assert_true(source.contains("_run.health.heal(landing_heal())"))
	assert_eq(Mementos.LANDING_EXTRA, 1)
