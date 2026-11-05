extends ItemEffect

# Collection Plate: every enemy he finishes drops one more Pension where it fell. Enemies that pay
# nothing (summons, which can come without end) drop nothing, so it cannot be farmed.

const PAY := 1


func on_kill(ctx: EffectContext, enemy: Enemy, _source: String) -> void:
	if enemy.coin_value() <= 0:
		return
	ctx.drop(RoomRules.DROP_COIN, enemy.global_position, PAY)
