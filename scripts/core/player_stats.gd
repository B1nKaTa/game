class_name PlayerStats
extends RefCounted

const BASE_PILLS := 4
const BASE_SPEED := 120.0
const BASE_DODGE_COOLDOWN := 1.0
const BASE_WARNING := 0.5
const MAX_DODGE_CUT := 0.5
const MIN_SWING_SPEED := 0.5
const MAX_SWING_SPEED := 2.0
# A form option never brings the dentures back sooner than this.
const MIN_TEETH_RETURN := 1.0
# A charged swing never charges in less than this share of its usual time, and a shop never cuts its
# prices by more than this share.
const MIN_CHARGE_TIME := 0.5
const MAX_SHOP_DISCOUNT := 0.5
# Below this share of its health an enemy shows its weak spot, which the Bifocals option hits harder.
const WOUNDED_BELOW := 0.5
# How far a Thermos blast reaches before the Big Bang option widens it. Thermos reads it from here, so
# this core script never names a world node class: Thermos -> Player -> RunState -> PlayerStats would
# otherwise close a load cycle.
const BASE_BLAST_RADIUS := 56.0
# Enemies never notice him less than this share as far, and a heal is never out of reach nearer than
# this share of its usual reach.
const MIN_NOTICE_MULT := 0.25
const MIN_HEAL_REACH := 0.25

var max_pills: int = BASE_PILLS
var move_speed: float = BASE_SPEED
var dodge_cooldown: float = BASE_DODGE_COOLDOWN
var damage_mult: float = 1.0
var pension_mult: float = 1.0
var warning_fraction: float = BASE_WARNING
var reveals_enemy_health := false
var thermos_damage_mult := 1.0
# How many levels of Thermos upgrade are owned, and whether that is every level there is.
var thermos_level := 0
var thermos_maxed := false
# The thrown dentures: what their bite is multiplied by, how far they fly, how many enemies one
# throw bites, and how long they lie before coming back.
var bite_damage_mult := 1.0
var bite_range := DentureThrow.BASE_RANGE
var bites_per_throw := 1
var teeth_return_delay := DentureThrow.RETURN_DELAY
# The form options' stats. How fast the cane combo swings, as a multiple of its usual pace.
var swing_speed := 1.0
# How long a dodge lasts, as a multiple of its usual length.
var dodge_length := 1.0
# Pills added to every heal that restores anything.
var heal_bonus := 0
# Multipliers on Pension by source, applied on top of pension_mult.
var enemy_pension_mult := 1.0
var reward_pension_mult := 1.0
# What the cane multiplies its damage by against an enemy below half health.
var wounded_damage_mult := 1.0
var reveals_secrets := false
var blast_radius := BASE_BLAST_RADIUS
# Thermoses added at the start of each run.
var bonus_bombs := 0
# The deep floors' stats. A charged swing's charge time and damage, as multiples of their usual.
var charge_time_mult := 1.0
var charge_damage_mult := 1.0
# The share taken off a run's shop prices.
var shop_discount := 0.0
# What Pension from bosses is multiplied by, on top of pension_mult and reward_pension_mult.
var boss_pension_mult := 1.0
# The chance that a swing does double damage.
var lucky_swing_chance := 0.0
# Lethal hits survived on one pill, once more on each floor.
var floor_lethal_saves := 0
# The share of a run's Pension paid again on dying in it.
var death_pension_bonus := 0.0
# The hundred items' rules. See StatEffect.
var wet_grip := false
var min_slow_factor := 0.0
var clean_kills := false
var shows_offscreen_enemies := false
# What his swings' push is multiplied by.
var swing_push_mult := 1.0
# The dentures' items. See StatEffect.
var teeth_glue_time := 0.0
var teeth_boomerang := false
var teeth_floor_bite := false
var teeth_sets := 1
# The movement items. Dodges he can make back to back, whether charging keeps his full walk, what
# sleepers' noticing range and a room's wait are scaled by, whether a dodge rounds corners, whether
# slides and pushes leave him be, and what his reach to take a heal on the floor is scaled by.
var dodge_charges := 1
var charge_full_speed := false
var notice_mult := 1.0
var dodge_rounds_corners := false
var steady_feet := false
var heal_reach_mult := 1.0
# The third batch's items. See StatEffect. max_pills_cap is 0 for no cap; RunState applies it.
var max_pills_cap := 0
var fuse_bonus := 0.0
var shop_extra_items := 0
var shop_markup := 0.0
var arcade_win_bonus := 0.0
var poker_win_bonus := 0.0
var coin_reach_mult := 1.0
var dark_light_mult := 1.0
var never_dark := false


