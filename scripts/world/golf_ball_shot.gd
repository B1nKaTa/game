class_name GolfBallShot
extends Projectile

# A golf ball driven down a warned lane: a white dimpled ball with a short streak behind it. It flies and
# hurts as any shot does, stopping at walls and props.
const BALL := Color("fbfbf4")
const DIMPLE := Color("aeb3aa")
const STREAK := Color(1.0, 1.0, 1.0, 0.4)
const RADIUS := 4.0


# Fires one from where the enemy stands, as Enemy.shoot does with a plain shot.
static func fire(enemy: Enemy, direction: Vector2, speed: float, damage := -1) -> GolfBallShot:
	var ball := GolfBallShot.new()
	ball.setup(direction, speed, enemy.target, enemy.attack_damage(damage))
	ball.position = enemy.position
	enemy.get_parent().add_child(ball)
	return ball


func _draw() -> void:
	var back := -_velocity.normalized() * 10.0
	draw_line(back, Vector2.ZERO, STREAK, 3.0)
	draw_circle(Vector2.ZERO, RADIUS, BALL)
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 12, Color.BLACK, 1.0)
	draw_circle(Vector2(-1.5, -1.0), 0.8, DIMPLE)
	draw_circle(Vector2(1.0, 1.0), 0.8, DIMPLE)
