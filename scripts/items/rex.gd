extends PetEffect

# Rex, the Late Dog: every EVERY seconds he bites the enemy nearest Harold within REACH for DAMAGE.

const EVERY := 1.0
const REACH := 160.0
const DAMAGE := 6.0
var _left := EVERY


func tick(ctx: EffectContext, delta: float) -> void:
	_left -= delta
	if _left > 0.0:
		return
	_left = EVERY
	strike(ctx, nearest(ctx, REACH), DAMAGE)
