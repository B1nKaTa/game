extends TestCase


func _room_with(changes: Dictionary) -> RoomLayout:
	var rows := ["#".repeat(20)]
	for y in range(1, 10):
		rows.append("#" + ".".repeat(18) + "#")
	rows.append("#".repeat(20))
	rows[4] = rows[4].substr(0, 9) + "H" + rows[4].substr(10)
	for cell: Vector2i in changes:
		var row: String = rows[cell.y]
		rows[cell.y] = row.substr(0, cell.x) + changes[cell] + row.substr(cell.x + 1)
	var layout := RoomLayout.new()
	layout.room_type = RoomLayout.TYPE_HEALING
	layout.rows = PackedStringArray(rows)
	return layout


func _load(id: String) -> EnemyDef:
	return load("res://data/enemies/%s.tres" % id)


# --- wading ---

func test_sand_slows_anyone_walking_in_it() -> void:
	assert_near(SandRule.SPEED_FACTOR, 0.6)
	assert_near(SandRule.speed_factor(true), 0.6)
	assert_near(SandRule.speed_factor(false), 1.0, "out of the sand he walks as ever")
	assert_true(SandRule.SPEED_FACTOR > SlowEffect.MIN_FACTOR, "sand alone always leaves him a fair walk")


func test_sand_and_a_sedative_never_leave_less_than_the_least_walk() -> void:
	assert_near(SandRule.slowed(1.0, true), 0.6)
	assert_near(SandRule.slowed(0.5, false), 0.5, "out of the sand only the sedative counts")
	assert_near(SandRule.slowed(SlowEffect.MIN_FACTOR, true), SlowEffect.MIN_FACTOR, "however slow, he can still wade out")
	assert_near(SandRule.slowed(0.5, true), SlowEffect.MIN_FACTOR)
	for slow in [1.0, 0.9, 0.7, 0.5, 0.4]:
		assert_true(SandRule.slowed(slow, true) >= SlowEffect.MIN_FACTOR, str(slow))
		assert_true(SandRule.slowed(slow, true) <= slow, "sand never speeds him up")


func test_grandpa_cannot_dodge_in_sand() -> void:
	assert_false(SandRule.can_dodge(true))
	assert_true(SandRule.can_dodge(false))


func test_the_player_and_enemies_read_the_sand() -> void:
	var player := FileAccess.get_file_as_string("res://scripts/actors/player.gd")
	assert_true(player.contains("SandRule.can_dodge(sunk):") and player.contains("if not _dodge.try_start(run.stats.dodge_cooldown"), "a dodge is refused before it spends its cooldown")
	assert_true(player.contains("SandRule.slowed(_slow.speed_factor(), sunk)"), "his walk is slowed")
	var enemy := FileAccess.get_file_as_string("res://scripts/actors/enemy.gd")
	assert_true(enemy.contains("if SandTrap.slows(self):"), "enemies wade too")


func test_walkers_and_bosses_wade_but_ghosts_mounds_and_fixtures_never_touch_it() -> void:
	assert_true(SandTrap.wades(_load("intern_reaper"), false))
	assert_true(SandTrap.wades(_load("mall_santa"), false), "a boss wades as anyone does")
	assert_false(SandTrap.wades(_load("intern_reaper"), true), "underground it passes under")
	assert_false(SandTrap.wades(_load("debt_ghost"), false), "a ghost floats over")
	assert_false(SandTrap.wades(_load("steam_valve"), false), "bolted to the wall")
	assert_false(SandTrap.wades(null, false))
	var walker := Enemy.new()
	walker.setup(_load("intern_reaper"), null, 0.5)
	assert_false(SandTrap.slows(walker), "out of a room there is no sand")
	walker.free()


func test_sand_only_slows_and_never_turns_a_charge_off_its_lane() -> void:
	var lane := Vector2(0.6, -0.8)
	var charge := lane * 400.0
	var waded := charge - charge * (1.0 - SandRule.SPEED_FACTOR)
	assert_true(waded.normalized().is_equal_approx(lane), "the charge keeps its warned way")
	assert_near(waded.length(), 400.0 * SandRule.SPEED_FACTOR)


# --- the sand cell ---

func test_a_sand_cell_covers_its_own_cell_only() -> void:
	var sand := SandTrap.new()
	sand.position = Vector2(48, 48)
	var traps := [sand]
	assert_true(SandTrap.any_covers(traps, Vector2(50, 50)))
	assert_true(SandTrap.any_covers(traps, Vector2(33, 63)), "the whole cell")
	assert_false(SandTrap.any_covers(traps, Vector2(80, 50)), "not the next one")
	assert_false(SandTrap.any_covers([], Vector2(50, 50)))
	assert_false(SandTrap.is_sand_at(null, Vector2(50, 50)))
	sand.free()


func test_sand_never_costs_a_pill() -> void:
	var sand := SandTrap.new()
	assert_false(sand.has_method("hit_target") or sand.has_method("damage") or sand.has_method("take_hit"), "sand has no way to hurt")
	sand.free()
	var patch := BunkerPatch.new()
	assert_false(patch.has_method("hit_target") or patch.has_method("damage"), "nor does spread sand")
	patch.free()


func test_grains_lie_inside_their_cell_and_stay_put() -> void:
	var half := RoomBackdrop.TILE / 2.0
	for cell in [Vector2i(1, 1), Vector2i(7, 3), Vector2i(28, 15)]:
		var spots := SandTrap.grain_spots(cell, SandTrap.GRAINS)
		assert_eq(spots.size(), SandTrap.GRAINS)
		assert_eq(spots, SandTrap.grain_spots(cell, SandTrap.GRAINS), "the same grains every frame")
		for spot in spots:
			assert_true(absf(spot.x) <= half and absf(spot.y) <= half, "%s inside its cell" % str(spot))


