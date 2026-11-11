extends HitScaleEffect

# Model Citizen's Badge: every rule kept this run makes his hits PER harder.

const PER := 0.06


func bonus(ctx: EffectContext) -> float:
	var run := ctx.run()
	return PER * run.rules_kept if run != null else 0.0
