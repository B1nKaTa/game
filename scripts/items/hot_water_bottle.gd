extends ItemEffect

# Hot Water Bottle: in a fight, once he has stood still for STILL_AFTER, the bottle warms for as long as he
# keeps still, and every EVERY seconds of warmth heal half a pill, at most ROOM_HALVES halves a room. Its
# warmth keeps while he walks, but any pill he loses cools it right down, so it never heals under fire.

const STILL_AFTER := 1.0
const EVERY := 8.0
const ROOM_HALVES := 2
# Slower than this counts as standing still.
const STILL_SPEED := 4.0
const COLOR := Color("ff9a5a")

var _still := 0.0
var _warmth := 0.0
var _halves := 0


func on_room_enter(_ctx: EffectContext, _room: Node) -> void:
	_still = 0.0
	_warmth = 0.0
	_halves = 0


func on_hurt(_ctx: EffectContext, pills: int, _source: String) -> int:
	if pills > 0:
		_still = 0.0
		_warmth = 0.0
	return pills


func tick(ctx: EffectContext, delta: float) -> void:
	if ctx.has_player():
		warm(ctx, ctx.player.velocity.length() <= STILL_SPEED and not ctx.player.is_dodging(), delta)


# A frame of standing still or not. Returns whether it healed.
func warm(ctx: EffectContext, still: bool, delta: float) -> bool:
	if not still:
		_still = 0.0
		return false
	_still += delta
	var run := ctx.run()
	if _still < STILL_AFTER or _halves >= ROOM_HALVES or run == null or run.health.pills >= run.health.max_pills:
		return false
	if ctx.enemies().is_empty():
		return false
	_warmth += delta
	if _warmth < EVERY:
		return false
	_warmth -= EVERY
	_halves += 1
	ctx.heal_half()
	ctx.add_fx(ItemFx.make_pop("+1/2", COLOR), ctx.feet() + Vector2(0, -14))
	return true


func warmth() -> float:
	return _warmth
