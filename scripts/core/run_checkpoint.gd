class_name RunCheckpoint
extends RefCounted

# An interrupted run, kept in its slot's run.json so it can be resumed after any quit. The file is
# written to run.json.tmp and then renamed, so a kill during the write leaves the old file, or only the
# finished temp file, which read takes in its place, never a broken one. A file from another build's version, a damaged one or a missing one is no run.

const VERSION := 1


static func write(path: String, data: Dictionary) -> bool:
	var full := ProjectSettings.globalize_path(path)
	var temp := full + ".tmp"
	DirAccess.make_dir_recursive_absolute(full.get_base_dir())
	var stamped := data.duplicate(true)
	stamped["version"] = VERSION
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		push_error("Could not write the run checkpoint: %s" % temp)
		return false
	file.store_string(JSON.stringify(stamped))
	file.close()
	if FileAccess.file_exists(full) and DirAccess.remove_absolute(full) != OK:
		push_error("Could not replace the run checkpoint: %s" % full)
		return false
	if DirAccess.rename_absolute(temp, full) != OK:
		push_error("Could not move the run checkpoint into place: %s" % full)
		return false
	return true


static func read(path: String) -> Dictionary:
	var full := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(full):
		# write removes the old file before renaming the new one, so a kill between the two leaves only
		# the temp file, written whole. One cut off mid-write does not parse and is no run.
		return _read_file(full + ".tmp")
	return _read_file(full)


static func _read_file(full: String) -> Dictionary:
	if not FileAccess.file_exists(full):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(full)) != OK:
		return {}
	var raw: Variant = json.data
	if not raw is Dictionary or not raw.has("version"):
		return {}
	if typeof(raw["version"]) != TYPE_FLOAT and typeof(raw["version"]) != TYPE_INT:
		return {}
	if int(raw["version"]) != VERSION:
		return {}
	# A run on a path that was replaced comes back on its replacement (PathMigration).
	return PathMigration.migrate_checkpoint(raw)


static func delete(path: String) -> void:
	var full := ProjectSettings.globalize_path(path)
	for each in [full, full + ".tmp"]:
		if FileAccess.file_exists(each):
			DirAccess.remove_absolute(each)


# The Pension the checkpoint keeps: the save's as it is now, less what the room he stands in paid while
# its fight is still on, since that fight comes back on resume. room_paid is 0 in a cleared room.
static func pension_to_save(data: ProgressData, room_paid: int) -> int:
	return maxi(data.pension - maxi(room_paid, 0), 0)


# Puts the save's Pension back as the checkpoint kept it. Coins are banked the moment they are picked
# up, and every fight after the checkpoint comes back on resume, so without this they would pay twice.
# The RunState in the file comes from the same moment, so the two agree. Condolences are NOT put back:
# a first boss beat's Condolences are paid for good when the boss falls (record_boss_beaten), and must
# stay paid even if the run is resumed from before it. False when the file keeps no Pension.
static func apply_pension(data: ProgressData, raw: Dictionary) -> bool:
	if not raw.has("pension") or (typeof(raw["pension"]) != TYPE_FLOAT and typeof(raw["pension"]) != TYPE_INT):
		return false
	data.pension = maxi(int(raw["pension"]), 0)
	return true


# The whole RunState, by ids, so the file names no resource paths.
static func run_to_dict(run: RunState) -> Dictionary:
	var item_ids: Array = []
	for item in run.items:
		item_ids.append(item.id)
	var perks: Array = run.perks.keys()
	perks.sort()
	var promised := run.promised_ids()
	promised.sort()
	var offered := run.offered_recipe_ids()
	offered.sort()
	return {
		"pills": run.health.pills,
		"max_pills": run.health.max_pills,
		"lethal_saves": run.health.lethal_saves,
		"first_heal_bonus": run.health.first_heal_bonus,
		"half_pills": run.health.half_pills,
		"lost_max_pills": run.lost_max_pills,
		"items": item_ids,
		"effects": run.effects.save_state(),
		"keys": run.keys,
		"bombs": run.bombs,
		"potion": run.potion.id if run.potion != null else "",
		"buff": run.buff.id if run.buff != null else "",
		"buff_left": snappedf(run.buff_left, 0.01),
		"cursed": run.cursed,
		"perks": perks,
		"promised": promised,
		"offered": offered,
	}


# What the run did so far for EndingRules (RunState's run-only tracking), kept apart from run_to_dict
# since play time goes on counting after a save. Won Arcade visits come back as a count, since visit
# numbers start again in the resumed scene.
static func ending_to_dict(run: RunState) -> Dictionary:
	var paths := {}
	for depth in run.paths_taken:
		paths[str(depth)] = str(run.paths_taken[depth])
	return {
		"play_time": snappedf(run.play_time, 0.1),
		"pension_earned": run.pension_earned,
		"boss_room_pill_lost": run.boss_room_pill_lost,
		"paths": paths,
		"table_visits_won": run.arcade_visits_won(),
		"tally": tally_to_dict(run),
	}


static func apply_ending(run: RunState, raw: Dictionary) -> void:
	run.play_time = maxf(float(raw.get("play_time", 0.0)), 0.0)
	run.pension_earned = maxi(int(raw.get("pension_earned", 0)), 0)
	run.boss_room_pill_lost = bool(raw.get("boss_room_pill_lost", false))
	run.paths_taken = {}
	var paths: Variant = raw.get("paths", {})
	if paths is Dictionary:
		for key in paths:
			if str(key).is_valid_int():
				run.paths_taken[int(key)] = str(paths[key])
	run.extra_table_visits = maxi(int(raw.get("table_visits_won", 0)), 0)
	apply_tally(run, raw.get("tally", {}))


