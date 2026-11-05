extends ItemEffect

# Second Opinion: the first heal he picks up on each floor while short of pills heals double.

const COLOR := Color("7fe08a")

var used := false


func on_floor_start(_ctx: EffectContext) -> void:
	used = false


func on_pickup(ctx: EffectContext, kind: String, amount: int) -> int:
	var run := ctx.run()
	if used or kind != RunEffects.HEAL or run == null or amount <= 0 or run.health.pills >= run.health.max_pills:
		return amount
	used = true
	ctx.add_fx(ItemFx.make_pop("Second opinion: x2", COLOR), ctx.feet())
	return amount * 2
