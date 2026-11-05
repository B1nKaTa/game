extends ItemEffect

# Casserole Dish: the first kill in each room heals half a pill.

const COLOR := Color("7fe08a")

var fed := false


func on_room_enter(_ctx: EffectContext, _room: Node) -> void:
	fed = false


func on_kill(ctx: EffectContext, _enemy: Enemy, _source: String) -> void:
	if fed:
		return
	fed = true
	ctx.heal_half()
	ctx.add_fx(ItemFx.make_pop("+1/2", COLOR), ctx.feet() + Vector2(0, -14))
