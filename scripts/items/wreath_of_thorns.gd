extends ItemEffect

# Wreath of Thorns: a ring of thorns round his feet, and any enemy whose body touches his takes DAMAGE,
# each at most once every AGAIN_AFTER. Its hits run the hooks as item hits.

const DAMAGE := 4.0
const AGAIN_AFTER := 0.5
# His body, round where he stands, and how close counts as touching. His feet box counts as body too, so
# whatever costs him a pill by touching him (ContactRule) is always close enough to prick.
const BODY := Vector2(20, 28)
const REACH := 3.0
const SPARK := Color("c9d98a")

var _time := 0.0
# Instance id -> the time it may be pricked again.
var _next := {}


func on_room_enter(ctx: EffectContext, _room: Node) -> void:
	_next.clear()
	if ctx.has_player():
		ctx.add_fx(ItemFx.make_wreath(ctx.player), ctx.player.global_position)


# The full loop measures what each hit on an enemy deals, so there the thorns prick nobody.
func tick(ctx: EffectContext, delta: float) -> void:
	_time += delta
	if ctx.has_player() and not ctx.counting_exact:
		prick(ctx, body_of(ctx.player.global_position, ctx.feet()))


# His body round its middle, with his feet box added.
static func body_of(center: Vector2, feet: Vector2) -> Rect2:
	return Rect2(center - BODY / 2.0, BODY).merge(ContactRule.feet_box(feet, Player.FEET_BOX_SIZE))


# Pricks every enemy due whose body touches this one. Returns how many it pricked.
func prick(ctx: EffectContext, body: Rect2) -> int:
	var count := 0
	var touching := body.grow(REACH)
	for enemy in ctx.enemies():
		if enemy.submerged or not touching.intersects(enemy.body_rect()):
			continue
		var key := enemy.get_instance_id()
		if float(_next.get(key, -1.0)) > _time:
			continue
		_next[key] = _time + AGAIN_AFTER
		ctx.hit_enemy(enemy, DAMAGE)
		ctx.add_fx(ItemFx.make_sparks(SPARK, 10.0), enemy.global_position)
		count += 1
	return count
