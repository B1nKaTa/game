class_name SaveStore
extends RefCounted

enum { STATUS_OK, STATUS_NEW, STATUS_BACKUP, STATUS_RESET }

var last_status: int = STATUS_NEW
var _path: String
var _backup: String
var _temp: String


func _init(path: String) -> void:
	_path = ProjectSettings.globalize_path(path)
	_backup = _path + ".bak"
	_temp = _path + ".tmp"


func save_progress(data: ProgressData) -> bool:
	var file := FileAccess.open(_temp, FileAccess.WRITE)
	if file == null:
		push_error("Could not write save file: %s" % _temp)
		return false
	file.store_string(JSON.stringify(data.to_dict()))
	file.close()
	if FileAccess.file_exists(_path):
		if FileAccess.file_exists(_backup):
			DirAccess.remove_absolute(_backup)
		DirAccess.rename_absolute(_path, _backup)
	return DirAccess.rename_absolute(_temp, _path) == OK


func load_progress() -> ProgressData:
	var had_main := FileAccess.file_exists(_path)
	var had_backup := FileAccess.file_exists(_backup)
	if not had_main and not had_backup:
		last_status = STATUS_NEW
		return ProgressData.new()
	var data := _read(_path)
	if data != null:
		last_status = STATUS_OK
		return data
	data = _read(_backup)
	if data != null:
		last_status = STATUS_BACKUP
		return data
	last_status = STATUS_RESET
	return ProgressData.new()


func delete_all() -> void:
	for path in [_path, _backup, _temp]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


func _read(path: String) -> ProgressData:
	if not FileAccess.file_exists(path):
		return null
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return null
	return ProgressData.from_dict(json.data)
