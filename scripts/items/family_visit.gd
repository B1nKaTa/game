extends ItemEffect

# Family Visit (Photo of the Grandkids with the Casserole Dish): on his last pill, a kill heals a whole
# pill, once a room.

const COLOR := Color("7fe08a")

var fed := false


func on_room_enter(_ctx: EffectContext, _room: Node) -> void:
	fed = false


func on_kill(ctx: EffectContext, _enemy: Enemy, _source: String) -> void:
	var run := ctx.run()
	if fed or run == null or run.health.pills != 1 or run.health.is_dead():
		return
	fed = true
	ctx.heal(1)
	ctx.add_fx(ItemFx.make_pop("GRANDKIDS +1", COLOR), ctx.feet() + Vector2(0, -14))
