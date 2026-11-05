class_name EnemyBehavior
extends RefCounted


func tick(_enemy: Enemy, _delta: float) -> void:
	pass


# Called once as the enemy is ready, before its first tick and before any wait at the room's start, for
# a look it must have from its first frame.
func on_ready(_enemy: Enemy) -> void:
	pass


# Called once when the enemy is killed, before the room hears of it.
func on_killed(_enemy: Enemy) -> void:
	pass


# Whether it lies asleep, an ambusher not yet woken, so walking into it costs nothing. See ContactRule.
func is_sleeping(_enemy: Enemy) -> bool:
	return false


# What a hit's damage is multiplied by, for an enemy that is easier to hurt at some moments.
func damage_scale(_enemy: Enemy) -> float:
	return 1.0
