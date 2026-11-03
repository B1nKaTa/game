class_name CornerSlide
extends RefCounted

# Walking straight into the very corner of something solid would stop Grandpa dead, which feels
# like a key not working. When what is in the way overlaps his feet by only a few pixels across the
# way he walks, he steps round its corner instead, sideways only, so the walk carries on.
const REACH := 5.0


# The sideways step that clears the corner, as long as the overlap: up or down when he walks
# across, left or right when he walks up or down. Zero when he walks at a slant, stands still,
# or overlaps the obstacle by more than reach.
static func nudge(feet: Rect2, obstacle: Rect2, moving: Vector2, reach := REACH) -> Vector2:
	var across_x := absf(moving.x) > 0.01
	var across_y := absf(moving.y) > 0.01
	if across_x == across_y:
		return Vector2.ZERO
	if across_x:
		var overlap := minf(feet.end.y, obstacle.end.y) - maxf(feet.position.y, obstacle.position.y)
		if overlap <= 0.0 or overlap > reach:
			return Vector2.ZERO
		return Vector2(0.0, -overlap if obstacle.get_center().y > feet.get_center().y else overlap)
	var overlap := minf(feet.end.x, obstacle.end.x) - maxf(feet.position.x, obstacle.position.x)
	if overlap <= 0.0 or overlap > reach:
		return Vector2.ZERO
	return Vector2(-overlap if obstacle.get_center().x > feet.get_center().x else overlap, 0.0)
