extends ItemEffect

# Wheelchair Wheels: the dodge is a longer roll (its stats), with a wheel at each side, and every enemy
# his body rolls over takes a plain swing's hit, once each a roll, and is shoved along the way he rolls.

const SHARE := 1.0
const PUSH := 90.0
# His body while he rolls, round his middle.
const BODY := Vector2(20, 28)

var _struck := {}
var _direction := Vector2.RIGHT


static func damage(run: RunState) -> float:
	return CaneCombo.DAMAGE[0] * SHARE * run.damage_mult()


func on_dodge(ctx: EffectContext, direction: Vector2) -> void:
	_struck.clear()
	_direction = direction.normalized() if not direction.is_zero_approx() else Vector2.RIGHT
	var run := ctx.run()
	var seconds := DodgeTimer.DURATION * (run.stats.dodge_length if run != null else 1.0) + 0.1
	var follow: Node2D = ctx.player if ctx.has_player() else null
	var at := follow.global_position if follow != null else ctx.feet()
	ctx.add_fx(ItemFx.make_wheels(follow, _direction, seconds), at)


func tick(ctx: EffectContext, _delta: float) -> void:
	if ctx.has_player() and ctx.player.is_dodging():
		roll_over(ctx, Rect2(ctx.player.global_position - BODY / 2.0, BODY))


# Every enemy his body overlaps that this roll has not hit yet is run over. Returns how many.
func roll_over(ctx: EffectContext, body: Rect2) -> int:
	var run := ctx.run()
	if run == null:
		return 0
	var count := 0
	for enemy in ctx.enemies():
		var key := enemy.get_instance_id()
		if _struck.has(key) or not body.intersects(enemy.body_rect()):
			continue
		_struck[key] = true
		ctx.hit_enemy(enemy, damage(run), RunEffects.ITEM, _direction * PUSH)
		ctx.add_fx(ItemFx.make_sparks(ItemFx.WHEEL_STEEL, 14.0), enemy.global_position)
		count += 1
	return count
