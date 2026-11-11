extends HitScaleEffect

# Scrapbook: every flashback started this run makes old Harold's hits PER harder (not young Harold's).

const PER := 0.08


func bonus(ctx: EffectContext) -> float:
	var run := ctx.run()
	if run == null or not run.era.is_empty():
		return 0.0
	return PER * run.flashbacks_played
