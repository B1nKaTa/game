extends ItemEffect

# Brass Cane Topper: a combo's finisher hits all the way round him, at the swing's own reach.

const BRASS := Color("e8b84a")


func on_swing(ctx: EffectContext, swing: SwingAttack) -> void:
	if not swing.finisher or swing.heavy:
		return
	swing.half_angle_deg = 180.0
	var origin := ctx.player.global_position if ctx.has_player() else Vector2.ZERO
	ctx.add_fx(ItemFx.make_shockwave(swing.reach, BRASS), origin)
