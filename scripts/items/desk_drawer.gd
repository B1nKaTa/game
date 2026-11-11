extends ItemEffect

# Desk Drawer: the first Slip he picks up in a room also gives a Thermos, and the first Thermos also gives
# a Slip. The full loop counts both exactly.

var _gave_bomb := false
var _gave_slip := false


func on_room_enter(_ctx: EffectContext, _room: Node) -> void:
	_gave_bomb = false
	_gave_slip = false


func on_pickup(ctx: EffectContext, kind: String, amount: int) -> int:
	var run := ctx.run()
	if run == null or ctx.counting_exact:
		return amount
	if kind == RunEffects.SLIP and not _gave_bomb:
		_gave_bomb = true
		run.add_bombs(1)
	elif kind == RunEffects.BOMB and not _gave_slip:
		_gave_slip = true
		run.add_keys(1)
	return amount
