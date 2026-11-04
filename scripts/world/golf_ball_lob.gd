class_name GolfBallLob
extends GroundStrike

# A golf ball chipped high onto a warned spot. The spot warns as any ground strike does, a red circle
# filling for its whole warning, while the ball sails in on a high arc from whoever chipped it and its
# shadow grows on the spot. It lands as a ground strike lands: it breaks props and costs a pill to
# whoever stands under it, and comes to nothing if the one who chipped it falls first.
const BALL := Color("fbfbf4")
const SHADOW := Color(0.0, 0.0, 0.0)
const ARC := 46.0
const BALL_RADIUS := 4.0

var _from := Vector2.INF


# Puts one down for an enemy, as Enemy.strike_ground does, flying in from where the enemy stands. Walls
# and holes take no ball.
static func chip(enemy: Enemy, at: Vector2, radius: float, warning: float, delay := 0.0, damage := -1) -> GolfBallLob:
	if enemy.open_ground.is_valid() and not enemy.open_ground.call(at):
		return null
	var ball := GolfBallLob.new()
	ball.setup(enemy, radius, warning, delay, 0.0, damage)
	ball.lob_from(enemy.global_position)
	enemy.get_parent().add_child(ball)
	ball.global_position = at
	return ball


func lob_from(point: Vector2) -> void:
	_from = point


func lobbed_from() -> Vector2:
	return _from


func _draw() -> void:
	super._draw()
	if _landed or _from == Vector2.INF or _delay > 0.0:
		return
	var filled := fill()
	draw_circle(Vector2.ZERO, _radius * 0.45 * filled, Color(SHADOW, 0.3 * filled))
	var start := _from - global_position
	var at := start.lerp(Vector2.ZERO, filled) + Vector2(0.0, -sin(filled * PI) * ARC)
	draw_circle(at, BALL_RADIUS, BALL)
	draw_arc(at, BALL_RADIUS, 0.0, TAU, 12, Color.BLACK, 1.0)
