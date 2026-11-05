extends ItemEffect

# Spare Pill Organizer: a heal taken at full health is stored instead, up to CAPACITY pills, and the
# store soaks the next damage he takes.

const CAPACITY := 2

var stored := 0


func accepts_pickup(ctx: EffectContext, kind: String) -> bool:
	var run := ctx.run()
	return kind == RunEffects.HEAL and stored < CAPACITY and run != null and run.health.pills >= run.health.max_pills


func on_pickup(ctx: EffectContext, kind: String, amount: int) -> int:
	var run := ctx.run()
	if kind != RunEffects.HEAL or run == null or run.health.pills < run.health.max_pills:
		return amount
	var kept := mini(amount, CAPACITY - stored)
	if kept > 0:
		stored += kept
		ctx.notice("Saved for later: %d in the organizer" % stored)
	return amount


func on_hurt(ctx: EffectContext, pills: int, _source: String) -> int:
	var used := mini(stored, pills)
	if used <= 0:
		return pills
	stored -= used
	ctx.add_fx(ItemFx.make_pop("-%d soaked" % used, Color("e4524f")), ctx.feet())
	return pills - used


# The heals waiting in the organizer.
func save_state() -> Dictionary:
	return state_of(["stored"])


func load_state(state: Dictionary) -> void:
	load_members(state, ["stored"])
