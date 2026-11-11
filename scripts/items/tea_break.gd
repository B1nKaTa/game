extends ItemEffect

# Tea Break: a blast of his that lands on MOST or more enemies heals half a pill.

const MOST := 3
const TEXT := "TEA BREAK"
const COLOR := Color("c98a4b")


func on_blast_hits(ctx: EffectContext, _at: Vector2, count: int) -> void:
	if count < MOST or ctx.counting_pills:
		return
	ctx.heal_half()
	ctx.add_fx(ItemFx.make_pop(TEXT, COLOR), ctx.feet())
	ctx.play_sound("pill_heal")
