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
}
const KEY_NAME := "Permission Slip"
const BOMB_NAME := "Overheated Thermos"
const DROP_NONE := ""
const DROP_KEY := "key"
const DROP_BOMB := "bomb"
const DROP_COIN := "coin"
const CLEAR_KEY_CHANCE := 0.15
const CLEAR_BOMB_CHANCE := 0.2
const BLOCK_COIN_CHANCE := 0.3
const BLOCK_BOMB_CHANCE := 0.15
const BLOCK_KEY_CHANCE := 0.1
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
