class_name DeskSlam
extends GroundStrike

# The Chairman's answer up close: he slams the desk, and the warned ring round him lands as any warned
# spot does, a pill for feet inside it, then a burst of loose papers. Whoever it catches is shoved out
# of the ring, back to a distance where his other attacks reach. A dodge passes through it, as a dodge
# breaks any push. It sits on the boss and is a GroundStrike, so a stored room clears it.
const PAPER := Color("f4efe0")
const PAPER_EDGE := Color("8e8878")
const DESK := Color("5a3423")
const SHOVE_SPEED := 260.0
const SHOVE_TIME := 0.25
const PAPERS := 10
# Its warning reads at least as strongly as the gavel's double ring (GavelStrike): a thicker rim on a
# dark backing, so it shows on pale paper and carpet alike, and a second ring inside it.
const RING_WIDTH := 3.0
const RING_BACKING := Color(0.05, 0.02, 0.03, 0.55)
const RING_BACKING_WIDTH := 6.0
const INNER_RING_GAP := 8.0
const INNER_RING_WIDTH := 2.0


# Which way, and how hard, the slam shoves feet that stand inside it.
static func shove_for(center: Vector2, feet: Vector2) -> Vector2:
	var way := center.direction_to(feet)
	if way.is_zero_approx():
		way = Vector2.DOWN
	return way * SHOVE_SPEED


func _ready() -> void:
	landed.connect(_shove)


func _shove(at: Vector2) -> void:
	if not is_instance_valid(_source) or not is_instance_valid(_source.target):
		return
	var feet := _source.target_ground()
	if not hits(at, _radius, feet):
		return
	if _source.target.has_method("is_dodging") and _source.target.is_dodging():
		return
	if _source.target.has_method("push"):
		_source.target.push(shove_for(at, feet), SHOVE_TIME)


func _draw() -> void:
	if _landed:
		var progress := 1.0 - maxf(_show_left, 0.0) / SHOW_TIME
		draw_arc(Vector2.ZERO, _radius * (0.7 + 0.3 * progress), 0.0, TAU, 32, Color(DUST_COLOR, 0.8 * (1.0 - progress)), 3.0)
		for i in PAPERS:
			var spot := Vector2.from_angle(TAU * i / PAPERS + 0.3) * _radius * (0.4 + 0.6 * progress)
			draw_set_transform(spot, 0.5 * i, Vector2.ONE)
			draw_rect(Rect2(-4, -5, 8, 10), Color(PAPER, 1.0 - progress * 0.7))
			draw_rect(Rect2(-4, -5, 8, 10), Color(PAPER_EDGE, 1.0 - progress * 0.7), false, 1.0)
		draw_set_transform(Vector2.ZERO)
		return
	var filled := fill()
	draw_circle(Vector2.ZERO, _radius * filled, Color(COLOR, 0.15 + 0.3 * filled))
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 48, RING_BACKING, RING_BACKING_WIDTH)
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 48, COLOR, RING_WIDTH)
	draw_arc(Vector2.ZERO, _radius - INNER_RING_GAP, 0.0, TAU, 48, COLOR, INNER_RING_WIDTH)
	# His fists coming down on the desk in front of him.
	var lift := 10.0 * (1.0 - filled)
	draw_rect(Rect2(-22, -4 - lift, 12, 9), Color(DESK, 0.4 + 0.5 * filled))
	draw_rect(Rect2(10, -4 - lift, 12, 9), Color(DESK, 0.4 + 0.5 * filled))
