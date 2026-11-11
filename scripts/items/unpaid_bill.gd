extends HitScaleEffect

# Unpaid Bill: his hits deal half again, but every fight room he walks into takes FEE Pension from the purse,
# or, with less than that, half a pill (never his last). The full loop counts Pension and pills exactly.

const BONUS := 0.5
const FEE := 10
const RED := Color("e0262f")


func bonus(_ctx: EffectContext) -> float:
	return BONUS


func on_room_enter(ctx: EffectContext, _room: Node) -> void:
	if ctx.enemies().is_empty() or ctx.counting_exact or ctx.counting_pills:
		return
	if ctx.spend_from_purse(FEE):
		ctx.add_fx(ItemFx.make_pop("BILL -%d" % FEE, RED), ctx.feet())
		ctx.play_sound("coin")
		return
	ctx.lose_half()
	ctx.add_fx(ItemFx.make_pop("FINAL DEMAND", RED), ctx.feet())
