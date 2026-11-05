extends ItemEffect

# Reading Glasses on a Chain: a swing that lands on ENOUGH enemies or more gives the dodge back at once.

const ENOUGH := 3
const SOURCES := [RunEffects.SWING, RunEffects.CHARGE, RunEffects.COMBO_3]

var refunds := 0
var _hits := 0


func on_swing(_ctx: EffectContext, _swing: SwingAttack) -> void:
	_hits = 0


func on_hit(_ctx: EffectContext, _enemy: Enemy, _amount: float, source: String) -> void:
	if SOURCES.has(source):
		_hits += 1


func on_swing_end(ctx: EffectContext, _swing: SwingAttack) -> void:
	if _hits < ENOUGH:
		return
	_hits = 0
	refunds += 1
	if ctx.has_player():
		ctx.player.refund_dodge()
		ctx.add_fx(ItemFx.make_pop("DODGE!", Color("9fd8ff")), ctx.feet())
	ctx.play_sound("chime")
