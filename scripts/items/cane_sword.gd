extends ItemEffect

# Cane Sword: a fully charged swing also sends a steel shockwave forward, hitting each enemy it passes.

const DAMAGE := 18.0
const DISTANCE := 150.0
# It leaves from just ahead of him, so it reads as coming off the blade.
const AHEAD := 18.0


func on_charge_release(ctx: EffectContext, full: bool) -> void:
	if full:
		send_wave(ctx)


func send_wave(ctx: EffectContext) -> void:
	var run := ctx.run()
	var way := ctx.player.aim_direction() if ctx.has_player() else Vector2.RIGHT
	var origin := ctx.player.global_position if ctx.has_player() else Vector2.ZERO
	var damage := DAMAGE * (run.damage_mult() if run != null else 1.0)
	ctx.add_fx(ItemFx.make_wave(ctx, way, damage, DISTANCE), origin + way * AHEAD)
	ctx.play_sound("shield_block")
