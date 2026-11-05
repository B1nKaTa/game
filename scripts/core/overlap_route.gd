class_name OverlapRoute
extends RefCounted

# Whether Grandpa can walk clear of several warned attacks at once, used by the floor-5 bosses before
# they overlap two attacks. The room's floor is a grid of feet positions STEP apart. He waits REACT
# seconds, then walks a step at a time at his base speed (never diagonally, which would be faster),
# never into anything solid, a raised rope or a boss's body. Each hazard is a rectangle or a circle
# that hurts between two times, counted from now. Red tape holds him RedTapeRule.HOLD seconds when
# he steps onto it, or when it is strung under him, and he must not be hit while held.
#
# The answer is cautious, so it can only miss a way out, never promise a false one: every hazard is
# grown by MARGIN (half a step, so nothing can pass between two grid points unseen, and a little
# more to spare) and lasts half a step longer at each end.
const STEP := 16.0
const MARGIN := 9.0
const REACT := 0.3
const STEP_TIME := STEP / PlayerStats.BASE_SPEED

var area := Rect2()
# How long he stands before he walks; REACT unless a check asks how much later he could start.
var react := REACT
var _nx := 0
var _ny := 0
var _rects: Array[Rect2] = []
var _rect_times: Array[Vector2] = []
var _circles: Array[Vector3] = []
var _circle_times: Array[Vector2] = []
var _blocks: Array[Rect2] = []
var _is_open := Callable()
var _sticky := {}
var _extra := Vector3.ZERO
var _extra_time := Vector2(-1.0, -1.0)
# Worked out once per room plan: which positions are blocked, and the hazards over each one.
var _built := false
var _blocked := PackedByteArray()
var _covers: Array = []
var _last_end := PackedFloat32Array()
# Blocked positions taken from another route over the same floor (share_floor), or empty.
var _shared_blocked := PackedByteArray()


func _init(room: Rect2) -> void:
	area = room
	_nx = maxi(floori(room.size.x / STEP), 1)
	_ny = maxi(floori(room.size.y / STEP), 1)


# A strip of floor that hurts from one time to another, counted from now.
func add_rect(rect: Rect2, from: float, to: float) -> void:
	_rects.append(rect.grow(MARGIN))
	_rect_times.append(Vector2(from - STEP_TIME / 2.0, to + STEP_TIME / 2.0))
	_built = false


func add_circle(center: Vector2, radius: float, from: float, to: float) -> void:
	_circles.append(Vector3(center.x, center.y, radius + MARGIN))
	_circle_times.append(Vector2(from - STEP_TIME / 2.0, to + STEP_TIME / 2.0))
	_built = false


# One more circle that can be changed without working the room out again, for trying the spots a
# heavy strike could fall on.
func set_extra_circle(center: Vector2, radius: float, from: float, to: float) -> void:
	_extra = Vector3(center.x, center.y, radius + MARGIN)
	_extra_time = Vector2(from - STEP_TIME / 2.0, to + STEP_TIME / 2.0)


func clear_extra_circle() -> void:
	_extra_time = Vector2(-1.0, -1.0)


# Something his feet may not enter: a raised rope, a body.
func add_block(rect: Rect2) -> void:
	_blocks.append(rect)
	_built = false


# is_open takes a point and says whether the cell there is open floor.
func set_open(is_open: Callable) -> void:
	_is_open = is_open
	_built = false


# Uses the blocked positions of another route over the same room, blocks and open cells, so a plan
# that tries many hazard layouts over one floor works the floor out once (it is most of the cost in
# a large room). Blocks and open cells given to this route are then ignored.
func share_floor(other: OverlapRoute) -> void:
	other._build()
	if other.area == area:
		_shared_blocked = other._blocked
		_built = false


# A copy of this route with more strips over it, each hurting in its own window, sharing this route's
# floor: for trying layouts of a new attack over attacks already under way.
func with_rects(rects: Array[Rect2], windows: Array[Vector2]) -> OverlapRoute:
	var copy := OverlapRoute.new(area)
	copy.react = react
	copy._rects = _rects.duplicate()
	copy._rect_times = _rect_times.duplicate()
	copy._circles = _circles.duplicate()
	copy._circle_times = _circle_times.duplicate()
	copy._blocks = _blocks.duplicate()
	copy._is_open = _is_open
	copy._sticky = _sticky.duplicate()
	copy._extra = _extra
	copy._extra_time = _extra_time
	for i in rects.size():
		copy.add_rect(rects[i], windows[i].x, windows[i].y)
	copy.share_floor(self)
	return copy


