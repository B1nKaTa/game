class_name LeashRule
extends RefCounted

# A hold that keeps Grandpa's feet inside a circle for a while (Madame Zara's On the Line): whatever
# moves him, a walk, a dodge, a push or a body's shove, may carry his feet anywhere inside it and along
# its edge, but never outward past it. Caught outside as it locks, he is drawn back in at DRIFT_SPEED,
# a little quicker than he walks, and may not step further out meanwhile. Player.leash_to holds him
# through this; FloorScene._enter_room and the caller's death let him go.
const DRIFT_SPEED := 150.0


# The velocity that keeps feet at a point held to the circle over the next delta seconds.
static func held_velocity(feet: Vector2, velocity: Vector2, center: Vector2, radius: float, delta: float) -> Vector2:
	if delta <= 0.0:
		return velocity
	var offset := feet - center
	var distance := offset.length()
	if distance > radius:
		# Outside: drawn back toward the middle, never further out, never sideways round it.
		var inward := -offset / distance
		var pull := maxf(velocity.dot(inward), DRIFT_SPEED)
		# Never past the middle in one step.
		return inward * minf(pull, distance / delta)
	var next := feet + velocity * delta
	if next.distance_to(center) <= radius:
		return velocity
	# A step that would cross the edge stops on it, keeping what of it runs along the edge.
	var on_edge := center + (next - center).normalized() * radius
	return (on_edge - feet) / delta


# Whether feet at a point stand inside the circle.
static func holds(feet: Vector2, center: Vector2, radius: float) -> bool:
	return feet.distance_to(center) <= radius + 0.01
