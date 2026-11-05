extends TestCase

# Head Office's bosses: Doreen, Executive Assistant, and the Chairman of the Board.

const Doreen := preload("res://scripts/actors/behaviors/doreen_behavior.gd")
const Chairman := preload("res://scripts/actors/behaviors/chairman_behavior.gd")
const Reverend := preload("res://scripts/actors/behaviors/reverend_behavior.gd")
const Diva := preload("res://scripts/actors/behaviors/fountain_diva_behavior.gd")
const Thrower := preload("res://scripts/actors/behaviors/thrower_behavior.gd")
# Head Office scales health by this, and its bosses hold their final health divided by it.
const OFFICE_HEALTH := 2.6
# The third floors scale by this, so their bosses' final health is their .tres health times it.
const FLOOR_THREE_HEALTH := 1.8
# The spec's final health for the fourth floor's bosses, which are built alongside this one. Once
# they are merged, the coordinator checks against their real numbers too.
const FLOOR_FOUR_MINI := 760.0
const FLOOR_FOUR_BOSS := 1950.0
const ROOMS: Array[Vector2i] = [Vector2i(14, 9), Vector2i(20, 11), Vector2i(30, 17)]


func _load(id: String) -> EnemyDef:
	return load("res://data/enemies/%s.tres" % id)


func _near_a_door(cell: Vector2i, cells: Vector2i, reach: int) -> bool:
	for door in FountainDivaBehavior.door_cells(cells):
		if absi(cell.x - door.x) <= reach and absi(cell.y - door.y) <= reach:
			return true
	return false


# --- Doreen: the memo storm ---

func test_the_memo_storm_drops_three_lanes_with_gaps_between() -> void:
	var room := ForemanBehavior.room_rect(Vector2i(20, 11))
	var feet := room.get_center()
	for down in [true, false]:
		var lanes := Doreen.memo_lanes(feet, room, down)
		assert_eq(lanes.size(), Doreen.MEMO_LANES, "three lanes in the open")
		var middle := lanes[1]
		assert_true(middle.has_point(feet), "the middle one is on him")
		for i in range(1, lanes.size()):
			var gap := lanes[i].position.x - lanes[i - 1].end.x if down else lanes[i].position.y - lanes[i - 1].end.y
			assert_near(gap, Doreen.MEMO_GAP, "a gap to stand in between lanes")
		for lane in lanes:
			if down:
				assert_near(lane.size.y, room.size.y, "it runs the room's whole height")
			else:
				assert_near(lane.size.x, room.size.x, "it runs the room's whole width")


func test_every_memo_lane_stays_inside_the_room() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for cells in ROOMS:
		var room := ForemanBehavior.room_rect(cells)
		for i in 200:
			var feet := Vector2(rng.randf_range(room.position.x, room.end.x), rng.randf_range(room.position.y, room.end.y))
			var lanes := Doreen.memo_lanes(feet, room, i % 2 == 0)
			assert_true(lanes.size() >= 2, "at least two lanes")
			for lane in lanes:
				assert_true(room.grow(0.01).encloses(lane), "%s inside %s" % [str(lane), str(room)])
			for a in lanes.size():
				for b in range(a + 1, lanes.size()):
					assert_false(lanes[a].intersects(lanes[b]), "lanes never overlap")


func test_memo_lanes_warn_long_enough_to_walk_out() -> void:
	var walk := PlayerStats.BASE_SPEED * (Doreen.MEMO_WARNING - 0.2)
	assert_true(walk > Doreen.MEMO_LANE_WIDTH, "%f" % walk)
	assert_true(Doreen.MEMO_GAP > Player.FEET_BOX_SIZE.x * 2.0, "a gap he fits in")


func test_a_lane_lands_once_on_feet_inside_it_only() -> void:
	var strip := Rect2(100, 32, 48, 288)
	var drop := LaneDrop.new()
	drop.setup(null, strip, 1.0, 0.3)
	assert_true(drop.is_waiting(), "a delayed lane waits first")
	assert_false(drop.advance(0.2))
	assert_near(drop.fill(), 0.0, "and shows no fill while it waits")
	drop.advance(0.2)
	assert_false(drop.is_waiting())
	assert_false(drop.advance(0.8), "still warning")
	assert_true(drop.advance(0.3), "it lands")
	assert_true(drop.hurts_at(Vector2(120, 100)))
	assert_false(drop.hurts_at(Vector2(160, 100)), "beside the lane is safe")
	drop.advance(LaneDrop.SHOW_TIME + 0.1)
	assert_true(drop.is_finished())
	assert_false(drop.hurts_at(Vector2(120, 100)), "the paper has settled")
	drop.free()


