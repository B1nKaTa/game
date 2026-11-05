extends SceneTree
# How much later than his usual reaction Grandpa could start and still walk clear of Augustine's
# runway (and the stamp after it) and the Chairman's chart (and a gavel during it), over the same
# 200 seeds as their tests. Headless, touches no save. Prints the spread of that slack per attack.

const Augustine := preload("res://scripts/actors/behaviors/head_of_departures_behavior.gd")
const Chairman := preload("res://scripts/actors/behaviors/chairman_behavior.gd")


func _open(layout: RoomLayout) -> Callable:
	return func(spot: Vector2) -> bool: return not layout.is_solid_at(WalkGrid.cell_of(spot))


func _ropes_of(layout: RoomLayout) -> Array[Rect2]:
	var ropes: Array[Rect2] = []
	var size := layout.size_in_cells()
	for y in size.y:
		for x in size.x:
			var cell := Vector2i(x, y)
			if layout.symbol_at(cell) == RoomLayout.SYMBOL_BARRIER:
				ropes.append(QueueBarrier.rope_rect(RoomBackdrop.cell_center(cell), layout.barrier_runs_across(cell)))
	return ropes


func _clear_spot(layout: RoomLayout, ropes: Array[Rect2], rng: RandomNumberGenerator, room: Rect2) -> Vector2:
	for i in 400:
		var spot := Vector2(rng.randf_range(room.position.x + 10.0, room.end.x - 10.0), rng.randf_range(room.position.y + 10.0, room.end.y - 10.0))
		var box := Rect2(spot - Player.FEET_BOX_SIZE / 2.0, Player.FEET_BOX_SIZE)
		var clear := true
		for corner in [box.position, box.end, Vector2(box.position.x, box.end.y), Vector2(box.end.x, box.position.y)]:
			if layout.is_solid_at(WalkGrid.cell_of(corner)):
				clear = false
		for rope in ropes:
			if rope.intersects(box):
				clear = false
		if clear:
			return spot
	return room.get_center()


# The longest extra wait (in steps of 0.05 s) after the usual reaction that still escapes.
func _slack(route: OverlapRoute, feet: Vector2) -> float:
	var extra := 0.0
	while extra < 2.0:
		route.react = OverlapRoute.REACT + extra + 0.05
		if not route.escape(feet)["safe"]:
			break
		extra += 0.05
	route.react = OverlapRoute.REACT
	return extra


func _report(label: String, values: Array) -> void:
	values.sort()
	var n := values.size()
	if n == 0:
		print("%s: none" % label)
		return
	var under := 0
	for v in values:
		if v < 0.2:
			under += 1
	print("%s: n %d, min %.2f, p10 %.2f, median %.2f, under 0.2 s extra: %d" % [label, n, values[0], values[int(n * 0.1)], values[n / 2], under])


func _initialize() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var runway := []
	var runway_stamp := []
	var arrive := []
	for seed_value in 200:
		var layout: RoomLayout = load("res://data/rooms/terminal_zero/%s.tres" % ("floor_boss_01" if seed_value % 2 == 0 else "floor_boss_large_01"))
		var room := ForemanBehavior.room_rect(layout.size_in_cells())
		var ropes := _ropes_of(layout)
		var is_open := _open(layout)
		var feet := _clear_spot(layout, ropes, rng, room)
		var boss_at := _clear_spot(layout, ropes, rng, room)
		if boss_at.distance_to(feet) < 50.0:
			boss_at = feet + (Vector2(80, 0) if feet.x < room.get_center().x else Vector2(-80, 0))
		var body := Rect2(boss_at - Vector2(22, 26), Vector2(44, 52))
		var prefer := Vector2.RIGHT if seed_value % 3 == 0 else Vector2.DOWN
		var plan := Augustine.runway_plan(room, feet, prefer, rng.randf() < 0.5, ropes, body, is_open)
		if plan["direction"] == Vector2.ZERO:
			continue
		var lanes := Augustine.runway_lanes(room, plan["direction"], plan["center"], plan["reverse"])
		# The windup is a warning too: lanes are known once he says it, so the reaction starts then.
		var route := Augustine.runway_route(room, lanes, Augustine.runway_windows(), ropes, body, is_open)
		runway.append(_slack(route, feet))
		arrive.append(route.escape(feet)["arrive"])
		var elapsed := 0.0 if seed_value % 2 == 0 else Augustine.BASE_COOLDOWN * 0.5
		var live := Augustine.runway_route(room, lanes, Augustine.runway_windows(elapsed), ropes, body, is_open)
		var stamp := Augustine.stamp_plan(live, feet, body, is_open)
		if stamp["spot"] != Vector2.INF:
			live.set_extra_circle(stamp["spot"], Augustine.STAMP_RADIUS, Augustine.STAMP_WINDUP, Augustine.STAMP_WINDUP + OverlapRoute.STEP_TIME)
			runway_stamp.append(_slack(live, feet))
	_report("Augustine runway", runway)
	_report("Augustine runway then stamp", runway_stamp)
	_report("Augustine runway arrive (s)", arrive)
	rng.seed = 2026
	var chart := []
	var chart_gavel := []
	for seed_value in 200:
		var layout: RoomLayout = load("res://data/rooms/head_office/%s.tres" % ("floor_boss_01" if seed_value % 2 == 0 else "floor_boss_large_01"))
		var cells := layout.size_in_cells()
		var room := ForemanBehavior.room_rect(cells)
		var is_open := _open(layout)
		var rolls: Array[Vector2] = []
		for i in Chairman.CHART_TRIES:
			rolls.append(Vector2(rng.randf() * 200.0, rng.randf()))
		var feet := _clear_spot(layout, [] as Array[Rect2], rng, room)
		var boss_at := _clear_spot(layout, [] as Array[Rect2], rng, room)
		if boss_at.distance_to(feet) < 50.0:
			boss_at = room.get_center() if feet.distance_to(room.get_center()) >= 50.0 else room.position + Vector2(40, 40)
		var body := Rect2(boss_at - Vector2(22, 26), Vector2(44, 52))
		var tape := {}
		var phase_two := seed_value % 4 >= 2
		if phase_two:
			for cell in Chairman.tape_cells(cells, WalkGrid.cell_of(feet), is_open):
				tape[cell] = TapeSpread.WARNING - Chairman.windup_for(Chairman.Attack.PROJECTIONS, true)
		var choice := Chairman.choose_chart(room, rolls, feet, body, is_open, tape)
		if choice["mark"] == Vector2.INF:
			continue
		var route: OverlapRoute = choice["route"]
		chart.append(_slack(route, feet))
		var bars: Array[Rect2] = choice["bars"]
		var elapsed := 0.0 if phase_two else Chairman.BASE_COOLDOWN * 0.5
		var live := Chairman.chart_route(room, bars, Chairman.bar_windows(bars.size(), choice["left_first"], elapsed), body, is_open, tape)
		if not live.escape(feet)["safe"]:
			continue
		var plan := Chairman.gavel_plan(live, feet, body, is_open)
		if plan["spot"] != Vector2.INF:
			live.set_extra_circle(plan["spot"], Chairman.GAVEL_RADIUS, Chairman.GAVEL_WINDUP, Chairman.GAVEL_WINDUP + OverlapRoute.STEP_TIME)
			chart_gavel.append(_slack(live, feet))
	_report("Chairman chart", chart)
	_report("Chairman chart then gavel", chart_gavel)
	quit()
