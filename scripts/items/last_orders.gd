extends ItemEffect

# Last Orders: the last enemy left standing in a room takes MULT times the damage. Bosses are spared
# it, since a boss so often stands alone. The full loop measures damage exactly, so there it adds nothing.

const MULT := 2.0


func hit_damage(ctx: EffectContext, enemy: Enemy, amount: float, _source: String) -> float:
	if ctx.counting_exact or enemy.def.is_boss or not is_last(ctx, enemy):
		return amount
	return amount * MULT


# Whether no other living enemy is in the room.
static func is_last(ctx: EffectContext, enemy: Enemy) -> bool:
	for other in ctx.enemies():
		if other != enemy:
			return false
	return true
