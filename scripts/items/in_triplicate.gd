extends ItemEffect

# In Triplicate: every Slip picked up or bought counts as two. The full loop counts Slips exactly.


func on_pickup(ctx: EffectContext, kind: String, amount: int) -> int:
	if kind == RunEffects.SLIP and not ctx.counting_exact:
		return amount * 2
	return amount
