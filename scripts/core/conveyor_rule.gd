class_name ConveyorRule
extends RefCounted

# An escalator strip carries whatever walks on it along its own way, on top of the walk. Walking
# against a strip is slow and walking with it is fast. It never hurts anyone.
const SPEED := 60.0


static func carry(strip_dir: Vector2, speed: float) -> Vector2:
	if strip_dir.is_zero_approx():
		return Vector2.ZERO
	return strip_dir.normalized() * speed
