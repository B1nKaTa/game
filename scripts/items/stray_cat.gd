extends PetEffect

# The Animal Lover's stray cat: every EVERY seconds it scratches the enemy nearest Harold within REACH for DAMAGE.

const EVERY := 1.5
const REACH := 120.0
const DAMAGE := 4.0
var _left := EVERY


func tick(ctx: EffectContext, delta: float) -> void:
	_left -= delta
	if _left > 0.0:
		return
	_left = EVERY
	strike(ctx, nearest(ctx, REACH), DAMAGE)
