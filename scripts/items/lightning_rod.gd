extends ItemEffect

# Lightning Rod Cane: every enemy a fully charged swing hits also takes a bolt of BOLT, an item hit. The
# full loop counts damage exactly, so there no bolt falls.

const BOLT := 20.0
const RADIUS := 14.0
# How far above the enemy the bolt starts.
const HEIGHT := 160.0
const COLOR := Color("cfe8ff")
var _full := false


func on_charge_release(_ctx: EffectContext, full: bool) -> void:
	_full = full


func on_hit(ctx: EffectContext, enemy: Enemy, _amount: float, source: String) -> void:
	if source != RunEffects.CHARGE or not _full or ctx.counting_exact:
		return
	var bolt := ItemFx.make_bolt(HEIGHT, COLOR) as ItemFx.FxBolt
	bolt.blast_radius = RADIUS
	ctx.add_fx(bolt, enemy.global_position)
	ctx.hit_enemy(enemy, BOLT, RunEffects.ITEM)


func on_swing_end(_ctx: EffectContext, _swing: SwingAttack) -> void:
	_full = false
