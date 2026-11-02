class_name HurtLook
extends RefCounted

const RED_TIME := 0.15
const BLINK_PERIOD := 0.1
const DIM_ALPHA := 0.35


static func alpha(invulnerable_left: float) -> float:
	if invulnerable_left <= 0.0:
		return 1.0
	if Health.INVULN_TIME - invulnerable_left < RED_TIME:
		return 1.0
	return DIM_ALPHA if int(invulnerable_left / BLINK_PERIOD) % 2 == 0 else 1.0
