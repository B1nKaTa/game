extends ItemEffect

# Suspicious Bifocals: a hit of his that leaves a regular enemy below BELOW of its health finishes it. Never
# a boss. The full loop counts damage exactly.

const BELOW := 0.15


func on_hit(ctx: EffectContext, enemy: Enemy, _amount: float, source: String) -> void:
	if ctx.counting_exact or enemy.is_dead() or enemy.def.is_boss or not RunEffects.is_his_hit(source):
		return
	if enemy.hp < enemy.max_hp() * BELOW:
		ctx.hit_enemy(enemy, enemy.hp + 1.0, RunEffects.ITEM)