# --- sand in a layout ---

func test_sand_is_walkable_floor_kept_two_cells_from_doors() -> void:
	var sand := RoomLayout.SYMBOL_SAND
	assert_eq(sand, "s")
	assert_true(RoomLayout.ALLOWED.contains(sand))
	assert_false(RoomLayout.SOLID_SYMBOLS.contains(sand))
	assert_false(RoomLayout.WALLS_AND_BOMB_ONLY.contains(sand))
	assert_false(RoomLayout.DECOR_SYMBOLS.contains(sand))
	assert_eq(RoomLayout.SAND_DOOR_CLEARANCE, SandRule.DOOR_CLEARANCE)
	assert_eq(RoomLayout.SAND_DOOR_CLEARANCE, 2)
	var good := _room_with({Vector2i(5, 3): "s", Vector2i(6, 3): "s", Vector2i(5, 6): "s", Vector2i(6, 6): "s", Vector2i(14, 7): "s"})
	assert_eq(good.validate().size(), 0, str(good.validate()))
	assert_true(_room_with({Vector2i(10, 3): "s"}).validate().size() > 0, "two cells below the north door is too close")
	assert_true(_room_with({Vector2i(3, 5): "s"}).validate().size() > 0, "two cells from the west door is too close")
	assert_true(_room_with({Vector2i(16, 5): "s"}).validate().size() > 0, "two cells from the east door is too close")
	assert_true(_room_with({Vector2i(9, 7): "s"}).validate().size() > 0, "two cells above the south door, a cell aside, is too close")
	assert_eq(_room_with({Vector2i(10, 4): "s"}).validate().size(), 0, "three cells away is fine")
	assert_eq(_room_with({Vector2i(4, 5): "s"}).validate().size(), 0, "three cells from the west door is fine")


func test_old_layouts_hold_no_sand() -> void:
	for path in ["res://data/rooms/floor_1/combat_01.tres", "res://data/rooms/golden_years_mall/combat_01.tres"]:
		var layout: RoomLayout = load(path)
		assert_true(layout.cells_of(RoomLayout.SYMBOL_SAND).is_empty(), path)


# --- spread sand ---

func test_spread_sand_warns_first_then_lies_for_eight_seconds() -> void:
	assert_near(BunkerPatch.WARNING, 1.0)
	assert_near(BunkerPatch.LAST, 8.0)
	var cells: Array[Vector2i] = [Vector2i(4, 4), Vector2i(5, 4)]
	var patch := BunkerPatch.new()
	patch.setup(cells, BunkerPatch.WARNING, BunkerPatch.LAST)
	assert_eq(patch.advance(BunkerPatch.WARNING - 0.05), BunkerPatch.NOTHING, "still a warning")
	assert_false(patch.is_laid())
	assert_eq(patch.advance(0.1), BunkerPatch.LAID, "then the sand goes down")
	assert_true(patch.is_laid())
	patch.lay()
	assert_eq(patch.sand_traps().size(), 2)
	assert_true(SandTrap.any_covers(patch.sand_traps(), RoomBackdrop.cell_center(Vector2i(4, 4))))
	assert_false(SandTrap.any_covers(patch.sand_traps(), RoomBackdrop.cell_center(Vector2i(6, 4))))
	assert_eq(patch.advance(BunkerPatch.LAST - 0.1), BunkerPatch.NOTHING, "it lies for its time")
	assert_eq(patch.advance(0.2), BunkerPatch.RAKED, "then it is raked away")
	assert_eq(patch.advance(1.0), BunkerPatch.NOTHING, "once")
	patch.free()


func test_spread_sand_lands_and_goes_once_whatever_the_frame_times() -> void:
	for step in [0.004, 0.016, 0.05, 0.3, 1.7]:
		var cells: Array[Vector2i] = [Vector2i(3, 3)]
		var patch := BunkerPatch.new()
		patch.setup(cells, BunkerPatch.WARNING, BunkerPatch.LAST)
		var laid := 0
		var raked := 0
		var time := 0.0
		while time < 12.0:
			time += step
			var event := patch.advance(step)
			if event == BunkerPatch.LAID:
				laid += 1
			elif event == BunkerPatch.RAKED:
				raked += 1
		assert_eq(laid, 1, "laid once at %f a frame" % step)
		assert_eq(raked, 1, "raked once at %f a frame" % step)
		patch.free()


func test_the_warning_leaves_time_to_walk_off_a_patch_even_wading() -> void:
	# From the middle of a three by three patch to clear of it, with his feet's half width.
	var way_out := RoomBackdrop.TILE * 1.5 + Player.FEET_BOX_SIZE.x / 2.0
	var react := 0.2
	assert_true(PlayerStats.BASE_SPEED * (BunkerPatch.WARNING - react) > way_out, "walking")
	assert_true(PlayerStats.BASE_SPEED * SandRule.SPEED_FACTOR * (BunkerPatch.WARNING - react) > way_out, "wading out of sand already there")


func test_spread_sand_is_cleared_from_a_stored_room_and_laid_bunkers_are_not() -> void:
	var patch := BunkerPatch.new()
	assert_true(RoomView.is_passing_effect(patch), "spread sand goes with Grandpa leaving")
	patch.free()
	var sand := SandTrap.new()
	assert_false(RoomView.is_passing_effect(sand), "a layout's bunker is part of the room")
	sand.free()
