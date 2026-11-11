extends ItemEffect

# Cactus Brooch: an enemy whose body touches his takes DAMAGE (an item hit) and is pushed away, each at
# most once every AGAIN. It shows as a green spark where it pricks, never a ring of thorns. The full loop
# measures what each hit deals, so there it pricks nobody.

const DAMAGE := 6.0
const PUSH := 160.0
const PUSH_TIME := 0.2
const AGAIN := 0.5
# His body over his feet, and how close counts as touching.
const BODY := Vector2(20, 28)
const REACH := 3.0
const GREEN := Color("6fbf5a")
var _again := {}


func on_room_enter(_ctx: EffectContext, _room: Node) -> void:
	_again.clear()


func tick(ctx: EffectContext, delta: float) -> void:
	for key in _again.keys():
		_again[key] = float(_again[key]) - delta
		if _again[key] <= 0.0:
			_again.erase(key)
	if ctx.counting_exact:
		return
	var body := Rect2(ctx.feet() - Vector2(BODY.x / 2.0, BODY.y), BODY).grow(REACH)
	for enemy in ctx.enemies():
		var key := enemy.get_instance_id()
		if _again.has(key) or not enemy.body_rect().intersects(body):
			continue
		_again[key] = AGAIN
		var away := ctx.feet().direction_to(enemy.global_position)
		ctx.add_fx(ItemFx.make_sparks(GREEN, 6.0), enemy.global_position)
		ctx.hit_enemy(enemy, DAMAGE, RunEffects.ITEM)
		if not enemy.is_dead() and not away.is_zero_approx():
			enemy.apply_push(away * PUSH, PUSH_TIME)
