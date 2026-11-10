extends HitScaleEffect

# Filing Cabinet: the Slip twin of the Tea Urn. Every Slip he carries makes his hits PER harder, counting
# at most PlayerStats.SCALE_CAP.

const PER := 0.05


func bonus(ctx: EffectContext) -> float:
	var run := ctx.run()
	return PER * run.scaled_keys() if run != null else 0.0
