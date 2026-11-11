extends ItemEffect

# Titanium Hip: dodging through an enemy hits it for a full plain swing, once each a dodge, and walking past
# a queue barrier sets off its metal detector.

const SHARE := 1.0
# His body while he rolls, round his middle.
const BODY := Vector2(20, 28)
const DETECTOR_REACH := 20.0

var _struck := {}
var _near_barriers := {}


func on_dodge(_ctx: EffectContext, _direction: Vector2) -> void:
	_struck.clear()


static func damage(run: RunState) -> float:
	return CaneCombo.DAMAGE[0] * SHARE * run.damage_mult()


func tick(ctx: EffectContext, _delta: float) -> void:
	if not ctx.has_player():
		return
	if ctx.player.is_dodging():
		strike_through(ctx, Rect2(ctx.player.global_position - BODY / 2.0, BODY))
	_check_detectors(ctx)


# Every enemy his body overlaps that this dodge has not hit yet takes a full swing.
func strike_through(ctx: EffectContext, body: Rect2) -> void:
	var run := ctx.run()
	if run == null:
		return
	for enemy in ctx.enemies():
		var key := enemy.get_instance_id()
		if _struck.has(key) or not body.intersects(enemy.body_rect()):
			continue
		_struck[key] = true
		ctx.hit_enemy(enemy, damage(run))
		ctx.add_fx(ItemFx.make_sparks(Color("c9c5d6")), enemy.global_position)


func _check_detectors(ctx: EffectContext) -> void:
	var feet := ctx.feet()
	for barrier in QueueBarrier.barriers_in(ctx.player.get_tree()):
		var key: int = barrier.get_instance_id()
		var near: bool = barrier.global_position.distance_to(feet) <= DETECTOR_REACH
		if near and not _near_barriers.has(key):
			ctx.play_sound("chime")
			ctx.add_fx(ItemFx.make_pop("BEEP", Color("e8c04a")), feet)
		if near:
			_near_barriers[key] = true
		else:
			_near_barriers.erase(key)
