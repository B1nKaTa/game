extends ItemEffect

# Obituary Clippings: each kill in a room makes his hits there PER_KILL harder, up to MOST_KILLS of them,
# and walking into another room starts the count again. Summons count for nothing, so a boss's endless
# helpers never stack it. The full loop measures damage exactly, so there it adds nothing.

const PER_KILL := 0.05
const MOST_KILLS := 10
const COLOR := Color("d8d2c0")

var kills := 0


func on_room_enter(_ctx: EffectContext, _room: Node) -> void:
	kills = 0


func on_kill(ctx: EffectContext, enemy: Enemy, _source: String) -> void:
	if enemy.is_summon or kills >= MOST_KILLS:
		return
	kills += 1
	ctx.add_fx(ItemFx.make_pop("+%d%%" % roundi(kills * PER_KILL * 100.0), COLOR), ctx.feet())


func hit_damage(ctx: EffectContext, _enemy: Enemy, amount: float, source: String) -> float:
	if ctx.counting_exact or not RunEffects.is_his_hit(source):
		return amount
	return amount * (1.0 + kills * PER_KILL)
