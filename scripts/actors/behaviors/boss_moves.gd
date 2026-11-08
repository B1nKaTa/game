class_name BossMoves
extends RefCounted

# A boss starts an attack only with its whole body inside what the camera really shows. The camera
# sits on the room's middle when the room fits the view and stops at its edges otherwise, so the
# view is worked out the way the floor places it, around Grandpa's feet. The margin keeps a body
# pressed to the screen's edge out.
const VIEW_MARGIN := Vector2(8.0, 8.0)
const CATCH_UP_SPEED := 1.9
const SUMMON_WARNING := 0.7


static func view_rect(room_size: Vector2, focus: Vector2) -> Rect2:
	var center := RoomCamera.center_for(room_size, focus, RoomBackdrop.VIEW_SIZE)
	return Rect2(center - RoomBackdrop.VIEW_SIZE / 2.0, RoomBackdrop.VIEW_SIZE)


# What the camera shows of the room clear of the HUD, in room space: the view below the HUD's top rows
# (Hud.BAND_BOTTOM), and the small map's panel in its top right corner (Hud.MAP_PANEL), which lies over
# the play area. Returns {"play": Rect2, "map": Rect2}.
static func clear_view(room_size: Vector2, focus: Vector2) -> Dictionary:
	var view := view_rect(room_size, focus)
	var play := view.grow_individual(0.0, -Hud.BAND_BOTTOM, 0.0, 0.0)
	var map := Rect2(view.position + Hud.MAP_PANEL.position, Hud.MAP_PANEL.size)
	return {"play": play, "map": map}


# Whether a point shows in a clear_view with margin to spare: inside the play area and off the map.
static func shown_clear(clear: Dictionary, point: Vector2, margin: float) -> bool:
	var play: Rect2 = clear["play"]
	var map: Rect2 = clear["map"]
	return play.grow(-margin).has_point(point) and not map.grow(margin).has_point(point)


static func in_view(body: Rect2, room_size: Vector2, focus: Vector2) -> bool:
	return view_rect(room_size, focus).grow_individual(-VIEW_MARGIN.x, -VIEW_MARGIN.y, -VIEW_MARGIN.x, -VIEW_MARGIN.y).encloses(body)


static func ring_directions(count: int, start_angle: float) -> Array[Vector2]:
	var directions: Array[Vector2] = []
	for i in count:
		directions.append(Vector2.from_angle(start_angle + TAU * i / float(count)))
	return directions


# Spots across the way Grandpa is walking. Standing still, the way ahead counts as away from the boss.
static func cutoff_points(player: Vector2, moving: Vector2, boss: Vector2, count: int, distance: float, spread: float) -> Array[Vector2]:
	var ahead := moving.normalized() if not moving.is_zero_approx() else boss.direction_to(player)
	var points: Array[Vector2] = []
	for i in count:
		var offset := (i - (count - 1) / 2.0) * spread
		points.append(player + ahead.rotated(offset) * distance)
	return points


static func can_summon(alive: int, cap: int) -> bool:
	return alive < cap


# Spread evenly over a total angle, with the middle one aimed down the lane that was shown.
static func fan_directions(aim: Vector2, count: int, spread: float) -> Array[Vector2]:
	var directions: Array[Vector2] = []
	for i in count:
		directions.append(aim.rotated(spread * (i / float(count - 1) - 0.5)) if count > 1 else aim)
	return directions
