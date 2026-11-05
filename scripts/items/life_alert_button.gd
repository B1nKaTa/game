extends ItemEffect

# Life Alert Button: the first hit that would cost him a pill in each room costs nothing.

const COLOR := Color("e4524f")

var blocked := false


func on_room_enter(_ctx: EffectContext, _room: Node) -> void:
	blocked = false


func on_hurt(ctx: EffectContext, pills: int, _source: String) -> int:
	if blocked or pills <= 0:
		return pills
	blocked = true
	ctx.add_fx(ItemFx.make_shockwave(30.0, COLOR), ctx.feet())
	ctx.add_fx(ItemFx.make_pop("HELP'S COMING", COLOR), ctx.feet())
	ctx.play_sound("alarm")
	return 0
