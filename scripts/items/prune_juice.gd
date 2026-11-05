extends ItemEffect

# Prune Juice: every dodge costs a Pension. With none left it is free, never below zero.

const COST := 1


func on_dodge(ctx: EffectContext, _direction: Vector2) -> void:
	ctx.spend(COST)
