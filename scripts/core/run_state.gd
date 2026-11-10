class_name RunState
extends RefCounted

signal changed
signal active_swapped(old: ItemDef, charge: int)

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
# The one active he holds (ItemDef.KIND_ACTIVE), not in items, and its charge in fight rooms cleared.
var active: ItemDef
var active_charge := 0
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
# The Game tab's Pick up heals at full pills. Off, a heal on the floor waits there while pills are full.
var heals_at_full := false
# What the ending is chosen from (EndingRules), kept for this run only and never saved. Play time
# counts only while the run is unpaused and on a floor; Pension is what the rooms paid. The Pension
# Fund Statement also pays a share of pension_earned; FloorScene adds to it as it pays.
var play_time := 0.0
var pension_earned := 0
# Pills of his maximum lost for good this run, as the Expired Coupon takes. Never below one pill left.
var lost_max_pills := 0
# Whether a pill was lost in a floor boss's room; FloorScene resets it on entering one, so at the
# Chairman's fall it tells of his room alone.
var boss_room_pill_lost := false
# Depth -> the path id taken there.
var paths_taken := {}
# Back Room visits won in the Waiting Room just before the run, which count as table visits too.
var extra_table_visits := 0
# The case file's tally of this run, for its pages and the run log (RunLog): kills by EnemyDef id, every
# EnemyDef id met, each item id picked up in order, the hits that cost him pills, and each floor's seed.
# The checkpoint keeps it (RunCheckpoint.ending_to_dict).
var kills := {}
var met := {}
var found: Array[String] = []
var hits_taken := 0
var seeds: Array[String] = []
# The Flashback Cinema's lobby card lines shown this run (LifeSigns), so none shows twice. The
# checkpoint keeps them with the tally.
var life_signs_shown: Array[String] = []
# The film reel he carries (an Eras id, "" for none): one memory at a time. The checkpoint keeps it.
var held_reel := ""
# The era he relives in this room (Eras), "" for old Harold. Never saved: a checkpoint resumes in a
# cleared room, where no flashback runs.
var era := ""
# What the bank held when this run began, so the items that read "Pension carried" read only what this
# run brought in (EffectContext.purse). -1 until known: a checkpoint from before it existed.
var pension_at_start := 0
# The depth of the floor or landing he is on, for the items offered only where rules are posted.
var floor_depth := 0
# This run's rules kept and broken, and flashbacks started, for the rules and memory items. The save's
# lifetime counts (ProgressData.rules_kept) are separate.
var rules_kept := 0
var rules_broken := 0
var flashbacks_played := 0
var _won_visits := {}
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
	health.pill_bonus_allowed = effects.ctx.pills_not_counted
	health.heal_bonus = stats.heal_bonus
	health.half_heal_bonus = stats.half_heal_bonus
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


# A game won on an Arcade visit, numbered by the scene. Each visit counts once however many it wins.
func note_arcade_win(visit: int) -> void:
	_won_visits[visit] = true


func arcade_visits_won() -> int:
	return _won_visits.size() + extra_table_visits


# What EndingRules.choose reads, taken the moment the Chairman falls.
func ending_snapshot() -> Dictionary:
	return {
		"pills": health.pills,
		"lost_pill_in_boss_room": boss_room_pill_lost,
		"play_time": play_time,
		"pension_earned": pension_earned,
		"items": items.size(),
		"arcade_visits_won": arcade_visits_won(),
		"cursed": cursed,
		"paths": paths_taken.duplicate(),
	}


func enemy_health_mult() -> float:
	return TicketRules.CURSED_HEALTH_MULT if cursed else 1.0


func enemy_pension_mult() -> float:
	return TicketRules.CURSED_PENSION_MULT if cursed else 1.0


# Pet items held, and pets that came with no item (the Animal Lover's stray cat).
func pet_count() -> int:
	var count := stats.extra_pets
	for item in items:
		if item.is_pet():
			count += 1
	return count


# What a pet's hit is multiplied by: the bonuses added (Tin of Dog Treats, Animal Lover), then each
# effect's scale (Tin of Pet Food, Dinner Bell).
func pet_damage_mult() -> float:
	return (1.0 + stats.pet_damage_bonus) * effects.pet_damage_scale()


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


# An active goes to the active slot, swapping out any held one, which keeps its charge
# (active_swapped). active_charge_left is the charge a dropped active is taken back with; -1 is full.
func add_item(item: ItemDef, active_charge_left := -1) -> void:
	found.append(item.id)
	if item.is_active():
		take_active(item, active_charge_left)
		return
	var saves_before := stats.floor_lethal_saves
	items.append(item)
	effects.add(item)
	refresh_stats()
	# A Life Jacket picked up mid-floor works on this floor already, as does a combo that adds a save.
	health.lethal_saves += maxi(stats.floor_lethal_saves - saves_before, 0)


func take_active(item: ItemDef, charge := -1) -> void:
	var old := active
	var old_charge := active_charge
	active = item
	active_charge = active_needed() if charge < 0 else clampi(charge, 0, active_needed())
	effects.set_active(item)
	refresh_stats()
	if old != null:
		active_swapped.emit(old, old_charge)


