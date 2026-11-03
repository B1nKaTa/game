class_name PerfumeHaze
extends LightsOut

# A small Lights Out that follows Grandpa's feet into perfume clouds: while he stands in one, his view
# closes in to a soft circle around him, and it opens again as he steps out. Warnings, marks and shots
# draw above it, as above any dark. A room keeps one, and it leaves once every cloud has faded.
const LIGHT_RADIUS_IN_CLOUD := 55.0
const DARKNESS := 0.8
# How fast the haze closes in and clears, in shade per second.
const EASE := 4.0

var _shade := 0.0
var _clouds_seen := false


# Eases the shade toward dark in a cloud and toward clear outside one.
static func shade_toward(shade: float, in_cloud: bool, delta: float) -> float:
	return move_toward(shade, DARKNESS if in_cloud else 0.0, EASE * delta)


# The room's haze, made when the first cloud lands.
static func ensure(room: Node, target: Node2D) -> PerfumeHaze:
	for child in room.get_children():
		if child is PerfumeHaze and not child.is_queued_for_deletion():
			return child
	var haze := PerfumeHaze.new()
	haze.follow(target)
	room.add_child(haze)
	return haze


func follow(target: Node2D) -> void:
	_target = target
	light_radius = LIGHT_RADIUS_IN_CLOUD
	text = ""


func current_shade() -> float:
	return _shade


func _process(delta: float) -> void:
	if not is_instance_valid(_target):
		queue_free()
		return
	var clouds := get_tree().get_nodes_in_group(PerfumeCloud.GROUP)
	var feet: Vector2 = _target.feet().global_position if _target.has_method("feet") else _target.global_position
	_shade = shade_toward(_shade, PerfumeCloud.any_covers(clouds, feet), delta)
	queue_redraw()
	_clouds_seen = _clouds_seen or not clouds.is_empty()
	if clouds.is_empty() and _shade <= 0.0 and _clouds_seen:
		queue_free()
