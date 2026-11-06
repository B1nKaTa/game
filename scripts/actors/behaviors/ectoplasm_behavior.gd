class_name EctoplasmBehavior
extends EnemyBehavior

# Ectoplasm, a slow blob of deep dark green goo that a medium calls up. It oozes after Grandpa and
# hurts only by touch, leaving a short sticky trail behind it (EctoplasmTrail) that slows him while his
# feet are on it, each blob fading after a few seconds. It has no attack of its own.
# A blob of goo every this many pixels oozed.
const LAY_EVERY := 10.0

var _since_piece := 0.0
var _last := Vector2.INF
var _trail: EctoplasmTrail


func tick(enemy: Enemy, _delta: float) -> void:
	enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed
	var at := enemy.global_position
	if _last != Vector2.INF:
		_since_piece += at.distance_to(_last)
	_last = at
	if _since_piece >= LAY_EVERY:
		_since_piece = 0.0
		_lay(enemy)


func _lay(enemy: Enemy) -> void:
	if not enemy.is_inside_tree():
		return
	if not is_instance_valid(_trail):
		_trail = EctoplasmTrail.new()
		_trail.setup(enemy.target, enemy)
		enemy.get_parent().add_child(_trail)
	_trail.add_piece(enemy.global_position + Vector2(0.0, enemy.def.body_size.y * 0.25))
