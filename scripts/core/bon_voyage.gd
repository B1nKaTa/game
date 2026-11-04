class_name BonVoyage
extends RefCounted

# The Purser's Bon Voyage Bag: while the Purser's Office is open, every run starts with one random
# consumable, a potion or a Thermos. A potion only goes in an empty slot, so a run that starts with a
# brew in the slot finds a Thermos in the bag instead. Pure rules, reading only what they are given.

const THERMOS := "thermos"
# The chance the bag holds a potion rather than a Thermos.
const POTION_CHANCE := 0.5


static func is_packed(data: ProgressData) -> bool:
	return Departments.is_open(Departments.PURSERS_OFFICE, data)


# Puts the bag's one consumable in the run and returns what it was: a potion's id, or THERMOS.
# kind_roll picks potion or Thermos and potion_roll which potion, both in [0, 1).
static func pack(run: RunState, potions: Array[PotionDef], kind_roll: float, potion_roll: float) -> String:
	if kind_roll < POTION_CHANCE and not potions.is_empty() and run.can_take_potion():
		var def: PotionDef = potions[clampi(int(potion_roll * potions.size()), 0, potions.size() - 1)]
		if run.give_potion(def):
			return def.id
	run.add_bomb()
	return THERMOS


# The start-of-run notice for what the bag held.
static func notice(given: String, potions: Array[PotionDef]) -> String:
	if given == THERMOS:
		return "Bon Voyage Bag: a Thermos"
	for def in potions:
		if def.id == given:
			return "Bon Voyage Bag: %s" % def.display_name
	return ""
