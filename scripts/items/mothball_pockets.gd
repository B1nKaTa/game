extends ItemEffect

# Mothball Pockets: after a hit costs him a pill, ghosts (the Soot Ghosts, the Debt Collector Ghost and
# the Weeping Mourners) are pushed back out of KEEP_AWAY for KEEP_TIME, with a puff of mothball haze
# round him while it lasts. Bosses never count as ghosts.

const KEEP_TIME := 2.0
const KEEP_AWAY := 72.0
const SHOVE := 220.0
const HAZE := Color(0.93, 0.93, 0.98, 0.5)

var left := 0.0


# Whether an enemy is one of the ghosts the mothballs keep off.
static func is_ghost(enemy_def: EnemyDef) -> bool:
	if enemy_def == null or enemy_def.is_boss:
		return false
	return enemy_def.id.contains("ghost") or enemy_def.id.contains("mourner")


func on_room_enter(_ctx: EffectContext, _room: Node) -> void:
	left = 0.0


func on_hurt(ctx: EffectContext, pills: int, _source: String) -> int:
	if pills > 0:
		left = KEEP_TIME
		var haze := ItemFx.make_cloud(KEEP_AWAY * 0.5, KEEP_TIME, HAZE)
		if ctx.has_player():
			haze.ride(ctx.player)
		ctx.add_fx(haze, ctx.feet())
	return pills


func tick(ctx: EffectContext, delta: float) -> void:
	if left <= 0.0:
		return
	left = maxf(left - delta, 0.0)
	keep_off(ctx, ctx.feet())


# Shoves every ghost within KEEP_AWAY of a spot away from it. Returns how many it shoved.
func keep_off(ctx: EffectContext, at: Vector2) -> int:
	var count := 0
	for enemy in ctx.enemies_near(at, KEEP_AWAY):
		if not is_ghost(enemy.def):
			continue
		var away := at.direction_to(enemy.global_position)
		if away.is_zero_approx():
			away = Vector2.RIGHT
		enemy.apply_push(away * SHOVE, 0.12)
		count += 1
	return count
