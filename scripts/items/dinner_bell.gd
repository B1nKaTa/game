extends ItemEffect

# Dinner Bell (active): his pets hit SCALE times as hard for TIME seconds. It waits while he has no pet.

const SCALE := 3.0
const TIME := 5.0
var _left := 0.0


func can_use(ctx: EffectContext) -> bool:
	var run := ctx.run()
	return run != null and not ctx.counting_exact and run.pet_count() > 0


func use(ctx: EffectContext) -> bool:
	_left = TIME
	ctx.add_fx(ItemFx.make_pop("DINNER!", ItemFx.BINGO_COLOR), ctx.feet())
	return true


func pet_damage_scale(_ctx: EffectContext) -> float:
	return SCALE if _left > 0.0 else 1.0


func tick(_ctx: EffectContext, delta: float) -> void:
	_left = maxf(_left - delta, 0.0)
