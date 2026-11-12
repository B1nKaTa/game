extends PetEffect

# Joey the Budgie: circles Harold and blocks a shot, then needs REST seconds before he blocks again. The full
# loop counts every pill a shot costs, so there he blocks nothing.

const REST := 3.0
const ORBIT := 22.0
const ORBIT_SPEED := 3.0
const REACH := 42.0
var _rest := 0.0
# Kept for can_block, which the guard calls with no context. Set on taking and on every room; a resumed run
# walks into its room, which sets it again. Safe: the run owns this effect, the context holds the run weakly.
var _ctx: EffectContext


func on_gain(ctx: EffectContext) -> void:
	_ctx = ctx
	super(ctx)


func on_room_enter(ctx: EffectContext, room: Node) -> void:
	_ctx = ctx
	super(ctx, room)


func setup_pet(_ctx_now: EffectContext, body: Pet) -> void:
	body.orbit_speed = ORBIT_SPEED
	body.orbit_radius = ORBIT
	body.radius = REACH
	body.check = can_block
	body.spend = blocked


func can_block() -> bool:
	return _rest <= 0.0 and not (_ctx != null and _ctx.counting_pills)


func blocked() -> void:
	_rest = REST


func tick(_ctx_now: EffectContext, delta: float) -> void:
	_rest = maxf(_rest - delta, 0.0)
