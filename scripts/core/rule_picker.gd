class_name RulePicker
extends RefCounted

# Which rooms of a floor post a rule, and which. Draws from its own generator seeded by the floor's seed,
# never from FloorBuilder's stream, so existing floors and checkpoints are unchanged.

# Rules post on every floor since the player build. Kept as a constant so a test can still ask for less.
const ENABLED_DEPTH := 99
const BY_DEPTH := {1: 1, 2: 2}
const DEEP_SHARE := 0.4
const DEEP_MIN := 2
# A save's first run meets its first rule among the first few fights on the main path.
const EARLY_ROOMS := 3


# extra more rooms on every floor (By the Book), deeper floors too, never more than its combat rooms.
static func rule_room_count(depth: int, combat_rooms: int, enabled_depth := ENABLED_DEPTH, extra := 0) -> int:
	if combat_rooms <= 0:
		return 0
	var wanted: int = 0 if depth > enabled_depth else BY_DEPTH.get(depth, maxi(DEEP_MIN, roundi(combat_rooms * DEEP_SHARE)))
	return mini(wanted + maxi(extra, 0), combat_rooms)


# The first EARLY_ROOMS combat rooms on the main path, in path order, never the start room.
static func early_candidates(map: FloorMap) -> Array[int]:
	var out: Array[int] = []
	for id in map.main_path:
		if out.size() >= EARLY_ROOMS:
			break
		if id != map.start_id and map.room(id).room_type == RoomLayout.TYPE_COMBAT:
			out.append(id)
	return out


# Combat rooms only: never loot, shop, treasure, item, healing, secret, vault, mini-boss or boss rooms.
# early (a save's first run): the first pick comes from early_candidates; the rest as always.
static func rule_rooms(map: FloorMap, depth: int, seed_text: String, extra := 0, early := false) -> Array[int]:
	var combat: Array[int] = []
	for room in map.rooms:
		if room.room_type == RoomLayout.TYPE_COMBAT and room.id != map.start_id:
			combat.append(room.id)
	combat.sort()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed_text + ":rule_rooms")
	var picked: Array[int] = []
	var count := rule_room_count(depth, combat.size(), ENABLED_DEPTH, extra)
	var first := early_candidates(map) if early else ([] as Array[int])
	if count > 0 and not first.is_empty():
		var chosen: int = first[rng.randi_range(0, first.size() - 1)]
		picked.append(chosen)
		combat.erase(chosen)
	while picked.size() < count:
		picked.append(combat.pop_at(rng.randi_range(0, combat.size() - 1)))
	picked.sort()
	return picked


static func pick_rule(seed_text: String, room_id: int, ready: Dictionary) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s:rule:%d" % [seed_text, room_id])
	var choices: Array[String] = []
	var total := 0.0
	for rule in RoomRule.ALL:
		if RoomRule.can_apply(rule, ready):
			choices.append(rule)
			total += RoomRule.WEIGHTS[rule]
	var roll := rng.randf() * total
	for rule in choices:
		roll -= RoomRule.WEIGHTS[rule]
		if roll <= 0.0:
			return rule
	return choices[-1]
