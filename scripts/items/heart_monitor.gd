extends HitScaleEffect

# Heart Monitor: every pill of his maximum makes his hits PER harder.

const PER := 0.06


func bonus(ctx: EffectContext) -> float:
	var run := ctx.run()
	return PER * run.health.max_pills if run != null else 0.0
