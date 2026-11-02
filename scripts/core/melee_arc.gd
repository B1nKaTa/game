class_name MeleeArc
extends RefCounted


static func hits(origin: Vector2, direction: Vector2, reach: float, half_angle_deg: float, target: Vector2) -> bool:
	var offset := target - origin
	if offset.length() > reach:
		return false
	if offset.is_zero_approx():
		return true
	return absf(direction.angle_to(offset)) <= deg_to_rad(half_angle_deg)