# Red tape on a cell, strung from a time counted from now (0 when it is strung already).
func add_sticky(cell: Vector2i, from: float) -> void:
	_sticky[cell] = minf(_sticky.get(cell, INF), from)


func position_of(index: int) -> Vector2:
	return area.position + Vector2((index % _nx) + 0.5, (index / _nx) + 0.5) * STEP


func index_of(point: Vector2) -> int:
	var i := clampi(floori((point.x - area.position.x) / STEP), 0, _nx - 1)
	var j := clampi(floori((point.y - area.position.y) / STEP), 0, _ny - 1)
	return j * _nx + i


# When the last hazard over a point ends, or 0 when none ever covers it. The extra circle counts.
func danger_end_at(point: Vector2) -> float:
	_build()
	var end := _last_end[index_of(point)]
	if _extra_time.y >= 0.0 and _in_circle(point, _extra):
		end = maxf(end, _extra_time.y)
	return end


func is_blocked_at(point: Vector2) -> bool:
	_build()
	return _blocked[index_of(point)] != 0


# Searches every way he could walk. "safe" says whether one keeps him unhurt to the end; "haven" is
# the nearest spot he reaches that nothing hurts from then on; "pure" the nearest spot nothing ever
# hurts, for marking (Vector2.INF when none was reached). keep_off, when valid, takes a point and
# says whether a mark may not go there.
func escape(feet: Vector2, keep_off := Callable()) -> Dictionary:
	_build()
	var result := {"safe": false, "haven": Vector2.INF, "pure": Vector2.INF, "arrive": INF}
	var count := _nx * _ny
	var horizon := 0.0
	for window in _rect_times:
		horizon = maxf(horizon, window.y)
	for window in _circle_times:
		horizon = maxf(horizon, window.y)
	horizon = maxf(horizon, _extra_time.y)
	var steps := ceili(horizon / STEP_TIME) + 1
	var start := index_of(feet)
	var current := PackedInt32Array([start])
	var seen := PackedInt32Array()
	seen.resize(count)
	seen.fill(-1)
	# Positions reached while held by tape, by the step they are let go.
	var later := {}
	for k in range(1, steps + 1):
		var t := k * STEP_TIME
		var t_before := (k - 1) * STEP_TIME
		var next := PackedInt32Array()
		if later.has(k):
			for q in later[k]:
				if seen[q] != k:
					seen[q] = k
					next.append(q)
		for p in current:
			var moves := PackedInt32Array([p])
			if t > react:
				var i := p % _nx
				if i > 0:
					moves.append(p - 1)
				if i < _nx - 1:
					moves.append(p + 1)
				if p >= _nx:
					moves.append(p - _nx)
				if p < count - _nx:
					moves.append(p + _nx)
			for q in moves:
				if seen[q] == k:
					continue
				if _blocked[q] != 0 and not (q == p and p == start):
					continue
				if _danger(q, t):
					continue
				var hold := _hold_steps(p, q, t_before, t)
				if hold > 0:
					var free_at := k + hold
					var held_safe := true
					for h in range(k + 1, free_at + 1):
						if _danger(q, h * STEP_TIME):
							held_safe = false
							break
					if not held_safe:
						continue
					if not later.has(free_at):
						later[free_at] = []
					later[free_at].append(q)
					continue
				seen[q] = k
				next.append(q)
		current = next
		if current.is_empty() and not _held_after(later, k):
			return result
		for q in current:
			# Standing on a rope or a body is no place to mark.
			if _blocked[q] != 0:
				continue
			var spot := position_of(q)
			var end := _last_end[q]
			if _extra_time.y >= 0.0 and _in_circle(spot, _extra):
				end = maxf(end, _extra_time.y)
			if result["haven"] == Vector2.INF and end <= t:
				result["haven"] = spot
			if end <= 0.0 and (not keep_off.is_valid() or not keep_off.call(spot)):
				result["pure"] = spot
				result["arrive"] = t
				result["safe"] = true
				if result["haven"] == Vector2.INF:
					result["haven"] = spot
				return result
	result["safe"] = not current.is_empty()
	if result["safe"] and result["haven"] == Vector2.INF:
		result["haven"] = position_of(current[0])
	return result


