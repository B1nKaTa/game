class_name Content
extends RefCounted

const ITEMS_DIR := "res://data/items/"
const UPGRADES_DIR := "res://data/upgrades/"
const POTIONS_DIR := "res://data/potions/"
const COMBOS_DIR := "res://data/combos/"


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


# An empty or missing folder gives none, since a combo ships only once both its items exist.
static func combos() -> Array[ComboDef]:
	var list: Array[ComboDef] = []
	if not DirAccess.dir_exists_absolute(COMBOS_DIR):
		return list
	for resource in load_dir(COMBOS_DIR):
		if resource is ComboDef:
			list.append(resource)
	return list


static func recipes() -> Array[ItemDef]:

	var list: Array[ItemDef] = []
	for item in items():
		if item.needs_recipe():
			list.append(item)
	return list


static func upgrades() -> Array[UpgradeDef]:
	var list: Array[UpgradeDef] = []
	for resource in load_dir(UPGRADES_DIR):
		if resource is UpgradeDef:
			list.append(resource)
	return list


static func potions() -> Array[PotionDef]:
	var list: Array[PotionDef] = []
	for resource in load_dir(POTIONS_DIR):
		if resource is PotionDef:
			list.append(resource)
	return list


static func potion(id: String) -> PotionDef:
	for def in potions():
		if def.id == id:
			return def
	return null


static func potions_for_sale() -> Array[PotionDef]:
	var list: Array[PotionDef] = []
	for def in potions():
		if def.is_for_sale():
			list.append(def)
	return list


static func upgrades_for(merchant_id: String) -> Array[UpgradeDef]:
	var list: Array[UpgradeDef] = []
	for upgrade in upgrades():
		if upgrade.merchant == merchant_id:
			list.append(upgrade)
	return list
