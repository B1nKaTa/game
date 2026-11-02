class_name UpgradeDef
extends StatEffect

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var prices: PackedInt32Array = []


func max_level() -> int:
	return prices.size()


func price_at(level: int) -> int:
	if level < 0 or level >= prices.size():
		return -1
	return prices[level]