# Where a heavy strike aimed at his feet may fall so that he still has a way out and a spot to mark:
# his feet first, then ever further off. Returns {spot, mark}, each
# Vector2.INF when nowhere works. lands_in counts from now; open_at says where a strike may land.
func strike_plan(feet: Vector2, radius: float, lands_in: float, open_at := Callable(), keep_off := Callable()) -> Dictionary:
	var tries: Array[Vector2] = [feet]
	for ring: float in [24.0, 48.0, 72.0, 96.0]:
		for k in 8:
			tries.append(feet + Vector2.from_angle(TAU * k / 8.0) * ring)
	for spot in tries:
		if not area.has_point(spot) or (open_at.is_valid() and not open_at.call(spot)):
			continue
		set_extra_circle(spot, radius, lands_in, lands_in + STEP_TIME)
		var out := escape(feet, keep_off)
		if out["safe"] and out["pure"] != Vector2.INF:
			clear_extra_circle()
			return {"spot": spot, "mark": out["pure"]}
	clear_extra_circle()
	return {"spot": Vector2.INF, "mark": Vector2.INF}


func _held_after(later: Dictionary, k: int) -> bool:
	for step in later:
		if int(step) > k:
			return true
	return false


func _build() -> void:
	if _built:
		return
	_built = true
	var count := _nx * _ny
	_blocked.resize(count)
	_last_end.resize(count)
	_covers.resize(count)
	if _shared_blocked.size() == count:
		_blocked = _shared_blocked.duplicate()
	else:
		_build_blocked()
	for index in count:
		var spot := position_of(index)
		var over: Array[Vector2] = []
		var end := 0.0
		for r in _rects.size():
			if _rects[r].has_point(spot):
				over.append(_rect_times[r])
				end = maxf(end, _rect_times[r].y)
		for c in _circles.size():
			if _in_circle(spot, _circles[c]):
				over.append(_circle_times[c])
				end = maxf(end, _circle_times[c].y)
		_covers[index] = over
		_last_end[index] = end


# Which positions his feet box may not stand on. Each block marks only the positions near it, and
# is_open, which answers for a whole cell (set_open), is asked once per cell, since both were slow
# in a large room with many ropes.
func _build_blocked() -> void:
	_blocked.fill(0)
	var feet_half := Player.FEET_BOX_SIZE / 2.0
	for block in _blocks:
		var i_from := clampi(floori((block.position.x - feet_half.x - area.position.x) / STEP - 0.5), 0, _nx - 1)
		var i_to := clampi(ceili((block.end.x + feet_half.x - area.position.x) / STEP - 0.5), 0, _nx - 1)
		var j_from := clampi(floori((block.position.y - feet_half.y - area.position.y) / STEP - 0.5), 0, _ny - 1)
		var j_to := clampi(ceili((block.end.y + feet_half.y - area.position.y) / STEP - 0.5), 0, _ny - 1)
		for j in range(j_from, j_to + 1):
			for i in range(i_from, i_to + 1):
				var index := j * _nx + i
				if _blocked[index] == 0 and block.intersects(Rect2(position_of(index) - feet_half, Player.FEET_BOX_SIZE)):
					_blocked[index] = 1
	if not _is_open.is_valid():
		return
	var asked := {}
	for index in _nx * _ny:
		if _blocked[index] != 0:
			continue
		var box := Rect2(position_of(index) - feet_half, Player.FEET_BOX_SIZE)
		for corner: Vector2 in [box.position, Vector2(box.end.x, box.position.y), box.end, Vector2(box.position.x, box.end.y)]:
			var cell := WalkGrid.cell_of(corner)
			if not asked.has(cell):
				asked[cell] = _is_open.call(corner)
			if not asked[cell]:
				_blocked[index] = 1
				break


func _in_circle(spot: Vector2, circle: Vector3) -> bool:
	return spot.distance_to(Vector2(circle.x, circle.y)) <= circle.z


func _danger(index: int, t: float) -> bool:
	for window: Vector2 in _covers[index]:
		if t >= window.x and t <= window.y:
			return true
	if _extra_time.y >= 0.0 and t >= _extra_time.x and t <= _extra_time.y and _in_circle(position_of(index), _extra):
		return true
	return false


# How many steps tape holds him for moving from p to q between two times: when q's cell is strung
# tape at the later time and he was not on strung tape at the earlier one.
func _hold_steps(p: int, q: int, t_before: float, t: float) -> int:
	if _sticky.is_empty():
		return 0
	var q_cell := WalkGrid.cell_of(position_of(q))
	if not _sticky.has(q_cell) or t < _sticky[q_cell]:
		return 0
	var p_cell := WalkGrid.cell_of(position_of(p))
	if _sticky.has(p_cell) and t_before >= _sticky[p_cell]:
		return 0
	return ceili(RedTapeRule.HOLD / STEP_TIME)
