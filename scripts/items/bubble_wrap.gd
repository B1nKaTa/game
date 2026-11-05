extends ItemEffect

# Bubble Wrap: the first shot to hit him on each floor pops and costs nothing.

const COLOR := Color("bfe8ff")

var popped := false


func on_floor_start(_ctx: EffectContext) -> void:
	popped = false


func on_hurt(ctx: EffectContext, pills: int, source: String) -> int:
	if popped or pills <= 0 or source != RunEffects.HURT_PROJECTILE:
		return pills
	popped = true
	ctx.add_fx(ItemFx.make_shockwave(24.0, COLOR), ctx.feet())
	ctx.add_fx(ItemFx.make_sparks(COLOR, 16.0), ctx.feet() + Vector2(0, -10))
	ctx.add_fx(ItemFx.make_pop("POP!", COLOR), ctx.feet())
	return 0
