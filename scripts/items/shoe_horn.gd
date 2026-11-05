extends ItemEffect

# Shoe Horn: his hits do MULT on an enemy winding up an attack.

const MULT := 1.3


func hit_damage(_ctx: EffectContext, enemy: Enemy, amount: float, _source: String) -> float:
	return amount * MULT if enemy.is_winding_up() else amount
