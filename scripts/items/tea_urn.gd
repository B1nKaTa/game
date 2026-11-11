extends HitScaleEffect

# Tea Urn: every Thermos he carries makes his hits PER harder, counting at most the scale cap
# (RunState.scaled_bombs).

const PER := 0.05


func bonus(ctx: EffectContext) -> float:
	var run := ctx.run()
	return PER * run.scaled_bombs() if run != null else 0.0