# --- Doreen: the hold music ---

func test_hold_music_spirals_out_in_even_arms() -> void:
	var ways := HoldMusic.note_ways(0.0, Doreen.MUSIC_ARMS, Doreen.MUSIC_NOTES, Doreen.MUSIC_TURN)
	assert_eq(ways.size(), Doreen.MUSIC_ARMS * Doreen.MUSIC_NOTES)
	assert_true(ways[0].is_equal_approx(Vector2.RIGHT), "the first arm starts where it was aimed")
	for arm in range(1, Doreen.MUSIC_ARMS):
		assert_near(rad_to_deg(absf(ways[arm - 1].angle_to(ways[arm]))), 360.0 / Doreen.MUSIC_ARMS, "arms evenly round her")
	for step in range(1, Doreen.MUSIC_NOTES):
		var before := ways[(step - 1) * Doreen.MUSIC_ARMS]
		var now := ways[step * Doreen.MUSIC_ARMS]
		assert_near(before.angle_to(now), Doreen.MUSIC_TURN, "each step turns a little further")
	var arm_points := HoldMusic.spiral_points(0.0, 0, Doreen.MUSIC_ARMS, Doreen.MUSIC_NOTES, Doreen.MUSIC_TURN, Doreen.MUSIC_EVERY, Doreen.NOTE_SPEED)
	assert_eq(arm_points.size(), Doreen.MUSIC_NOTES)
	for i in range(1, arm_points.size()):
		assert_true(arm_points[i].length() < arm_points[i - 1].length(), "the first note is furthest out")


func test_the_notes_wait_for_the_warning_then_come_one_step_at_a_time() -> void:
	var music := HoldMusic.new()
	music.setup(null, Doreen.MUSIC_WINDUP, 0.0, Doreen.MUSIC_ARMS, Doreen.MUSIC_NOTES, Doreen.MUSIC_EVERY, Doreen.MUSIC_TURN, Doreen.NOTE_SPEED)
	var sent := 0
	var time := 0.0
	var first_at := -1.0
	while time < 3.0:
		time += 1.0 / 60.0
		var due := music.advance(1.0 / 60.0)
		assert_true(due <= 1, "one step a frame at most at this frame rate")
		if due > 0 and first_at < 0.0:
			first_at = time
		sent += due
	assert_true(first_at >= Doreen.MUSIC_WINDUP - 0.001, "nothing before the warning ends, the first at %f" % first_at)
	assert_eq(sent, Doreen.MUSIC_NOTES, "every step comes")
	assert_true(music.is_finished())
	assert_near(HoldMusic.play_time(Doreen.MUSIC_NOTES, Doreen.MUSIC_EVERY), (Doreen.MUSIC_NOTES - 1) * Doreen.MUSIC_EVERY)
	music.free()
	var slow := HoldMusic.new()
	slow.setup(null, 0.1, 0.0, 3, 4, 0.15, 0.3, 90.0)
	assert_eq(slow.advance(1.0), 1, "a long frame after the warning still lets only the first step out")
	assert_eq(slow.advance(1.0), 3, "and the next long frame catches up the rest")
	slow.free()


func test_the_notes_are_slow_shots() -> void:
	assert_true(Doreen.NOTE_SPEED < Thrower.PROJECTILE_SPEED, "slower than a filing clerk's paper")
	assert_eq(HoldMusic.NOTE_LOOK, Projectile.LOOK_NOTE)
	var walk := PlayerStats.BASE_SPEED * (Doreen.MUSIC_WINDUP - 0.2)
	assert_true(walk + Doreen.NOTE_SPEED * Doreen.MUSIC_EVERY > Projectile.HIT_RADIUS * 2.0, "time to step off an arm")


# --- Doreen: the rest ---

func test_she_alternates_her_two_attacks() -> void:
	assert_eq(Doreen.choose_attack(Doreen.Attack.MEMOS, 0.1), Doreen.Attack.MUSIC)
	assert_eq(Doreen.choose_attack(Doreen.Attack.MUSIC, 0.9), Doreen.Attack.MEMOS)


