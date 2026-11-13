extends PetEffect

# Pet Rock: a pet that only grows. Its size is 1 plus the other pets-build items held. At BIG or more it
# sits at his heel and stops every shot that touches it.

const BIG := 3
var _ctx: EffectContext


func on_gain(ctx: EffectContext) -> void:
	_ctx = ctx
	super(ctx)


func size(ctx: EffectContext) -> int:
	var run := ctx.run()
	if run == null:
		return 1
	var grown := 1
	for item in run.items:
		if item.build == "pets" and item.id != "pet_rock":
			grown += 1
	if run.active != null and run.active.build == "pets":
		grown += 1
	return grown


func setup_pet(ctx: EffectContext, body: Pet) -> void:
	_ctx = ctx
	body.radius = 6.0 + 3.0 * size(ctx)
	body.check = can_block
	body.roams = false
	body.scale = Vector2.ONE * (1.0 + 0.25 * (size(ctx) - 1))


func can_block() -> bool:
	return _ctx != null and size(_ctx) >= BIG and not _ctx.counting_pills
