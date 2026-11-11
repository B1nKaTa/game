extends ItemEffect

# Shepherd's Crook Handle: each regular enemy a combo finisher hits is pulled toward his feet. Bosses stand.

const PULL := 240.0
const TIME := 0.25


func on_hit(ctx: EffectContext, enemy: Enemy, _amount: float, source: String) -> void:
	if source != RunEffects.COMBO_3 or enemy.def.is_boss or enemy.is_dead():
		return
	var way := enemy.global_position.direction_to(ctx.feet())
	if way.is_zero_approx():
		return
	enemy.apply_push(way * PULL, TIME)
