class_name DodgeGhost
extends Sprite2D

const FADE_TIME := 0.22
const START_ALPHA := 0.45
const TINT := Color(0.7, 0.85, 1.0)

var _left := FADE_TIME


static func alpha_at(left: float) -> float:
	return START_ALPHA * clampf(left / FADE_TIME, 0.0, 1.0)


func _ready() -> void:
	# Behind Grandpa and above the floor.
	z_index = -1
	# A run ending mid-dodge disables the player, and the ghost must still finish fading.
	process_mode = Node.PROCESS_MODE_ALWAYS
	modulate = Color(TINT, alpha_at(_left))


func _process(delta: float) -> void:
	_left -= delta
	modulate = Color(TINT, alpha_at(_left))
	if _left <= 0.0:
		queue_free()
