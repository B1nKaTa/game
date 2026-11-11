extends ItemEffect

# Photocopier (active): copies the waiting pickup nearest him (a coin, Slip, Thermos, heal or potion), the
# copy beside it. With nothing to copy it keeps its charge.


func use(ctx: EffectContext) -> bool:
	return ctx.copy_pickup()
