class_name DummyBehavior
extends EnemyBehavior

# The Training Yard's dummy. It never moves or attacks, and its health is back to full every frame, so
# it can take any number of hits and never falls.


func tick(enemy: Enemy, _delta: float) -> void:
	enemy.hp = enemy.max_hp()


func damage_scale(_enemy: Enemy) -> float:
	return 1.0
