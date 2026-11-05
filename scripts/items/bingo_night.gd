extends ItemEffect

# Bingo Night, the combo of the Lucky Bingo Card and the Bingo Dabber: every BINGO also heals half a pill.

const COLOR := Color("7fe08a")


func on_event(ctx: EffectContext, event: String) -> void:
	if event != RunEffects.EVENT_BINGO:
		return
	ctx.heal_half()
	ctx.add_fx(ItemFx.make_pop("+1/2", COLOR), ctx.feet() + Vector2(0, -14))
