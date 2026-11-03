class_name SlideRule
extends RefCounted

# On dry ground a body goes where it is told at once. On a wet floor it only eases toward that,
# so letting go keeps some speed and a turn takes a moment.
const WET_GRIP := 4.0


static func velocity(current: Vector2, wanted: Vector2, on_wet: bool, delta: float) -> Vector2:
	if not on_wet:
		return wanted
	return current.lerp(wanted, minf(WET_GRIP * delta, 1.0))
