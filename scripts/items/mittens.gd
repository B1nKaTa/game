extends PetEffect

# Mittens: every EVERY seconds she finishes the nearest regular enemy within REACH that is below BELOW of
# its health. Never a boss. The full loop counts damage exactly, so there she only watches.

const EVERY := 0.5
const REACH := 200.0
const BELOW := 0.25
var _left := EVERY


func tick(ctx: EffectContext, delta: float) -> void:
	_left -= delta
	if _left > 0.0:
		return
	_left = EVERY
	var target := nearest_where(ctx, REACH, _is_low)
	if target != null:
		# Her pounce finishes it, whatever the pet multiplier is.
		strike(ctx, target, (target.hp + 1.0) / maxf(mult(ctx), 0.01))


static func _is_low(enemy: Enemy) -> bool:
	return not enemy.def.is_boss and enemy.hp < enemy.max_hp() * BELOW
