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
# Below this share of its health an enemy shows its weak spot, which the Bifocals option hits harder.
const WOUNDED_BELOW := 0.5

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
var blast_radius := Thermos.BLAST_RADIUS
# Thermoses added at the start of each run.
var bonus_bombs := 0


# choices maps a form id to its milestone option. A form at or past its milestone with no entry
# reads as option A, and the chosen option's effect counts once, whatever the level.
static func compute(upgrades: Array[UpgradeDef], levels: Dictionary, items: Array[ItemDef], choices: Dictionary = {}) -> PlayerStats:
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
	var effects: Array = []
	for upgrade in upgrades:
		var level := int(levels.get(upgrade.id, 0))
		effects.append([upgrade, level])
		if upgrade.has_choice() and level >= upgrade.milestone_level:
			effects.append([upgrade.option(str(choices.get(upgrade.id, UpgradeDef.OPTION_A))), 1])
	for item in items:
		effects.append([item, 1])
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
	stats.blast_radius = Thermos.BLAST_RADIUS * (1.0 + radius)
	stats.bonus_bombs = bombs
	return stats


# What a hit does once the weak spot is counted: wounded_mult applies only below WOUNDED_BELOW health.
static func strike_damage(base: float, hp_fraction: float, wounded_mult: float) -> float:
	return base * wounded_mult if hp_fraction < WOUNDED_BELOW else base
