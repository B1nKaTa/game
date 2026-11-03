class_name PlayerStats
extends RefCounted

const BASE_PILLS := 4
const BASE_SPEED := 120.0
const BASE_DODGE_COOLDOWN := 1.0
const BASE_WARNING := 0.5
const MAX_DODGE_CUT := 0.5

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


static func compute(upgrades: Array[UpgradeDef], levels: Dictionary, items: Array[ItemDef]) -> PlayerStats:
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
	var effects: Array = []
	for upgrade in upgrades:
		effects.append([upgrade, int(levels.get(upgrade.id, 0))])
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
	stats.teeth_return_delay = DentureThrow.QUICK_RETURN_DELAY if quick_return else DentureThrow.RETURN_DELAY
	return stats
