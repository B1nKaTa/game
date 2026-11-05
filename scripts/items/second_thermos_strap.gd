extends ItemEffect

# Second Thermos Strap: two Thermoses the moment it is taken, and one more at the start of every floor.
# Landings are rests between floors, so they add none.

const AT_ONCE := 2
const EACH_FLOOR := 1


func on_gain(ctx: EffectContext) -> void:
	var run := ctx.run()
	if run != null:
		for i in AT_ONCE:
			run.add_bomb()


func on_floor_start(ctx: EffectContext) -> void:
	var run := ctx.run()
	if run == null or ctx.is_landing():
		return
	for i in EACH_FLOOR:
		run.add_bomb()