func test_she_calls_yes_men_who_pay_nothing_never_past_five() -> void:
	var def := _load("doreen")
	assert_eq(def.summon.id, "yes_man")
	assert_eq(Doreen.MAX_ENEMIES, 5)
	for alive in 9:
		var count := Doreen.summon_count(alive, Doreen.MAX_ENEMIES)
		assert_true(count >= 0 and count <= Doreen.SUMMON_COUNT)
		assert_true(alive + count <= maxi(Doreen.MAX_ENEMIES, alive), "%d alive, %d called" % [alive, count])
		assert_eq(BossMoves.can_summon(alive, Doreen.MAX_ENEMIES), alive < 5)
	var yes_man := Enemy.new()
	yes_man.setup(def.summon, null, 0.5)
	yes_man.is_summon = true
	yes_man.apply_floor(OFFICE_HEALTH, 3.0)
	assert_eq(yes_man.coin_value(), 0)
	yes_man.free()


func test_doreen_is_at_least_as_hard_as_the_mini_bosses_before_her() -> void:
	var def := _load("doreen")
	assert_true(def.is_boss)
	assert_true(absf(def.max_hp * OFFICE_HEALTH - 880.0) < 0.5, str(def.max_hp * OFFICE_HEALTH))
	assert_true(def.max_hp * OFFICE_HEALTH >= FLOOR_FOUR_MINI, "the fourth floor's minis, about 760 by the spec")
	for id in ["reverend", "gloria"]:
		assert_true(def.max_hp * OFFICE_HEALTH >= _load(id).max_hp * FLOOR_THREE_HEALTH, id)
	assert_true(Doreen.COOLDOWN <= Reverend.COOLDOWN, "rests no longer than the Reverend's")
	assert_true(Doreen.COOLDOWN <= Diva.COOLDOWN, "or Gloria's")
	assert_true(Doreen.MEMO_WINDUP <= Reverend.EULOGY_WINDUP + 0.001, "windups no slower")
	assert_true(Doreen.MUSIC_WINDUP <= Diva.COIN_WINDUP + 0.001)
	assert_true(Doreen.SUMMON_COUNT >= Reverend.SUMMON_COUNT)
	assert_true(def.speed >= _load("gloria").speed)
	var body := def.body_size * 0.8
	assert_true(body.x <= RoomBackdrop.TILE and body.y <= RoomBackdrop.TILE, "her box fits one cell")


# --- the Chairman: the gavel ---

func test_the_gavel_costs_three_pills_and_its_warning_shows_whole() -> void:
	assert_eq(Chairman.GAVEL_DAMAGE, Enemy.HEAVIEST_DAMAGE)
	assert_eq(Chairman.GAVEL_DAMAGE, 3)
	assert_true(Chairman.GAVEL_SHOWN_WHOLE)
	assert_near(Chairman.GAVEL_WINDUP, 1.2)
	for phase_two in [false, true]:
		assert_near(Chairman.windup_for(Chairman.Attack.GAVEL, phase_two), 1.2, "the second phase never shortens it")
	var chairman := Enemy.new()
	chairman.setup(_load("chairman_of_the_board"), null, 0.25)
	var telegraph := Telegraph.new()
	telegraph.start(Chairman.GAVEL_WINDUP)
	chairman.set_warning(telegraph, Chairman.WARNING_RADIUS, Chairman.GAVEL_SHOWN_WHOLE)
	assert_near(chairman._warning_share(), 1.0, "whatever his warning stat")
	assert_true(telegraph.shows_warning(chairman._warning_share()), "it shows from the first instant")
	chairman.free()


func test_the_gavels_mark_fills_for_its_whole_windup_with_a_second_ring() -> void:
	var strike := GavelStrike.new()
	strike.setup(null, Chairman.GAVEL_RADIUS, Chairman.GAVEL_WINDUP, 0.0, 0.0, Chairman.GAVEL_DAMAGE)
	assert_true(strike is GroundStrike, "it lands as any warned spot does")
	assert_true(RoomView.is_passing_effect(strike), "and is cleared from a stored room")
	assert_eq(strike.damage(), 3)
	assert_true(GavelStrike.RING_GAP > 0.0, "a second ring outside the first")
	assert_false(strike.advance(Chairman.GAVEL_WINDUP - 0.05), "no landing before the windup is over")
	assert_true(strike.fill() > 0.9, "the mark has filled almost all the way")
	assert_true(strike.advance(0.1), "it lands at the end of the windup")
	strike.free()


func test_he_can_step_out_of_the_gavel_in_time() -> void:
	var walk := PlayerStats.BASE_SPEED * (Chairman.GAVEL_WINDUP - 0.3)
	assert_true(walk > Chairman.GAVEL_RADIUS * 2.0, "%f" % walk)


# --- the Chairman: quarterly projections ---