# choices maps a form id to its milestone option. A form at or past its milestone with no entry
# reads as option A, and the chosen option's effect counts once, whatever the level.
# combos are the ComboDefs the run has formed. Their numbers count once each, as an item's do.
static func compute(upgrades: Array[UpgradeDef], levels: Dictionary, items: Array[ItemDef], choices: Dictionary = {}, combos: Array[ComboDef] = []) -> PlayerStats:
	var pills := 0
	var speed := 0.0
	var cut := 0.0
	var damage := 0.0
	var bite := 0.0
	var reach := 0.0
	var bites := 1
	var quick_return := false
	var pension := 0.0
	var warning := 0.0
	var reveals := false
	var thermos := 0.0
	var thermos_levels := 0
	var thermos_all := false
	var swing := 0.0
	var lasting := 0.0
	var heal := 0
	var enemy_pension := 0.0
	var reward_pension := 0.0
	var wounded := 0.0
	var secrets := false
	var radius := 0.0
	var bombs := 0
	var return_cut := 0.0
	var charge_cut := 0.0
	var charge_damage := 0.0
	var discount := 0.0
	var boss_pension := 0.0
	var lucky := 0.0
	var lethal_saves := 0
	var death_pension := 0.0
	var grip := false
	var slow_floor := 0.0
	var clean := false
	var arrows := false
	var push := 0.0
	var glue := 0.0
	var boomerang := false
	var floor_bite := false
	var sets := 1
	var charges := 0
	var full_charge := false
	var notice := 0.0
	var corners := false
	var steady := false
	var reach_cut := 0.0
	var pill_cap := 0
	var fuse := 0.0
	var shop_extra := 0
	var markup := 0.0
	var arcade_win := 0.0
	var poker_win := 0.0
	var coin_reach := 0.0
	var dark_light := 0.0
	var lit := false
	var effects: Array = []
	for upgrade in upgrades:
		var level := int(levels.get(upgrade.id, 0))
		effects.append([upgrade, level])
		if upgrade.has_choice() and level >= upgrade.milestone_level:
			effects.append([upgrade.option(str(choices.get(upgrade.id, UpgradeDef.OPTION_A))), 1])
	for item in items:
		effects.append([item, 1])
	for combo in combos:
		effects.append([combo, 1])
	for entry in effects:
		var effect: StatEffect = entry[0]
		var count: int = entry[1]
		pills += effect.bonus_pills * count
		speed += effect.move_speed_bonus * count
		cut += effect.dodge_cooldown_cut * count
		damage += effect.damage_bonus * count
		pension += effect.pension_bonus * count
		warning += effect.warning_bonus * count
		thermos += effect.thermos_damage_bonus * count
		bite += effect.bite_damage_bonus * count
		reach += effect.bite_range_bonus * count
		swing += effect.swing_speed_bonus * count
		lasting += effect.dodge_length_bonus * count
		heal += effect.heal_bonus * count
		enemy_pension += effect.enemy_pension_bonus * count
		reward_pension += effect.reward_pension_bonus * count
		wounded += effect.wounded_damage_bonus * count
		radius += effect.blast_radius_bonus * count
		bombs += effect.bonus_bombs * count
		return_cut += effect.teeth_return_cut * count
		charge_cut += effect.charge_time_cut * count
		charge_damage += effect.charge_damage_bonus * count
		discount += effect.shop_discount * count
		boss_pension += effect.boss_pension_bonus * count
		lucky += effect.lucky_swing_chance * count
		lethal_saves += effect.floor_lethal_saves * count
		death_pension += effect.death_pension_bonus * count
		push += effect.swing_push_bonus * count
		charges += effect.bonus_dodge_charges * count
		notice += effect.notice_bonus * count
		reach_cut += effect.heal_reach_cut * count
		fuse += effect.fuse_bonus * count
		shop_extra += effect.shop_extra_items * count
		markup += effect.shop_markup * count
		arcade_win += effect.arcade_win_bonus * count
		poker_win += effect.poker_win_bonus * count
		coin_reach += effect.coin_reach_bonus * count
		dark_light += effect.dark_light_bonus * count
		if count > 0 and effect.max_pills_cap > 0:
			pill_cap = effect.max_pills_cap if pill_cap == 0 else mini(pill_cap, effect.max_pills_cap)
		if count > 0:
			lit = lit or effect.never_dark
		if count > 0:
			bites = maxi(bites, effect.bites_through)
		if effect is UpgradeDef and effect.thermos_damage_bonus > 0.0:
			thermos_levels += count
			thermos_all = count >= effect.max_level()
		# The last level of Denture Adhesive also brings the teeth back sooner.
		if effect is UpgradeDef and effect.bite_range_bonus > 0.0 and count > 0 and count >= effect.max_level():
			quick_return = true
		if count > 0 and effect.reveals_enemy_health:
			reveals = true
		if count > 0 and effect.reveals_secrets:
			secrets = true
		if count > 0:
			grip = grip or effect.wet_grip
			slow_floor = maxf(slow_floor, effect.min_slow_factor)
			clean = clean or effect.clean_kills
			arrows = arrows or effect.shows_offscreen_enemies
			glue = maxf(glue, effect.teeth_glue_time)
			boomerang = boomerang or effect.teeth_boomerang
			floor_bite = floor_bite or effect.teeth_floor_bite
			sets = maxi(sets, effect.teeth_sets)
			full_charge = full_charge or effect.charge_full_speed
			corners = corners or effect.dodge_rounds_corners
			steady = steady or effect.steady_feet
	var stats := PlayerStats.new()
	stats.max_pills = BASE_PILLS + pills
	stats.move_speed = BASE_SPEED * (1.0 + speed)
	stats.dodge_cooldown = BASE_DODGE_COOLDOWN * (1.0 - minf(cut, MAX_DODGE_CUT))
	stats.damage_mult = 1.0 + damage
	stats.pension_mult = 1.0 + pension
	stats.warning_fraction = minf(BASE_WARNING + warning, 1.0)
	stats.reveals_enemy_health = reveals
	stats.thermos_damage_mult = 1.0 + thermos
	stats.thermos_level = thermos_levels
	stats.thermos_maxed = thermos_all
	stats.bite_damage_mult = 1.0 + bite
	stats.bite_range = DentureThrow.BASE_RANGE + reach
	stats.bites_per_throw = bites
	var return_delay := DentureThrow.QUICK_RETURN_DELAY if quick_return else DentureThrow.RETURN_DELAY
	if return_cut > 0.0:
		return_delay = maxf(return_delay - return_cut, MIN_TEETH_RETURN)
	stats.teeth_return_delay = return_delay
	stats.swing_speed = clampf(1.0 + swing, MIN_SWING_SPEED, MAX_SWING_SPEED)
	stats.dodge_length = 1.0 + lasting
	stats.heal_bonus = heal
	stats.enemy_pension_mult = 1.0 + enemy_pension
	stats.reward_pension_mult = 1.0 + reward_pension
	stats.wounded_damage_mult = 1.0 + wounded
	stats.reveals_secrets = secrets
	stats.blast_radius = BASE_BLAST_RADIUS * (1.0 + radius)
	stats.bonus_bombs = bombs
	stats.charge_time_mult = maxf(1.0 - charge_cut, MIN_CHARGE_TIME)
	stats.charge_damage_mult = 1.0 + charge_damage
	stats.shop_discount = clampf(discount, 0.0, MAX_SHOP_DISCOUNT)
	stats.boss_pension_mult = 1.0 + boss_pension
	stats.lucky_swing_chance = clampf(lucky, 0.0, 1.0)
	stats.floor_lethal_saves = lethal_saves
	stats.death_pension_bonus = death_pension
	stats.wet_grip = grip
	stats.min_slow_factor = clampf(slow_floor, 0.0, 1.0)
	stats.clean_kills = clean
	stats.shows_offscreen_enemies = arrows
	stats.swing_push_mult = maxf(1.0 + push, 0.0)
	stats.teeth_glue_time = glue
	stats.teeth_boomerang = boomerang
	stats.teeth_floor_bite = floor_bite
	stats.teeth_sets = sets
	stats.dodge_charges = 1 + maxi(charges, 0)
	stats.charge_full_speed = full_charge
	stats.notice_mult = maxf(1.0 + notice, MIN_NOTICE_MULT)
	stats.dodge_rounds_corners = corners
	stats.steady_feet = steady
	stats.heal_reach_mult = clampf(1.0 - reach_cut, MIN_HEAL_REACH, 1.0)
	stats.max_pills_cap = pill_cap
	stats.fuse_bonus = maxf(fuse, 0.0)
	stats.shop_extra_items = maxi(shop_extra, 0)
	stats.shop_markup = maxf(markup, 0.0)
	stats.arcade_win_bonus = maxf(arcade_win, 0.0)
	stats.poker_win_bonus = maxf(poker_win, 0.0)
	stats.coin_reach_mult = maxf(1.0 + coin_reach, 1.0)
	stats.dark_light_mult = maxf(1.0 + dark_light, 1.0)
	stats.never_dark = lit
	return stats



# What a hit does once the weak spot is counted: wounded_mult applies only below WOUNDED_BELOW health.
static func strike_damage(base: float, hp_fraction: float, wounded_mult: float) -> float:
	return base * wounded_mult if hp_fraction < WOUNDED_BELOW else base


# A hit on a boss, with the gold gavel's mult. Anything else takes the hit as it is.
static func boss_damage(base: float, is_boss: bool, boss_mult: float) -> float:
	return base * boss_mult if is_boss else base


# A swing's damage after the Lucky Tee's roll, in [0, 1): double when the roll falls under the chance.
static func lucky_damage(base: float, chance: float, roll: float) -> float:
	return base * 2.0 if roll < chance else base
