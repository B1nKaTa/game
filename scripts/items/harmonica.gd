extends ItemEffect

# Harmonica (active): plays the one song he knows and heals a pill. It waits while his pills are full.


func can_use(ctx: EffectContext) -> bool:
	var run := ctx.run()
	return run != null and not ctx.counting_pills and run.health.pills < run.health.max_pills


func use(ctx: EffectContext) -> bool:
	ctx.heal(1)
	ctx.add_fx(ItemFx.make_note(0), ctx.feet())
	ctx.play_sound("pill_heal")
	return true