func test_the_bars_and_gaps_cover_the_room_and_stay_inside_it() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	for cells in ROOMS:
		var room := ForemanBehavior.room_rect(cells)
		for seed_value in 200:
			var bars := Chairman.projection_bars(room, rng.randf() * 200.0)
			var gaps := Chairman.projection_gaps(room, bars)
			assert_true(bars.size() >= 3, "a chart has bars")
			var covered := 0.0
			for bar in bars:
				assert_true(room.grow(0.01).encloses(bar), "bar %s inside %s" % [str(bar), str(room)])
				assert_true(bar.size.x >= Chairman.BAR_MIN - 0.01)
				assert_near(bar.size.y, room.size.y, "each bar runs the room's height")
				covered += bar.size.x
			var standable := 0
			for gap in gaps:
				assert_true(room.grow(0.01).encloses(gap), "gap %s inside %s" % [str(gap), str(room)])
				for bar in bars:
					assert_false(gap.intersects(bar), "a gap is never under a bar")
				covered += gap.size.x
				if gap.size.x >= Chairman.BAR_GAP - 0.01:
					standable += 1
			assert_near(covered, room.size.x, "bars and gaps fill the room from wall to wall")
			assert_true(standable >= 1, "seed %d: always a gap to stand in" % seed_value)


func test_a_safe_gap_is_always_marked_and_never_under_a_bar_or_him() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for cells in ROOMS:
		var room := ForemanBehavior.room_rect(cells)
		for seed_value in 200:
			var bars := Chairman.projection_bars(room, rng.randf() * 200.0)
			var gaps := Chairman.projection_gaps(room, bars)
			var feet := Vector2(rng.randf_range(room.position.x, room.end.x), rng.randf_range(room.position.y, room.end.y))
			var boss_at := Vector2(rng.randf_range(room.position.x, room.end.x), rng.randf_range(room.position.y, room.end.y))
			var body := Rect2(boss_at - Vector2(22, 26), Vector2(44, 52))
			var spot := Chairman.safe_gap_point(gaps, feet, body)
			assert_true(spot != Vector2.INF, "seed %d: a spot is marked" % seed_value)
			if spot == Vector2.INF:
				continue
			assert_true(room.has_point(spot), "inside the room")
			assert_false(body.grow(SafeSpotMark.RADIUS).has_point(spot), "off his body")
			for bar in bars:
				assert_false(bar.has_point(spot), "never under a bar")


func test_bars_rise_in_turn_and_warn_long_enough() -> void:
	assert_true(Chairman.BAR_STAGGER > 0.0, "one after another")
	var walk := PlayerStats.BASE_SPEED * (Chairman.BAR_WARNING - 0.2)
	assert_true(walk > Chairman.BAR_WIDTH, "%f" % walk)
	assert_true(Chairman.BAR_GAP > Player.FEET_BOX_SIZE.x * 2.0, "a gap he fits in")
	var bar := LaneDrop.new()
	bar.setup(null, Rect2(32, 32, 64, 288), Chairman.BAR_WARNING, 0.0, Chairman.BAR_STAND, -1, LaneDrop.LOOK_BAR)
	assert_true(bar.advance(Chairman.BAR_WARNING + 0.01), "it rises")
	bar.advance(Chairman.BAR_STAND * 0.5)
	assert_true(bar.hurts_at(Vector2(60, 100)), "and hurts while it stands")
	bar.advance(Chairman.BAR_STAND)
	assert_false(bar.hurts_at(Vector2(60, 100)), "not once it sinks")
	bar.free()
	assert_true(Chairman.projection_time(5) > Chairman.BAR_WARNING)


# --- the Chairman: hostile takeover ---

func test_a_dodge_snaps_the_tether() -> void:
	assert_true(Chairman.tether_holds(false))
	assert_false(Chairman.tether_holds(true))
	assert_true(Chairman.TETHER_SHOWN_WHOLE)
	var walk := PlayerStats.BASE_SPEED * (Chairman.TETHER_WINDUP - 0.3)
	assert_true(walk > Chairman.TETHER_LANE_WIDTH, "time to react")
	var tether := TakeoverTether.new()
	tether.setup(null, Chairman.TETHER_WINDUP)
	assert_false(tether.is_snapped())
	tether.snap()
	assert_true(tether.is_snapped())
	assert_true(RoomView.is_passing_effect(tether))
	tether.free()


