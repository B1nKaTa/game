class_name Pet
extends ShotGuard

# A pet beside Harold: it walks to its slot round his feet (or circles him), lunges at what it bites, and
# draws a placeholder in its colour until res://art/props/pet_<look>.png exists. Its rules live in its
# item's effect (PetEffect); this node shows it, and blocks a shot when its effect sets check.

const SPEED := 150.0
const SLOT_REACH := 22.0
# Behind him first, then to his sides, then round again a little further out.
const SLOT_ANGLES := [150.0, 30.0, 210.0, 330.0, 90.0, 270.0]
const LUNGE_TIME := 0.18
const LUNGE_PACE := 2.5
const EYE := Color("1a1410")
# A sideways move shorter than this (pixels in one frame) does not turn it.
const TURN_MIN := 0.05

var look := ""
var color := Color.WHITE
var slot := 0
var speed := SPEED
# Radians a second for the pets that circle him (Joey, the moths); 0 for one that keeps its slot.
var orbit_speed := 0.0
var orbit_radius := SLOT_REACH
var orbit_angle := 0.0
# 1 faces right, -1 faces left: the way it last moved sideways. A move this small sideways is not a turn.
var facing := 1
var _lunge_to := Vector2.INF
var _lunge_left := 0.0


static func make(pet_look: String, pet_color: Color, pet_slot: int, walk_speed := SPEED) -> Pet:
	var pet := Pet.new()
	pet.look = pet_look
	pet.color = pet_color
	pet.slot = pet_slot
	pet.speed = walk_speed
	return pet


static func slot_offset(pet_slot: int, reach := SLOT_REACH) -> Vector2:
	var ring := pet_slot / SLOT_ANGLES.size()
	var angle := deg_to_rad(float(SLOT_ANGLES[pet_slot % SLOT_ANGLES.size()]))
	return Vector2.from_angle(angle) * (reach + 10.0 * ring)


static func step_toward(from: Vector2, to: Vector2, pace: float, delta: float) -> Vector2:
	var offset := to - from
	var step := pace * delta
	return to if offset.length() <= step else from + offset.normalized() * step


func home() -> Vector2:
	if not is_instance_valid(follow):
		return global_position
	if orbit_speed != 0.0:
		return follow.global_position + Vector2.from_angle(orbit_angle) * orbit_radius
	return follow.global_position + slot_offset(slot)


func lunge_to(at: Vector2) -> void:
	_face(at.x - global_position.x)
	_lunge_to = at
	_lunge_left = LUNGE_TIME


# Turns to face a sideways move and redraws, only when the way it faces changes.
func _face(dx: float) -> void:
	if absf(dx) < TURN_MIN:
		return
	var way := 1 if dx > 0.0 else -1
	if way == facing:
		return
	facing = way
	queue_redraw()


func _process(delta: float) -> void:
	var before := global_position
	orbit_angle = wrapf(orbit_angle + orbit_speed * delta, 0.0, TAU)
	if _lunge_left > 0.0:
		_lunge_left -= delta
		global_position = step_toward(global_position, _lunge_to, speed * LUNGE_PACE, delta)
	elif orbit_speed != 0.0:
		global_position = home()
	else:
		global_position = step_toward(global_position, home(), speed, delta)
	_face(global_position.x - before.x)


# A round body, a smaller head toward where it last moved, and one dark eye. No straight crossing strokes.
# The picture is drawn mirrored when it faces left.
func _draw() -> void:
	var art := PropArt.texture("pet_" + look)
	if art != null:
		if facing < 0:
			var top_left := PropArt.centred(art)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1.0, 1.0))
			draw_texture(art, Vector2(-top_left.x - art.get_width(), top_left.y))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			PropArt.draw(self, art)
		return
	var side := float(facing)
	draw_circle(Vector2(0, 1), 5.0, color.darkened(0.35))
	draw_circle(Vector2.ZERO, 4.5, color)
	draw_circle(Vector2(4 * side, -3), 3.0, color)
	draw_circle(Vector2(5 * side, -3.5), 0.9, EYE)
