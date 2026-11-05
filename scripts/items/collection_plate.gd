extends ItemEffect

# Collection Plate: the first enemies he finishes in each room drop one more Pension where they fell.
# Enemies that pay nothing (summons, which can come without end) drop nothing, so it cannot be farmed.
# A coin for every kill added about half again to a floor's fights; ROOM_LIMIT keeps it near a tenth
# of a full clear (income_probe, 2026-11-05).

const PAY := 1
const ROOM_LIMIT := 3

var _paid := 0


func on_room_enter(_ctx: EffectContext, _room: Node) -> void:
	_paid = 0


func on_kill(ctx: EffectContext, enemy: Enemy, _source: String) -> void:
	if enemy.coin_value() <= 0 or _paid >= ROOM_LIMIT or ctx.counting_exact:
		return
	_paid += 1
	ctx.drop(RoomRules.DROP_COIN, enemy.global_position, PAY)
