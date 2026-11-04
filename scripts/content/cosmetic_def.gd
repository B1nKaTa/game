class_name CosmeticDef
extends Resource

# Something bought with Condolences: a look for Grandpa, or decor for the lobby. It carries no stats,
# so nothing it does can make him stronger. Drawn in code from its shape and colour until the art pass.

const DIR := "res://data/cosmetics/"
const SLOT_HAT := "hat"
const SLOT_CARDIGAN := "cardigan"
const SLOT_CANE := "cane"
const SLOT_DECOR := "decor"
# What Grandpa can wear, one of each, in the order the Decor Office lists them.
const WORN_SLOTS: Array[String] = [SLOT_HAT, SLOT_CARDIGAN, SLOT_CANE]

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var slot: String = SLOT_HAT
# In Condolences. 0 means a wanted poster's reward, never sold.
@export var price: int = 0
@export var color: Color = Color.WHITE
# Which placeholder drawing it uses, such as "cone" for a hat or "tank" for decor.
@export var shape: String = ""


static func all() -> Array[CosmeticDef]:
	var list: Array[CosmeticDef] = []
	for resource in Content.load_dir(DIR):
		if resource is CosmeticDef:
			list.append(resource)
	return list


static func find(id_wanted: String, defs: Array[CosmeticDef]) -> CosmeticDef:
	for def in defs:
		if def.id == id_wanted:
			return def
	return null


func is_sold() -> bool:
	return price > 0


func is_decor() -> bool:
	return slot == SLOT_DECOR
