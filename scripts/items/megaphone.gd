extends ItemEffect

# Megaphone (active): every enemy in a cone ahead of him is shoved away and stunned.

const REACH := 150.0
const HALF_ANGLE := 45.0
const PUSH := 220.0
const PUSH_TIME := 0.3
const STUN := 1.5
const COLOR := Color("ffd24a")


static func in_cone(from: Vector2, aim: Vector2, at: Vector2, reach: float, half_angle_deg: float) -> bool:
	var offset := at - from
	if offset.length() > reach or offset.is_zero_approx():
		return offset.is_zero_approx()
	return absf(aim.angle_to(offset)) <= deg_to_rad(half_angle_deg)


func use(ctx: EffectContext) -> bool:
	var aim := ctx.player.aim_direction() if ctx.has_player() else Vector2.RIGHT
	for enemy in ctx.enemies():
		if not in_cone(ctx.feet(), aim, enemy.global_position, REACH, HALF_ANGLE):
			continue
		enemy.apply_push(ctx.feet().direction_to(enemy.global_position) * PUSH, PUSH_TIME)
		ctx.stun(enemy, STUN)
	ctx.add_fx(ItemFx.make_shockwave(REACH * 0.6, COLOR), ctx.feet() + aim * 30.0)
	ctx.play_sound("alarm")
	return true
