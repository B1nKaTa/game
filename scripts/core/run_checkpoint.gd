class_name RunCheckpoint
extends RefCounted

# An interrupted run, kept in its slot's run.json so it can be resumed after any quit. The file is
# written to run.json.tmp and then renamed, so a kill during the write leaves the old file or none,
# never a broken one. A file from another build's version, a damaged one or a missing one is no run.

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
	return raw


static func delete(path: String) -> void:
	var full := ProjectSettings.globalize_path(path)
	for each in [full, full + ".tmp"]:
		if FileAccess.file_exists(each):
			DirAccess.remove_absolute(each)
