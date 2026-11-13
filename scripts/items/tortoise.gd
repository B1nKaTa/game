extends PetEffect

# Shelley the Tortoise: plods after Harold at SPEED. Every shot that touches her body stops; she cannot be
# hurt and never runs out. The full loop counts every pill a shot costs, so there she stops nothing.

const SPEED := 40.0
const BODY_REACH := 10.0
var _ctx: EffectContext


func on_gain(ctx: EffectContext) -> void:
	_ctx = ctx
	super(ctx)


func base_speed() -> float:
	return SPEED


func setup_pet(ctx: EffectContext, body: Pet) -> void:
	_ctx = ctx
	body.radius = BODY_REACH
	body.check = can_block
	body.roams = false
	body.spend = blocked


func can_block() -> bool:
	return not (_ctx != null and _ctx.counting_pills)


func blocked() -> void:
	pass
