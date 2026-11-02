class_name Content
extends RefCounted

const ITEMS_DIR := "res://data/items/"
const UPGRADES_DIR := "res://data/upgrades/"


static func load_dir(path: String) -> Array:
	var loaded: Array = []
	var files := DirAccess.get_files_at(path)
	files.sort()
	for file in files:
		var name := file.trim_suffix(".remap")
		if not name.ends_with(".tres"):
			continue
		var resource := ResourceLoader.load(path + name)
		if resource == null:
			push_error("Could not load content file: %s" % (path + name))
			continue
		loaded.append(resource)
	return loaded


static func items() -> Array[ItemDef]:
	var list: Array[ItemDef] = []
	for resource in load_dir(ITEMS_DIR):
		if resource is ItemDef:
			list.append(resource)
	return list


static func upgrades() -> Array[UpgradeDef]:
	var list: Array[UpgradeDef] = []
	for resource in load_dir(UPGRADES_DIR):
		if resource is UpgradeDef:
			list.append(resource)
	return list
