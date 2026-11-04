class_name StatEffect
extends Resource

@export var bonus_pills: int = 0
@export var move_speed_bonus: float = 0.0
@export var dodge_cooldown_cut: float = 0.0
# Cane damage only. The thrown dentures have their own bonus below.
@export var damage_bonus: float = 0.0
# Extra bite damage for the thrown dentures, as a fraction of their base.
@export var bite_damage_bonus: float = 0.0
# Pixels added to how far the dentures fly.
@export var bite_range_bonus: float = 0.0
# How many enemies one throw can bite through. Zero leaves the usual one.
@export var bites_through: int = 0
@export var pension_bonus: float = 0.0
@export var warning_bonus: float = 0.0
@export var reveals_enemy_health: bool = false
# Extra damage a Thermos blast does to enemies, never to Grandpa.
@export var thermos_damage_bonus: float = 0.0
# The form options' effects. Each is a fraction of the base unless noted.
# How much faster the cane combo swings. Negative swings slower.
@export var swing_speed_bonus: float = 0.0
# How much longer a dodge lasts.
@export var dodge_length_bonus: float = 0.0
# Pills added to every heal that restores anything.
@export var heal_bonus: int = 0
# Extra Pension from regular enemies, on top of the general pension_bonus.
@export var enemy_pension_bonus: float = 0.0
# Extra Pension from chests, treasure and bosses, on top of the general pension_bonus.
@export var reward_pension_bonus: float = 0.0
# Extra cane damage to enemies below half health.
@export var wounded_damage_bonus: float = 0.0
# Whether secret rooms show on the map before they are found.
@export var reveals_secrets: bool = false
# How much wider a Thermos blast reaches.
@export var blast_radius_bonus: float = 0.0
# Thermoses added at the start of each run.
@export var bonus_bombs: int = 0
# Seconds cut from how long the thrown dentures lie before coming back.
@export var teeth_return_cut: float = 0.0