# A resumed run's active, put back without a second on_gain.
func restore_active(item: ItemDef, charge: int) -> void:
	active = item
	active_charge = clampi(charge, 0, active_needed())
	effects.set_active(item, false)


# Fight rooms the held active needs, 1 for a once-a-floor one, 0 with none.
func active_needed() -> int:
	if active == null:
		return 0
	return 1 if active.charge_per_floor else maxi(active.charge_rooms, 1)


func active_ready() -> bool:
	return active != null and active_charge >= active_needed()


# A fight room cleared.
func charge_active() -> void:
	if active == null or active.charge_per_floor or active_ready():
		return
	active_charge += 1
	changed.emit()


# A floor start fills a once-a-floor active.
func fill_active() -> void:
	if active != null and active.charge_per_floor and not active_ready():
		active_charge = active_needed()
		changed.emit()


func use_active() -> bool:
	if not active_ready() or not effects.use_active():
		return false
	active_charge = 0
	changed.emit()
	return true


func note_met(enemy_id: String) -> void:
	if not enemy_id.is_empty():
		met[enemy_id] = true


func note_kill(enemy_id: String) -> void:
	if enemy_id.is_empty():
		return
	met[enemy_id] = true
	kills[enemy_id] = int(kills.get(enemy_id, 0)) + 1


func kill_count() -> int:
	var total := 0
	for id in kills:
		total += int(kills[id])
	return total


# A resumed run's item, put back as it was held: its effect and combos come back, but its on_gain never
# runs twice (the Inheritance Letter's Pension, the Strap's Thermoses). The caller refreshes the stats.
func restore_item(item: ItemDef) -> void:
	items.append(item)
	effects.add(item, false)


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
	active = null
	active_charge = 0
	effects.clear()
	lost_max_pills = 0
	refresh_stats()
	health.lethal_saves = mini(health.lethal_saves, stats.floor_lethal_saves)


# Works his stats out again from the forms and the items he holds, keeping the items. The levels and
# choices are the dictionaries the run was made with, which Progress.make_run takes straight from the
# save, so a form filed or refiled since then counts here. A higher maximum adds the pills it gains,
# and a lower one never leaves him holding more pills than it allows (Health.raise_max).
func refresh_stats() -> void:
	stats = PlayerStats.compute(_upgrades, _levels, items, _choices, effects.active_combos(), effects.active_sets())
	_apply_pill_rules()
	health.heal_bonus = stats.heal_bonus
	health.half_heal_bonus = stats.half_heal_bonus

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
	if active != null and active.id == id:
		return true
	return false


# A promised item is on its way to the player as a reward, so nothing else offers it.
func promise(item: ItemDef) -> void:
	_promised[item.id] = true


func is_promised(id: String) -> bool:
	return _promised.has(id)


# The promised and offered ids, for the run checkpoint, and how it puts them back.
func promised_ids() -> Array:
	return _promised.keys()


func offered_recipe_ids() -> Array:
	return _offered_recipes.keys()


func restore_marks(promised: Array, offered: Array) -> void:
	for id in promised:
		_promised[str(id)] = true
	for id in offered:
		_offered_recipes[str(id)] = true


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


func add_keys(count: int) -> void:
	if count <= 0:
		return
	keys = mini(keys + count, MAX_CONSUMABLE)
	changed.emit()


func add_bombs(count: int) -> void:
	if count <= 0:
		return
	bombs = mini(bombs + count, MAX_CONSUMABLE)
	changed.emit()


# What the items that scale per Thermos or Slip carried count: never more than PlayerStats.SCALE_CAP,
# and for Thermoses the Flask Holster and the Tea Lady count a few more.
func scaled_bombs() -> int:
	return mini(bombs, PlayerStats.SCALE_CAP + stats.thermos_scale_bonus)


func scaled_keys() -> int:
	return mini(keys, PlayerStats.SCALE_CAP)


# Whether a heal lying on the floor may be picked up now.
func can_take_heal() -> bool:
	return heals_at_full or health.pills < health.max_pills


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
	if not potion.action.is_empty() or potion.effect != null:
		return PotionActions.can_drink(self, potion)
	return potion.has_buff() or health.pills < health.max_pills


func swap_slips_and_thermoses() -> void:
	var slips := keys
	keys = bombs
	bombs = slips
	changed.emit()


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
	if not drunk.action.is_empty() or drunk.effect != null:
		PotionActions.apply(self, drunk)
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
	return stats.move_speed * (1.0 + (buff.speed_bonus if buff != null else 0.0)) * effects.move_pace() * Eras.speed_mult(era)


# One memory at a time: a second reel is wasted, on purpose, to reward using them.
func give_reel(era_id: String) -> bool:
	if not held_reel.is_empty():
		return false
	held_reel = era_id
	changed.emit()
	return true


func take_reel() -> String:
	var reel := held_reel
	held_reel = ""
	changed.emit()
	return reel


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


# What a charged swing's damage is multiplied by, before the cane's own damage_mult: the Charging Crystal's
# Full Moon and the crystal ball.
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
