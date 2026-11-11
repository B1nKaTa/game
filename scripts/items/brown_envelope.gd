extends ItemEffect

# Brown Envelope: the Auditor pays twice his Pension and always leaves an item.

const MULT := 2.0


# The full loop counts Pension and the Auditor's drops exactly, so there he pays as usual.
func on_auditor(ctx: EffectContext, auditor: Enemy) -> void:
	if ctx.counting_exact:
		return
	auditor.coin_mult = MULT
	auditor.leaves_item = true
