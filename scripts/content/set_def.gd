class_name SetDef
extends StatEffect

# A set bonus: holding `needed` items of one build adds its stats and runs its effect, after the items'
# and combos'. The held active counts for its build; the pets set counts pet items (kind pet) instead.
# A set forms once per run, the moment the count is reached, and stays.

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var build: String = ""
@export var needed: int = 3
@export var effect: ItemEffect


func count_in(items: Array[ItemDef], active: ItemDef = null) -> int:
	var held: Array[ItemDef] = []
	held.assign(items)
	if active != null:
		held.append(active)
	var count := 0
	for item in held:
		if build == "pets":
			if item.is_pet():
				count += 1
		elif item.build == build:
			count += 1
	return count


func is_met(items: Array[ItemDef], active: ItemDef = null) -> bool:
	return count_in(items, active) >= needed
