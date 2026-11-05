extends ItemEffect

# Dentist's Nightmare, the combo of the Gold Fillings and the Denture Glue Gun: every whole second the
# dentures stay glued knocks a one-Pension coin loose. Only from enemies that pay at all, and never more
# than ROOM_LIMIT a room.

const ROOM_LIMIT := 8
const GOLD := Color("ffd24a")

var _dropped := 0


func on_room_enter(_ctx: EffectContext, _room: Node) -> void:
	_dropped = 0


func on_glue_tick(ctx: EffectContext, enemy: Enemy) -> void:
	if _dropped >= ROOM_LIMIT or enemy.coin_value() <= 0:
		return
	_dropped += 1
	ctx.drop(RoomRules.DROP_COIN, enemy.global_position, 1)
	ctx.add_fx(ItemFx.make_sparks(GOLD, 16.0), enemy.global_position)
