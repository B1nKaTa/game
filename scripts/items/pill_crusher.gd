extends ItemEffect

# Pill Crusher: every heal he picks up while short of pills restores half a pill more. The halves share
# Health.half_pills, so two of them make a whole pill, given with the heal that completes it. Its other
# half, the shorter reach to take a heal, is a stat.


func on_pickup(ctx: EffectContext, kind: String, amount: int) -> int:
	var run := ctx.run()
	if kind != RunEffects.HEAL or run == null or amount <= 0 or run.health.pills >= run.health.max_pills:
		return amount
	if run.health.half_pills >= 1:
		run.health.half_pills = 0
		return amount + 1
	run.health.half_pills = 1
	return amount
