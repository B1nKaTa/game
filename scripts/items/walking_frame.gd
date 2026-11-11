extends ItemEffect

# Walking Frame (active): plants a frame ahead of him, across his aim, for WalkingFrame.LIFE seconds.


func use(ctx: EffectContext) -> bool:
	var aim := ctx.player.aim_direction() if ctx.has_player() else Vector2.RIGHT
	var frame := WalkingFrame.make(ctx.feet(), aim, ctx)
	ctx.add_fx(frame, frame.position)
	return true
