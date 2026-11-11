extends PetEffect

# Pocketful of Moths: two moths circle Harold at ORBIT, opposite each other. A moth touching an enemy's
# body nibbles it for DAMAGE (a pet hit), each enemy at most once every AGAIN per moth. Each moth blocks
# one shot, then is gone for GONE seconds.

const COUNT := 2
const ORBIT := 26.0
const DAMAGE := 2.0
const AGAIN := 0.5
const GONE := 4.0
const REACH := 8.0
@export var orbit_speed := 2.5
var _angle := 0.0
var _gone: Array[float] = [0.0, 0.0]
# Moth index -> {enemy instance id: seconds until it may nibble that one again}.
var _again: Array = [{}, {}]
var _ctx: EffectContext


func on_gain(ctx: EffectContext) -> void:
	_ctx = ctx


func on_room_enter(ctx: EffectContext, _room: Node) -> void:
	_ctx = ctx
	_again = [{}, {}]
	for i in COUNT:
		var body := Pet.make(look, color, slot, base_speed())
		body.follow = ctx.player if ctx.has_player() else null
		body.orbit_speed = orbit_speed
		body.orbit_radius = ORBIT
		body.orbit_angle = _angle + PI * i
		body.radius = REACH
		body.check = can_block.bind(i)
		body.spend = blocked.bind(i)
		ctx.add_fx(body, moth_spot(ctx, i))


func moth_spot(ctx: EffectContext, index: int) -> Vector2:
	return ctx.feet() + Vector2.from_angle(_angle + PI * index) * ORBIT


func can_block(index: int) -> bool:
	return _gone[index] <= 0.0 and not (_ctx != null and _ctx.counting_pills)


func blocked(index: int) -> void:
	_gone[index] = GONE


func tick(ctx: EffectContext, delta: float) -> void:
	_angle = wrapf(_angle + orbit_speed * delta, 0.0, TAU)
	for i in COUNT:
		_gone[i] = maxf(_gone[i] - delta, 0.0)
		var waits: Dictionary = _again[i]
		for key in waits.keys():
			waits[key] = float(waits[key]) - delta
			if waits[key] <= 0.0:
				waits.erase(key)
		if _gone[i] > 0.0:
			continue
		var spot := moth_spot(ctx, i)
		for enemy in ctx.enemies():
			var key := enemy.get_instance_id()
			if waits.has(key) or not enemy.body_rect().grow(REACH).has_point(spot):
				continue
			if strike(ctx, enemy, DAMAGE):
				waits[key] = AGAIN
