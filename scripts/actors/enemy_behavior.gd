class_name EnemyBehavior
extends RefCounted


func tick(_enemy: Enemy, _delta: float) -> void:
	pass


# Called once when the enemy is killed, before the room hears of it.
func on_killed(_enemy: Enemy) -> void:
	pass
