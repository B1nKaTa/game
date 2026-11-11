extends HitScaleEffect

# Rose-Tinted Glasses: in a flashback, his hits deal BONUS more.

const BONUS := 0.3


func bonus(ctx: EffectContext) -> float:
	var run := ctx.run()
	return BONUS if run != null and not run.era.is_empty() else 0.0
