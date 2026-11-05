extends ItemEffect

# Dentures in a Glass: while his dentures are out of his mouth, thrown or lying in the room, his cane
# combo swings PACE faster. Nothing else.

const PACE := 1.15


func swing_pace(ctx: EffectContext) -> float:
	if is_instance_valid(ctx.player) and not ctx.player.has_teeth():
		return PACE
	return 1.0
