extends ItemEffect

# Neck Pillow: a landing heals him fully.


func on_floor_start(ctx: EffectContext) -> void:
	var run := ctx.run()
	if run != null and ctx.is_landing():
		ctx.heal(run.health.max_pills)
