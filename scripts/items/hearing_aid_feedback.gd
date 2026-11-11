extends ItemEffect

# Hearing Aid (active): a feedback screech stuns every enemy in the room for STUN. With nobody to stun it
# keeps its charge.

const STUN := 2.0
const RING := 160.0
const COLOR := Color("9fd8ff")


func can_use(ctx: EffectContext) -> bool:
	return not ctx.enemies().is_empty()


func use(ctx: EffectContext) -> bool:
	for enemy in ctx.enemies():
		ctx.stun(enemy, STUN)
	ctx.add_fx(ItemFx.make_shockwave(RING, COLOR), ctx.feet())
	ctx.play_sound("alarm")
	return true
