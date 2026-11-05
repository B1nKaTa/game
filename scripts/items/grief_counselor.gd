extends ItemEffect

# Grief Counselor's Card: a fight room cleared without losing a pill pays PAY Pension. Each room clears
# once, so it can pay once a room at most.

const PAY := 8
const COLOR := Color("ffd24a")


func on_room_clear(ctx: EffectContext, _room: Node, damage_taken_here: int) -> void:
	if damage_taken_here > 0:
		return
	ctx.pay(PAY)
	ctx.add_fx(ItemFx.make_pop("NO GRIEF +%d" % PAY, COLOR), ctx.feet())
