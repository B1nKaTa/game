class_name PathMigration
extends RefCounted

# Golden Years Mall and Fairway's End were replaced by the Flashback Cinema and the Séance Hotline, so
# every id a save or a run checkpoint keeps for them moves to its replacement here. ProgressData.from_dict
# and RunCheckpoint.read call it on the raw file, before anything is read from it. A migrated file
# holds no old id that this would map again, so running it twice changes nothing.

const PATHS := {"golden_years_mall": "flashback_cinema", "fairways_end": "seance_hotline"}
const BOSSES := {"gloria": "crabtree", "mall_santa": "projectionist", "chip": "celestine", "thaddeus_fairweather": "madame_zara"}
# A poster's id is its boss's id (ProgressData.bounty_matches_boss), so the posters move the same way.
const POSTERS := BOSSES
const DEPARTMENTS := {"pro_shop": "crystal_counter"}
const FLOOR_DIR := "res://data/floors/"
# Set on a checkpoint that stood on a retired path: the floor is rebuilt on the new path and the run
# starts it again from its first room (RunCheckpoint.restart_floor), since the old rooms are gone.
const FLOOR_START := "restart_floor"


# A copy of a raw save with every retired id moved on.
static func migrate_save(raw: Dictionary) -> Dictionary:
	var out := raw.duplicate(true)
	for key in ["paths_cleared", "item_paths_seen", "letters_read"]:
		_rename_keys(out, key, PATHS)
	_merge_counts(out, "path_clears", PATHS)
	_rename_keys(out, "departments_seen", DEPARTMENTS)
	_rename_keys(out, "bounties_retired", POSTERS)
	var taken: Variant = out.get("bounty_taken", "")
	if taken is String and POSTERS.has(taken):
		out["bounty_taken"] = POSTERS[taken]
	# An old save with no Bestiary yet seeds it from the bosses it beat (ProgressData.from_dict), which
	# must stay the bosses really met, so it is seeded here before their replacements join the list.
	var beaten: Variant = out.get("bosses_beaten", {})
	if beaten is Dictionary:
		if not out.has("enemies_seen"):
			var seen := {}
			for id in beaten:
				seen[str(id)] = 0
			out["enemies_seen"] = seen
		# The old bosses stay as history, and their replacements count as beaten too, so first-beat
		# Condolences are never paid twice for one floor's boss.
		for id in beaten.keys():
			if BOSSES.has(str(id)):
				beaten[BOSSES[str(id)]] = true
	return out


# A copy of a raw run checkpoint with every retired id moved on. A run that stood on a retired path
# comes back at the start of that floor on its replacement, with its items, pills and money as they were.
static func migrate_checkpoint(raw: Dictionary) -> Dictionary:
	var out := raw.duplicate(true)
	var floor_path := str(out.get("floor", ""))
	for old: String in PATHS:
		if floor_path == FLOOR_DIR + old + ".tres":
			out["floor"] = FLOOR_DIR + PATHS[old] + ".tres"
			out[FLOOR_START] = true
			out["rooms"] = {}
			out["visited"] = []
			out["is_cleared"] = false
	var ending: Variant = out.get("ending", {})
	if ending is Dictionary:
		var paths: Variant = ending.get("paths", {})
		if paths is Dictionary:
			for depth in paths.keys():
				if paths[depth] is String and PATHS.has(paths[depth]):
					paths[depth] = PATHS[paths[depth]]
	return out


static func new_path(id: String) -> String:
	return str(PATHS.get(id, id))


# An id set or map: each old key moves to its new one, keeping its value.
static func _rename_keys(raw: Dictionary, key: String, ids: Dictionary) -> void:
	var ids_set: Variant = raw.get(key)
	if not ids_set is Dictionary:
		return
	for old in ids_set.keys():
		if ids.has(str(old)):
			var value: Variant = ids_set[old]
			ids_set.erase(old)
			if not ids_set.has(ids[str(old)]):
				ids_set[ids[str(old)]] = value


# A map of counts: an old key's count adds to its new one's.
static func _merge_counts(raw: Dictionary, key: String, ids: Dictionary) -> void:
	var counts: Variant = raw.get(key)
	if not counts is Dictionary:
		return
	for old in counts.keys():
		if ids.has(str(old)):
			var value: Variant = counts[old]
			counts.erase(old)
			var add := int(value) if value is int or value is float else 0
			var have: Variant = counts.get(ids[str(old)], 0)
			counts[ids[str(old)]] = (int(have) if have is int or have is float else 0) + add
