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


func _run() -> RunState:
	var empty: Array[UpgradeDef] = []
	return RunState.new(empty, {})


# --- the beat ---

func test_a_pipe_glows_before_each_chord() -> void:
	var beat := PipeBeat.new(3.2, 0.8, 0.0)
	assert_eq(beat.state_at(0.5), PipeBeat.QUIET)
	assert_eq(beat.state_at(2.0), PipeBeat.QUIET)
	assert_eq(beat.state_at(2.4), PipeBeat.GLOW, "it glows before the chord")
	assert_eq(beat.state_at(3.0), PipeBeat.GLOW)
	assert_eq(beat.state_at(3.15), PipeBeat.CHORD, "the chord is the end of the period")
	assert_near(beat.glow_progress(2.3 + 0.4), 0.5)


func test_the_beat_repeats() -> void:
	var beat := PipeBeat.new(3.2, 0.8, 0.0)
	for lap in 4:
		var start := lap * 3.2
		assert_eq(beat.state_at(start + 0.5), PipeBeat.QUIET, "lap %d" % lap)
		assert_eq(beat.state_at(start + 2.6), PipeBeat.GLOW, "lap %d" % lap)
		assert_eq(beat.state_at(start + 3.15), PipeBeat.CHORD, "lap %d" % lap)


func test_an_offset_shifts_the_whole_beat() -> void:
	var beat := PipeBeat.new(3.2, 0.8, 1.6)
	assert_eq(beat.state_at(3.15), PipeBeat.QUIET, "half a period later it is resting")
	assert_eq(beat.state_at(4.75), PipeBeat.CHORD)
	assert_eq(beat.state_at(4.2), PipeBeat.GLOW)


func test_each_chord_is_counted_once_however_the_frames_fall() -> void:
	var beat := PipeBeat.new(3.2, 0.8, 0.0)
	var chords := 0
	var time := 0.0
	for frame in 1000:
		var step := 0.016 if frame % 3 != 0 else 0.033
		chords += beat.chords_between(time, time + step)
		time += step
	assert_eq(chords, floori((time - (3.2 - PipeBeat.CHORD_TIME)) / 3.2) + 1)


func test_neighbouring_pipes_take_turns() -> void:
	var here := OrganPipe.offset_for(Vector2i(4, 0), OrganPipe.PERIOD)
	var there := OrganPipe.offset_for(Vector2i(5, 0), OrganPipe.PERIOD)
	assert_near(absf(here - there), OrganPipe.PERIOD / 2.0)


# --- the ring ---

func test_the_ring_pushes_outward_inside_its_band() -> void:
	var center := Vector2(100, 0)
	var push := PipeRing.push_for(center, 80.0, 16.0, center + Vector2(0, 80), 220.0)
	assert_true(push.is_equal_approx(Vector2(0, 220)), str(push))
	var aslant := PipeRing.push_for(center, 80.0, 16.0, center + Vector2(60, 50), 220.0)
	assert_near(aslant.length(), 220.0)
	assert_true(aslant.dot(Vector2(60, 50)) > 0.0, "away from the pipe")


func test_the_hollow_and_beyond_are_not_pushed() -> void:
	var center := Vector2(100, 0)
	assert_eq(PipeRing.push_for(center, 80.0, 16.0, center + Vector2(0, 40), 220.0), Vector2.ZERO, "in the hollow")
	assert_eq(PipeRing.push_for(center, 80.0, 16.0, center + Vector2(0, 120), 220.0), Vector2.ZERO, "not reached yet")


func test_the_push_follows_the_plan() -> void:
	assert_near(PipeRing.PUSH_SPEED, 220.0)
	assert_near(PipeRing.PUSH_TIME, 0.35)


func test_the_beats_ring_pushes_grandpa_but_never_costs_a_pill() -> void:
	var run := _run()
	var player := Player.new()
	player.setup(run)
	var ring := PipeRing.new()
	ring.setup(Vector2.DOWN)
	assert_eq(ring.damage(), 0)
	var pills := run.health.pills
	ring.touch_player(player, Vector2(0, ring.radius_now()))
	assert_true(player.is_pushed(), "he is shoved")
	assert_eq(run.health.pills, pills, "and keeps every pill")
	ring.touch_player(player, Vector2(0, ring.radius_now()))
	assert_eq(run.health.pills, pills)
	ring.free()
	player.free()


func test_enemies_are_pushed_the_same_but_bosses_barely() -> void:
	var def: EnemyDef = load("res://data/enemies/intern_reaper.tres")
	var enemy := Enemy.new()
	enemy.setup(def, null, 0.5)
	enemy.apply_push(Vector2(220, 0), 0.35)
	assert_true(enemy.is_pushed())
	var valve := Enemy.new()
	valve.setup(load("res://data/enemies/steam_valve.tres"), null, 0.5)
	valve.apply_push(Vector2(220, 0), 0.35)
	assert_false(valve.is_pushed(), "something bolted to the wall stays put")
	enemy.free()
	valve.free()


# --- pipes in a room ---

func test_pipes_sit_in_the_border_wall_and_count_as_wall() -> void:
	assert_true(RoomLayout.ALLOWED.contains(RoomLayout.SYMBOL_ORGAN_PIPE))
	assert_true(RoomLayout.WALL_LIKE.contains(RoomLayout.SYMBOL_ORGAN_PIPE))
	assert_true(RoomLayout.SOLID_SYMBOLS.contains(RoomLayout.SYMBOL_ORGAN_PIPE))
	assert_true(RoomLayout.WALLS.contains(RoomLayout.SYMBOL_ORGAN_PIPE))
	var layout := _room_with({Vector2i(4, 0): "o", Vector2i(15, 10): "o", Vector2i(0, 2): "o"})
	assert_eq(layout.validate().size(), 0, str(layout.validate()))
	assert_eq(layout.inward_of(Vector2i(4, 0)), Vector2.DOWN)
	assert_eq(layout.inward_of(Vector2i(15, 10)), Vector2.UP)
	assert_eq(layout.inward_of(Vector2i(0, 2)), Vector2.RIGHT)
	assert_eq(layout.inward_of(Vector2i(19, 7)), Vector2.LEFT)


func test_a_pipe_never_stands_in_the_floor_a_door_or_a_corner() -> void:
	assert_true(_room_with({Vector2i(6, 6): "o"}).validate().size() > 0, "not on the floor")
	assert_true(_room_with({Vector2i(10, 0): "o"}).validate().size() > 0, "not where a door's crack goes")
	assert_true(_room_with({Vector2i(9, 0): "o"}).validate().size() > 0, "not right beside a door")
	assert_true(_room_with({Vector2i(0, 0): "o"}).validate().size() > 0, "not in a corner")
