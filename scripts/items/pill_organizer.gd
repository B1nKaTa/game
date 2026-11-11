extends ItemEffect

# Spare Pill Organizer: a heal taken at full health is stored instead, up to CAPACITY, and each stored heal
# soaks one whole hit, however big. The full loop counts every pill, so there it neither stores nor soaks.

const CAPACITY := 3
const COLOR := Color("e4524f")
var stored := 0


func accepts_pickup(ctx: EffectContext, kind: String) -> bool:
	var run := ctx.run()
	return kind == RunEffects.HEAL and stored < CAPACITY and run != null and run.health.pills >= run.health.max_pills and not ctx.counting_pills


func on_pickup(ctx: EffectContext, kind: String, amount: int) -> int:
	var run := ctx.run()
	if kind != RunEffects.HEAL or run == null or ctx.counting_pills or run.health.pills < run.health.max_pills or stored >= CAPACITY:
		return amount
	stored += 1
	ctx.notice("Saved for later: %d in the organizer" % stored)
	return amount


func on_hurt(ctx: EffectContext, pills: int, _source: String) -> int:
	if pills <= 0 or stored <= 0 or ctx.counting_pills:
		return pills
	stored -= 1
	ctx.add_fx(ItemFx.make_pop("SOAKED", COLOR), ctx.feet())
	return 0


func save_state() -> Dictionary:
	return state_of(["stored"])


func load_state(state: Dictionary) -> void:
	load_members(state, ["stored"])
