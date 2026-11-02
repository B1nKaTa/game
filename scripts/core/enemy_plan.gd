class_name EnemyPlan
extends RefCounted

const GROUP_REACH := 2


# Who stands where when a room starts, from the room's layout and its floor's mix. Each entry
# holds "def", "cell" and "leader", where only the leader of a group pays.
static func plan(layout: RoomLayout, floor_def: FloorDef, extra: int, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if floor_def.enemies.is_empty():
		return entries
	var spare := layout.spare_fighter_cells()
	var cells: Array[Vector2i] = layout.cells_of("E")
	for i in extra:
		if spare.is_empty():
			break
		var at := rng.randi_range(0, spare.size() - 1)
		cells.append(spare[at])
		spare.remove_at(at)
	var taken := {}
	for cell in cells:
		taken[cell] = true
	var counts := {}
	for cell in cells:
		var def := pick(floor_def, counts, rng)
		counts[def] = counts.get(def, 0) + 1
		entries.append({"def": def, "cell": cell, "leader": true})
		for member in def.group_size - 1:
			var spot := _next_to(cell, spare, taken, rng)
			entries.append({"def": def, "cell": spot, "leader": false})
	return entries


# A weighted pick among the types still under their cap. If all are capped, any will do,
# because an enemy cell never stays empty.
static func pick(floor_def: FloorDef, counts: Dictionary, rng: RandomNumberGenerator) -> EnemyDef:
	var total := 0
	var options: Array[int] = []
	for i in floor_def.enemies.size():
		var def: EnemyDef = floor_def.enemies[i]
		if def.max_per_room > 0 and counts.get(def, 0) >= def.max_per_room:
			continue
		options.append(i)
		total += floor_def.enemy_weight(i)
	if options.is_empty():
		return floor_def.enemies[rng.randi_range(0, floor_def.enemies.size() - 1)]
	var roll := rng.randi_range(0, total - 1)
	for i in options:
		roll -= floor_def.enemy_weight(i)
		if roll < 0:
			return floor_def.enemies[i]
	return floor_def.enemies[options[-1]]


# The nearest free good cell, or the same cell when a crowd has used them all up.
static func _next_to(cell: Vector2i, spare: Array[Vector2i], taken: Dictionary, rng: RandomNumberGenerator) -> Vector2i:
	var near: Array[Vector2i] = []
	for reach in range(1, GROUP_REACH + 1):
		for candidate in spare:
			if not taken.has(candidate) and maxi(absi(candidate.x - cell.x), absi(candidate.y - cell.y)) == reach:
				near.append(candidate)
		if not near.is_empty():
			break
	if near.is_empty():
		return cell
	var spot := near[rng.randi_range(0, near.size() - 1)]
	taken[spot] = true
	spare.erase(spot)
	return spot
