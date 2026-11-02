class_name RunState
extends RefCounted

signal changed

var stats: PlayerStats
var health: Health
var items: Array[ItemDef] = []
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


func pension_amount(base: int) -> int:
	return ceili(base * stats.pension_mult)