# The case file's tally (RunState.kills and the rest). An older checkpoint has none and starts empty.
static func tally_to_dict(run: RunState) -> Dictionary:
	return {
		"kills": run.kills.duplicate(),
		"met": run.met.keys(),
		"found": Array(run.found),
		"hits": run.hits_taken,
		"seeds": Array(run.seeds),
	}


static func apply_tally(run: RunState, raw: Variant) -> void:
	if not raw is Dictionary:
		return
	var kills: Variant = raw.get("kills", {})
	if kills is Dictionary:
		for id in kills:
			if (kills[id] is int or kills[id] is float) and int(kills[id]) > 0:
				run.kills[str(id)] = int(kills[id])
				run.met[str(id)] = true
	for key in ["met", "found", "seeds"]:
		var list: Variant = raw.get(key, [])
		if not list is Array:
			continue
		for value in list:
			if not value is String or value.is_empty():
				continue
			match key:
				"met":
					run.met[value] = true
				"found":
					run.found.append(value)
				"seeds":
					run.seeds.append(value)
	var hits: Variant = raw.get("hits", 0)
	if hits is int or hits is float:
		run.hits_taken = maxi(int(hits), 0)


# Puts a saved run back on a run made fresh by Progress.make_run. Ids that match nothing are skipped.
static func apply_run(run: RunState, raw: Dictionary, items: Array[ItemDef]) -> void:
	var perks := {}
	for id in raw.get("perks", []):
		perks[str(id)] = true
	run.perks = perks
	run.apply_perks()
	# Through restore_item, so each item's effect and any combo come back too, without a second on_gain.
	# Each effect's own state (a once-a-run flag, a counter, a recharge) comes back after them. The pills
	# and saves are set from the file below.
	for id in raw.get("items", []):
		for item in items:
			if item.id == str(id):
				run.restore_item(item)
				break
	run.lost_max_pills = maxi(int(raw.get("lost_max_pills", 0)), 0)
	var effects: Variant = raw.get("effects", {})
	run.effects.load_state(effects if effects is Dictionary else {})
	run.refresh_stats()
	run.health.max_pills = maxi(int(raw.get("max_pills", run.health.max_pills)), 1)
	run.health.pills = clampi(int(raw.get("pills", run.health.pills)), 1, run.health.max_pills)
	run.health.lethal_saves = int(raw.get("lethal_saves", run.health.lethal_saves))
	run.health.first_heal_bonus = int(raw.get("first_heal_bonus", run.health.first_heal_bonus))
	run.health.half_pills = clampi(int(raw.get("half_pills", 0)), 0, 1)
	run.keys = clampi(int(raw.get("keys", 0)), 0, RunState.MAX_CONSUMABLE)
	run.bombs = clampi(int(raw.get("bombs", 0)), 0, RunState.MAX_CONSUMABLE)
	var potion := str(raw.get("potion", ""))
	run.potion = Content.potion(potion) if not potion.is_empty() else null
	var buff := str(raw.get("buff", ""))
	run.buff = Content.potion(buff) if not buff.is_empty() else null
	run.buff_left = float(raw.get("buff_left", 0.0)) if run.buff != null else 0.0
	run.cursed = bool(raw.get("cursed", false))
	run.restore_marks(raw.get("promised", []), raw.get("offered", []))
	run.changed.emit()


# A generator's seed and state as text, since JSON numbers cannot hold 64 bits.
static func rng_to_dict(rng: RandomNumberGenerator) -> Dictionary:
	return {"seed": str(rng.seed), "state": str(rng.state)}


static func apply_rng(rng: RandomNumberGenerator, raw: Dictionary) -> void:
	rng.seed = int(str(raw.get("seed", "0")))
	rng.state = int(str(raw.get("state", "0")))


# A fresh floor seed, as text for the same reason.
static func new_seed(rng: RandomNumberGenerator) -> String:
	return str(rng.randi())


# Builds a floor from its seed alone, so the same seed always gives the same map.
static func build_floor(def: FloorDef, seed_text: String, pool: Array[RoomLayout] = []) -> FloorMap:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(seed_text)
	return FloorBuilder.build_from_pool(rng, def, pool if not pool.is_empty() else FloorBuilder.pool_for(def))


# A checkpoint moved off a retired path (PathMigration.FLOOR_START) starts its floor again, as walking
# out of the Crossroads does: he stands in the floor's first room, come in from the Crossroads, with
# nothing on the floor visited or cleared yet. Items, pills and money are the checkpoint's own.
static func restart_floor(resume: Dictionary, map: FloorMap, crossroads_id: int) -> void:
	resume["room"] = map.start_id
	resume["from"] = crossroads_id
	resume["visited"] = [crossroads_id]
	resume["rooms"] = {}
	resume["is_cleared"] = false
	resume.erase(PathMigration.FLOOR_START)


# Everything that makes two maps the same floor.
static func map_signature(map: FloorMap) -> Array:
	var rooms := []
	if map == null:
		return rooms
	for room in map.rooms:
		var doors := []
		for side: Vector2i in room.doors:
			doors.append([side, room.doors[side]])
		doors.sort()
		rooms.append([room.id, room.room_type, room.cell, room.layout.resource_path if room.layout != null else "", room.decor_seed, room.extra_enemies, doors])
	return [map.start_id, map.boss_id, map.main_path, rooms]
