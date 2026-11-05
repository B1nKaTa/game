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
# A boss's own Pension: a reward for the Bribed Clerk's options, and the Golden Handshake's on top.
const PENSION_BOSS := "boss"

var stats: PlayerStats
var health: Health
var items: Array[ItemDef] = []
# What the held items do at moments of play, in pickup order, and the combos they form.
var effects: RunEffects
var keys := 0
var bombs := STARTING_BOMBS
var unlocked_items := {}
# Path id -> true for every path whose floor boss has fallen, for the items those first clears open.
var paths_cleared := {}
# The one potion Grandpa carries, and the buff he is under, if any.
var potion: PotionDef
var buff: PotionDef
var buff_left := 0.0
# The memento perks this run carries, by Mementos perk id. Set before apply_perks.
var perks: Dictionary = {}
# What Grandpa wears this run, slot -> CosmeticDef. Looks only: nothing reads it for a stat.
var look: Dictionary = {}
# A run taken on a cursed ticket: tougher enemies that pay more Pension.
var cursed := false
# Pension the run has earned, for items paid by a share of it (Pension Fund Statement). FloorScene adds
# to it as it pays.
var pension_earned := 0
# Pills of his maximum lost for good this run, as the Expired Coupon takes. Never below one pill left.
var lost_max_pills := 0
var _promised := {}
var _offered_recipes := {}
var _upgrades: Array[UpgradeDef]
var _levels: Dictionary
var _choices: Dictionary


func _init(upgrades: Array[UpgradeDef], levels: Dictionary, choices: Dictionary = {}) -> void:
	_upgrades = upgrades
	_levels = levels
	_choices = choices
	effects = RunEffects.new(self)
	stats = PlayerStats.compute(_upgrades, _levels, items, _choices)
	_apply_pill_rules()
	health = Health.new(stats.max_pills)
	health.changed.connect(changed.emit)
	health.heal_bonus = stats.heal_bonus
	health.lethal_saves = stats.floor_lethal_saves
	bombs = STARTING_BOMBS + stats.bonus_bombs


# The looks worn, by slot, from the save's cosmetics_worn. An id with no CosmeticDef, decor, or a look
# saved under the wrong slot is skipped.
static func look_from(worn: Dictionary, defs: Array[CosmeticDef]) -> Dictionary:
	var found := {}
	for slot in worn:
		for def in defs:
			if def.id == str(worn[slot]) and def.slot == str(slot) and not def.is_decor():
				found[def.slot] = def
	return found


func enemy_health_mult() -> float:
	return TicketRules.CURSED_HEALTH_MULT if cursed else 1.0


func enemy_pension_mult() -> float:
	return TicketRules.CURSED_PENSION_MULT if cursed else 1.0


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
	return ItemUnlocks.is_open(item, unlocked_items, paths_cleared)


func offer_recipe(id: String) -> void:
	_offered_recipes[id] = true


func was_recipe_offered(id: String) -> bool:
	return _offered_recipes.has(id)


func add_item(item: ItemDef) -> void:
	var saves_before := stats.floor_lethal_saves
	items.append(item)
	effects.add(item)
	refresh_stats()
	# A Life Jacket picked up mid-floor works on this floor already, as does a combo that adds a save.
	health.lethal_saves += maxi(stats.floor_lethal_saves - saves_before, 0)


# A new floor fills the Life Jacket's saves again.
func start_floor() -> void:
	health.lethal_saves = stats.floor_lethal_saves


# What the Golden Parachute pays on a death in a run that earned this much: its share, rounded up.
func parachute_pay(earned: int) -> int:
	if stats.death_pension_bonus <= 0.0:
		return 0
	return ceili(maxi(earned, 0) * stats.death_pension_bonus)


# Drops every item, as leaving the Training Yard does, and puts his stats and pills back. A lower
# maximum never leaves him holding more pills than it allows.
func clear_items() -> void:
	items.clear()
	effects.clear()
	lost_max_pills = 0
	refresh_stats()
	health.lethal_saves = mini(health.lethal_saves, stats.floor_lethal_saves)


# Works his stats out again from the forms and the items he holds, keeping the items. The levels and
# choices are the dictionaries the run was made with, which Progress.make_run takes straight from the
# save, so a form filed or refiled since then counts here. A higher maximum adds the pills it gains,
# and a lower one never leaves him holding more pills than it allows (Health.raise_max).
func refresh_stats() -> void:
	stats = PlayerStats.compute(_upgrades, _levels, items, _choices, effects.active_combos())
	_apply_pill_rules()
	health.heal_bonus = stats.heal_bonus

	if stats.max_pills != health.max_pills:
		health.raise_max(stats.max_pills)
	else:
		changed.emit()


# The items that take pills off his maximum: a cap (Do Not Resuscitate Bracelet), then any lost for
# good (Expired Coupon). He always keeps one. The full loop counts his pills, so it keeps them all.
func _apply_pill_rules() -> void:
	if effects.ctx.counting_pills:
		return
	if stats.max_pills_cap > 0:
		stats.max_pills = mini(stats.max_pills, stats.max_pills_cap)
	stats.max_pills = maxi(stats.max_pills - lost_max_pills, 1)


# Takes one pill off his maximum for good, never his last. Returns whether one was taken.
func lose_max_pill() -> bool:
	if stats.max_pills <= 1:
		return false
	lost_max_pills += 1
	refresh_stats()
	return true


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


# Hands a Slip over. An item may let him keep it (Forged Signature); either way it counts as spent.
func use_key() -> bool:
	if keys <= 0:
		return false
	var kept := effects.keeps_slip()
	if not kept:
		keys -= 1
	effects.slip_spent(kept)
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
	return stats.move_speed * (1.0 + (buff.speed_bonus if buff != null else 0.0)) * effects.move_pace()


# How fast the cane combo swings, as a multiple of its usual pace: the forms' and items' stats, and any
# item that speeds it for a while (Early Bird Special, Dentures in a Glass).
func swing_speed() -> float:
	return stats.swing_speed * effects.swing_pace()


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
	elif source == PENSION_BOSS:
		mult = stats.reward_pension_mult * stats.boss_pension_mult
	return ceili(base * stats.pension_mult * mult)


# What a charged swing's damage is multiplied by, before the cane's own damage_mult: the Golf Glove's
# Follow Through and the golf trophy.
func charge_damage_mult() -> float:
	return stats.charge_damage_mult + (Mementos.CHARGE_POWER_BONUS if has_perk(Mementos.CHARGE_PERK) else 0.0)


# How far slides and pushes move him, as a share: half with the ship's anchor, and not at all in
# Gravity Boots.
func slide_mult() -> float:
	if stats.steady_feet:
		return 0.0
	return Mementos.SLIDE_MULT if has_perk(Mementos.SLIDE_PERK) else 1.0


# What his hits on a boss are multiplied by: more with the gold gavel.
func boss_damage_mult() -> float:
	return Mementos.BOSS_DAMAGE_MULT if has_perk(Mementos.BOSS_DAMAGE_PERK) else 1.0
