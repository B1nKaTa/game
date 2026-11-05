class_name BountyBoard
extends RefCounted

# The wanted posters' rules. They read and write only ProgressData, so the Bounty Office and the tests
# share them. Progress wraps take and collect in saving calls.

const DIR := "res://data/bounties/"
const FLOORS_DIR := "res://data/floors/"
# A recipe already found pays this share of the poster's Pension again instead.
const FOUND_RECIPE_SHARE := 0.5


static func all() -> Array[BountyDef]:
	var list: Array[BountyDef] = []
	for resource in Content.load_dir(DIR):
		if resource is BountyDef:
			list.append(resource)
	return list


# A poster shows only for a floor Grandpa can reach, so he can never be stuck with one he cannot finish.
static func floor_reachable(floor_def: FloorDef, data: ProgressData) -> bool:
	if floor_def == null:
		return false
	return floor_def.is_open_for(data) and (floor_def.depth <= 1 or data.clears_at(floor_def.depth - 1) > 0)


# The posters on the board: every one whose floor is reachable and that has not been collected.
# floors maps a FloorDef id to its FloorDef.
static func posters(defs: Array[BountyDef], floors: Dictionary, data: ProgressData) -> Array[BountyDef]:
	var list: Array[BountyDef] = []
	for def in defs:
		if data.bounties_retired.has(def.id):
			continue
		if floor_reachable(floors.get(def.floor_id) as FloorDef, data):
			list.append(def)
	return list


# Each poster's floor, by id. A floor's file is named after its id, as every shipped floor is.
static func floors_for(defs: Array[BountyDef]) -> Dictionary:
	var floors := {}
	for def in defs:
		if not floors.has(def.floor_id):
			floors[def.floor_id] = load(FLOORS_DIR + def.floor_id + ".tres")
	return floors


# What the Bounty Office's board shows for this save.
static func showing(data: ProgressData) -> Array[BountyDef]:
	var defs := all()
	return posters(defs, floors_for(defs), data)


static func is_taken(def: BountyDef, data: ProgressData) -> bool:
	return data.bounty_taken == def.id


# One poster at a time, and a collected poster is gone for good.
static func can_take(def: BountyDef, data: ProgressData) -> bool:
	return data.bounty_taken.is_empty() and not data.bounties_retired.has(def.id)


# A taken poster whose id matches no BountyDef would lock the board for good, since only one poster is
# taken at a time. Progress drops such a poster, and its win, once a save is loaded.
static func drop_unknown_taken(defs: Array[BountyDef], data: ProgressData) -> bool:
	if data.bounty_taken.is_empty():
		return false
	for def in defs:
		if def.id == data.bounty_taken:
			return false
	data.bounty_taken = ""
	data.bounty_won = false
	return true


# A poster collected before its reward became an item paid what it paid then, so its item would never
# join. Every retired poster that now pays an item unlocks it. Returns whether anything changed.
static func grant_retired_items(defs: Array[BountyDef], data: ProgressData) -> bool:
	var changed := false
	for def in defs:
		if def.extra_kind == BountyDef.EXTRA_ITEM and data.bounties_retired.has(def.id) and not data.is_unlocked(def.extra_id):
			data.items_unlocked[def.extra_id] = true
			changed = true
	return changed


# Taking clears any win, so a boss beaten before the poster was taken never counts.
static func take(def: BountyDef, data: ProgressData) -> bool:
	if not can_take(def, data):
		return false
	data.bounty_taken = def.id
	data.bounty_won = false
	return true


static func can_collect(def: BountyDef, data: ProgressData) -> bool:
	return is_taken(def, data) and data.bounty_won


# Pays the poster's Pension and Condolences straight into the save, so no run multiplier applies, then
# hands over its extra and retires it. An empty result means nothing was paid.
static func collect(def: BountyDef, data: ProgressData) -> Dictionary:
	if not can_collect(def, data):
		return {}
	var pension := def.pension
	var was_new := true
	if def.extra_kind == BountyDef.EXTRA_RECIPE:
		was_new = not data.has_recipe(def.extra_id)
		if was_new:
			data.find_recipe(def.extra_id)
		else:
			pension += roundi(def.pension * FOUND_RECIPE_SHARE)
	elif def.extra_kind == BountyDef.EXTRA_ITEM:
		# A won item joins the rotation through items_unlocked, the same set crafted items use.
		was_new = not data.is_unlocked(def.extra_id)
		data.items_unlocked[def.extra_id] = true
	elif def.extra_kind == BountyDef.EXTRA_COSMETIC:
		# Owned at once, ready to wear from the Decor Office.
		was_new = not data.cosmetics_owned.has(def.extra_id)
		data.cosmetics_owned[def.extra_id] = true
	data.add_pension(pension)
	data.add_condolences(def.condolences)
	data.bounties_retired[def.id] = true
	data.bounty_taken = ""
	data.bounty_won = false
	return {
		"pension": pension,
		"condolences": def.condolences,
		"extra_kind": def.extra_kind,
		"extra_id": def.extra_id,
		"extra_was_new": was_new,
	}
