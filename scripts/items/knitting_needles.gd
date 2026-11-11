extends ItemEffect

# Knitting Needles: every swing also pokes two needles forward, a little either side of the swing.

const DAMAGE := 5.0
const DISTANCE := 130.0
# Radians either side of the swing's middle.
const SPREAD := 0.21
const AHEAD := 12.0


func on_swing(ctx: EffectContext, swing: SwingAttack) -> void:
	var run := ctx.run()
	var damage := DAMAGE * (run.damage_mult() if run != null else 1.0)
	var origin := ctx.player.global_position if ctx.has_player() else Vector2.ZERO
	for side: float in [-1.0, 1.0]:
		var way := swing.direction.rotated(SPREAD * side)
		ctx.add_fx(ItemFx.make_needle(ctx, way, damage, DISTANCE), origin + way * AHEAD)
