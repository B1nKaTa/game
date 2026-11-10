extends ItemEffect

# Flask Holster: two Thermoses the moment it is taken; its stats let the Thermos items count four more.

const AT_ONCE := 2


func on_gain(ctx: EffectContext) -> void:
	var run := ctx.run()
	if run != null:
		run.add_bombs(AT_ONCE)
