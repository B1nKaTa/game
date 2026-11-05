extends ItemEffect

# Expired Coupon: the first shop he walks into on each floor sells everything for nothing, and every
# new floor (not a landing) takes one pill off his maximum for good, never the last one.

const FREE_NOTICE := "Expired Coupon: everything here is free."
const PILL_NOTICE := "Expired Coupon: one pill less, for good."

var _used_this_floor := false


func on_floor_start(ctx: EffectContext) -> void:
	if ctx.is_landing():
		return
	_used_this_floor = false
	var run := ctx.run()
	if run != null and run.lose_max_pill():
		ctx.notice(PILL_NOTICE)


func on_shop_open(ctx: EffectContext, stock: Array[Dictionary]) -> void:
	if _used_this_floor or ctx.counting_exact:
		return
	_used_this_floor = true
	for entry in stock:
		entry["price"] = 0
	ctx.notice(FREE_NOTICE)


# This floor's free shop, since a resumed floor does not start again.
func save_state() -> Dictionary:
	return state_of(["_used_this_floor"])


func load_state(state: Dictionary) -> void:
	load_members(state, ["_used_this_floor"])
