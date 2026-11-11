extends PetEffect

# Racing Pigeon: every EVERY seconds it fetches the nearest waiting coin, Slip or Thermos in the room that
# Harold could take, which flies to him.

const EVERY := 1.5
var _left := EVERY


func tick(ctx: EffectContext, delta: float) -> void:
	_left -= delta
	if _left > 0.0:
		return
	_left = EVERY
	if ctx.fetch_pickup():
		var body := pet()
		if body != null:
			body.lunge_to(ctx.feet())
