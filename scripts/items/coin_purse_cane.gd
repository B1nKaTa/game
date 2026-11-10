extends ItemEffect

# Coin Purse Cane: every PER Pension picked up loads a coin, at most MOST, and his next cane swing fires
# one: a shot that stops at the first enemy. A flashback's own moves fire nothing.

const PER := 10
const MOST := 3
const DAMAGE := 12.0
const DISTANCE := 220.0
const SPEED := 360.0
const AHEAD := 12.0
const GOLD := Color("ffd24a")
var loaded := 0
var _toward := 0


func on_pickup(_ctx: EffectContext, kind: String, amount: int) -> int:
	if kind != RunEffects.PENSION:
		return amount
	_toward += amount
	while _toward >= PER and loaded < MOST:
		_toward -= PER
		loaded += 1
	if loaded >= MOST:
		_toward = 0
	return amount


func on_swing(ctx: EffectContext, swing: SwingAttack) -> void:
	if loaded <= 0 or swing.from_era or ctx.counting_exact:
		return
	loaded -= 1
	var coin := ItemFx.make_needle(ctx, swing.direction, DAMAGE, DISTANCE)
	coin.stops_at_first = true
	coin.speed = SPEED
	coin.color = GOLD
	ctx.add_fx(coin, ctx.feet() + swing.direction * AHEAD)
	ctx.play_sound("coin")


func save_state() -> Dictionary:
	return state_of(["loaded", "_toward"])


func load_state(state: Dictionary) -> void:
	load_members(state, ["loaded", "_toward"])
