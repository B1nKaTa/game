extends ItemEffect

# Duplicate Key Cutter: three Slips the moment it is taken, and one more at every floor start (never a landing).

const AT_ONCE := 3
const EACH_FLOOR := 1


func on_gain(ctx: EffectContext) -> void:
	var run := ctx.run()
	if run != null:
		run.add_keys(AT_ONCE)


func on_floor_start(ctx: EffectContext) -> void:
	var run := ctx.run()
	if run != null and not ctx.is_landing() and not ctx.counting_exact:
		run.add_keys(EACH_FLOOR)
