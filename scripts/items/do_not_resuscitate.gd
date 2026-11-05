extends ItemEffect

# Do Not Resuscitate Bracelet: every hit of his deals three times as much, and its stats cap his pills
# at one. The full loop measures damage exactly, so there it hits as usual.

const MULT := 3.0


func hit_damage(ctx: EffectContext, _enemy: Enemy, amount: float, _source: String) -> float:
	return amount if ctx.counting_exact else amount * MULT
