class_name RunState
extends RefCounted

signal changed

const STARTING_BOMBS := 1

var stats: PlayerStats
var health: Health
var items: Array[ItemDef] = []
var keys := 0
var bombs := STARTING_BOMBS
var _upgrades: Array[UpgradeDef]
var _levels: Dictionary


func _init(upgrades: Array[UpgradeDef], levels: Dictionary) -> void:
	_upgrades = upgrades
	_levels = levels
	stats = PlayerStats.compute(_upgrades, _levels, items)
	health = Health.new(stats.max_pills)
	health.changed.connect(changed.emit)


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


func add_key() -> void:
	keys += 1
	changed.emit()


func use_key() -> bool:
	if keys <= 0:
		return false
	keys -= 1
	changed.emit()
	return true


func add_bomb() -> void:
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
