extends ItemEffect

# Early Bird Special: for the first RUSH seconds in a fight room he walks and swings BOOST faster. With
# the Alarm Clock (Early Riser) the rush lasts COMBO_RUSH. A room counts while it has enemies when he
# walks in, so a cleared room starts no rush.

const RUSH := 10.0
const COMBO_RUSH := 20.0
const BOOST := 1.2
const COMBO := "early_riser"
const COLOR := Color("ffb347")
const TEXT := "EARLY BIRD!"

var left := 0.0


func on_room_enter(ctx: EffectContext, _room: Node) -> void:
	left = 0.0
	if ctx.enemies().is_empty():
		return
	left = rush_time(ctx)
	ctx.add_fx(ItemFx.make_pop(TEXT, COLOR), ctx.feet())


func rush_time(ctx: EffectContext) -> float:
	var run := ctx.run()
	return COMBO_RUSH if run != null and run.effects.has_combo(COMBO) else RUSH


func tick(_ctx: EffectContext, delta: float) -> void:
	left = maxf(left - delta, 0.0)


func move_pace(_ctx: EffectContext) -> float:
	return BOOST if left > 0.0 else 1.0


func swing_pace(_ctx: EffectContext) -> float:
	return BOOST if left > 0.0 else 1.0