func test_the_pull_is_short_and_never_brings_him_too_close() -> void:
	assert_true(Chairman.PULL_SPEED * Chairman.PULL_TIME <= 96.0, "a short way, three cells at most")
	for distance: float in [0.0, 30.0, Chairman.PULL_KEEP, 70.0, 100.0, 200.0, 400.0]:
		var seconds := Chairman.pull_time(distance)
		assert_true(seconds >= 0.0 and seconds <= Chairman.PULL_TIME + 0.0001, str(distance))
		if distance >= Chairman.PULL_KEEP:
			assert_true(distance - Chairman.PULL_SPEED * seconds >= Chairman.PULL_KEEP - 0.01, "kept %f away at %f" % [Chairman.PULL_KEEP, distance])
		else:
			assert_near(seconds, 0.0, "already close, no pull")
	var shove := Chairman.pull_shove(Vector2(100, 100), Vector2(300, 100))
	assert_true(shove.normalized().is_equal_approx(Vector2.RIGHT), "toward him")
	assert_near(shove.length(), Chairman.PULL_SPEED)
	assert_eq(Chairman.pull_shove(Vector2(5, 5), Vector2(5, 5)), Vector2.ZERO)


func test_the_pull_is_a_push_that_walls_stop_and_a_dodge_breaks() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/actors/behaviors/chairman_behavior.gd")
	assert_true(source.contains("enemy.target.push("), "the pull goes through Player.push, which slides against walls")
	assert_false(source.contains("target.global_position =") or source.contains("target.position ="), "he is never moved by hand through anything")
	var player_source := FileAccess.get_file_as_string("res://scripts/actors/player.gd")
	assert_true(player_source.contains("breaks free of any gust"), "a dodge breaks any push")
	var empty: Array[UpgradeDef] = []
	var player := Player.new()
	player.setup(RunState.new(empty, {}))
	player.push(Chairman.pull_shove(Vector2.ZERO, Vector2(100, 0)), Chairman.pull_time(200.0))
	assert_true(player.is_pushed())
	player.free()


func test_the_charge_after_the_pull_warns_its_own_lane() -> void:
	var walk := PlayerStats.BASE_SPEED * (Chairman.CHARGE_WINDUP - 0.3)
	assert_true(walk > Chairman.CHARGE_LANE_WIDTH, "%f" % walk)
	assert_eq(Chairman.CHARGE_DAMAGE, Enemy.HEAVY_DAMAGE, "heavy, but not the heaviest")


func test_the_takeover_is_only_for_when_he_is_far() -> void:
	for roll in [0.0, 0.3, 0.6, 0.99]:
		for distance: float in [0.0, 60.0, 100.0, Chairman.TAKEOVER_START - 1.0]:
			assert_true(Chairman.choose_attack(Chairman.Attack.NONE, distance, false, roll) != Chairman.Attack.TAKEOVER)
	var seen := {}
	for i in 100:
		seen[Chairman.choose_attack(Chairman.Attack.NONE, 200.0, false, i / 100.0)] = true
	assert_true(seen.has(Chairman.Attack.TAKEOVER), "far away it comes")
	assert_true(seen.has(Chairman.Attack.GAVEL))
	for last in [Chairman.Attack.GAVEL, Chairman.Attack.TAKEOVER]:
		for i in 20:
			assert_true(Chairman.choose_attack(last, 200.0, false, i / 20.0) != last, "never the same twice running")


# --- the Chairman: the desk slam up close ---

func test_the_desk_slam_answers_him_up_close() -> void:
	var seen := {}
	for i in 100:
		seen[Chairman.choose_attack(Chairman.Attack.NONE, 50.0, false, i / 100.0)] = true
	assert_true(seen.has(Chairman.Attack.SLAM), "up close he slams")
	assert_true(Chairman.SLAM_START >= 75.0 and Chairman.SLAM_START <= 85.0, "about 80 px")
	for i in 20:
		assert_true(Chairman.choose_attack(Chairman.Attack.SLAM, 50.0, false, i / 20.0) != Chairman.Attack.SLAM, "never twice running")
		assert_true(Chairman.choose_attack(Chairman.Attack.NONE, 100.0, false, i / 20.0) != Chairman.Attack.SLAM, "not from further off")
		assert_true(Chairman.choose_attack(Chairman.Attack.NONE, 50.0, true, i / 20.0) == Chairman.Attack.GAVEL, "while a chart runs he only gavels")


