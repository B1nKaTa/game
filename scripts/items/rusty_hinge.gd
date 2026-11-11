extends ItemEffect

# Rusty Hinge: the third hit of a combo stuns for a full second. The same enemy can be stunned again only
# after AGAIN_AFTER, so a boss is never held for good.

const STUN_TIME := 1.0
const AGAIN_AFTER := 2.5
const RUST := Color("c8743a")

var _time := 0.0
# Instance id -> the time it may be stunned again.
var _next := {}


func tick(_ctx: EffectContext, delta: float) -> void:
	_time += delta


func on_hit(ctx: EffectContext, enemy: Enemy, _amount: float, source: String) -> void:
	if source != RunEffects.COMBO_3 or enemy.is_dead():
		return
	var key := enemy.get_instance_id()
	if float(_next.get(key, -1.0)) > _time:
		return
	_next[key] = _time + AGAIN_AFTER
	ctx.stun(enemy, STUN_TIME)
	ctx.add_fx(ItemFx.make_sparks(RUST, 14.0), enemy.global_position)
