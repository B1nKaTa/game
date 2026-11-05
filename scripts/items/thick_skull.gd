extends ItemEffect

# Thick Skull: a blast, an enemy's or his own Thermos, costs one pill less, but never none.


func on_hurt(ctx: EffectContext, pills: int, source: String) -> int:
	if pills < 2 or not (source in [RunEffects.HURT_BLAST, RunEffects.HURT_OWN_BLAST]):
		return pills
	ctx.add_fx(ItemFx.make_pop("Thunk", Color("d9c9a8")), ctx.feet())
	return pills - 1