func test_the_desk_slam_warns_whole_and_leaves_time_to_step_out() -> void:
	assert_true(Chairman.SLAM_SHOWN_WHOLE, "it starts right beside him")
	for phase_two in [false, true]:
		assert_near(Chairman.windup_for(Chairman.Attack.SLAM, phase_two), Chairman.SLAM_WINDUP, "the second phase never shortens it")
	var body := _load("chairman_of_the_board").body_size * 0.8
	var closest := minf(body.x, body.y) / 2.0
	var walk := PlayerStats.BASE_SPEED * (Chairman.SLAM_WINDUP - 0.3)
	assert_true(walk > Chairman.SLAM_RADIUS - closest + 4.0, "out of the ring from right beside him: %f" % walk)
	assert_true(Chairman.SLAM_RADIUS <= Chairman.SLAM_START, "the ring reaches where it is called for")
	var slam := DeskSlam.new()
	slam.setup(null, Chairman.SLAM_RADIUS, Chairman.SLAM_WINDUP)
	assert_true(slam is GroundStrike, "it lands as any warned spot does")
	assert_true(RoomView.is_passing_effect(slam), "and is cleared from a stored room")
	assert_false(slam.advance(Chairman.SLAM_WINDUP - 0.05))
	assert_true(slam.advance(0.1))
	slam.free()
	var shove := DeskSlam.shove_for(Vector2(100, 100), Vector2(140, 100))
	assert_true(shove.normalized().is_equal_approx(Vector2.RIGHT), "away from him")
	assert_true(DeskSlam.SHOVE_SPEED * DeskSlam.SHOVE_TIME <= 96.0, "a short shove")
	assert_true(DeskSlam.shove_for(Vector2(5, 5), Vector2(5, 5)) != Vector2.ZERO, "even right under him")


# --- the Chairman: the chart and the gavel together ---

func _boss_layout(name: String) -> RoomLayout:
	return load("res://data/rooms/head_office/%s.tres" % name)


func _open_in(layout: RoomLayout) -> Callable:
	return func(spot: Vector2) -> bool: return not layout.is_solid_at(WalkGrid.cell_of(spot))


# A spot for feet: open floor, its whole feet box on open cells.
func _feet_spot(layout: RoomLayout, rng: RandomNumberGenerator, room: Rect2) -> Vector2:
	var is_open := _open_in(layout)
	for i in 200:
		var spot := Vector2(rng.randf_range(room.position.x + 10.0, room.end.x - 10.0), rng.randf_range(room.position.y + 10.0, room.end.y - 10.0))
		var box := Rect2(spot - Player.FEET_BOX_SIZE / 2.0, Player.FEET_BOX_SIZE)
		if is_open.call(box.position) and is_open.call(box.end) and is_open.call(Vector2(box.position.x, box.end.y)) and is_open.call(Vector2(box.end.x, box.position.y)):
			return spot
	return room.get_center()


func test_projection_gaps_are_all_wide_enough_to_stand_in() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for cells in ROOMS:
		var room := ForemanBehavior.room_rect(cells)
		for i in 200:
			var bars := Chairman.projection_bars(room, rng.randf() * 200.0)
			for gap in Chairman.projection_gaps(room, bars):
				assert_true(gap.size.x >= Chairman.BAR_GAP - 0.01, "%s in %s" % [str(gap), str(room)])
			for bar in bars:
				assert_true(bar.size.x <= Chairman.BAR_WIDTH + 0.01)


func test_bar_windows_follow_the_order_they_rise_in() -> void:
	var left := Chairman.bar_windows(4, true)
	assert_near(left[0].x, Chairman.BAR_WARNING)
	assert_near(left[3].x, Chairman.BAR_WARNING + 3 * Chairman.BAR_STAGGER)
	assert_near(left[0].y - left[0].x, Chairman.BAR_STAND)
	var right := Chairman.bar_windows(4, false, 0.5)
	assert_near(right[3].x, Chairman.BAR_WARNING - 0.5, "the right one first, counted from half a second in")
	var bar := LaneDrop.new()
	bar.setup(null, Rect2(32, 32, 64, 288), Chairman.BAR_WARNING, 0.3, Chairman.BAR_STAND, -1, LaneDrop.LOOK_BAR)
	var window := bar.danger_window()
	assert_near(window.x, 0.3 + Chairman.BAR_WARNING, "a bar's own window agrees")
	assert_near(window.y, 0.3 + Chairman.BAR_WARNING + Chairman.BAR_STAND)
	bar.advance(0.3)
	bar.advance(Chairman.BAR_WARNING + 0.01)
	bar.advance(Chairman.BAR_STAND + 0.01)
	assert_true(bar.danger_window().y < 0.0, "and is over once it sinks")
	bar.free()


