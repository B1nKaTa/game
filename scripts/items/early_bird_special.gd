extends ItemEffect

# Early Bird Special: for the first RUSH seconds in a fight room he walks and swings BOOST faster. A room
# counts while it has enemies when he walks in, so a cleared room starts no rush.

const RUSH := 10.0
const BOOST := 1.25
const COLOR := Color("ffb347")
const TEXT := "EARLY BIRD!"

var left := 0.0


func on_room_enter(ctx: EffectContext, _room: Node) -> void:
	left = 0.0
	if ctx.enemies().is_empty():
		return
	left = rush_time()
	ctx.add_fx(ItemFx.make_pop(TEXT, COLOR), ctx.feet())
	ctx.play_sound("charge_ready")


func rush_time() -> float:
	return RUSH


func tick(_ctx: EffectContext, delta: float) -> void:
	left = maxf(left - delta, 0.0)


func move_pace(_ctx: EffectContext) -> float:
	return BOOST if left > 0.0 else 1.0


func swing_pace(_ctx: EffectContext) -> float:
	return BOOST if left > 0.0 else 1.0
