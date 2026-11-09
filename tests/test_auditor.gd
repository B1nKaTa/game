extends TestCase

const AUDITOR := "res://data/enemies/auditor.tres"


func _view() -> RoomView:
	var room := FloorRoom.new()
	room.layout = load("res://data/rooms/floor_1/combat_01.tres")
	room.room_type = RoomLayout.TYPE_COMBAT
	var view := RoomView.new()
	view.setup(room, null, load("res://data/floors/floor_1.tres"), RunState.new([] as Array[UpgradeDef], {}), null, RandomNumberGenerator.new(), null, null)
	return view


func test_the_auditor_is_a_tough_regular_not_a_boss() -> void:
	var def: EnemyDef = load(AUDITOR)
	assert_false(def.is_boss, "a boss's death wipes the room")
	assert_eq(def.max_per_room, 1)
	assert_eq(def.id, RoomView.AUDITOR_ID)


# The floor's pay rate scales him and the regulars alike, so the ratio holds on every floor.
func test_he_pays_about_three_times_a_regular_and_less_than_a_mini_boss() -> void:
	var def: EnemyDef = load(AUDITOR)
	var floor_def: FloorDef = load("res://data/floors/floor_1.tres")
	var regular: EnemyDef = floor_def.enemies[0]
	assert_true(def.pension_drop >= 2 * regular.pension_drop and def.pension_drop <= 5 * regular.pension_drop,
		"%d against a regular's %d" % [def.pension_drop, regular.pension_drop])
	assert_true(def.pension_drop < floor_def.mini_boss.pension_drop, "below the floor-1 mini-boss's")


func test_his_health_lies_between_the_first_floors_regulars_and_its_mini_boss() -> void:
	var def: EnemyDef = load(AUDITOR)
	var floor_def: FloorDef = load("res://data/floors/floor_1.tres")
	var toughest := 0.0
	for regular: EnemyDef in floor_def.enemies:
		toughest = maxf(toughest, regular.max_hp)
	assert_true(def.max_hp > toughest, "tougher than every floor-1 regular")
	assert_true(def.max_hp < floor_def.mini_boss.max_hp, "weaker than the floor-1 mini-boss")
	assert_true(def.max_hp >= toughest * 1.4, "a mini-elite, clearly tougher than the toughest regular")


func test_his_door_flash_is_a_passing_effect_that_frees_itself() -> void:
	var flash := AuditFlash.new()
	assert_true(RoomView.is_passing_effect(flash))
	flash._process(AuditFlash.LIFE - 0.1)
	assert_false(flash.is_queued_for_deletion(), "still showing")
	flash._process(0.2)
	assert_true(flash.is_queued_for_deletion(), "gone after its time")
	flash.free()
	assert_near(AuditFlash.LIFE, 1.0, "about a second")


func test_his_door_flash_keeps_out_from_under_the_hud() -> void:
	assert_true(AuditFlash.word_offset(200.0, 1.0).y < 0.0, "on a low door it stands on the door")
	assert_true(AuditFlash.word_offset(Hud.BAND_BOTTOM + 4.0, 1.0).y > 0.0, "on a north door it shows below")


# On a north door his "Rules are rules." drops below his body too (Enemy.say_spot), and the first shot
# showed it right over the word.
func test_on_a_north_door_the_word_clears_his_arrival_line() -> void:
	var def: EnemyDef = load(AUDITOR)
	for door_y in [Hud.BAND_BOTTOM - 12.0, Hud.BAND_BOTTOM + 4.0, Hud.BAND_BOTTOM + 12.0]:
		var middle := AuditFlash.word_offset(door_y, 1.0)
		if middle.y < 0.0:
			continue
		var line := Enemy.say_spot(Vector2(320.0, door_y), 1.0, def.body_size.y, 80.0, Vector2(640, 360))
		var line_bottom := line.y + 3.0
		var word_top := middle.y - AuditFlash.SIZE * 0.75 - 4.0
		assert_true(word_top > line_bottom, "word top %.0f below the line's %.0f at door y %.0f" % [word_top, line_bottom, door_y])


func test_he_walks_in_with_the_stamp_flash() -> void:
	var view := _view()
	view.call_auditor(load(AUDITOR), null)
	view._tick_audit(RoomView.AUDIT_DELAY + 0.1)
	var flashes := 0
	for child in view.get_children():
		if child is AuditFlash:
			flashes += 1
	assert_eq(flashes, 1)
	view.free()


