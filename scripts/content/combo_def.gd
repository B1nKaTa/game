class_name ComboDef
extends StatEffect

# A named pair of items. Holding both adds this combo's stats and runs its effect, after the items'
# own. A combo forms once per run, the moment the second of its items is taken.

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var item_a: String = ""
@export var item_b: String = ""
@export var effect: ItemEffect


func needs(item_id: String) -> bool:
	return item_id == item_a or item_id == item_b
