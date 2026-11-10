extends ItemEffect

# Bottomless Flask: every EVERY-th fight room cleared gives a Thermos back, with a pop. The full loop
# counts Thermoses as the rooms give them, so there it gives none.

const EVERY := 2
const TEXT := "+1 THERMOS"
var cleared := 0


func on_room_clear(ctx: EffectContext, _room: Node, _damage_taken_here: int) -> void:
	cleared += 1
	var run := ctx.run()
	if cleared % EVERY != 0 or run == null or ctx.counting_exact:
		return
	run.add_bombs(1)
	ctx.add_fx(ItemFx.make_pop(TEXT), ctx.feet())
	ctx.play_sound("thermos_pickup")


func save_state() -> Dictionary:
	return state_of(["cleared"])


func load_state(state: Dictionary) -> void:
	load_members(state, ["cleared"])
