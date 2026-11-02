class_name ProgressData
extends RefCounted

const VERSION := 1

var pension: int = 0
var upgrades: Dictionary = {}
var opening_seen: bool = false


func level_of(id: String) -> int:
	return int(upgrades.get(id, 0))


func add_pension(amount: int) -> void:
	pension += maxi(amount, 0)


func can_buy(def: UpgradeDef) -> bool:
	var price := def.price_at(level_of(def.id))
	return price >= 0 and pension >= price


func buy(def: UpgradeDef) -> bool:
	if not can_buy(def):
		return false
	pension -= def.price_at(level_of(def.id))
	upgrades[def.id] = level_of(def.id) + 1
	return true


func to_dict() -> Dictionary:
	return {
		"version": VERSION,
		"pension": pension,
		"upgrades": upgrades,
		"opening_seen": opening_seen,
	}


static func from_dict(raw: Variant) -> ProgressData:
	if not raw is Dictionary:
		return null
	for key in ["version", "pension", "upgrades", "opening_seen"]:
		if not raw.has(key):
			return null
	if int(raw["version"]) != VERSION or int(raw["pension"]) < 0:
		return null
	if not raw["upgrades"] is Dictionary or not raw["opening_seen"] is bool:
		return null
	var data := ProgressData.new()
	data.pension = int(raw["pension"])
	data.opening_seen = raw["opening_seen"]
	for id in raw["upgrades"]:
		data.upgrades[str(id)] = int(raw["upgrades"][id])
	return data