func test_he_is_on_no_floor_since_only_a_broken_rule_sends_him() -> void:
	for file in DirAccess.get_files_at("res://data/floors"):
		if not file.ends_with(".tres"):
			continue
		var floor_def: FloorDef = load("res://data/floors/" + file)
		for regular: EnemyDef in floor_def.enemies:
			assert_true(regular.id != RoomView.AUDITOR_ID, "%s lists the Auditor" % file)


func test_the_room_cannot_clear_while_he_is_on_his_way() -> void:
	var view := _view()
	view.debug_set_alive(1)
	view.call_auditor(load(AUDITOR), null)
	view.debug_set_alive(view.debug_alive() - 1)
	assert_true(view.debug_alive() >= 1, "he is counted from the whistle")
	assert_true(view.is_fighting(), "the last regular falling does not clear the room")
	view.call_auditor(load(AUDITOR), null)
	assert_eq(view.debug_alive(), 1, "at most one per room")
	view.free()


func test_he_walks_in_after_the_delay_and_takes_his_reserved_place() -> void:
	var view := _view()
	view.call_auditor(load(AUDITOR), null)
	view._tick_audit(RoomView.AUDIT_DELAY - 0.1)
	assert_eq(_auditors(view).size(), 0, "not before the delay")
	view._tick_audit(0.2)
	assert_eq(_auditors(view).size(), 1)
	assert_eq(view.debug_alive(), 1, "his reservation becomes him, not a second count")
	view._tick_audit(5.0)
	assert_eq(_auditors(view).size(), 1, "only one ever comes")
	view.free()


func test_he_comes_in_by_the_door_he_is_given() -> void:
	var view := _view()
	var door := Door.new()
	door.position = RoomBackdrop.cell_center(Vector2i(1, 4))
	view.call_auditor(load(AUDITOR), door)
	view._tick_audit(RoomView.AUDIT_DELAY + 0.1)
	var auditors := _auditors(view)
	assert_eq(auditors.size(), 1)
	if auditors.size() == 1:
		assert_true(auditors[0].position.distance_to(door.position) <= RoomBackdrop.TILE, "at the door")
	door.free()
	view.free()


func test_a_finished_room_sends_no_auditor() -> void:
	var view := _view()
	view._finished = true
	view.call_auditor(load(AUDITOR), null)
	assert_eq(view.debug_alive(), 0)
	view.free()


func _auditors(view: RoomView) -> Array:
	var found := []
	for child in view.get_children():
		if child is Enemy and child.def.id == RoomView.AUDITOR_ID:
			found.append(child)
	return found


func test_his_stamp_and_ink_are_passing_effects() -> void:
	var blot := InkBlot.new()
	assert_true(RoomView.is_passing_effect(blot))
	blot.free()


func test_the_ink_blot_slows_only_where_it_lies() -> void:
	var blot := InkBlot.new()
	blot.position = Vector2(100, 100)
	assert_true(blot.covers(Vector2(104, 102)))
	assert_false(blot.covers(Vector2(140, 100)))
	assert_eq(blot.threat_at(Vector2(104, 102), false), 1)
	assert_eq(blot.threat_at(Vector2(140, 100), false), 0)
	assert_false(blot.threat_imminent(Vector2(104, 102)))
	assert_true(InkBlot.SLOW < 1.0 and InkBlot.SLOW >= SlowEffect.MIN_FACTOR)
	blot.free()


func test_no_ink_lands_in_a_room_he_has_left() -> void:
	var away := Node2D.new()
	InkBlot.spawn_at(Vector2(10, 10), away, null)
	assert_eq(away.get_child_count(), 0, "a room out of the tree takes no blot")
	away.free()
	InkBlot.spawn_at(Vector2(10, 10), away, null)
	assert_true(true, "a freed room is no error")


func test_the_stamp_has_its_own_look() -> void:
	assert_eq(Projectile.LOOK_FINED, "fined")
	var shot := Projectile.new()
	assert_true(shot.has_signal("landed_at"))
	shot.free()


func test_the_floor_scene_sends_him_by_the_door_harold_came_in_by() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
	assert_true(source.contains("_rules.rule_broken.connect(_on_rule_broken)"))
	var broken := source.substr(source.find("func _on_rule_broken("), 400)
	assert_true(broken.contains("view.door_to(_arrived_from)"), "he comes in by the door Harold came in by")
