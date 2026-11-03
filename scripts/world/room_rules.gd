class_name RoomRules
extends RefCounted

const ICONS := {
	RoomLayout.TYPE_COMBAT: "C",
	RoomLayout.TYPE_ITEM: "I",
	RoomLayout.TYPE_HEALING: "H",
	RoomLayout.TYPE_SIDE: "?",
	RoomLayout.TYPE_MINI_BOSS: "M",
	RoomLayout.TYPE_FLOOR_BOSS: "B",
	RoomLayout.TYPE_TREASURE: "T",
	RoomLayout.TYPE_SHOP: "$",
	RoomLayout.TYPE_SECRET: "S",
	RoomLayout.TYPE_VAULT: "V",
	RoomLayout.TYPE_CROSSROADS: "+",
	RoomLayout.TYPE_LANDING: "v",
}
const KEY_NAME := "Permission Slip"
const BOMB_NAME := "Overheated Thermos"
const DROP_NONE := ""
const DROP_KEY := "key"
const DROP_BOMB := "bomb"
const DROP_COIN := "coin"
const DROP_POTION := "potion"
const CLEAR_KEY_CHANCE := 0.15
const CLEAR_BOMB_CHANCE := 0.2
const BLOCK_COIN_CHANCE := 0.3
const BLOCK_BOMB_CHANCE := 0.15
const BLOCK_KEY_CHANCE := 0.1
# Most barrels hold nothing or a coin.
const BARREL_COIN_CHANCE := 0.22
const BARREL_KEY_CHANCE := 0.05
const BARREL_BOMB_CHANCE := 0.05
const BARREL_POTION_CHANCE := 0.06
const PILE_COIN_CHANCE := 0.12
const ROCK_COIN_CHANCE := 0.3
# A graveyard has far more stones than an office has rocks, so each one hides a coin less often.
const GRAVESTONE_COIN_CHANCE := 0.1
# A care home has many armchairs and beds, so each hides a coin about as rarely as a gravestone.
const FURNITURE_COIN_CHANCE := 0.1
# A small potion fills the potion slot. Its effect lives in the potion data, so it heals as that says.
const POTION_NAME := "Small Potion"
const SMALL_POTION_ID := "small_potion"
const TREASURE_RECIPE_CHANCE := 0.25
const MINI_BOSS_RECIPE_CHANCE := 0.5


static func block_drop(roll: float) -> String:
	if roll < BLOCK_COIN_CHANCE:
		return DROP_COIN
	if roll < BLOCK_COIN_CHANCE + BLOCK_BOMB_CHANCE:
		return DROP_BOMB
	if roll < BLOCK_COIN_CHANCE + BLOCK_BOMB_CHANCE + BLOCK_KEY_CHANCE:
		return DROP_KEY
	return DROP_NONE


static func barrel_drop(roll: float) -> String:
	var edge := BARREL_COIN_CHANCE
	if roll < edge:
		return DROP_COIN
	edge += BARREL_KEY_CHANCE
	if roll < edge:
		return DROP_KEY
	edge += BARREL_BOMB_CHANCE
	if roll < edge:
		return DROP_BOMB
	edge += BARREL_POTION_CHANCE
	if roll < edge:
		return DROP_POTION
	return DROP_NONE


static func pile_drops_coin(roll: float) -> bool:
	return roll < PILE_COIN_CHANCE


static func gravestone_hides_coin(roll: float) -> bool:
	return roll < GRAVESTONE_COIN_CHANCE


static func rock_hides_coin(roll: float) -> bool:
	return roll < ROCK_COIN_CHANCE


static func clear_drop(roll: float) -> String:
	if roll < CLEAR_KEY_CHANCE:
		return DROP_KEY
	if roll < CLEAR_KEY_CHANCE + CLEAR_BOMB_CHANCE:
		return DROP_BOMB
	return DROP_NONE


static func door_icon(room_type: String) -> String:
	return ICONS.get(room_type, "<")


static func pick_items(all: Array[ItemDef], run: RunState, count: int, rng: RandomNumberGenerator) -> Array[ItemDef]:
	var options: Array[ItemDef] = []
	for item in all:
		if run.can_offer(item) and not run.has_item(item.id) and not run.is_promised(item.id):
			options.append(item)
	var picked: Array[ItemDef] = []
	while picked.size() < count and not options.is_empty():
		var index := rng.randi_range(0, options.size() - 1)
		picked.append(options[index])
		options.remove_at(index)
	return picked


# Picks a recipe the player hasn't found and that this run hasn't already offered, or null.
static func pick_recipe(all: Array[ItemDef], found: Dictionary, run: RunState, rng: RandomNumberGenerator) -> ItemDef:
	var options: Array[ItemDef] = []
	for item in all:
		if item.needs_recipe() and not found.has(item.id) and not run.was_recipe_offered(item.id):
			options.append(item)
	if options.is_empty():
		return null
	var picked := options[rng.randi_range(0, options.size() - 1)]
	run.offer_recipe(picked.id)
	return picked


static func furniture_hides_coin(roll: float) -> bool:
	return roll < FURNITURE_COIN_CHANCE