# Over 200 charts in both of his rooms, with him and Grandpa anywhere, in both phases (the second with
# red tape going up as the chart does): every chart marks a spot he can reach, and every gavel while
# the bars run leaves a spot he can reach in time, off every bar, off the gavel and off the Chairman.
func test_a_gavel_during_a_chart_always_leaves_a_reachable_safe_spot() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	var on_feet := 0
	for seed_value in 200:
		var layout := _boss_layout("floor_boss_01" if seed_value % 2 == 0 else "floor_boss_large_01")
		var cells := layout.size_in_cells()
		var room := ForemanBehavior.room_rect(cells)
		var is_open := _open_in(layout)
		var bars := Chairman.projection_bars(room, rng.randf() * 200.0)
		var left_first := rng.randf() < 0.5
		var feet := _feet_spot(layout, rng, room)
		var boss_at := _feet_spot(layout, rng, room)
		if boss_at.distance_to(feet) < 50.0:
			boss_at = room.get_center() if feet.distance_to(room.get_center()) >= 50.0 else room.position + Vector2(40, 40)
		var body := Rect2(boss_at - Vector2(22, 26), Vector2(44, 52))
		var tape := {}
		var phase_two := seed_value % 4 >= 2
		if phase_two:
			for cell in Chairman.tape_cells(cells, WalkGrid.cell_of(feet), is_open):
				tape[cell] = TapeSpread.WARNING - Chairman.windup_for(Chairman.Attack.PROJECTIONS, true)
		var fresh := Chairman.chart_route(room, bars, Chairman.bar_windows(bars.size(), left_first), body, is_open, tape)
		var first_mark := Chairman.chart_mark(fresh, feet, body)
		assert_true(first_mark != Vector2.INF, "seed %d: the chart marks a spot" % seed_value)
		for bar in bars:
			assert_false(bar.has_point(first_mark), "seed %d: the mark is never under a bar" % seed_value)
		# The gavel comes as the chart is raised in the second phase, after a rest in the first, or
		# later on in the chart for a second gavel.
		var elapsed := 0.0 if phase_two else Chairman.BASE_COOLDOWN * 0.5
		if seed_value % 5 == 4:
			elapsed = Chairman.GAVEL_WINDUP + Chairman.BASE_COOLDOWN
		var route := Chairman.chart_route(room, bars, Chairman.bar_windows(bars.size(), left_first, elapsed), body, is_open, tape)
		var plan := Chairman.gavel_plan(route, feet, body, is_open)
		assert_true(plan["spot"] != Vector2.INF, "seed %d: the gavel finds a spot" % seed_value)
		if plan["spot"] == Vector2.INF:
			continue
		if plan["spot"] == feet:
			on_feet += 1
		var mark: Vector2 = plan["mark"]
		assert_true(mark.distance_to(plan["spot"]) > Chairman.GAVEL_RADIUS, "seed %d: the mark is off the gavel" % seed_value)
		assert_false(body.grow(SafeSpotMark.RADIUS).has_point(mark), "seed %d: off his body" % seed_value)
		assert_true(route.danger_end_at(mark) <= 0.0, "seed %d: no bar covers the mark" % seed_value)
		route.set_extra_circle(plan["spot"], Chairman.GAVEL_RADIUS, Chairman.GAVEL_WINDUP, Chairman.GAVEL_WINDUP + OverlapRoute.STEP_TIME)
		assert_true(route.escape(feet)["safe"], "seed %d: and he can walk clear of it all" % seed_value)
	assert_true(on_feet > 100, "most gavels still fall on him: %d of 200" % on_feet)


# --- the Chairman: phase two ---

func test_only_the_second_phase_spreads_tape_and_not_too_often() -> void:
	assert_false(Chairman.spreads_tape(false, 100.0))
	assert_true(Chairman.spreads_tape(true, Chairman.TAPE_EVERY))
	assert_false(Chairman.spreads_tape(true, Chairman.TAPE_EVERY - 0.1))
	assert_true(Chairman.is_phase_two(1000.0, 2250.0))
	assert_false(Chairman.is_phase_two(1200.0, 2250.0))
	assert_near(TapeSpread.LAST, 10.0, "the tape stays ten seconds")
	var walk := PlayerStats.BASE_SPEED * (TapeSpread.WARNING - 0.2)
	assert_true(walk > RoomBackdrop.TILE, "time to step off a warned row")


