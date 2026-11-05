extends ItemEffect

# Grandma's Rolling Pin: every swing but a charged one is a slow, huge overhead smash that reaches in
# front and behind him. Its slowness is the item's swing_speed_bonus; the rest is set here.

const DAMAGE_MULT := 2.0
const REACH := 62.0
const HALF_ANGLE := 70.0
const PUSH := 170.0
const DURATION := 0.16
const FLOUR := Color("f6ecd6")


func on_swing(ctx: EffectContext, swing: SwingAttack) -> void:
	if swing.heavy:
		return
	swing.damage *= DAMAGE_MULT
	swing.reach = maxf(swing.reach, REACH)
	swing.half_angle_deg = maxf(swing.half_angle_deg, HALF_ANGLE)
	swing.push = maxf(swing.push, PUSH)
	swing.both_ways = true
	swing.style = SwingAttack.STYLE_PIN
	swing.set_duration(DURATION)
	var origin := ctx.player.global_position if ctx.has_player() else Vector2.ZERO
	for side: float in [1.0, -1.0]:
		ctx.add_fx(ItemFx.make_shockwave(30.0, FLOUR), origin + swing.direction * side * REACH * 0.7)
	ctx.play_sound("charged_hit")
