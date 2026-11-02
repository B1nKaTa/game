class_name RunState
extends RefCounted

signal changed

const STARTING_BOMBS := 1
const MAX_CONSUMABLE := 99

var stats: PlayerStats
var health: Health
var items: Array[ItemDef] = []
var keys := 0
var bombs := STARTING_BOMBS
var treasure_rewards: Array[ItemDef] = []
var boss_rewards: Array[ItemDef] = []
var mini_boss_down := false
var unlocked_items := {}
var _promised := {}
var _offered_recipes := {}
var _upgrades: Array[UpgradeDef]
var _levels: Dictionary


func _init(upgrades: Array[UpgradeDef], levels: Dictionary) -> void:
	_upgrades = upgrades
	_levels = levels
	stats = PlayerStats.compute(_upgrades, _levels, items)
	health = Health.new(stats.max_pills)
	health.changed.connect(changed.emit)


# Recipe items only join the rotation once they have been crafted.
func can_offer(item: ItemDef) -> bool:
	return not item.needs_recipe() or unlocked_items.has(item.id)


func offer_recipe(id: String) -> void:
	_offered_recipes[id] = true


func was_recipe_offered(id: String) -> bool:
	return _offered_recipes.has(id)


func add_item(item: ItemDef) -> void:
	items.append(item)
	stats = PlayerStats.compute(_upgrades, _levels, items)
	if stats.max_pills != health.max_pills:
		health.raise_max(stats.max_pills)
	else:
		changed.emit()


func has_item(id: String) -> bool:
	for item in items:
		if item.id == id:
			return true
	return false


# A promised item is on its way to the player as a reward, so nothing else offers it.
func promise(item: ItemDef) -> void:
	_promised[item.id] = true


func is_promised(id: String) -> bool:
	return _promised.has(id)


func can_add_key() -> bool:
	return keys < MAX_CONSUMABLE


func can_add_bomb() -> bool:
	return bombs < MAX_CONSUMABLE


func add_key() -> void:
	if not can_add_key():
		return
	keys += 1
	changed.emit()


func use_key() -> bool:
	if keys <= 0:
		return false
	keys -= 1
	changed.emit()
	return true


func add_bomb() -> void:
	if not can_add_bomb():
		return
	bombs += 1
	changed.emit()


func use_bomb() -> bool:
	if bombs <= 0:
		return false
	bombs -= 1
	changed.emit()
	return true


func pension_amount(base: int) -> int:
	return ceili(base * stats.pension_mult)
