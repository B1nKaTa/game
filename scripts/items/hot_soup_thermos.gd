extends ItemEffect

# Hot Soup Thermos: every blast of his leaves a puddle of burning soup that hurts the enemies standing
# in it now and then, never him. With the Second Thermos Strap (Soup of the Day) it burns twice as long.
# The full loop measures each blast's damage, so there no puddle is laid.

const RADIUS := 34.0
const TIME := 3.0
const DAMAGE := 2.0
const COMBO := "soup_of_the_day"


func on_bomb(ctx: EffectContext, at: Vector2) -> void:
	if ctx.counting_exact:
		return
	ctx.add_fx(ItemFx.make_soup(ctx, RADIUS, puddle_time(ctx), DAMAGE), at)


func puddle_time(ctx: EffectContext) -> float:
	var run := ctx.run()
	return TIME * (2.0 if run != null and run.effects.has_combo(COMBO) else 1.0)
