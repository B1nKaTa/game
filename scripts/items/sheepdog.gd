extends PetEffect

# Old Shep: every EVERY seconds he herds every regular enemy within REACH toward a spot AHEAD of Harold,
# the way he aims, over TIME, dazing them a moment. No damage. The full loop places its own enemies, so
# there he only watches.

const EVERY := 6.0
const REACH := 220.0
const AHEAD := 64.0
const TIME := 0.35
const DAZE := 0.3
var _left := EVERY


func tick(ctx: EffectContext, delta: float) -> void:
	_left -= delta
	if _left > 0.0:
		return
	_left = EVERY
	if ctx.counting_exact:
		return
	var aim := ctx.player.aim_direction() if ctx.has_player() else Vector2.RIGHT
	var spot := ctx.feet() + aim * AHEAD
	for enemy in ctx.enemies_near(ctx.feet(), REACH):
		if enemy.def.is_boss:
			continue
		enemy.apply_push((spot - enemy.global_position) / TIME, TIME)
		enemy.daze(DAZE)
	var body := pet()
	if body != null:
		body.lunge_to(spot)
