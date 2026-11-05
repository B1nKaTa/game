class_name SaveSlots
extends RefCounted

# Three save slots, each a folder of its own beside the old single save: slot_N/save.json, its .bak,
# and run.json, the interrupted run. Every function takes the root folder ("user://" in the game, a
# temp folder in tests), so nothing here is tied to the real user folder.
#
# Migration copies an existing save.json and save.json.bak into slot_1, byte for byte, and leaves the
# originals exactly where and as they were. It never copies over a slot_1/save.json already there,
# and it happens once: migrated.txt marks it done, so a slot 1 deleted later is never filled again.

const COUNT := 3
const SAVE_FILE := "save.json"
const RUN_FILE := "run.json"
# Which slot was used last, kept beside the slots. Like settings.cfg, it is no slot's own.
const LAST_FILE := "last_slot.txt"
# Left beside the slots once the old save has been copied into slot 1, so the copy is made only once
# and a slot 1 deleted since stays deleted.
const MIGRATED_FILE := "migrated.txt"


static func slot_dir(root: String, slot: int) -> String:
	return root + "slot_%d/" % slot


static func save_path(root: String, slot: int) -> String:
	return slot_dir(root, slot) + SAVE_FILE


static func run_path(root: String, slot: int) -> String:
	return slot_dir(root, slot) + RUN_FILE


# Returns whether anything was copied.
static func migrate(root: String) -> bool:
	var marker := ProjectSettings.globalize_path(root + MIGRATED_FILE)
	if FileAccess.file_exists(marker):
		return false
	var old := ProjectSettings.globalize_path(root + SAVE_FILE)
	var target := ProjectSettings.globalize_path(save_path(root, 1))
	# A backup alone is still a save: its main file was lost, and the slot loads from the backup.
	if not FileAccess.file_exists(old) and not FileAccess.file_exists(old + ".bak"):
		return false
	# A slot 1 already there came from an earlier build's copy, or from play since: it is kept. One that
	# does not parse, with no marker, is a copy killed halfway, and is made again.
	if FileAccess.file_exists(target) and _parses(target):
		_write_marker(marker)
		return false
	DirAccess.make_dir_recursive_absolute(target.get_base_dir())
	# The backup first and the save last, each through a temp file renamed into place, so a kill at any
	# point leaves no slot_1/save.json that is only half there, and no marker until both are done.
	if FileAccess.file_exists(old + ".bak") and not _copy_into(old + ".bak", target + ".bak"):
		return false
	if FileAccess.file_exists(old):
		if not _copy_into(old, target):
			return false
	elif FileAccess.file_exists(target) and DirAccess.remove_absolute(target) != OK:
		return false
	write_last(root, 1)
	_write_marker(marker)
	return true


static func _copy_into(from: String, to: String) -> bool:
	var temp := to + ".tmp"
	if DirAccess.copy_absolute(from, temp) != OK:
		push_error("Could not copy the save into slot 1: %s" % from)
		return false
	if FileAccess.file_exists(to) and DirAccess.remove_absolute(to) != OK:
		push_error("Could not replace a broken copy in slot 1: %s" % to)
		return false
	if DirAccess.rename_absolute(temp, to) != OK:
		push_error("Could not move the copy into slot 1: %s" % to)
		return false
	return true


static func _parses(path: String) -> bool:
	var json := JSON.new()
	return json.parse(FileAccess.get_file_as_string(path)) == OK and json.data is Dictionary


static func _write_marker(marker: String) -> void:
	var file := FileAccess.open(marker, FileAccess.WRITE)
	if file != null:
		file.store_string("slot 1")
		file.close()


# A slot has progress once the opening has been seen or a run played. A brand new save has neither.
static func has_progress(data: ProgressData) -> bool:
	return data != null and (data.opening_seen or data.run_count > 0)


# The slot's progress, or null when it has none on disk.
static func load_data(root: String, slot: int) -> ProgressData:
	var path := save_path(root, slot)
	if not FileAccess.file_exists(ProjectSettings.globalize_path(path)) and not FileAccess.file_exists(ProjectSettings.globalize_path(path + ".bak")):
		return null
	var store := SaveStore.new(path)
	var data := store.load_progress()
	return data if store.last_status != SaveStore.STATUS_RESET else null


# What the slot picker shows on a card. "empty" is true for a slot with no progress.
static func summary(root: String, slot: int) -> Dictionary:
	var data := load_data(root, slot)
	var found := summary_of(data)
	if not found["empty"]:
		var saved := FileAccess.get_modified_time(ProjectSettings.globalize_path(save_path(root, slot)))
		found["date"] = date_text(saved)
		found["run_floor"] = int(RunCheckpoint.read(run_path(root, slot)).get("depth", 0))
	return found


static func summary_of(data: ProgressData) -> Dictionary:
	var found := {"empty": true, "floors": 0, "deepest": 0, "pension": 0, "runs": 0, "date": "", "run_floor": 0}
	if not has_progress(data):
		return found
	found["empty"] = false
	var floors := 0
	var deepest := 0
	for depth: int in ProgressData.PATHS_AT_DEPTH:
		var clears := data.clears_at(depth)
		floors += clears
		if clears > 0:
			deepest = maxi(deepest, depth)
	found["floors"] = floors
	found["deepest"] = deepest
	found["pension"] = data.pension
	found["runs"] = data.run_count
	return found


static func date_text(unix_time: int) -> String:
	if unix_time <= 0:
		return ""
	var bias := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	return Time.get_date_string_from_unix_time(unix_time + bias)


static func delete_slot(root: String, slot: int) -> void:
	for path in [save_path(root, slot), save_path(root, slot) + ".bak", save_path(root, slot) + ".tmp"]:
		var full := ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(full):
			DirAccess.remove_absolute(full)
	RunCheckpoint.delete(run_path(root, slot))


static func read_last(root: String) -> int:
	var path := ProjectSettings.globalize_path(root + LAST_FILE)
	if not FileAccess.file_exists(path):
		return 1
	var text := FileAccess.get_file_as_string(path).strip_edges()
	if not text.is_valid_int() or int(text) < 1 or int(text) > COUNT:
		return 1
	return int(text)


static func write_last(root: String, slot: int) -> void:
	var file := FileAccess.open(ProjectSettings.globalize_path(root + LAST_FILE), FileAccess.WRITE)
	if file != null:
		file.store_string(str(slot))
		file.close()


static func slots_with_progress(root: String) -> int:
	var count := 0
	for slot in range(1, COUNT + 1):
		if not summary(root, slot)["empty"]:
			count += 1
	return count


# The slot Continue loads: the last used one when it has progress, otherwise the one saved most
# recently that has. 0 when no slot has any.
static func continue_slot(root: String) -> int:
	var last := read_last(root)
	if has_progress(load_data(root, last)):
		return last
	var best := 0
	var best_time := -1
	for slot in range(1, COUNT + 1):
		if not has_progress(load_data(root, slot)):
			continue
		var saved := FileAccess.get_modified_time(ProjectSettings.globalize_path(save_path(root, slot)))
		if saved > best_time:
			best = slot
			best_time = saved
	return best


# The title screen's menu, by id. Continue shows while any slot has progress, and Load Game once more
# than one has.
static func menu_items(with_progress: int) -> Array[String]:
	var items: Array[String] = []
	if with_progress > 0:
		items.append("continue")
	items.append("new")
	if with_progress > 1:
		items.append("load")
	items.append_array(["options", "credits", "quit"])
	return items
