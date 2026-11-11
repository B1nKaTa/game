extends HitScaleEffect

# Pet Cemetery Plot: every pet he has (RunState.pet_count) makes his hits PER harder.

const PER := 0.08


func bonus(ctx: EffectContext) -> float:
	var run := ctx.run()
	return PER * run.pet_count() if run != null else 0.0
