extends TestCase


func _run() -> RunState:
	var empty: Array[UpgradeDef] = []
	return RunState.new(empty, {})


func test_a_run_starts_with_one_thermos_and_no_slips() -> void:
	var run := _run()
	assert_eq(run.keys, 0)
	assert_eq(run.bombs, RunState.STARTING_BOMBS)
	assert_eq(RunState.STARTING_BOMBS, 1)


func test_using_a_slip_needs_one() -> void:
	var run := _run()
	assert_false(run.use_key())
	assert_eq(run.keys, 0, "never goes negative")
	run.add_key()
	assert_true(run.use_key())
	assert_eq(run.keys, 0)


func test_using_a_thermos_needs_one() -> void:
	var run := _run()
	assert_true(run.use_bomb())
	assert_false(run.use_bomb())
	assert_eq(run.bombs, 0, "never goes negative")
	run.add_bomb()
	assert_eq(run.bombs, 1)


func test_changes_are_announced() -> void:
	var run := _run()
	var count := [0]
	run.changed.connect(func(): count[0] += 1)
	run.add_key()
	run.use_key()
	run.add_bomb()
	run.use_bomb()
	assert_eq(count[0], 4)
	run.use_key()
	assert_eq(count[0], 4, "a refused use changes nothing")


func test_clear_drop_follows_the_chances() -> void:
	assert_eq(RoomRules.clear_drop(0.0), RoomRules.DROP_KEY)
	assert_eq(RoomRules.clear_drop(RoomRules.CLEAR_KEY_CHANCE - 0.001), RoomRules.DROP_KEY)
	assert_eq(RoomRules.clear_drop(RoomRules.CLEAR_KEY_CHANCE + 0.001), RoomRules.DROP_BOMB)
	assert_eq(RoomRules.clear_drop(0.99), RoomRules.DROP_NONE)


func test_thermos_blast_reaches_a_body_by_its_edge() -> void:
	var body := Rect2(Thermos.BLAST_RADIUS - 1.0, -10, 20, 20)
	assert_true(Thermos.in_blast(Vector2.ZERO, body), "edge is inside even though the center is not")
	var far := Rect2(Thermos.BLAST_RADIUS + 1.0, -10, 20, 20)
	assert_false(Thermos.in_blast(Vector2.ZERO, far))


func test_thermos_fuse_runs_out_once() -> void:
	var thermos := Thermos.new()
	assert_false(thermos.tick_fuse(Thermos.FUSE_TIME - 0.01))
	assert_true(thermos.tick_fuse(0.02))
	assert_false(thermos.tick_fuse(1.0), "already gone off")
	thermos.free()


func test_a_frozen_frame_does_not_burn_the_fuse() -> void:
	var thermos := Thermos.new()
	thermos.tick_fuse(Thermos.FUSE_TIME - 0.01)
	assert_false(thermos.tick_fuse(0.0))
	thermos.free()


func test_explosion_sound_exists() -> void:
	assert_true(SoundBank.names().has("explosion"))
	assert_true(SoundBank.names().has("consumable_pickup"))
