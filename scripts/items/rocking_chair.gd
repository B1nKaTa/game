extends ItemEffect

# Rocking Chair Rhythm: the first swing within WINDOW of a dodge ending hits twice as hard and further.

const WINDOW := 0.8
const MULT := 2.0
const PUSH := 220.0
const COLOR := Color("ffd27a")

var _primed := 0.0


func is_primed() -> bool:
	return _primed > 0.0


func on_dodge_end(_ctx: EffectContext) -> void:
	_primed = WINDOW


func tick(_ctx: EffectContext, delta: float) -> void:
	_primed = maxf(_primed - delta, 0.0)


func on_swing(ctx: EffectContext, swing: SwingAttack) -> void:
	if _primed <= 0.0 or swing.heavy:
		return
	_primed = 0.0
	swing.damage *= MULT
	swing.push = maxf(swing.push, PUSH)
	var origin := ctx.player.global_position if ctx.has_player() else Vector2.ZERO
	ctx.add_fx(ItemFx.make_sparks(COLOR, 18.0), origin + swing.direction * 26.0)
