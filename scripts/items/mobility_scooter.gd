extends ItemEffect

# Mobility Scooter, the combo of the Titanium Hip and Wheelchair Wheels: the roll leaves a short trail of
# small fires behind it, one every STEP pixels, each burning what stands in it for a while.

const STEP := 18.0
const RADIUS := 10.0
const TIME := 1.5
const DAMAGE := 3.0

var _last := Vector2.INF


func tick(ctx: EffectContext, _delta: float) -> void:
	if not ctx.has_player() or not ctx.player.is_dodging():
		_last = Vector2.INF
		return
	trail(ctx, ctx.feet())


# Lays a fire here if the roll has come STEP from the last one. Returns whether it laid one.
func trail(ctx: EffectContext, at: Vector2) -> bool:
	if _last != Vector2.INF and at.distance_to(_last) < STEP:
		return false
	_last = at
	ctx.add_fx(ItemFx.make_burn(ctx, RADIUS, TIME, DAMAGE), at)
	return true


func end_roll() -> void:
	_last = Vector2.INF
