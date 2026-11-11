extends ItemEffect

# Chattering Ricochet: after each bite, the dentures jump to the next nearest living enemy within REACH of
# the bitten one that this throw has not bitten, up to JUMPS a throw. A jump is a bite: bite damage, the
# bite source, and the bite hook runs, so bleeds and glue follow it. The full loop counts damage exactly.

const JUMPS := 3
const REACH := 140.0
var _jumps := 0
var _bitten := {}


func on_throw(_ctx: EffectContext) -> void:
	_jumps = 0
	_bitten.clear()


func on_bite(ctx: EffectContext, enemy: Enemy) -> void:
	_bitten[enemy.get_instance_id()] = true
	var run := ctx.run()
	if _jumps >= JUMPS or run == null or ctx.counting_exact:
		return
	var next := _next(ctx, enemy)
	if next == null:
		return
	_jumps += 1
	ctx.add_fx(ItemFx.make_sparks(ItemFx.FIZZ_COLOR), next.global_position)
	if ctx.hit_enemy(next, ThrownDentures.bite_damage(run.bite_damage_mult()), RunEffects.BITE):
		run.effects.bite(next)


func _next(ctx: EffectContext, from: Enemy) -> Enemy:
	var best: Enemy = null
	for enemy in ctx.enemies_near(from.global_position, REACH):
		if enemy == from or _bitten.has(enemy.get_instance_id()):
			continue
		if best == null or enemy.global_position.distance_to(from.global_position) < best.global_position.distance_to(from.global_position):
			best = enemy
	return best
