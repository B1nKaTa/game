extends ItemEffect

# Banana Peel: his first dodge in a room while enemies stand in it drops a peel where it began. The first
# enemy onto it trips, stunned for TRIP_TIME (ItemFx.FxPeel). One peel a room.

const TRIP_TIME := 1.2

var _dropped := false


func on_room_enter(_ctx: EffectContext, _room: Node) -> void:
	_dropped = false


func on_dodge(ctx: EffectContext, _direction: Vector2) -> void:
	if _dropped or ctx.enemies().is_empty():
		return
	_dropped = true
	ctx.add_fx(ItemFx.make_peel(ctx, TRIP_TIME), ctx.feet())
