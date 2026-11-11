extends ItemEffect

# Exchange Desk (active): swaps his Slips and Thermoses. It waits while they are equal.


func can_use(ctx: EffectContext) -> bool:
	var run := ctx.run()
	return run != null and run.keys != run.bombs


func use(ctx: EffectContext) -> bool:
	ctx.run().swap_slips_and_thermoses()
	ctx.play_sound("form_filed")
	return true