func test_spread_tape_lies_in_rows_inside_the_room_off_doors_and_props() -> void:
	var is_open := func(spot: Vector2) -> bool:
		var cell := WalkGrid.cell_of(spot)
		return not (cell.x >= 6 and cell.x <= 7 and cell.y >= 3 and cell.y <= 6)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for cells in ROOMS:
		for i in 200:
			var target := Vector2i(rng.randi_range(1, cells.x - 2), rng.randi_range(1, cells.y - 2))
			var taped := Chairman.tape_cells(cells, target, is_open)
			assert_false(taped.is_empty(), "%s: some tape" % str(cells))
			var rows := {}
			for cell in taped:
				rows[cell.y] = true
				assert_true(cell.x >= 1 and cell.y >= 1 and cell.x <= cells.x - 2 and cell.y <= cells.y - 2, "off the walls")
				assert_false(_near_a_door(cell, cells, RoomLayout.RED_TAPE_DOOR_CLEARANCE), "two cells off the doors at %s" % str(cell))
				assert_true(is_open.call(RoomBackdrop.cell_center(cell)), "on open floor")
			assert_true(rows.size() <= Chairman.TAPE_ROWS, "at most three rows")
			if Chairman.can_be_taped(target, cells, is_open):
				assert_true(taped.has(target), "one row runs through where he stands")


func test_every_chart_is_followed_by_the_gavel_straight_away_in_phase_two() -> void:
	var projections := Chairman.Attack.PROJECTIONS
	var gavel := Chairman.Attack.GAVEL
	assert_eq(Chairman.followup(projections, true), gavel)
	assert_eq(Chairman.followup(projections, false), gavel, "the gavel falls while the bars run in both phases")
	assert_near(Chairman.rest_after_chart(true), 0.0, "without a rest in the second phase")
	assert_true(Chairman.rest_after_chart(false) > 0.0)
	assert_eq(Chairman.followup(gavel, true), Chairman.Attack.NONE, "the gavel never chains again")
	for attack in [Chairman.Attack.TAKEOVER, Chairman.Attack.CHARGE, Chairman.Attack.TAPE, Chairman.Attack.SLAM]:
		assert_eq(Chairman.followup(attack, true), Chairman.Attack.NONE)
	for attack in [Chairman.Attack.PROJECTIONS, Chairman.Attack.TAKEOVER, Chairman.Attack.CHARGE, Chairman.Attack.TAPE]:
		assert_true(Chairman.windup_for(attack, true) < Chairman.windup_for(attack, false), "his other windups quicken")
	assert_true(Chairman.cooldown_for(true) < Chairman.cooldown_for(false))
	assert_true(Chairman.chart_break(true) < Chairman.chart_break(false), "charts come closer together")
	assert_near(Chairman.PHASE_TWO_SPEED, 1.2)


func test_phase_two_tape_goes_up_with_a_chart_not_on_its_own() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/actors/behaviors/chairman_behavior.gd")
	var begin := source.substr(source.find("func _begin("), 4000)
	var chart := begin.substr(begin.find("Attack.PROJECTIONS:"), 400)
	assert_true(chart.contains("spreads_tape(") and chart.contains("_spread_tape(enemy)"), "the tape spreads as the chart is raised")
	var tick := source.substr(source.find("func tick("), 2400)
	assert_false(tick.contains("Attack.TAPE"), "and never comes as an attack of its own")


func test_the_chairman_is_clearly_harder_than_every_floor_boss_before_him() -> void:
	var def := _load("chairman_of_the_board")
	assert_true(def.is_boss)
	# 2500 since the balance pass of 2026-11-05, so he ends above Augustine (2400), the hardest of all.
	assert_true(absf(def.max_hp * OFFICE_HEALTH - 2500.0) < 0.5, str(def.max_hp * OFFICE_HEALTH))
	assert_true(def.max_hp > _load("augustine").max_hp, "more than Augustine, who stands just below him")
	assert_true(def.max_hp * OFFICE_HEALTH >= FLOOR_FOUR_BOSS * 1.1, "the fourth floor's bosses, about 1950 by the spec")
	for id in ["mortimer_grimsby", "mall_santa"]:
		assert_true(def.max_hp * OFFICE_HEALTH >= _load(id).max_hp * FLOOR_THREE_HEALTH * 1.1, id)
	assert_true(Chairman.BASE_COOLDOWN < FuneralDirectorBehavior.BASE_COOLDOWN)
	assert_true(Chairman.BASE_COOLDOWN < MallSantaBehavior.BASE_COOLDOWN)
	assert_true(Chairman.PHASE_TWO_COOLDOWN < MallSantaBehavior.PHASE_TWO_COOLDOWN)
	assert_true(Chairman.GAVEL_DAMAGE > Enemy.HEAVY_DAMAGE)
	assert_true(def.speed >= _load("mall_santa").speed)
	assert_true(def.summon == null, "he calls no one")
