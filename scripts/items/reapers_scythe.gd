extends ItemEffect

# The Reaper's Other Scythe: a fully charged swing becomes a wide sweep all the way round him, the blade
# going once round while it hits.

const REACH := 76.0
const DAMAGE_MULT := 1.3
const PUSH := 260.0
const DURATION := 0.3


func on_swing(ctx: EffectContext, swing: SwingAttack) -> void:
	if not swing.heavy:
		return
	swing.half_angle_deg = 180.0
	swing.reach = maxf(swing.reach, REACH)
	swing.damage *= DAMAGE_MULT
	swing.push = maxf(swing.push, PUSH)
	swing.style = SwingAttack.STYLE_SWEEP
	swing.set_duration(DURATION)
	ctx.play_sound("charged_hit")
