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
