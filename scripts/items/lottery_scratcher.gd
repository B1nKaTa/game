extends ItemEffect

# Lottery Scratcher (active, once a floor): scratch for one prize at his feet: a coin of COIN Pension, a
# Slip, a Thermos, a one-pill heal or, rarely, a free item (a coin when no item is left to offer).

const COIN := 25
const EDGES := [[0.40, "coin"], [0.60, "key"], [0.80, "bomb"], [0.95, "heal"], [1.01, "item"]]
const AHEAD := Vector2(16, 0)
var rng := RandomNumberGenerator.new()


static func prize(roll: float) -> String:
	for edge in EDGES:
		if roll < edge[0]:
			return edge[1]
	return "item"


func on_gain(_ctx: EffectContext) -> void:
	rng.randomize()


func load_state(_state: Dictionary) -> void:
	rng.randomize()


func use(ctx: EffectContext) -> bool:
	var run := ctx.run()
	# A coin and a heal do nothing while the full loop counts, so the charge is kept.
	if run == null or ctx.counting_exact or ctx.counting_pills:
		return false
	var at := ctx.feet() + AHEAD
	match prize(rng.randf()):
		"key":
			ctx.drop(RoomRules.DROP_KEY, at)
		"bomb":
			ctx.drop(RoomRules.DROP_BOMB, at)
		"heal":
			ctx.drop(RoomRules.DROP_HEAL, at, 1)
		"item":
			var picked := RoomRules.pick_items(Content.items(), run, 1, rng, ItemRarity.ITEM_ROOM)
			if picked.is_empty():
				ctx.drop(RoomRules.DROP_COIN, at, run.pension_amount(COIN, RunState.PENSION_REWARD))
			else:
				ctx.drop_item(picked[0], at)
		_:
			ctx.drop(RoomRules.DROP_COIN, at, run.pension_amount(COIN, RunState.PENSION_REWARD))
	ctx.play_sound("slot_win")
	return true
