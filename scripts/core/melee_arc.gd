class_name MeleeArc
extends RefCounted


static func closest_point(body: Rect2, point: Vector2) -> Vector2:
	return point.clamp(body.position, body.end)


static func hits_body(origin: Vector2, direction: Vector2, reach: float, half_angle_deg: float, body: Rect2) -> bool:
	var offset := closest_point(body, origin) - origin
	if offset.length() > reach:
		return false
	var half_angle := deg_to_rad(half_angle_deg)
	if offset.is_zero_approx() or absf(direction.angle_to(offset)) <= half_angle:
		return true
	# The nearest point is outside the angle, so the body can only enter the arc across a side edge.
	for side in [-half_angle, half_angle]:
		if _segment_crosses(body, origin, origin + direction.rotated(side) * reach):
			return true
	return false


static func _segment_crosses(body: Rect2, from: Vector2, to: Vector2) -> bool:
	var corners := [body.position, Vector2(body.end.x, body.position.y), body.end, Vector2(body.position.x, body.end.y)]
	for i in corners.size():
		if Geometry2D.segment_intersects_segment(from, to, corners[i], corners[(i + 1) % corners.size()]) != null:
			return true
	return false
