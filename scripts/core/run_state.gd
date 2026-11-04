class_name RunState
extends RefCounted

signal changed

const STARTING_BOMBS := 1
const MAX_CONSUMABLE := 99
# Thermoses in the Training Yard, topped up after every throw.
const YARD_SUPPLY := MAX_CONSUMABLE
# Where Pension comes from, for the Bribed Clerk's options. Anything else gets the general rate only.
const PENSION_ENEMY := "enemy"
const PENSION_REWARD := "reward"

var stats: PlayerStats
var health: Health
var items: Array[ItemDef] = []
var keys := 0
var bombs := STARTING_BOMBS
var unlocked_items := {}
# The one potion Grandpa carries, and the buff he is under, if any.
var potion: PotionDef
var buff: PotionDef
var buff_left := 0.0
# The memento perks this run carries, by Mementos perk id. Set before apply_perks.
var perks: Dictionary = {}
var _promised := {}
var _offered_recipes := {}
var _upgrades: Array[UpgradeDef]
var _levels: Dictionary
var _choices: Dictionary


func _init(upgrades: Array[UpgradeDef], levels: Dictionary, choices: Dictionary = {}) -> void:
	_upgrades = upgrades
	_levels = levels
	_choices = choices
	stats = PlayerStats.compute(_upgrades, _levels, items, _choices)
	health = Health.new(stats.max_pills)
	health.changed.connect(changed.emit)
	health.heal_bonus = stats.heal_bonus
	bombs = STARTING_BOMBS + stats.bonus_bombs


func has_perk(id: String) -> bool:
	return perks.has(id)


# Hands the perks that live on his health to it. Call once, after setting perks.
func apply_perks() -> void:
	health.first_heal_bonus = Mementos.FIRST_HEAL_EXTRA if has_perk(Mementos.FIRST_HEAL_PERK) else 0


# How much likelier breakables are to hold a coin.
func prop_coin_mult() -> float:
	return Mementos.PROP_COIN_MULT if has_perk(Mementos.PROP_COINS_PERK) else 1.0


# Recipe items only join the rotation once they have been crafted, and bounty items once won.
func can_offer(item: ItemDef) -> bool:
	if item.from_bounty:
		return unlocked_items.has(item.id)
	return not item.needs_recipe() or unlocked_items.has(item.id)


func offer_recipe(id: String) -> void:
	_offered_recipes[id] = true


func was_recipe_offered(id: String) -> bool:
	return _offered_recipes.has(id)


func add_item(item: ItemDef) -> void:
	items.append(item)
	stats = PlayerStats.compute(_upgrades, _levels, items, _choices)
	health.heal_bonus = stats.heal_bonus
	if stats.max_pills != health.max_pills:
		health.raise_max(stats.max_pills)
	else:
		changed.emit()


# Drops every item, as leaving the Training Yard does, and puts his stats and pills back. A lower
# maximum never leaves him holding more pills than it allows.
func clear_items() -> void:
	items.clear()
	stats = PlayerStats.compute(_upgrades, _levels, items, _choices)
	health.heal_bonus = stats.heal_bonus
	if stats.max_pills != health.max_pills:
		health.raise_max(stats.max_pills)
	else:
		changed.emit()


func has_item(id: String) -> bool:
	for item in items:
		if item.id == id:
			return true
	return false


# A promised item is on its way to the player as a reward, so nothing else offers it.
func promise(item: ItemDef) -> void:
	_promised[item.id] = true


func is_promised(id: String) -> bool:
	return _promised.has(id)


func can_add_key() -> bool:
	return keys < MAX_CONSUMABLE


func can_add_bomb() -> bool:
	return bombs < MAX_CONSUMABLE


func add_key() -> void:
	if not can_add_key():
		return
	keys += 1
	changed.emit()


func use_key() -> bool:
	if keys <= 0:
		return false
	keys -= 1
	changed.emit()
	return true


func add_bomb() -> void:
	if not can_add_bomb():
		return
	bombs += 1
	changed.emit()


func use_bomb() -> bool:
	if bombs <= 0:
		return false
	bombs -= 1
	changed.emit()
	return true


func can_take_potion() -> bool:
	return potion == null


# A found potion stays on the floor when the slot is full, so this refuses rather than replaces.
func give_potion(def: PotionDef) -> bool:
	if def == null or not can_take_potion():
		return false
	potion = def
	changed.emit()
	return true


# Healing is never wasted on a full set of pills, so drinking waits until it helps.
func can_drink_potion() -> bool:
	if potion == null:
		return false
	return potion.has_buff() or health.pills < health.max_pills


func drink_potion() -> bool:
	if not can_drink_potion():
		return false
	var drunk := potion
	potion = null
	if drunk.heal > 0:
		health.heal(drunk.heal)
	if drunk.has_buff():
		buff = drunk
		buff_left = drunk.duration
	changed.emit()
	return true


func tick_buff(delta: float) -> void:
	if buff == null:
		return
	buff_left -= delta
	if buff_left <= 0.0:
		buff = null
		buff_left = 0.0
		changed.emit()


func move_speed() -> float:
	return stats.move_speed * (1.0 + (buff.speed_bonus if buff != null else 0.0))


# What the cane multiplies its damage by. The dentures and a Thermos have their own stats.
func damage_mult() -> float:
	return stats.damage_mult + (buff.damage_bonus if buff != null else 0.0)


# What the thrown dentures multiply their bite by. A buff such as Fury Liniment covers them as well.
func bite_damage_mult() -> float:
	return stats.bite_damage_mult + (buff.damage_bonus if buff != null else 0.0)


func pension_amount(base: int, source := "") -> int:
	var mult := 1.0
	if source == PENSION_ENEMY:
		mult = stats.enemy_pension_mult
	elif source == PENSION_REWARD:
		mult = stats.reward_pension_mult
	return ceili(base * stats.pension_mult * mult)
