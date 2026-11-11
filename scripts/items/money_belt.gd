extends HitScaleEffect

# Money Belt: every full STEP Pension in the purse (EffectContext.purse) makes his hits PER harder, at most
# MOST_STEPS of them.

const STEP := 50
const PER := 0.05
const MOST_STEPS := 10


func bonus(ctx: EffectContext) -> float:
	return PER * mini(ctx.purse() / STEP, MOST_STEPS)
