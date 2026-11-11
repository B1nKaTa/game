extends ItemEffect

# Paper Cuts: every combo finisher also flings a paper slip forward that cuts every enemy in its line,
# for free. A flashback's own moves fling nothing.

const DAMAGE := 14.0
const DISTANCE := 180.0
const SPEED := 320.0
const AHEAD := 14.0
const PAPER := Color("f2ecd8")


func on_swing(ctx: EffectContext, swing: SwingAttack) -> void:
	if not swing.finisher or swing.from_era or ctx.counting_exact:
		return
	var slip := ItemFx.make_needle(ctx, swing.direction, DAMAGE, DISTANCE)
	slip.stops_at_first = false
	slip.speed = SPEED
	slip.color = PAPER
	ctx.add_fx(slip, ctx.feet() + swing.direction * AHEAD)
