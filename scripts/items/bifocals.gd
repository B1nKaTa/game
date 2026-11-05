extends ItemEffect

# Suspicious Bifocals: any hit on an enemy under a quarter of its health lands half again as hard.

const BELOW := 0.25
const MULT := 1.5


func hit_damage(_ctx: EffectContext, enemy: Enemy, amount: float, _source: String) -> float:
	if enemy.hp / maxf(enemy.max_hp(), 1.0) < BELOW:
		return amount * MULT
	return amount
