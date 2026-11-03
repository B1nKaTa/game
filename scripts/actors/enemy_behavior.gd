class_name EnemyBehavior
extends RefCounted


func tick(_enemy: Enemy, _delta: float) -> void:
	pass


# Called once when the enemy is killed, before the room hears of it.
func on_killed(_enemy: Enemy) -> void:
	pass


# What a hit's damage is multiplied by, for an enemy that is easier to hurt at some moments.
func damage_scale(_enemy: Enemy) -> float:
	return 1.0
