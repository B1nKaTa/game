extends ItemEffect

# Eternal Warranty: the first hit of the run that would finish him (after any Life Jacket) instead puts
# him back at the room's door, the spot he walked in at, with every pill. It saves him through the run's
# lethal hook, so it waits its turn behind the Life Jacket and any item taken before it.

const NOTICE := "Eternal Warranty: repaired as new, back at the door."
const COLOR := Color("8fe6f2")

var used := false
var _saving := false


func on_lethal(_ctx: EffectContext) -> bool:
	if used:
		return false
	used = true
	_saving = true
	return true


# The hit has left him on one pill: fill him up and take him back to the door.
func on_saved(ctx: EffectContext) -> void:
	if not _saving:
		return
	_saving = false
	var run := ctx.run()
	if run != null:
		run.health.heal(run.health.max_pills)
	ctx.return_to_door()
	ctx.notice(NOTICE)
	ctx.add_fx(ItemFx.make_pop("GOOD AS NEW", COLOR), ctx.feet())
	ctx.play_sound("lethal_save")


# Once a run, so a resumed run remembers it was used.
func save_state() -> Dictionary:
	return state_of(["used"])


func load_state(state: Dictionary) -> void:
	load_members(state, ["used"])
