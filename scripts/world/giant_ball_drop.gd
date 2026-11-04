class_name GiantBallDrop
extends GroundStrike

# A giant golf ball dropped from on high onto a warned spot: a floor boss's heaviest attack, so its mark
# is the clearest. It is a ground strike whose warning always fills for the whole windup, with a second
# ring standing outside the first, the ball's shadow darkening the spot and the ball itself growing as
# it falls. It lands as any ground strike does, breaking props and costing its damage to whoever stands
# under it, and comes to nothing if the boss falls first.
const RING_GAP := 8.0
const BALL := Color("fbfbf4")
const DIMPLE := Color("aeb3aa")
const SHADOW := Color(0.0, 0.0, 0.0)
# How high the ball starts above the spot, in pixels.
const FALL := 90.0


# Puts one down for a boss, as Enemy.strike_ground does. Walls and holes take no ball.
static func drop(enemy: Enemy, at: Vector2, radius: float, warning: float, damage: int) -> GiantBallDrop:
	if enemy.open_ground.is_valid() and not enemy.open_ground.call(at):
		return null
	var ball := GiantBallDrop.new()
	ball.setup(enemy, radius, warning, 0.0, 0.0, damage)
	enemy.get_parent().add_child(ball)
	ball.global_position = at
	return ball


func outer_ring() -> float:
	return _radius + RING_GAP


func _draw() -> void:
	super._draw()
	if _landed:
		var fade := clampf(_show_left / SHOW_TIME, 0.0, 1.0)
		draw_circle(Vector2.ZERO, _radius * 0.7, Color(BALL, 0.8 * fade))
		return
	var filled := fill()
	draw_arc(Vector2.ZERO, outer_ring(), 0.0, TAU, 32, COLOR, 2.0)
	draw_circle(Vector2.ZERO, _radius * 0.85 * filled, Color(SHADOW, 0.15 + 0.3 * filled))
	# The ball falls in from above and grows, drawn see-through so the warning under it still reads.
	var size := lerpf(6.0, _radius * 0.7, filled)
	var at := Vector2(0.0, -FALL * (1.0 - filled))
	draw_circle(at, size, Color(BALL, 0.55))
	draw_arc(at, size, 0.0, TAU, 24, Color(0.0, 0.0, 0.0, 0.8), 1.5)
	for i in 4:
		draw_circle(at + Vector2.from_angle(i * TAU / 4.0 + 0.4) * size * 0.45, maxf(size * 0.08, 1.0), Color(DIMPLE, 0.8))
